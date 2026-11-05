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
    let updater: UpdateChecking = SparkleUpdater()
    let hud = MinimumSizeHUD()
    // MARK: add-multi-window-modes
    /// Screens with the Stage Manager strip and Todo sidebar removed; used by single-window snapping.
    let layoutScreens: ScreenProvider
    let controller: SnapController
    private(set) lazy var multiWindow = MultiWindowCoordinator(
        settings: settings, windows: windows, screens: screens, snap: controller, isTrusted: { [weak self] in self?.trusted ?? false })
    let debugLog = DebugLog(isEnabled: { HiddenPreferences().debugLogging })
    private(set) lazy var router = AutomationRouter(settings: settings, host: self, log: debugLog)
    private(set) lazy var dragMonitor = DragSnapMonitor(
        windows: windows, screens: layoutScreens, controller: controller, settings: settings, overlay: overlay)

    private(set) lazy var input = InputCoordinator(
        settings: settings, windows: windows, screens: layoutScreens, controller: controller, overlay: overlay,
        isWindowDrag: { [weak self] in self?.dragMonitor.isWindowDrag ?? false })

    // MARK: add-custom-layouts-and-spaces (logic lives in AppModel+CustomLayouts.swift)
    private(set) lazy var layoutStore = CustomLayoutStore(settings: settings)
    private(set) lazy var spaceMover = PrivateSpaceMover(provider: windows)
    private(set) lazy var spaces = SpaceActionController(
        settings: settings, windows: windows, mover: spaceMover, log: debugLog)
    private(set) lazy var runner = RuntimeActionRunner(
        store: layoutStore, controller: controller, windows: windows, screens: screens, lister: windows,
        spaces: spaces, options: { [settings] in settings.get(.layoutOptions) })
    @Published var layoutMessage: String?

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
        let store = settings
        layoutScreens = ReservedScreenProvider(
            base: screens, settings: store,
            stageManagerActive: MultiWindowCoordinator.isStageManagerActive)
        controller = SnapController(windows: windows, screens: layoutScreens, options: { store.get(.layoutOptions) })
        controller.onMinimumSizeReached = { [hud] _, actual in hud.show(near: actual) }
        windows.compatibility = WindowCompatibility(settings: settings)
        windows.debugLog = debugLog
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func start() {
        hotkeys.onAction = { [weak self] action in self?.perform(action) }
        hotkeys.onRuntimeAction = { [weak self] action in self?.perform(action) }
        hotkeys.install()
        loadLaunchConfig()
        trackFrontmostApp()
        applyShortcuts()
        settings.changes
            .filter {
                [SettingKey<ShortcutMap>.shortcuts.name, SettingKey<LossyArray<CustomZone>>.customZones.name,
                    SettingKey<LossyArray<SavedLayout>>.savedLayouts.name].contains($0)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyShortcuts() }
            .store(in: &cancellables)
        settings.changes
            .filter { $0 == SettingKey<[String]>.ignoredApps.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshIgnoreState() }
            .store(in: &cancellables)

        multiWindow.start()
        applyUpdateSettings()
        settings.changes
            .filter { $0 == SettingKey<Bool>.automaticUpdateChecks.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyUpdateSettings(userChanged: true) }
            .store(in: &cancellables)

        refreshTrust()
        if !trusted { showOnboarding() }
        // refreshTrust() owns the poll timer: it polls until access is granted and the drag monitor is up.
    }

    func perform(_ action: SnapAction) {
        if !trusted { showOnboarding(); return }
        // MARK: add-multi-window-modes
        let changed = action.isMultiWindow ? multiWindow.controller.perform(action) : controller.perform(action)
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
        let map = settings.get(.shortcuts)
        failedShortcuts = hotkeys.register(map, runtime: layoutStore.hotkeyBindings(builtIn: map))
    }

    /// Pushes the setting to Sparkle. At launch only an explicit "off" is applied: setting `true` in code
    /// would skip Sparkle's own consent prompt.
    func applyUpdateSettings(userChanged: Bool = false) {
        let enabled = settings.get(.automaticUpdateChecks)
        if userChanged || !enabled { updater.automaticallyChecks = enabled }
    }

    func refreshTrust() {
        let now = AXIsProcessTrusted()
        if now != trusted { trusted = now }
        if now {
            if !dragMonitor.isRunning { dragMonitor.start() }
            input.start()
            onboarding.close()
        } else if dragMonitor.isRunning {
            dragMonitor.stop()
            input.stop()
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
        settingsWindow.show(
            title: "Snapr Settings", size: CGSize(width: 860, height: 620), minSize: CGSize(width: 760, height: 520)
        ) {
            SettingsView(model: self)
        }
    }
}
