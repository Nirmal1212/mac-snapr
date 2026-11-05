import AppKit
import ApplicationServices
import Combine
import SnaprCore

/// Composition root: owns providers, controller, hotkeys, drag monitor and permission state.
final class AppModel: ObservableObject, AutomationHost {
    static let shared = AppModel()

    let settings = SettingsStore()
    let windows = AXWindowProvider()
    let screens = SystemScreenProvider()
    let hotkeys = HotkeyManager()
    let overlay = PreviewOverlay()
    let controller: SnapController
    let debugLog = DebugLog(isEnabled: { HiddenPreferences().debugLogging })
    private(set) lazy var router = AutomationRouter(settings: settings, host: self, log: debugLog)
    private(set) lazy var dragMonitor = DragSnapMonitor(
        windows: windows, screens: screens, controller: controller, settings: settings, overlay: overlay)

    @Published private(set) var trusted = AXIsProcessTrusted()
    @Published private(set) var dragRunning = false
    @Published var failedShortcuts: [SnapAction] = []
    /// The most recent frontmost app other than Snapr (target of "Ignore app").
    @Published private(set) var targetApp: (bundleID: String, name: String)?
    @Published var configMessage: String?

    private var cancellables: Set<AnyCancellable> = []
    private var pollTimer: Timer?
    private let onboarding = WindowPresenter()
    private let settingsWindow = WindowPresenter()
    private let debugWindow = WindowPresenter()

    private init() {
        controller = SnapController(windows: windows, screens: screens)
        windows.compatibility = WindowCompatibility(settings: settings)
        windows.debugLog = debugLog
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func start() {
        hotkeys.onAction = { [weak self] action in self?.perform(action) }
        hotkeys.install()
        loadLaunchConfig()
        trackFrontmostApp()
        applyShortcuts()
        settings.changes
            .filter { $0 == SettingKey<ShortcutMap>.shortcuts.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyShortcuts() }
            .store(in: &cancellables)
        settings.changes
            .filter { $0 == SettingKey<[String]>.ignoredApps.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshIgnoreState() }
            .store(in: &cancellables)

        refreshTrust()
        if !trusted { showOnboarding() }
        // refreshTrust() owns the poll timer: it polls until access is granted and the drag monitor is up.
    }

    func perform(_ action: SnapAction) {
        if !trusted { showOnboarding(); return }
        let changed = controller.perform(action)
        debugLog.log("perform \(action.name) -> \(changed ? "moved" : "no change")")
    }

    // MARK: - Automation

    /// Entry point for `snapr://` URLs.
    func handle(url: URL) { router.handle(url) }

    // MARK: - Ignored apps

    var targetAppIgnored: Bool { settings.isIgnored(targetApp?.bundleID) }

    func toggleIgnoreTargetApp() {
        guard let id = targetApp?.bundleID else { return }
        if settings.isIgnored(id) { settings.unignore(id) } else { settings.ignore(id) }
    }

    /// Follows app activation: remembers the last external app and suspends hotkeys while an ignored app is frontmost.
    private func trackFrontmostApp() {
        updateTarget(NSWorkspace.shared.frontmostApplication)
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                self?.updateTarget(note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            }
            .store(in: &cancellables)
    }

    private func updateTarget(_ app: NSRunningApplication?) {
        guard let app, app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
            let id = app.bundleIdentifier
        else { return }
        targetApp = (id, app.localizedName ?? id)
        refreshIgnoreState()
    }

    private func refreshIgnoreState() {
        let enabled = !targetAppIgnored
        guard enabled != hotkeys.enabled else { return }
        hotkeys.enabled = enabled
        hotkeys.register(hotkeys.current)
        debugLog.log("shortcuts \(enabled ? "enabled" : "suspended") for \(targetApp?.bundleID ?? "?")")
    }

    // MARK: - Config

    private func loadLaunchConfig() {
        guard let url = ConfigDocument.defaultFileURL(), FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let skipped = try ConfigDocument.decode(from: Data(contentsOf: url)).apply(to: settings)
            debugLog.log("loaded \(url.path), skipped: \(skipped)")
        } catch {
            debugLog.log("could not load \(url.path): \(error.localizedDescription)")
        }
    }

    func exportConfig() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "snapr-config.json"
        panel.allowedContentTypes = [.json]
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ConfigDocument.export(from: settings).encoded().write(to: url)
            configMessage = "Exported to \(url.lastPathComponent)"
        } catch {
            configMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let skipped = try ConfigDocument.decode(from: Data(contentsOf: url)).apply(to: settings)
            configMessage = skipped.isEmpty
                ? "Imported \(url.lastPathComponent)"
                : "Imported; skipped unknown actions: \(skipped.joined(separator: ", "))"
            debugLog.log("imported \(url.path), skipped: \(skipped)")
        } catch {
            configMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    func applySpectacleShortcuts() { settings.set(ShortcutPresets.spectacle(), for: .shortcuts) }
    func restoreDefaultShortcuts() { settings.set(ShortcutPresets.defaults(), for: .shortcuts) }

    func showDebugLog() {
        debugWindow.show(title: "Snapr Debug Log", size: CGSize(width: 640, height: 420)) {
            DebugLogView(log: debugLog)
        }
    }

    func applyShortcuts() {
        failedShortcuts = hotkeys.register(settings.get(.shortcuts))
    }

    func refreshTrust() {
        let now = AXIsProcessTrusted()
        if now != trusted { trusted = now }
        if now {
            if !dragMonitor.isRunning { dragMonitor.start() }
            onboarding.close()
        } else if dragMonitor.isRunning {
            dragMonitor.stop()
        }
        let running = dragMonitor.isRunning
        if running != dragRunning { dragRunning = running }
        if now && running {
            pollTimer?.invalidate()
            pollTimer = nil
        } else if pollTimer == nil {
            pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
                self?.refreshTrust()
            }
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
