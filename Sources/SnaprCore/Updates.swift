import Foundation

/// Abstraction over the update engine (Sparkle in the app, a mock in tests).
public protocol UpdateChecking: AnyObject {
    /// True when the engine can run (bundle has a feed URL and public key).
    var isAvailable: Bool { get }
    var automaticallyChecks: Bool { get set }
    /// User-initiated check; shows UI.
    func checkForUpdates()
}

/// Decides from Info.plist values whether updating is configured for this build.
public struct UpdaterConfig: Equatable {
    public static let feedURLKey = "SUFeedURL"
    public static let publicKeyKey = "SUPublicEDKey"

    public let feedURL: URL?
    public let publicKey: String?

    public init(feedURL: URL?, publicKey: String?) {
        self.feedURL = feedURL
        self.publicKey = publicKey
    }

    public init(info: [String: Any]?) {
        let url = Self.trimmed(info?[Self.feedURLKey]).flatMap { URL(string: $0) }
        self.init(feedURL: url, publicKey: Self.trimmed(info?[Self.publicKeyKey]))
    }

    /// Only https feeds with a public key are usable; `file`/`http` feeds are rejected.
    public var isConfigured: Bool {
        guard let feedURL, publicKey != nil else { return false }
        return feedURL.scheme?.lowercased() == "https" && feedURL.host?.isEmpty == false
    }

    private static func trimmed(_ value: Any?) -> String? {
        guard let string = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty else {
            return nil
        }
        return string
    }
}

public extension SettingKey {
    /// Whether Snapr checks for updates automatically (about once a day).
    static var automaticUpdateChecks: SettingKey<Bool> { .init("automaticUpdateChecks", default: true) }
}
