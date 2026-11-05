import Foundation

/// One searchable setting. `id` is also the scroll/highlight anchor used by the settings views and
/// must be `"<section idPrefix>.<name>"`.
public struct SettingsEntry: Identifiable, Hashable {
    public let id: String
    public let section: SettingsSection
    public let title: String
    public let keywords: [String]

    public init(_ id: String, _ section: SettingsSection, _ title: String, _ keywords: [String] = []) {
        self.id = id
        self.section = section
        self.title = title
        self.keywords = keywords
    }
}

/// Pure settings search. Case- and diacritic-insensitive; every query token must be a prefix of a word in the
/// title or keywords. Title matches rank above keyword matches, then sidebar order, then declaration order.
public struct SettingsIndex {
    public let entries: [SettingsEntry]
    private let words: [(title: [String], all: [String])]

    public init(entries: [SettingsEntry]) {
        self.entries = entries
        words = entries.map { entry in
            let title = Self.words(entry.title)
            return (title, title + entry.keywords.flatMap(Self.words))
        }
    }

    /// The index of every setting in the app.
    public static let standard = SettingsIndex(entries: SettingsSection.allCases.flatMap(\.searchEntries))

    public func search(_ query: String) -> [SettingsEntry] {
        let tokens = Self.words(query)
        guard !tokens.isEmpty else { return [] }
        var hits: [(tier: Int, section: Int, position: Int)] = []
        for (position, entry) in entries.enumerated() {
            let candidate = words[position]
            guard tokens.allSatisfy({ token in candidate.all.contains { $0.hasPrefix(token) } }) else { continue }
            let inTitle = tokens.allSatisfy { token in candidate.title.contains { $0.hasPrefix(token) } }
            hits.append((inTitle ? 0 : 1, entry.section.order, position))
        }
        return hits.sorted { ($0.tier, $0.section, $0.position) < ($1.tier, $1.section, $1.position) }
            .map { entries[$0.position] }
    }

    /// Folds case and diacritics and splits on anything that is not a letter or digit.
    static func words(_ text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
