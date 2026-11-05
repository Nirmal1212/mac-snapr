import AppKit
import ApplicationServices
import Combine
import SnaprCore

/// Composition root: owns providers, controller, hotkeys, drag monitor and permission state.
final class AppModel: ObservableObject {
    static let shared = AppModel()

    let settings = SettingsStore()
    let windows = AXWindowProvider()
    let screens = SystemScreenProvider()
    let hotkeys = HotkeyManager()
    let overlay = PreviewOverlay()
    let controller: SnapController
    private(set) lazy var dragMonitor = DragSnapMonitor(
        windows: windows, screens: screens, controller: controller, settings: settings, overlay: overlay)

    @Published private(set) var trusted = AXIsProcessTrusted()
    @Published var failedShortcuts: [SnapAction] = []

    private var cancellables: Set<AnyCancellable> = []
    private var pollTimer: Timer?
    private let onboarding = WindowPresenter()
    private let settingsWindow = WindowPresenter()

    private init() {
        controller = SnapController(windows: windows, screens: screens)
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func start() {
        hotkeys.onAction = { [weak self] action in self?.controller.perform(action) }
        hotkeys.install()
        applyShortcuts()
        settings.changes
            .filter { $0 == SettingKey<ShortcutMap>.shortcuts.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyShortcuts() }
            .store(in: &cancellables)

        refreshTrust()
        if !trusted {
            showOnboarding()
            // Poll cheaply until the user grants access, then bring features up.
            pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
                self?.refreshTrust()
            }
        }
    }

    func perform(_ action: SnapAction) {
        if !trusted { showOnboarding(); return }
        controller.perform(action)
    }

    func applyShortcuts() {
        failedShortcuts = hotkeys.register(settings.get(.shortcuts))
    }

    func refreshTrust() {
        let now = AXIsProcessTrusted()
        if now != trusted { trusted = now }
        if now {
            if !dragMonitor.isRunning { dragMonitor.start() }
            pollTimer?.invalidate()
            pollTimer = nil
            onboarding.close()
        }
    }

    /// Shows the system prompt and opens the Accessibility pane.
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func showOnboarding() {
        onboarding.show(title: "Welcome to Snapr", size: CGSize(width: 440, height: 260)) {
            OnboardingView(model: self)
        }
    }

    func showSettings() {
        settingsWindow.show(title: "Snapr Settings", size: CGSize(width: 560, height: 640)) {
            SettingsView(model: self)
        }
    }
}
