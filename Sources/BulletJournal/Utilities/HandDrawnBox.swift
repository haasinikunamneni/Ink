import SwiftUI

/// A rounded rectangle with very slight per-corner irregularity so it reads
/// as "hand drawn on a page" rather than a perfect system rectangle.
struct WobblyRoundedRect: Shape {
    var cornerRadius: CGFloat = 18
    var seed: Double = 0

    func path(in rect: CGRect) -> Path {
        let jitter: CGFloat = 1.6

        func offset(_ index: Int) -> CGPoint {
            let angle = Double(index) * 2.399963 + seed
            let dx = CGFloat(sin(angle)) * jitter
            let dy = CGFloat(cos(angle * 1.31)) * jitter
            return CGPoint(x: dx, y: dy)
        }

        let tl = CGPoint(x: rect.minX, y: rect.minY) + offset(0)
        let tr = CGPoint(x: rect.maxX, y: rect.minY) + offset(1)
        let br = CGPoint(x: rect.maxX, y: rect.maxY) + offset(2)
        let bl = CGPoint(x: rect.minX, y: rect.maxY) + offset(3)

        var path = Path()
        path.move(to: CGPoint(x: tl.x + cornerRadius, y: tl.y))
        path.addLine(to: CGPoint(x: tr.x - cornerRadius, y: tr.y))
        path.addQuadCurve(to: CGPoint(x: tr.x, y: tr.y + cornerRadius), control: tr)
        path.addLine(to: CGPoint(x: br.x, y: br.y - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: br.x - cornerRadius, y: br.y), control: br)
        path.addLine(to: CGPoint(x: bl.x + cornerRadius, y: bl.y))
        path.addQuadCurve(to: CGPoint(x: bl.x, y: bl.y - cornerRadius), control: bl)
        path.addLine(to: CGPoint(x: tl.x, y: tl.y + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: tl.x + cornerRadius, y: tl.y), control: tl)
        path.closeSubpath()
        return path
    }
}

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

struct NotebookBoxStyle: ViewModifier {
    var seed: Double

    func body(content: Content) -> some View {
        content
            .padding(26)
            .background(WobblyRoundedRect(cornerRadius: 18, seed: seed).fill(Color.black))
            .overlay(
                WobblyRoundedRect(cornerRadius: 18, seed: seed)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1.1)
            )
    }
}

extension View {
    /// Applies the matte-black, thin-white-outline notebook box look.
    func notebookBox(seed: Double = 0) -> some View {
        modifier(NotebookBoxStyle(seed: seed))
    }
}
