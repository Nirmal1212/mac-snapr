import Foundation
import SnaprCore
import Sparkle

/// Adapts Sparkle's standard updater to `UpdateChecking`.
/// Stays inert (no network, no scheduled checks) unless the bundle carries a feed URL and public key.
final class SparkleUpdater: NSObject, UpdateChecking {
    private let controller: SPUStandardUpdaterController?

    override init() {
        if UpdaterConfig(info: Bundle.main.infoDictionary).isConfigured {
            controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        } else {
            controller = nil
        }
        super.init()
    }

    var isAvailable: Bool { controller != nil }

    var automaticallyChecks: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
