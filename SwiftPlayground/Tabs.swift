import SwiftUI

// MARK: - 预览 Tab：全局 Live View

struct PreviewTab: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        NavigationStack {
            Group {
                if let node = session.liveNode {
                    ScrollView {
                        ViewRenderer(node: node) { id in
                            try? session.interpreter?.tapButton(id)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("还没有实时预览")
                            .font(.headline)
                        Text("到「游乐场」打开「界面与预览」示例，运行调用了 setLiveView 的代码后，这里会实时显示界面，还能直接点按钮交互。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 80)
                }
            }
            .navigationTitle(session.title.isEmpty ? "预览" : "预览 · \(session.title)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 关于 Tab

struct AboutTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("这是什么") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SwiftPlayground 是专为 iPhone 打造的 Swift 游乐场。内置纯 Swift 实现的 Swift 子集解释器，写完代码点 ▶ 即可运行，无需编译器。")
                        Text("界面代码通过 setLiveView 实时渲染，交互体验与官方 Playground 的 Live View 一致。")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                }
                Section("支持的语法") {
                    row("var / let、中文标识符", icon: "textformat")
                    row("Int / Double / String / Bool / 数组 / 范围", icon: "number")
                    row("if-else / for-in / while / break / continue", icon: "arrow.triangle.branch")
                    row("自定义函数、return", icon: "function")
                    row("字符串插值 \\(表达式)", icon: "curlybraces")
                    row("闭包 { x in ... }、$0 简写、尾随闭包", icon: "chevron.left.forwardslash.chevron.right")
                    row("map / filter / reduce / sorted", icon: "list.number")
                }
                Section("Live View 控件") {
                    row("Text / VStack / HStack / ZStack", icon: "rectangle.split.3x1")
                    row("Circle / RoundedRect rectangle / Spacer / Divider", icon: "square.on.circle")
                    row("Button（可点击交互）", icon: "hand.tap")
                    row(".font / .foregroundColor / .background / .padding", icon: "wand.and.stars")
                }
                Section(footer: Text("未签名 IPA 需通过 Sideloadly / AltStore 等工具签名后安装，免费 Apple ID 签名 7 天有效。")) {
                    row("版本 1.0 · 仅支持 iPhone", icon: "iphone.gen3")
                }
            }
            .navigationTitle("关于")
        }
    }

    private func row(_ text: String, icon: String) -> some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.tint)
        }
    }
}
