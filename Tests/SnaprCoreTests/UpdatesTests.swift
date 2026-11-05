import XCTest
@testable import SnaprCore

final class UpdatesTests: XCTestCase {
    func testConfiguredWithHTTPSFeedAndKey() {
        let config = UpdaterConfig(info: ["SUFeedURL": "https://example.com/appcast.xml", "SUPublicEDKey": "abc="])
        XCTAssertTrue(config.isConfigured)
    }

    func testMissingKeysAreUnconfigured() {
        XCTAssertFalse(UpdaterConfig(info: nil).isConfigured)
        XCTAssertFalse(UpdaterConfig(info: [:]).isConfigured)
        XCTAssertFalse(UpdaterConfig(info: ["SUFeedURL": "https://example.com/a.xml"]).isConfigured)
        XCTAssertFalse(UpdaterConfig(info: ["SUPublicEDKey": "abc="]).isConfigured)
    }

    func testBlankValuesAreUnconfigured() {
        let config = UpdaterConfig(info: ["SUFeedURL": "  ", "SUPublicEDKey": ""])
        XCTAssertNil(config.feedURL)
        XCTAssertNil(config.publicKey)
        XCTAssertFalse(config.isConfigured)
    }

    func testNonHTTPSFeedIsRejected() {
        XCTAssertFalse(UpdaterConfig(info: ["SUFeedURL": "http://example.com/a.xml", "SUPublicEDKey": "k"]).isConfigured)
        XCTAssertFalse(UpdaterConfig(info: ["SUFeedURL": "file:///tmp/a.xml", "SUPublicEDKey": "k"]).isConfigured)
    }

    func testAutomaticChecksDefaultsOnAndPersists() {
        let store = SettingsStore(storage: MemorySettingsStorage())
        XCTAssertTrue(store.get(.automaticUpdateChecks))
        store.set(false, for: .automaticUpdateChecks)
        XCTAssertFalse(store.get(.automaticUpdateChecks))
    }
}
