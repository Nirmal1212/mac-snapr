import XCTest
@testable import SnaprCore

final class SettingsIndexTests: XCTestCase {
    private let index = SettingsIndex.standard

    // MARK: Registry completeness

    func testSidebarOrderMatchesDesign() {
        XCTAssertEqual(
            SettingsSection.allCases.map(\.title),
            [
                "General", "Shortcuts", "Layout", "Gaps", "Drag and Snap", "Multiple Windows", "Custom Layouts",
                "Ignored Apps", "Compatibility", "Configuration", "About"
            ])
    }

    func testEverySectionHasSymbolAndEntries() {
        for section in SettingsSection.allCases {
            XCTAssertFalse(section.symbol.isEmpty, section.title)
            XCTAssertFalse(section.searchEntries.isEmpty, "\(section.title) has no search entries")
        }
    }

    func testEntryIdsAreUniqueAndNamespacedBySection() {
        let ids = index.entries.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate ids: \(ids.filter { id in ids.filter { $0 == id }.count > 1 })")
        for entry in index.entries {
            XCTAssertTrue(entry.id.hasPrefix(entry.section.idPrefix + "."), entry.id)
            XCTAssertFalse(entry.title.isEmpty, entry.id)
        }
    }

    func testEverySectionIsRepresentedInTheIndex() {
        let covered = Set(index.entries.map(\.section))
        XCTAssertEqual(covered, Set(SettingsSection.allCases))
    }

    func testEveryShortcutActionIsSearchable() {
        let ids = Set(SettingsSection.shortcuts.searchEntries.map(\.id))
        for action in ActionRegistry.all {
            XCTAssertTrue(ids.contains("shortcuts.action.\(action.rawValue)"), action.rawValue)
        }
    }

    // MARK: Matching

    func testGapFindsGapSettings() {
        let results = index.search("gap")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.id == "gaps.window-gap" })
        XCTAssertTrue(results.allSatisfy {
            $0.section == .gaps || $0.title.localizedCaseInsensitiveContains("gap") || !$0.keywords.isEmpty
        })
    }

    func testMultiWordRequiresEveryToken() {
        let results = index.search("launch login")
        XCTAssertEqual(results.map(\.id), ["general.launch-at-login"])
    }

    func testPrefixMatchingNotSubstring() {
        XCTAssertTrue(index.search("laun").contains { $0.id == "general.launch-at-login" })
        XCTAssertFalse(index.search("aunch").contains { $0.id == "general.launch-at-login" })
    }

    func testNoMatchAndBlankQueries() {
        XCTAssertTrue(index.search("zzzxqv").isEmpty)
        XCTAssertTrue(index.search("").isEmpty)
        XCTAssertTrue(index.search("   ").isEmpty)
        XCTAssertTrue(index.search("launch zzzxqv").isEmpty)
    }

    func testCaseAndDiacriticInsensitive() {
        let custom = SettingsIndex(entries: [SettingsEntry("general.cafe", .general, "Café mode", ["Überblick"])])
        XCTAssertEqual(custom.search("CAFE").count, 1)
        XCTAssertEqual(custom.search("café").count, 1)
        XCTAssertEqual(custom.search("uberblick").count, 1)
        XCTAssertEqual(custom.search("ÜBER").count, 1)
    }

    // MARK: Ranking

    func testTitleMatchesRankAboveKeywordMatches() {
        let custom = SettingsIndex(entries: [
            SettingsEntry("general.a", .general, "Alpha", ["beta"]),
            SettingsEntry("general.b", .general, "Beta", [])
        ])
        XCTAssertEqual(custom.search("beta").map(\.id), ["general.b", "general.a"])
    }

    func testTitleTierBeatsSidebarOrder() {
        let custom = SettingsIndex(entries: [
            SettingsEntry("general.kw", .general, "Other", ["gap"]),
            SettingsEntry("about.title", .about, "Gap", [])
        ])
        XCTAssertEqual(custom.search("gap").map(\.id), ["about.title", "general.kw"])
    }

    func testTiesFollowSidebarThenDeclarationOrder() {
        let custom = SettingsIndex(entries: [
            SettingsEntry("about.x", .about, "Thing", []),
            SettingsEntry("layout.y", .layout, "Thing two", []),
            SettingsEntry("layout.z", .layout, "Thing one", []),
            SettingsEntry("general.w", .general, "Thing", [])
        ])
        XCTAssertEqual(custom.search("thing").map(\.id), ["general.w", "layout.y", "layout.z", "about.x"])
    }

    func testMultiWordMayMixTitleAndKeywordsButRanksLower() {
        let custom = SettingsIndex(entries: [
            SettingsEntry("general.mixed", .general, "Startup", ["login item"]),
            SettingsEntry("general.title", .general, "Login startup", [])
        ])
        XCTAssertEqual(custom.search("startup login").map(\.id), ["general.title", "general.mixed"])
    }
}

/// Guards drift between catalog entries and the `.settingTarget("<id>")` anchors in the views.
final class SettingsAnchorDriftTests: XCTestCase {
    private func anchorLiterals() throws -> [String] {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Snapr")
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        let regex = try NSRegularExpression(pattern: #"(?:\.settingTarget\(|targetID: )"([^"\\]+)""#)
        var found: [String] = []
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            let range = NSRange(text.startIndex..., in: text)
            for match in regex.matches(in: text, range: range) {
                if let r = Range(match.range(at: 1), in: text) { found.append(String(text[r])) }
            }
        }
        return found
    }

    func testEveryStaticCatalogEntryHasExactlyOneAnchor() throws {
        let anchors = try anchorLiterals()
        XCTAssertFalse(anchors.isEmpty, "no anchors found; is the path resolution broken?")
        for entry in SettingsIndex.standard.entries where !entry.id.hasPrefix("shortcuts.action.") {
            XCTAssertEqual(anchors.filter { $0 == entry.id }.count, 1, "anchor count for \(entry.id)")
        }
    }

    func testEveryLiteralAnchorHasAnEntry() throws {
        let ids = Set(SettingsIndex.standard.entries.map(\.id))
        for anchor in try anchorLiterals() {
            XCTAssertTrue(ids.contains(anchor), "anchor \(anchor) has no catalog entry")
        }
    }
}
