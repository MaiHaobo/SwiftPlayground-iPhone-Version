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
            id: "models",
            title: "结构与枚举",
            icon: "shippingbox.fill",
            color: .teal,
            subtitle: "struct / enum / switch / 下标"
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

    var isSample: Bool { !id.hasPrefix("my_") }
}

// MARK: - 新建模板

struct DocTemplate {
    let name: String
    let icon: String
    let color: Color
    let code: String

    static let all: [DocTemplate] = [
        DocTemplate(name: "空白", icon: "doc.badge.plus", color: .gray, code: """
            // 空白游乐场 — 随便写点什么吧！

            print("Hello, Swift!")

            """),
        DocTemplate(name: "Hello 世界", icon: "hand.wave.fill", color: .blue, code: """
            print("你好，iPhone！")

            var 名字 = "游乐场"
            print("欢迎来到 \\(名字)")
            """),
        DocTemplate(name: "循环练习", icon: "repeat", color: .orange, code: """
            for i in 1...9 {
                var line = ""
                for _ in 1...i {
                    line += "*"
                }
                print(line)
            }
            """),
        DocTemplate(name: "函数练习", icon: "function", color: .purple, code: """
            func square(n) {
                return n * n
            }

            print(square(8))
            """),
        DocTemplate(name: "计数器界面", icon: "paintbrush.pointed.fill", color: .pink, code: """
            import SwiftUI

            var count = 0

            func update() {
                setLiveView(VStack(spacing: 16) {
                    Text("当前次数：\\(count)")
                        .font(.title)
                        .foregroundColor(.blue)
                    Button("点我 +1") {
                        count += 1
                        update()
                    }
                })
            }

            update()
            """)
    ]
}

// MARK: - 我的App 文档仓库（跨 Tab 共享）

final class DocsStore: ObservableObject {
    @Published var myDocIDs: [String] = UserDefaults.standard.stringArray(forKey: "myDocIDs") ?? [] {
        didSet { UserDefaults.standard.set(myDocIDs, forKey: "myDocIDs") }
    }

    func docs() -> [PlaygroundDocument] {
        myDocIDs.map { id in
            let ud = UserDefaults.standard
            let title = ud.string(forKey: "title_" + id) ?? "未命名"
            let tpl = DocTemplate.all[max(0, ud.integer(forKey: "tpl_" + id))]
            return PlaygroundDocument(id: id, title: title, icon: tpl.icon, color: tpl.color, subtitle: tpl.name)
        }
    }

    @discardableResult
    func addDoc(title: String, templateIndex: Int) -> PlaygroundDocument {
        let id = "my_" + UUID().uuidString.prefix(8)
        let ud = UserDefaults.standard
        ud.set(title, forKey: "title_" + id)
        ud.set(templateIndex, forKey: "tpl_" + id)
        let tpl = DocTemplate.all[templateIndex]
        let doc = PlaygroundDocument(id: id, title: title, icon: tpl.icon, color: tpl.color, subtitle: tpl.name)
        doc.saveCode(tpl.code)
        myDocIDs.append(id)
        return doc
    }

    func removeDoc(_ id: String) {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "title_" + id)
        ud.removeObject(forKey: "code_" + id)
        ud.removeObject(forKey: "tpl_" + id)
        myDocIDs.removeAll { $0 == id }
    }

    func clearAllCode() {
        let ud = UserDefaults.standard
        for key in ud.dictionaryRepresentation().keys where key.hasPrefix("code_") || key.hasPrefix("title_") || key.hasPrefix("tpl_") {
            ud.removeObject(forKey: key)
        }
        myDocIDs = []
    }
}

// MARK: - Tab1 首页（我的App）

struct PlaygroundsHome: View {
    @EnvironmentObject var docs: DocsStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if docs.docs().isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.tint)
                            Text("还没有自己的 App，去「新建」标签创建一个吧！")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(docs.docs()) { doc in
                            NavigationLink(value: doc) {
                                docRow(doc)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    docs.removeDoc(doc.id)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("我的App")
                }

                Section("内置示例") {
                    ForEach(PlaygroundDocument.samples) { doc in
                        NavigationLink(value: doc) {
                            docRow(doc)
                        }
                    }
                }
            }
            .navigationTitle("首页")
            .navigationDestination(for: PlaygroundDocument.self) { doc in
                PlaygroundEditor(doc: doc)
            }
        }
    }

    private func docRow(_ doc: PlaygroundDocument) -> some View {
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
