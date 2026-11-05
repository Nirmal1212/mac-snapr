import ApplicationServices
import CoreGraphics
import Darwin
import Foundation
import SnaprCore

/// EXPERIMENTAL. Moves windows between Spaces through private CoreGraphics (CGS) functions.
///
/// Risk: these symbols are undocumented, can change or be restricted in any macOS release (macOS 14.5+
/// refuses to move windows owned by other processes in many cases), and rule out App Store distribution.
/// Nothing here requires disabling SIP or injecting code. Symbols are resolved at run time with `dlsym`;
/// if any is missing `isAvailable` is false and every call is a no-op. `SpaceActionController` additionally
/// verifies every move, so a call that silently does nothing is reported as a failure.
/// Isolated behind `SpaceMoving` and the default-off `spacesEnabled` setting; see the change's design.md.
final class PrivateSpaceMover: SpaceMoving {
    private typealias MainConnection = @convention(c) () -> Int32
    private typealias CopyDisplaySpaces = @convention(c) (Int32) -> Unmanaged<CFArray>?
    private typealias CopySpacesForWindows = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?
    private typealias MoveWindows = @convention(c) (Int32, CFArray, UInt64) -> Void
    private typealias AXGetWindow = @convention(c) (AXUIElement, UnsafeMutablePointer<CGWindowID>) -> AXError

    private let mainConnection: MainConnection?
    private let copyDisplaySpaces: CopyDisplaySpaces?
    private let copySpacesForWindows: CopySpacesForWindows?
    private let moveWindows: MoveWindows?
    private let axGetWindow: AXGetWindow?
    private let provider: AXWindowProvider

    init(provider: AXWindowProvider) {
        self.provider = provider
        func symbol<T>(_ name: String, as type: T.Type) -> T? {
            // RTLD_DEFAULT
            guard let pointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), name) else { return nil }
            return unsafeBitCast(pointer, to: type)
        }
        mainConnection = symbol("CGSMainConnectionID", as: MainConnection.self)
        copyDisplaySpaces = symbol("CGSCopyManagedDisplaySpaces", as: CopyDisplaySpaces.self)
        copySpacesForWindows = symbol("CGSCopySpacesForWindows", as: CopySpacesForWindows.self)
        moveWindows = symbol("CGSMoveWindowsToManagedSpace", as: MoveWindows.self)
        axGetWindow = symbol("_AXUIElementGetWindow", as: AXGetWindow.self)
    }

    var isAvailable: Bool {
        mainConnection != nil && copyDisplaySpaces != nil && copySpacesForWindows != nil && moveWindows != nil
            && axGetWindow != nil
    }

    // MARK: SpaceMoving

    func spaceCount(of window: WindowID) -> Int? {
        layout(of: window)?.spaces.count
    }

    func spaceIndex(of window: WindowID) -> Int? {
        layout(of: window).map { $0.currentIndex + 1 }
    }

    func move(_ window: WindowID, toSpaceIndex index: Int) -> Bool {
        guard isAvailable, let connection = mainConnection?(), let moveWindows,
            let windowNumber = windowNumber(of: window), let info = layout(of: window),
            info.spaces.indices.contains(index - 1)
        else { return false }
        moveWindows(connection, [NSNumber(value: windowNumber)] as CFArray, info.spaces[index - 1])
        return true
    }

    // MARK: Private API access

    private func windowNumber(of id: WindowID) -> CGWindowID? {
        guard let axGetWindow, let element = provider.axElement(for: id) else { return nil }
        var number: CGWindowID = 0
        guard axGetWindow(element, &number) == .success, number != 0 else { return nil }
        return number
    }

    /// The user Spaces of the display holding the window (in order) and the index of the window's Space.
    private func layout(of id: WindowID) -> (spaces: [UInt64], currentIndex: Int)? {
        guard isAvailable, let connection = mainConnection?(), let number = windowNumber(of: id),
            let windowSpaces = copySpacesForWindows?(connection, 0x7, [NSNumber(value: number)] as CFArray)?
                .takeRetainedValue() as? [NSNumber],
            let spaceID = windowSpaces.first?.uint64Value,
            let displays = copyDisplaySpaces?(connection)?.takeRetainedValue() as? [[String: Any]]
        else { return nil }
        for display in displays {
            // Type 0 are regular user Spaces; full-screen app Spaces have another type.
            let spaces = (display["Spaces"] as? [[String: Any]] ?? [])
                .filter { ($0["type"] as? Int ?? 0) == 0 }
                .compactMap { ($0["ManagedSpaceID"] as? NSNumber)?.uint64Value }
            if let index = spaces.firstIndex(of: spaceID) { return (spaces, index) }
        }
        return nil
    }
}
