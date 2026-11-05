import Foundation

/// Titles, categories and classification of the multi-window actions.
public enum MultiWindowCatalog {
    public static func title(for action: SnapAction) -> String {
        switch action {
        case .tileAll: return "Tile All Windows"
        case .tileActiveApp: return "Tile Active App"
        case .tileRows: return "Tile in Rows"
        case .tileColumns: return "Tile in Columns"
        case .cascadeAll: return "Cascade All Windows"
        case .cascadeActiveApp: return "Cascade Active App"
        case .stackNext: return "Next Stacked Window"
        case .stackPrevious: return "Previous Stacked Window"
        case .reverseAll: return "Reverse All Windows"
        case .toggleTodo: return "Toggle Todo Mode"
        case .reflowTodo: return "Reflow Todo"
        default: return action.name
        }
    }

    public static func category(for action: SnapAction) -> ActionCategory { .multiWindow }

    /// Actions that operate on many windows and are handled by `MultiWindowController`.
    public static func isMultiWindow(_ action: SnapAction) -> Bool {
        switch action {
        case .tileAll, .tileActiveApp, .tileRows, .tileColumns, .cascadeAll, .cascadeActiveApp, .stackNext,
            .stackPrevious, .reverseAll, .toggleTodo, .reflowTodo:
            return true
        default:
            return false
        }
    }
}

public extension SnapAction {
    /// True for actions handled by `MultiWindowController` instead of `SnapController`.
    var isMultiWindow: Bool { MultiWindowCatalog.isMultiWindow(self) }
}
