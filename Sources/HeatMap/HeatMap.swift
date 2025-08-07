import Foundation
import SwiftUI

public protocol HeatMapValue: Identifiable, Sendable {
    var heat: Double { get }
}

struct HeatMapRect<ID: Hashable>: Identifiable {
    let id: ID
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var heat: Double
}

public struct HeatMap {
    public enum FrameAlignment { case highPrecision, retinaSubPixel, integral }

    var values: [any HeatMapValue]
    let alignment: FrameAlignment
    
    public init(values: [some HeatMapValue], alignment: FrameAlignment = .retinaSubPixel) {
        self.values = values
        self.alignment = alignment
    }
    
    private var heatValues: [Double] {
        values.map(\.heat)
    }
    
    private var totalHeatValue: Double {
        heatValues.reduce(0, +)
    }

    private var normalizedWeights: [Double] {
        heatValues.map { $0 / totalHeatValue }
    }

    func computeRects<ID: Hashable>(in frame: CGRect) -> [HeatMapRect<ID>] {
        let base = Rect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height)
        let rawRects = tessellate(weights: normalizedWeights, inRect: base)
        return zip(rawRects, values).map {
            HeatMapRect(
                id: $1.id as! ID,
                x: $0.x,
                y: $0.y,
                width: $0.width,
                height: $0.height,
                heat: $1.heat
            )
        }
    }

    // MARK: - Internal types

    struct Rect {
        var x, y, width, height: Double
        mutating func align(using a: FrameAlignment) {
            guard a != .highPrecision else { return }
            let maxX = x + width, maxY = y + height
            x = align(x, a); y = align(y, a)
            width = align(maxX, a) - x; height = align(maxY, a) - y
        }
        private func align(_ p: Double, _ a: FrameAlignment) -> Double {
            let (i, f) = modf(p)
            let s = a == .retinaSubPixel
            if s && f < 0.25 { return i }
            else if f < 0.5 { return i + 0.5 }
            else if s && f < 0.75 { return i + 0.5 }
            else { return i + 1 }
        }
    }

    enum Axis { case horizontal, vertical }

    func tessellate(weights: [Double], inRect rect: Rect) -> [Rect] {
        var areas = weights.map { $0 * rect.width * rect.height }
        var result: [Rect] = [], canvas = rect
        while !areas.isEmpty {
            var remaining = canvas
            let group = tessellateRow(areas: areas, inRect: canvas, remaining: &remaining)
            result += group; canvas = remaining; areas.removeFirst(group.count)
        }
        return result
    }

    func tessellateRow(areas: [Double], inRect rect: Rect, remaining: inout Rect) -> [Rect] {
        let dir: Axis = rect.width >= rect.height ? .horizontal : .vertical
        let length = dir == .horizontal ? rect.height : rect.width

        var aspect = Double.greatestFiniteMagnitude
        var accepted: [Double] = [], accWeight: Double = 0

        for area in areas {
            let newAspect = worstAspectRatio(for: accepted, sum: accWeight, proposed: area, length: length, limit: aspect)
            if newAspect > aspect { break }
            accepted.append(area); accWeight += area; aspect = newAspect
        }

        let w = accWeight / length
        var offset = dir == .horizontal ? rect.y : rect.x
        let result = accepted.map { a in
            let h = a / w, o = offset; offset += h
            var r = dir == .horizontal
                ? Rect(x: rect.x, y: o, width: w, height: h)
                : Rect(x: o, y: rect.y, width: h, height: w)
            r.align(using: alignment); return r
        }

        switch dir {
        case .horizontal:
            remaining = Rect(x: rect.x + w, y: rect.y, width: rect.width - w, height: rect.height)
        case .vertical:
            remaining = Rect(x: rect.x, y: rect.y + w, width: rect.width, height: rect.height - w)
        }
        return result
    }

    func worstAspectRatio(for ws: [Double], sum: Double, proposed: Double, length: Double, limit: Double) -> Double {
        let total = sum + proposed, width = total / length
        var worst = aspect(width, proposed / width)
        for w in ws {
            worst = max(worst, aspect(width, w / width))
            if worst > limit { break }
        }
        return worst
    }

    func aspect(_ a: Double, _ b: Double) -> Double { max(a / b, b / a) }
}



/// A view that arranges a collection of `HeatMapValue`-conforming views in a heatmap layout.
///
/// ```swift
/// HeatMapView {
///     ForEach(stocks) { stock in
///         StockItemView(stock)
///     }
/// }
/// ```
/// - Parameters:
///   - alignment: How to align the frames of the heatmap rectangles.
///   - content: A `@ViewBuilder` closure that produces the views to layout. The closure must produce a `ForEach` or similar structure containing views that conform to `HeatMapValue` (or wrap such values). The number and order of `HeatMapValue` instances must match the layout expectations.
///
/// - Important: The user must ensure that the `ForEach` closure inside `HeatMapView` produces views conforming to `HeatMapValue` (or wrappers), and that the number and order of `HeatMapValue`s match the view layout expectations.
public struct HeatMapView<Item: HeatMapValue, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let alignment: HeatMap.FrameAlignment
    let content: (Item, Double) -> Content

    public init(
        items: [Item],
        spacing: CGFloat = 1.5,
        alignment: HeatMap.FrameAlignment = .retinaSubPixel,
        @ViewBuilder content: @escaping (Item, Double) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    public var body: some View {
        GeometryReader { geo in
            let heatmap = HeatMap(values: items, alignment: alignment)
            let rects = heatmap.computeRects(in: geo.frame(in: .local)) as [HeatMapRect<Item.ID>]
            let maxHeat = items.map(\.heat).max() ?? 1.0
            ZStack {
                ForEach(Array(zip(items, rects)), id: \.0.id) { item, rect in
                    let frame = CGRect(
                        x: rect.x,
                        y: rect.y,
                        width: rect.width - spacing,
                        height: rect.height - spacing
                    )
                    let normalized = item.heat / maxHeat
                    let safeWidth = (frame.width.isFinite && frame.width > 0) ? frame.width : 0
                    let safeHeight = (frame.height.isFinite && frame.height > 0) ? frame.height : 0
                    content(item, normalized)
                        .frame(width: safeWidth, height: safeHeight)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
        }
    }
}
