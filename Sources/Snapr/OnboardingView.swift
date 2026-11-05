import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Snapr needs Accessibility access").font(.title2).bold()
            Text(
                "Snapr moves and resizes windows of other apps using the macOS Accessibility API. "
                    + "Nothing leaves your Mac: there is no network access or telemetry.")
            Text("Open System Settings → Privacy & Security → Accessibility and switch Snapr on. "
                + "This window closes automatically once access is granted.")
                .foregroundColor(.secondary)
            HStack {
                Button("Open Accessibility Settings") { model.requestAccessibility() }
                    .keyboardShortcut(.defaultAction)
                Button("Later") { model.refreshTrust() }
            }
        }
        .padding(24)
        .frame(width: 440, alignment: .leading)
    }
}
