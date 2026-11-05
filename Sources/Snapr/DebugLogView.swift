import SnaprCore
import SwiftUI

/// Viewer for the in-memory debug log. Recording is enabled with
/// `defaults write com.you.snapr debugLogging -bool true`.
struct DebugLogView: View {
    @ObservedObject var log: DebugLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if log.entries.isEmpty {
                Text("No entries. Enable logging with: defaults write com.you.snapr debugLogging -bool true")
                    .font(.caption).foregroundColor(.secondary)
            }
            ScrollView {
                Text(log.text)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            HStack {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(log.text, forType: .string)
                }
                Button("Clear") { log.clear() }
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 320)
    }
}
