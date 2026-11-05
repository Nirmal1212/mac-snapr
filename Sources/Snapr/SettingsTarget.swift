import SnaprCore
import SwiftUI

private struct HighlightedSettingKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// Id of the setting that search just navigated to; nil when nothing is highlighted.
    var highlightedSetting: String? {
        get { self[HighlightedSettingKey.self] }
        set { self[HighlightedSettingKey.self] = newValue }
    }
}

/// Makes a control the scroll/highlight target for a search entry. The id must match a `SettingsEntry.id`
/// in `SettingsCatalog.swift`. The highlight is a tinted background plus an outline (not color alone), and the
/// control also receives accessibility focus so VoiceOver follows the jump.
private struct SettingTarget: ViewModifier {
    let id: String
    @Environment(\.highlightedSetting) private var highlighted
    @AccessibilityFocusState private var accessibilityFocused: Bool

    private var active: Bool { highlighted == id }

    func body(content: Content) -> some View {
        content
            .id(id)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(active ? 0.22 : 0)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: active ? 2 : 0))
            .animation(.easeInOut(duration: 0.25), value: active)
            .accessibilityFocused($accessibilityFocused)
            .onChange(of: active) { isActive in
                if isActive { accessibilityFocused = true }
            }
    }
}

extension View {
    /// Registers this control as the destination of the search entry `id`.
    func settingTarget(_ id: String) -> some View { modifier(SettingTarget(id: id)) }
}

extension SettingsStore {
    func binding(_ key: SettingKey<Bool>) -> Binding<Bool> {
        Binding(get: { self.get(key) }, set: { self.set($0, for: key) })
    }
}
