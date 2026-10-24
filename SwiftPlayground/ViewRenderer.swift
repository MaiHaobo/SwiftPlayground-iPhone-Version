import SwiftUI

// MARK: - Live View 渲染器：把解释器产出的视图树渲染成 SwiftUI

struct ViewRenderer: View {
    let node: ViewNode
    let onTap: (Int) -> Void

    var body: some View {
        render(node)
    }

    private func render(_ n: ViewNode) -> AnyView {
        switch n.kind {
        case .text(let s):
            return AnyView(
                Text(s)
                    .font(fontOf(n.font))
                    .foregroundColor(colorOf(n.color, fallback: .primary))
                    .padding(n.padding ? 8 : 0)
            )
        case .stack(let axis, let children):
            let spacing = CGFloat(n.spacing ?? 12)
            let content = ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                render(child)
            }
            let stack: AnyView = axis == "h"
                ? AnyView(HStack(spacing: spacing) { content })
                : (axis == "z"
                    ? AnyView(ZStack { content })
                    : AnyView(VStack(spacing: spacing) { content }))
            return AnyView(
                stack
                    .padding(n.padding ? 12 : 0)
                    .background(backgroundColorOf(n.bg))
                    .cornerRadius(n.bg != nil ? 12 : 0)
            )
        case .shape(let name, let size):
            let side = CGFloat(size ?? 64)
            let fill = colorOf(n.color, fallback: .blue)
            if name == "circle" {
                return AnyView(
                    Circle()
                        .fill(fill)
                        .frame(width: side, height: side)
                        .padding(n.padding ? 8 : 0)
                )
            } else {
                return AnyView(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(fill)
                        .frame(width: side, height: side * 0.7)
                        .padding(n.padding ? 8 : 0)
                )
            }
        case .button(let label, let id):
            return AnyView(
                Button(label) { onTap(id) }
                    .buttonStyle(.borderedProminent)
                    .padding(n.padding ? 8 : 0)
            )
        case .spacer:
            return AnyView(Spacer().frame(height: 12))
        case .divider:
            return AnyView(Divider().padding(.vertical, 4))
        }
    }

    private func fontOf(_ name: String?) -> Font {
        switch name {
        case "largeTitle": return .largeTitle
        case "title": return .title
        case "headline": return .headline
        case "subheadline": return .subheadline
        case "caption": return .caption
        case "footnote": return .footnote
        default: return .body
        }
    }

    private func colorOf(_ name: String?, fallback: Color) -> Color {
        guard let name = name else { return fallback }
        switch name {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray": return .gray
        case "cyan": return .cyan
        case "mint": return .mint
        case "indigo": return .indigo
        case "teal": return .teal
        case "brown": return .brown
        case "white": return .white
        case "black": return .black
        case "primary": return .primary
        case "secondary": return .secondary
        default: return fallback
        }
    }

    private func backgroundColorOf(_ name: String?) -> Color {
        guard let name = name else { return .clear }
        return colorOf(name, fallback: .clear).opacity(0.25)
    }
}
