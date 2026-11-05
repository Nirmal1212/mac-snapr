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

    func ignore(_ bundleID: String) {
        var list = get(.ignoredApps)
        guard !list.contains(bundleID) else { return }
        list.append(bundleID)
        set(list, for: .ignoredApps)
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
    /// `snapr://ignore-app[?bundle-id=…]`; nil means the frontmost app.
    case ignoreApp(bundleID: String?)
    /// `snapr://unignore-app[?bundle-id=…]`; nil means the frontmost app.
    case unignoreApp(bundleID: String?)
}

public enum AutomationURL {
    public static let scheme = "snapr"

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
            return .ignoreApp(bundleID: value("bundle-id"))
        case "unignore-app":
            return .unignoreApp(bundleID: value("bundle-id"))
        default:
            return nil
        }
    }
}

/// What the app must provide to carry out automation commands.
public protocol AutomationHost: AnyObject {
    var frontmostBundleID: String? { get }
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
        case noTargetApp
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
        log?.log("url \(url.absoluteString) -> \(outcome)")
        return outcome
    }

    private func run(_ command: AutomationCommand?) -> Outcome {
        guard let command else { return .invalidURL }
        switch command {
        case .executeAction(let name):
            guard let action = ActionRegistry.action(named: name) else { return .unknownAction(name) }
            host?.perform(action)
            return .performed(action)
        case .ignoreApp(let bundleID):
            guard let id = bundleID ?? host?.frontmostBundleID else { return .noTargetApp }
            settings.ignore(id)
            return .ignored(id)
        case .unignoreApp(let bundleID):
            guard let id = bundleID ?? host?.frontmostBundleID else { return .noTargetApp }
            settings.unignore(id)
            return .unignored(id)
        }
    }
}
