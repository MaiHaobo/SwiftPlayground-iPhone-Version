import SwiftUI

// MARK: - Tab2 新建

struct NewDocTab: View {
    @EnvironmentObject var docs: DocsStore
    @State private var name = ""
    @State private var templateIndex = 0
    @State private var path: [PlaygroundDocument] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("App 名称") {
                    TextField("例如：我的计算器", text: $name)
                }
                Section("选择模板") {
                    ForEach(DocTemplate.all.indices, id: \.self) { i in
                        Button {
                            templateIndex = i
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: DocTemplate.all[i].icon)
                                    .font(.title3)
                                    .foregroundStyle(DocTemplate.all[i].color)
                                    .frame(width: 34)
                                Text(DocTemplate.all[i].name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if templateIndex == i {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                Section {
                    Button {
                        createDoc()
                    } label: {
                        Label("创建 App", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                } footer: {
                    Text("创建后会自动打开代码编辑器，模板代码可以直接改。")
                }
            }
            .navigationTitle("新建")
            .navigationDestination(for: PlaygroundDocument.self) { doc in
                PlaygroundEditor(doc: doc)
            }
        }
    }

    private func createDoc() {
        let title = name.trimmingCharacters(in: .whitespaces)
        let doc = docs.addDoc(title: title, templateIndex: templateIndex)
        name = ""
        templateIndex = 0
        path.append(doc)
    }
}

// MARK: - 预览面板（编辑器内嵌，控制台/预览切换用）

struct PreviewPane: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        if let node = session.liveNode {
            ScrollView {
                ViewRenderer(node: node) { id in
                    try? session.interpreter?.tapButton(id)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("运行调用 setLiveView 的代码后，这里会显示实时界面")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Tab3 设置

struct SettingsTab: View {
    @EnvironmentObject var docs: DocsStore
    @State private var confirmClear = false
    @AppStorage("gh_cloud_token") private var ghToken = ""
    @AppStorage("gh_cloud_repo") private var ghRepo = ""


    var body: some View {
        NavigationStack {
            List {
                Section {
                    // 用普通文本框：SecureField 会强制禁用第三方输入法
                    TextField("粘贴 Token（填 Token 即登录，无需输账号密码）", text: $ghToken)
                        .font(.footnote.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("仓库名（默认 swiftplayground-cloud）", text: $ghRepo)
                        .font(.footnote.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("云端真编译（GitHub Actions）")
                } footer: {
                    Text("填入你自己的 Personal Access Token 就等于登录了你的账号——代码会自动传到 Token 所属账号的仓库里编译，不需要再输用户名或密码。生成方法：GitHub → 头像 → Settings → Developer settings → Personal access tokens → Generate new token，勾选 repo 和 workflow 两项权限。首次云运行会自动在你账号下创建 swiftplayground-cloud 仓库。用完建议随时撤销 Token。")
                }
                Section("数据") {
                    Button {
                        confirmClear = true
                    } label: {
                        Label("清除所有代码与自建 App", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
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
                    row("Circle / RoundedRectangle / Spacer / Divider", icon: "square.on.circle")
                    row("Button（可点击交互）", icon: "hand.tap")
                    row(".font / .foregroundColor / .background / .padding", icon: "wand.and.stars")
                }
                Section(footer: Text("未签名 IPA 需通过 Sideloadly / AltStore 等工具签名后安装，免费 Apple ID 签名 7 天有效。")) {
                    row("版本 1.5 · 仅支持 iPhone", icon: "iphone.gen3")
                }
            }
            .navigationTitle("设置")
            .alert("确定清除所有数据？", isPresented: $confirmClear) {
                Button("清除", role: .destructive) { docs.clearAllCode() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("所有自建 App 与修改过的代码都会被删除，内置示例恢复初始代码。")
            }
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
