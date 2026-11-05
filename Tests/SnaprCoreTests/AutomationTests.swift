import XCTest
@testable import SnaprCore

private final class FakeHost: AutomationHost {
    var frontmostBundleID: String? = "com.example.Front"
    var performed: [SnapAction] = []
    func perform(_ action: SnapAction) { performed.append(action) }
}

final class AutomationTests: XCTestCase {
    private func url(_ string: String) -> URL { URL(string: string)! }

    // MARK: URL parsing

    func testParseExecuteAction() {
        XCTAssertEqual(
            AutomationURL.parse(url("snapr://execute-action?name=left-half")), .executeAction(name: "left-half"))
    }

    func testParseRejectsBadInput() {
        XCTAssertNil(AutomationURL.parse(url("https://execute-action?name=left-half")))
        XCTAssertNil(AutomationURL.parse(url("snapr://execute-action")))
        XCTAssertNil(AutomationURL.parse(url("snapr://execute-action?name=")))
        XCTAssertNil(AutomationURL.parse(url("snapr://nope?name=x")))
    }

    func testParseIgnoreVariants() {
        XCTAssertEqual(AutomationURL.parse(url("snapr://ignore-app?bundle-id=a.b")), .ignoreApp(bundleID: "a.b"))
        XCTAssertEqual(AutomationURL.parse(url("snapr://ignore-app")), .ignoreApp(bundleID: nil))
        XCTAssertEqual(AutomationURL.parse(url("snapr://unignore-app?bundle-id=a.b")), .unignoreApp(bundleID: "a.b"))
    }

    // MARK: Router

    private func makeRouter() -> (AutomationRouter, FakeHost, SettingsStore) {
        let settings = SettingsStore(storage: MemorySettingsStorage())
        let host = FakeHost()
        return (AutomationRouter(settings: settings, host: host), host, settings)
    }

    func testRouterExecutesEveryRegisteredAction() {
        let (router, host, _) = makeRouter()
        for action in ActionRegistry.all {
            XCTAssertEqual(router.handle(url("snapr://execute-action?name=\(action.name)")), .performed(action))
        }
        XCTAssertEqual(host.performed, ActionRegistry.all)
    }

    func testRouterRejectsUnknownAction() {
        let (router, host, _) = makeRouter()
        XCTAssertEqual(router.handle(url("snapr://execute-action?name=bogus")), .unknownAction("bogus"))
        XCTAssertTrue(host.performed.isEmpty)
        XCTAssertEqual(router.handle(url("snapr://bogus")), .invalidURL)
    }

    func testIgnoreAndUnignore() {
        let (router, _, settings) = makeRouter()
        XCTAssertEqual(router.handle(url("snapr://ignore-app?bundle-id=a.b")), .ignored("a.b"))
        XCTAssertEqual(router.handle(url("snapr://ignore-app?bundle-id=a.b")), .ignored("a.b"))
        XCTAssertEqual(settings.get(.ignoredApps), ["a.b"])
        XCTAssertTrue(settings.isIgnored("a.b"))
        XCTAssertEqual(router.handle(url("snapr://unignore-app?bundle-id=a.b")), .unignored("a.b"))
        XCTAssertFalse(settings.isIgnored("a.b"))
    }

    func testIgnoreDefaultsToFrontmostApp() {
        let (router, host, settings) = makeRouter()
        XCTAssertEqual(router.handle(url("snapr://ignore-app")), .ignored("com.example.Front"))
        XCTAssertTrue(settings.isIgnored("com.example.Front"))
        host.frontmostBundleID = nil
        XCTAssertEqual(router.handle(url("snapr://unignore-app")), .noTargetApp)
    }

    // MARK: Hidden preferences

    private func makeDefaults() -> UserDefaults {
        let name = "snapr.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    func testHiddenPreferencesDefaults() {
        let prefs = HiddenPreferences(defaults: makeDefaults())
        XCTAssertFalse(prefs.debugLogging)
        XCTAssertTrue(prefs.enhancedUIHandling)
        XCTAssertEqual(prefs.nativeResizeApps, [])
    }

    func testHiddenPreferencesReadNativeValues() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "debugLogging")
        defaults.set(false, forKey: "enhancedUIHandling")
        defaults.set(["a.b", "c.d"], forKey: "nativeResizeApps")
        let prefs = HiddenPreferences(defaults: defaults)
        XCTAssertTrue(prefs.debugLogging)
        XCTAssertFalse(prefs.enhancedUIHandling)
        XCTAssertEqual(prefs.nativeResizeApps, ["a.b", "c.d"])
    }

    func testHiddenPreferencesIgnoreWrongTypes() {
        let defaults = makeDefaults()
        defaults.set("yes", forKey: "debugLogging")
        defaults.set("oops", forKey: "nativeResizeApps")
        let prefs = HiddenPreferences(defaults: defaults)
        XCTAssertFalse(prefs.debugLogging)
        XCTAssertEqual(prefs.nativeResizeApps, [])
    }

    func testNativeResizeMergesSettingsAndHidden() {
        let defaults = makeDefaults()
        defaults.set(["hidden.app"], forKey: "nativeResizeApps")
        let settings = SettingsStore(storage: MemorySettingsStorage())
        settings.set(["list.app"], for: .nativeResizeApps)
        let compat = WindowCompatibility(settings: settings, hidden: HiddenPreferences(defaults: defaults))
        XCTAssertTrue(compat.usesNativeResize("hidden.app"))
        XCTAssertTrue(compat.usesNativeResize("list.app"))
        XCTAssertFalse(compat.usesNativeResize("other"))
        XCTAssertFalse(compat.usesNativeResize(nil))
    }

    // MARK: Debug log

    func testDebugLogRespectsEnabledAndCapacity() {
        var enabled = false
        let log = DebugLog(capacity: 3, isEnabled: { enabled })
        log.log("dropped")
        XCTAssertTrue(log.entries.isEmpty)
        enabled = true
        (1...5).forEach { log.log("m\($0)") }
        XCTAssertEqual(log.entries.map(\.message), ["m3", "m4", "m5"])
        log.clear()
        XCTAssertTrue(log.entries.isEmpty)
    }
}
