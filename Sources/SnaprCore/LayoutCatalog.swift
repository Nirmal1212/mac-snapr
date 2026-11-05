import CoreGraphics

/// A rectangular cell of an even `cols` x `rows` grid (zero-based `col`/`row`, optional spans).
public struct GridCell: Equatable {
    public var cols: Int
    public var rows: Int
    public var col: Int
    public var row: Int
    public var colSpan: Int = 1
    public var rowSpan: Int = 1

    public func frame(in area: CGRect) -> CGRect {
        let cw = area.width / CGFloat(cols)
        let rh = area.height / CGFloat(rows)
        return CGRect(
            x: area.minX + cw * CGFloat(col), y: area.minY + rh * CGFloat(row),
            width: cw * CGFloat(colSpan), height: rh * CGFloat(rowSpan))
    }
}

/// Static description of the actions added by `add-layout-engine`: grid cells, titles, categories and
/// default shortcuts. `SnapAction`'s exhaustive switches delegate here for these cases.
public enum LayoutCatalog {
    struct Entry {
        var title: String
        var category: ActionCategory
        var cell: GridCell?
    }

    /// Every action in this catalog, in menu order.
    public static var actions: [SnapAction] { order }

    public static func cell(for action: SnapAction) -> GridCell? { table[action]?.cell }

    public static func title(for action: SnapAction) -> String { table[action]?.title ?? action.rawValue }

    public static func category(for action: SnapAction) -> ActionCategory { table[action]?.category ?? .size }

    /// Default shortcut; most layout actions ship unbound to avoid colliding with system shortcuts.
    public static func defaultCombo(for action: SnapAction) -> KeyCombo? {
        let base = DefaultShortcuts.base
        switch action {
        case .larger: return KeyCombo(keyCode: KeyCombo.Key.equal, modifiers: base)
        case .smaller: return KeyCombo(keyCode: KeyCombo.Key.minus, modifiers: base)
        case .maximizeHeight: return KeyCombo(keyCode: KeyCombo.Key.up, modifiers: base.union(.shift))
        default: return nil
        }
    }

    /// Whether the window gap applies to this action's frame (region layouts only).
    public static func usesWindowGap(_ action: SnapAction) -> Bool {
        if table[action]?.cell != nil { return true }
        switch action {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf,
            .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter,
            .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds, .centerHalf:
            return true
        default:
            return false
        }
    }

    // MARK: Geometry

    /// Frame for a catalog action inside `area`. `current` is needed by sizing/moving actions.
    public static func frame(
        for action: SnapAction, in area: CGRect, current: CGRect?, step: Int, options: LayoutOptions
    ) -> CGRect? {
        if let cell = cell(for: action) { return cell.frame(in: area) }
        let (w, h) = (area.width, area.height)
        switch action {
        case .centerHalf:
            return CGRect(x: area.midX - w / 4, y: area.minY, width: w / 2, height: h)
        case .centerProminently:
            return WindowGeometry.centered(size: CGSize(width: w * 0.7, height: h * 0.85), in: area)
        case .almostMaximize:
            let f = min(max(options.almostMaximizeFraction, 0.1), 1)
            return WindowGeometry.centered(size: CGSize(width: w * f, height: h * f), in: area)
        case .specifiedSize:
            return WindowGeometry.centered(size: options.specifiedSize, in: area)
        default:
            break
        }
        guard let current else { return nil }
        let stepSize = options.resizeStep
        switch action {
        case .maximizeHeight:
            return WindowGeometry.clamped(CGRect(x: current.minX, y: area.minY, width: current.width, height: h), to: area)
        case .larger:
            return resized(current, to: CGSize(width: current.width + stepSize, height: current.height + stepSize), in: area)
        case .smaller:
            let min = options.minimumWindowSize
            let size = CGSize(
                width: Swift.max(current.width - stepSize, Swift.min(min.width, current.width)),
                height: Swift.max(current.height - stepSize, Swift.min(min.height, current.height)))
            return resized(current, to: size, in: area)
        case .moveLeft: return moved(current, x: area.minX, y: current.minY, in: area)
        case .moveRight: return moved(current, x: area.maxX - current.width, y: current.minY, in: area)
        case .moveUp: return moved(current, x: current.minX, y: area.minY, in: area)
        case .moveDown: return moved(current, x: current.minX, y: area.maxY - current.height, in: area)
        case .doubleWidth: return resizedKeepingOrigin(current, width: current.width * 2, height: current.height, in: area)
        case .halveWidth: return resizedKeepingOrigin(current, width: current.width / 2, height: current.height, in: area)
        case .doubleHeight: return resizedKeepingOrigin(current, width: current.width, height: current.height * 2, in: area)
        case .halveHeight: return resizedKeepingOrigin(current, width: current.width, height: current.height / 2, in: area)
        default:
            return nil
        }
    }

    private static func moved(_ frame: CGRect, x: CGFloat, y: CGFloat, in area: CGRect) -> CGRect {
        WindowGeometry.clamped(CGRect(origin: CGPoint(x: x, y: y), size: frame.size), to: area)
    }

    private static func resizedKeepingOrigin(
        _ frame: CGRect, width: CGFloat, height: CGFloat, in area: CGRect
    ) -> CGRect {
        WindowGeometry.clamped(CGRect(origin: frame.origin, size: CGSize(width: width, height: height)), to: area)
    }

    /// Resizes about the center, clamped into `area`.
    private static func resized(_ frame: CGRect, to size: CGSize, in area: CGRect) -> CGRect {
        let rect = CGRect(
            x: frame.midX - size.width / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)
        return WindowGeometry.clamped(rect, to: area)
    }

    // MARK: Table

    private static let order: [SnapAction] = table.keys.sorted { index[$0, default: 0] < index[$1, default: 0] }
    private static let index: [SnapAction: Int] = Dictionary(
        uniqueKeysWithValues: SnapAction.allCases.enumerated().map { ($1, $0) })

    private static let table: [SnapAction: Entry] = {
        var t: [SnapAction: Entry] = [:]
        func add(_ action: SnapAction, _ title: String, _ category: ActionCategory, _ cell: GridCell? = nil) {
            t[action] = Entry(title: title, category: category, cell: cell)
        }
        func cell(_ cols: Int, _ rows: Int, _ col: Int, _ row: Int, _ colSpan: Int = 1, _ rowSpan: Int = 1) -> GridCell {
            GridCell(cols: cols, rows: rows, col: col, row: row, colSpan: colSpan, rowSpan: rowSpan)
        }

        // Fourths
        add(.firstFourth, "First Fourth", .fourths, cell(4, 1, 0, 0))
        add(.secondFourth, "Second Fourth", .fourths, cell(4, 1, 1, 0))
        add(.thirdFourth, "Third Fourth", .fourths, cell(4, 1, 2, 0))
        add(.lastFourth, "Last Fourth", .fourths, cell(4, 1, 3, 0))
        add(.leftThreeFourths, "Left Three Fourths", .fourths, cell(4, 1, 0, 0, 3))
        add(.rightThreeFourths, "Right Three Fourths", .fourths, cell(4, 1, 1, 0, 3))

        // Sixths (3 columns x 2 rows)
        add(.topLeftSixth, "Top Left Sixth", .sixths, cell(3, 2, 0, 0))
        add(.topCenterSixth, "Top Center Sixth", .sixths, cell(3, 2, 1, 0))
        add(.topRightSixth, "Top Right Sixth", .sixths, cell(3, 2, 2, 0))
        add(.bottomLeftSixth, "Bottom Left Sixth", .sixths, cell(3, 2, 0, 1))
        add(.bottomCenterSixth, "Bottom Center Sixth", .sixths, cell(3, 2, 1, 1))
        add(.bottomRightSixth, "Bottom Right Sixth", .sixths, cell(3, 2, 2, 1))

        // Vertical sixths (2 columns x 3 rows)
        add(.verticalSixthLeftTop, "Vertical Sixth Left Top", .sixths, cell(2, 3, 0, 0))
        add(.verticalSixthLeftMiddle, "Vertical Sixth Left Middle", .sixths, cell(2, 3, 0, 1))
        add(.verticalSixthLeftBottom, "Vertical Sixth Left Bottom", .sixths, cell(2, 3, 0, 2))
        add(.verticalSixthRightTop, "Vertical Sixth Right Top", .sixths, cell(2, 3, 1, 0))
        add(.verticalSixthRightMiddle, "Vertical Sixth Right Middle", .sixths, cell(2, 3, 1, 1))
        add(.verticalSixthRightBottom, "Vertical Sixth Right Bottom", .sixths, cell(2, 3, 1, 2))

        // Eighths (4 columns x 2 rows)
        add(.topFirstEighth, "Top First Eighth", .eighths, cell(4, 2, 0, 0))
        add(.topSecondEighth, "Top Second Eighth", .eighths, cell(4, 2, 1, 0))
        add(.topThirdEighth, "Top Third Eighth", .eighths, cell(4, 2, 2, 0))
        add(.topFourthEighth, "Top Fourth Eighth", .eighths, cell(4, 2, 3, 0))
        add(.bottomFirstEighth, "Bottom First Eighth", .eighths, cell(4, 2, 0, 1))
        add(.bottomSecondEighth, "Bottom Second Eighth", .eighths, cell(4, 2, 1, 1))
        add(.bottomThirdEighth, "Bottom Third Eighth", .eighths, cell(4, 2, 2, 1))
        add(.bottomFourthEighth, "Bottom Fourth Eighth", .eighths, cell(4, 2, 3, 1))

        // Vertical eighths (2 columns x 4 rows)
        add(.verticalEighthLeft1, "Vertical Eighth Left 1", .eighths, cell(2, 4, 0, 0))
        add(.verticalEighthLeft2, "Vertical Eighth Left 2", .eighths, cell(2, 4, 0, 1))
        add(.verticalEighthLeft3, "Vertical Eighth Left 3", .eighths, cell(2, 4, 0, 2))
        add(.verticalEighthLeft4, "Vertical Eighth Left 4", .eighths, cell(2, 4, 0, 3))
        add(.verticalEighthRight1, "Vertical Eighth Right 1", .eighths, cell(2, 4, 1, 0))
        add(.verticalEighthRight2, "Vertical Eighth Right 2", .eighths, cell(2, 4, 1, 1))
        add(.verticalEighthRight3, "Vertical Eighth Right 3", .eighths, cell(2, 4, 1, 2))
        add(.verticalEighthRight4, "Vertical Eighth Right 4", .eighths, cell(2, 4, 1, 3))

        // Ninths (3 x 3)
        add(.ninthTopLeft, "Ninth Top Left", .ninths, cell(3, 3, 0, 0))
        add(.ninthTopCenter, "Ninth Top Center", .ninths, cell(3, 3, 1, 0))
        add(.ninthTopRight, "Ninth Top Right", .ninths, cell(3, 3, 2, 0))
        add(.ninthMiddleLeft, "Ninth Middle Left", .ninths, cell(3, 3, 0, 1))
        add(.ninthMiddleCenter, "Ninth Middle Center", .ninths, cell(3, 3, 1, 1))
        add(.ninthMiddleRight, "Ninth Middle Right", .ninths, cell(3, 3, 2, 1))
        add(.ninthBottomLeft, "Ninth Bottom Left", .ninths, cell(3, 3, 0, 2))
        add(.ninthBottomCenter, "Ninth Bottom Center", .ninths, cell(3, 3, 1, 2))
        add(.ninthBottomRight, "Ninth Bottom Right", .ninths, cell(3, 3, 2, 2))

        // Corner two-thirds (2/3 x 2/3 in a corner)
        add(.topLeftTwoThirds, "Top Left Two Thirds", .thirds, cell(3, 3, 0, 0, 2, 2))
        add(.topRightTwoThirds, "Top Right Two Thirds", .thirds, cell(3, 3, 1, 0, 2, 2))
        add(.bottomLeftTwoThirds, "Bottom Left Two Thirds", .thirds, cell(3, 3, 0, 1, 2, 2))
        add(.bottomRightTwoThirds, "Bottom Right Two Thirds", .thirds, cell(3, 3, 1, 1, 2, 2))

        // Centered and large
        add(.centerHalf, "Center Half", .size)
        add(.centerProminently, "Center Prominently", .size)
        add(.almostMaximize, "Almost Maximize", .size)
        add(.maximizeHeight, "Maximize Height", .size)

        // Sizing and moving
        add(.larger, "Larger", .sizing)
        add(.smaller, "Smaller", .sizing)
        add(.moveLeft, "Move Left", .sizing)
        add(.moveRight, "Move Right", .sizing)
        add(.moveUp, "Move Up", .sizing)
        add(.moveDown, "Move Down", .sizing)
        add(.doubleWidth, "Double Width", .sizing)
        add(.halveWidth, "Halve Width", .sizing)
        add(.doubleHeight, "Double Height", .sizing)
        add(.halveHeight, "Halve Height", .sizing)
        add(.specifiedSize, "Specified Size", .sizing)
        return t
    }()
}
