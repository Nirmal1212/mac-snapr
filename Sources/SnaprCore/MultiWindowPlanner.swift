import CoreGraphics

/// Pure frame computation for multi-window layouts. No OS access; all frames in the global space.
public enum MultiWindowPlanner {
    // MARK: Grids

    /// Column count whose cells best match the area's aspect ratio (cells closest to square).
    public static func balancedColumns(count: Int, area: CGSize) -> Int {
        guard count > 1, area.width > 0, area.height > 0 else { return max(count, 1) }
        var best = 1
        var bestScore = CGFloat.greatestFiniteMagnitude
        for columns in 1...count {
            let rows = (count + columns - 1) / columns
            let cellRatio = (area.width / CGFloat(columns)) / (area.height / CGFloat(rows))
            // Empty cells waste space; penalize them slightly so exact grids win ties.
            let empty = CGFloat(columns * rows - count)
            let score = abs(log(cellRatio)) + empty * 0.5
            if score < bestScore { best = columns; bestScore = score }
        }
        return best
    }

    /// Row-major grid with `columns` columns. When `balanced`, the last row's cells stretch to fill the row.
    public static func grid(
        count: Int, columns: Int, in area: CGRect, balanced: Bool, gap: CGFloat = 0
    ) -> [CGRect] {
        guard count > 0 else { return [] }
        let columns = min(max(columns, 1), count)
        let rows = (count + columns - 1) / columns
        var frames: [CGRect] = []
        for index in 0..<count {
            let row = index / columns, column = index % columns
            let inRow = row == rows - 1 && balanced ? count - columns * (rows - 1) : columns
            frames.append(cell(row: row, of: rows, column: column, of: inRow, in: area, gap: gap))
        }
        return frames
    }

    /// Column-major layout with at most `perColumn` windows per column (0 = one column).
    /// Windows fill each column top to bottom, columns left to right.
    public static func columns(
        count: Int, perColumn: Int, in area: CGRect, balanced: Bool, gap: CGFloat = 0
    ) -> [CGRect] {
        guard count > 0 else { return [] }
        let per = perColumn > 0 ? min(perColumn, count) : count
        let columnCount = (count + per - 1) / per
        var frames: [CGRect] = []
        for index in 0..<count {
            let column = index / per, row = index % per
            let inColumn = column == columnCount - 1 && balanced ? count - per * (columnCount - 1) : per
            frames.append(cell(row: row, of: inColumn, column: column, of: columnCount, in: area, gap: gap))
        }
        return frames
    }

    /// Rows with at most `perRow` windows each (0 = one row).
    public static func rows(count: Int, perRow: Int, in area: CGRect, balanced: Bool, gap: CGFloat = 0) -> [CGRect] {
        grid(count: count, columns: perRow > 0 ? perRow : count, in: area, balanced: balanced, gap: gap)
    }

    /// Cell `row` of `rows` by `column` of `columns`, edges rounded to whole points before the gap.
    private static func cell(row: Int, of rows: Int, column: Int, of columns: Int, in area: CGRect, gap: CGFloat) -> CGRect {
        func edge(_ origin: CGFloat, _ length: CGFloat, _ index: Int, _ total: Int) -> CGFloat {
            (origin + length * CGFloat(index) / CGFloat(total)).rounded()
        }
        let minX = edge(area.minX, area.width, column, columns)
        let maxX = column == columns - 1 ? area.maxX : edge(area.minX, area.width, column + 1, columns)
        let minY = edge(area.minY, area.height, row, rows)
        let maxY = row == rows - 1 ? area.maxY : edge(area.minY, area.height, row + 1, rows)
        let raw = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return LayoutEngine.pixelAligned(LayoutEngine.applyWindowGap(raw, in: area, gap: gap))
    }

    // MARK: Cascade and stack

    /// Number of distinct offset steps that keep windows at least 40% of the area.
    static func maxSteps(in area: CGRect, offset: CGFloat) -> Int {
        let room = min(area.width, area.height) * 0.6
        return max(1, Int(room / max(offset, 1)) + 1)
    }

    /// Cascade: window i sits `i * offset` down and right of the area's origin (wrapping after the last
    /// step). Sizes are the windows' own, limited so every step stays inside the area.
    public static func cascade(sizes: [CGSize], in area: CGRect, offset: CGFloat) -> [CGRect] {
        let steps = min(sizes.count, maxSteps(in: area, offset: offset))
        guard steps > 0 else { return [] }
        let limit = CGSize(
            width: area.width - CGFloat(steps - 1) * offset, height: area.height - CGFloat(steps - 1) * offset)
        return sizes.enumerated().map { index, size in
            let step = CGFloat(index % steps)
            let fitted = CGSize(width: min(size.width, limit.width), height: min(size.height, limit.height))
            return LayoutEngine.pixelAligned(
                CGRect(origin: CGPoint(x: area.minX + step * offset, y: area.minY + step * offset), size: fitted))
        }
    }

    /// Stack: index 0 is the front window and sits at the largest offset, so the windows behind it show
    /// their top edges. With `sameSize` every window takes the front window's size.
    public static func stack(sizes: [CGSize], in area: CGRect, offset: CGFloat, sameSize: Bool) -> [CGRect] {
        let steps = min(sizes.count, maxSteps(in: area, offset: offset))
        guard steps > 0 else { return [] }
        let limit = CGSize(
            width: area.width - CGFloat(steps - 1) * offset, height: area.height - CGFloat(steps - 1) * offset)
        return sizes.enumerated().map { index, size in
            let base = sameSize ? sizes[0] : size
            let fitted = CGSize(width: min(base.width, limit.width), height: min(base.height, limit.height))
            let step = CGFloat(steps - 1 - (index % steps))
            return LayoutEngine.pixelAligned(
                CGRect(origin: CGPoint(x: area.minX + step * offset, y: area.minY + step * offset), size: fitted))
        }
    }

    // MARK: Ordering, reverse, distribution

    /// Reading order: top to bottom in bands of 40 points, then left to right.
    public static func readingOrder(_ windows: [ManagedWindow]) -> [ManagedWindow] {
        windows.sorted {
            let a = ($0.frame.minY / 40).rounded(.down), b = ($1.frame.minY / 40).rounded(.down)
            return a != b ? a < b : $0.frame.minX < $1.frame.minX
        }
    }

    /// Frames after reversing positions: the i-th window (reading order) takes the frame of the
    /// (n-1-i)-th. Returns pairs in reading order.
    public static func reversed(_ windows: [ManagedWindow]) -> [(id: WindowID, frame: CGRect)] {
        let ordered = readingOrder(windows)
        return ordered.enumerated().map { index, window in (window.id, ordered[ordered.count - 1 - index].frame) }
    }

    /// Splits `count` windows over screens in proportion to `weights` (largest remainder). Every screen
    /// with a positive weight gets at least one window when there are enough windows.
    public static func distribute(count: Int, weights: [CGFloat]) -> [Int] {
        let total = weights.reduce(0, +)
        guard count > 0, total > 0 else { return Array(repeating: 0, count: weights.count) }
        let exact = weights.map { CGFloat(count) * $0 / total }
        var counts = exact.map { Int($0.rounded(.down)) }
        var remaining = count - counts.reduce(0, +)
        let byRemainder = exact.indices.sorted { exact[$0] - CGFloat(counts[$0]) > exact[$1] - CGFloat(counts[$1]) }
        for index in byRemainder where remaining > 0 {
            counts[index] += 1
            remaining -= 1
        }
        return counts
    }

    /// `frame` limited to `content`: shrunk when larger, then moved inside.
    public static func fitting(_ frame: CGRect, in content: CGRect) -> CGRect {
        let size = CGSize(width: min(frame.width, content.width), height: min(frame.height, content.height))
        return WindowGeometry.clamped(CGRect(origin: frame.origin, size: size), to: content)
    }
}
