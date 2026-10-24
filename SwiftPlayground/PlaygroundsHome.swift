import SwiftUI

// MARK: - 游乐场文档

struct PlaygroundDocument: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let subtitle: String

    var storedCode: String {
        get { UserDefaults.standard.string(forKey: "code_" + id) ?? defaultCode }
    }

    func saveCode(_ newCode: String) {
        UserDefaults.standard.set(newCode, forKey: "code_" + id)
    }
}

extension PlaygroundDocument {
    static let samples: [PlaygroundDocument] = [
        PlaygroundDocument(
            id: "hello",
            title: "我的第一行代码",
            icon: "hand.wave.fill",
            color: .blue,
            subtitle: "变量、字符串与打印"
        ),
        PlaygroundDocument(
            id: "loops",
            title: "循环与图形",
            icon: "repeat",
            color: .orange,
            subtitle: "for / while / 金字塔"
        ),
        PlaygroundDocument(
            id: "funcs",
            title: "函数与数学",
            icon: "function",
            color: .purple,
            subtitle: "自定义函数、递归思维"
        ),
        PlaygroundDocument(
            id: "arrays",
            title: "数组与条件",
            icon: "list.bullet.rectangle.fill",
            color: .green,
            subtitle: "数组、if/else、排序"
        ),
        PlaygroundDocument(
            id: "ui",
            title: "界面与预览",
            icon: "paintbrush.pointed.fill",
            color: .pink,
            subtitle: "Live View：写 SwiftUI 风格界面"
        ),
        PlaygroundDocument(
            id: "blank",
            title: "空白游乐场",
            icon: "doc.badge.plus",
            color: .gray,
            subtitle: "从零开始写"
        )
    ]
}

// MARK: - 首页（系统原生列表，自动适配液态玻璃）

struct PlaygroundsHome: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(PlaygroundDocument.samples) { doc in
                        NavigationLink(value: doc) {
                            HStack(spacing: 14) {
                                Image(systemName: doc.icon)
                                    .font(.title3)
                                    .foregroundStyle(doc.color)
                                    .frame(width: 34)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(doc.title)
                                        .font(.body)
                                    Text(doc.subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } footer: {
                    Text("内置 Swift 子集解释器，支持 print、变量、函数、循环、数组、字符串插值、闭包与 Live View 实时预览，写完代码点 ▶ 即可运行。")
                }
            }
            .navigationTitle("SwiftPlayground")
            .navigationDestination(for: PlaygroundDocument.self) { doc in
                PlaygroundEditor(doc: doc)
            }
        }
    }
}
