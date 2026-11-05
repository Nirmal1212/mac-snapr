import Foundation

public extension SettingKey {
    /// Bundle identifiers of apps for which Snapr shortcuts are disabled while frontmost.
    static var ignoredApps: SettingKey<[String]> { .init("ignoredApps", default: []) }
    /// Bundle identifiers of apps resized with a single size-then-position pass.
    static var nativeResizeApps: SettingKey<[String]> { .init("nativeResizeApps", default: []) }
}

public extension SettingsStore {
    func isIgnored(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return get(.ignoredApps).contains(bundleID)
    }

    /// Maximum number of ignored apps (bounds growth from automation).
    static var maxIgnoredApps: Int { 500 }

    /// Adds `bundleID`; returns false when the list is full. Already-listed ids succeed.
    @discardableResult
    func ignore(_ bundleID: String) -> Bool {
        var list = get(.ignoredApps)
        if list.contains(bundleID) { return true }
        guard list.count < Self.maxIgnoredApps else { return false }
        list.append(bundleID)
        set(list, for: .ignoredApps)
        return true
    }

    func unignore(_ bundleID: String) {
        let list = get(.ignoredApps)
        guard list.contains(bundleID) else { return }
        set(list.filter { $0 != bundleID }, for: .ignoredApps)
    }
}

/// A parsed `snapr://` command.
public enum AutomationCommand: Equatable {
    /// `snapr://execute-action?name=<action name>`. The name is resolved through `ActionRegistry` at run time.
    case executeAction(name: String)
    /// `snapr://ignore-app?bundle-id=…`. The id is required: URLs never default to the frontmost app.
    case ignoreApp(bundleID: String)
    /// `snapr://unignore-app?bundle-id=…` (id required).
    case unignoreApp(bundleID: String)
}

public enum AutomationURL {
    public static let scheme = "snapr"

    /// Bundle ids from URLs must be 1...255 characters of [A-Za-z0-9.-].
    public static func isValidBundleID(_ id: String) -> Bool {
        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.-")
        return !id.isEmpty && id.utf8.count <= 255 && id.allSatisfy { allowed.contains($0) }
    }

    /// Parses a `snapr://` URL. Returns nil for other schemes, unknown tasks or missing required parameters.
    public static func parse(_ url: URL) -> AutomationCommand? {
        guard url.scheme?.lowercased() == scheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        // snapr://task?x=y puts the task in the host; tolerate snapr:///task too.
        let task = (components.host ?? components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            .lowercased()
        func value(_ name: String) -> String? {
            let found = components.queryItems?.first { $0.name == name }?.value
            return found?.isEmpty == false ? found : nil
        }
        switch task {
        case "execute-action":
            return value("name").map { .executeAction(name: $0) }
        case "ignore-app":
            guard let id = value("bundle-id"), isValidBundleID(id) else { return nil }
            return .ignoreApp(bundleID: id)
        case "unignore-app":
            guard let id = value("bundle-id"), isValidBundleID(id) else { return nil }
            return .unignoreApp(bundleID: id)
        default:
            return nil
        }
    }
}

/// What the app must provide to carry out automation commands.
public protocol AutomationHost: AnyObject {
    func perform(_ action: SnapAction)
}

/// Executes URL commands. Action names go through `ActionRegistry.action(named:)`, so every action
/// registered by any change is reachable without touching this type.
public final class AutomationRouter {
    public enum Outcome: Equatable {
        case performed(SnapAction)
        case ignored(String)
        case unignored(String)
        case unknownAction(String)
        case ignoreListFull
        case invalidURL
    }

    private let settings: SettingsStore
    private weak var host: AutomationHost?
    private let log: DebugLog?

    public init(settings: SettingsStore, host: AutomationHost, log: DebugLog? = nil) {
        self.settings = settings
        self.host = host
        self.log = log
    }

    @discardableResult
    public func handle(_ url: URL) -> Outcome {
        let outcome = run(AutomationURL.parse(url))
        log?.log("url \(url.absoluteString.prefix(200)) -> \(String(describing: outcome).prefix(200))")
        return outcome
    }

    private func run(_ command: AutomationCommand?) -> Outcome {
        guard let command else { return .invalidURL }
        switch command {
        case .executeAction(let name):
            guard let action = ActionRegistry.action(named: name) else { return .unknownAction(name) }
            host?.perform(action)
            return .performed(action)
        case .ignoreApp(let id):
            return settings.ignore(id) ? .ignored(id) : .ignoreListFull
        case .unignoreApp(let id):
            settings.unignore(id)
            return .unignored(id)
        }
    }
}
