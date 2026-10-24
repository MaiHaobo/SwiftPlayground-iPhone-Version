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
            id: "blank",
            title: "空白游乐场",
            icon: "doc.badge.plus",
            color: .gray,
            subtitle: "从零开始写"
        )
    ]
}

// MARK: - 首页

struct PlaygroundsHome: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("我的游乐场")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(PlaygroundDocument.samples) { doc in
                            NavigationLink(value: doc) {
                                card(doc)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    Text("本 App 内置了一个 Swift 子集解释器，支持 print、变量、函数、循环、数组、字符串插值等常用语法，写完代码点 ▶ 即可运行。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(white: 0.07).ignoresSafeArea())
            .navigationTitle("SwiftPlayground")
            .navigationDestination(for: PlaygroundDocument.self) { doc in
                PlaygroundEditor(doc: doc)
            }
        }
    }

    private func card(_ doc: PlaygroundDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: doc.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(doc.color.gradient, in: RoundedRectangle(cornerRadius: 10))
            Text(doc.title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(doc.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 14))
    }
}
