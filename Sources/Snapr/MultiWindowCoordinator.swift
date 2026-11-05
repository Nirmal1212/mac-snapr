import AppKit
import Combine
import SnaprCore

/// App-side owner of the multi-window features: the controller, the stack badge and the opt-in
/// new-window scan timer.
final class MultiWindowCoordinator {
    let controller: MultiWindowController
    private let monitor: NewWindowMonitor
    private let settings: SettingsStore
    private let badge = StackBadgeHUD()
    private var timer: Timer?
    private var cancellable: AnyCancellable?
    private let isTrusted: () -> Bool

    /// Whether Stage Manager is enabled (the system exposes only the on/off state, not the strip width).
    static func isStageManagerActive() -> Bool {
        UserDefaults(suiteName: "com.apple.WindowManager")?.bool(forKey: "GloballyEnabled") ?? false
    }

    init(
        settings: SettingsStore, windows: AXWindowProvider, screens: ScreenProvider, snap: SnapController,
        isTrusted: @escaping () -> Bool
    ) {
        self.settings = settings
        self.isTrusted = isTrusted
        let controller = MultiWindowController(
            list: windows, windows: windows, screens: screens,
            layoutOptions: { settings.get(.layoutOptions) },
            options: { settings.get(.multiWindowOptions) },
            saveOptions: { settings.set($0, for: .multiWindowOptions) },
            stageManagerActive: Self.isStageManagerActive)
        self.controller = controller
        monitor = NewWindowMonitor(
            list: windows,
            options: { settings.get(.multiWindowOptions) },
            apply: { action, window in
                if action.isMultiWindow {
                    controller.perform(action)
                } else {
                    snap.perform(action, on: window.info)
                }
            })
        controller.onStackChanged = { [badge] index, count, frame in badge.show(index: index, count: count, over: frame) }
    }

    func start() {
        updateTimer()
        cancellable = settings.changes
            .filter { $0 == SettingKey<MultiWindowOptions>.multiWindowOptions.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateTimer() }
    }

    /// The scan runs once per second and only while a new-window action is configured.
    private func updateTimer() {
        let wanted = monitor.isEnabled
        if wanted, timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self, self.isTrusted() else { return }
                self.monitor.scan()
            }
        } else if !wanted {
            timer?.invalidate()
            timer = nil
            monitor.scan()  // resets the baseline
        }
    }
}
