import SwiftUI

// MARK: - 代码编辑器 + 控制台 + Live View 预览

struct PlaygroundEditor: View {
    let doc: PlaygroundDocument
    @State private var code: String = ""
    @State private var lines: [ConsoleLine] = []
    @State private var autoRun = true
    @State private var tab = 0            // 0 = 代码, 1 = 预览
    @State private var liveNode: ViewNode?
    @State private var interpreter: Interpreter?

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Picker("视图", selection: $tab) {
                    Text("代码").tag(0)
                    Text("预览").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                if tab == 0 {
                    codeEditor
                        .frame(height: geo.size.height * 0.52)
                } else {
                    previewPane
                        .frame(height: geo.size.height * 0.52)
                }
                Divider()
                consoleSection
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(doc.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tab = (tab == 0 ? 1 : 0)
                } label: {
                    Image(systemName: tab == 0 ? "rectangle.on.rectangle" : "pencil.line")
                        .tint(.accentColor)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    run()
                } label: {
                    Image(systemName: "play.fill")
                        .tint(.accentColor)
                }
            }
        }
        .onAppear {
            if code.isEmpty {
                code = doc.storedCode
                run()
            }
        }
        .onChange(of: code) { newValue in
            doc.saveCode(newValue)
            if autoRun { run() }
        }
    }

    // MARK: 编辑器（高亮层 + 透明输入层）

    private var codeEditor: some View {
        ZStack(alignment: .topLeading) {
            highlightText(code)
                .font(.system(size: 14, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 14)
                .padding(.leading, 16)
                .allowsHitTesting(false)
            TextEditor(text: $code)
                .font(.system(size: 14, design: .monospaced))
                .scrollContentBackground(.hidden)
                .foregroundColor(.clear)
                .padding(.top, 10)
        }
        .background(Color(.systemBackground))
    }

    // MARK: Live View 预览

    private var previewPane: some View {
        ScrollView {
            if let node = liveNode {
                ViewRenderer(node: node) { id in
                    try? interpreter?.tapButton(id)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("在代码里调用 setLiveView(视图) 后，实时预览会显示在这里")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: 控制台

    private var consoleSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("控制台")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("自动运行", isOn: $autoRun)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                Text("自动")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button {
                    lines = []
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if lines.isEmpty {
                            Text("点击右上角 ▶ 运行，输出会显示在这里")
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        ForEach(lines) { line in
                            Text(line.text)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(line.isError ? .red : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(line.id)
                        }
                    }
                    .padding(10)
                }
                .onChange(of: lines) { _ in
                    if let last = lines.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func run() {
        let interp = Interpreter()
        interp.liveViewHandler = { node in
            DispatchQueue.main.async {
                self.liveNode = node
            }
        }
        self.interpreter = interp
        do {
            try interp.run(code)
            lines = interp.output
        } catch {
            var out = interp.output
            out.append(ConsoleLine(text: "⛔ \(error)", isError: true))
            lines = out
        }
    }

    // MARK: 语法高亮

    private func highlightText(_ source: String) -> Text {
        let keywords: Set<String> = [
            "var", "let", "func", "if", "else", "for", "in", "while",
            "return", "break", "continue", "true", "false", "import", "print",
            "VStack", "HStack", "ZStack", "Text", "Button", "Circle", "Rectangle",
            "setLiveView", "Spacer", "Divider"
        ]
        let ls = source.components(separatedBy: "\n")
        var out = Text("")
        for (idx, line) in ls.enumerated() {
            out = out + highlightLine(line, keywords: keywords)
            if idx < ls.count - 1 { out = out + Text("\n") }
        }
        return out
    }

    private func highlightLine(_ line: String, keywords: Set<String>) -> Text {
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
            return Text(line).foregroundColor(.secondary)
        }
        var result = Text("")
        var word = ""
        var isInString = false
        var strText = ""

        func flushWord() {
            guard !word.isEmpty else { return }
            if keywords.contains(word) {
                result = result + Text(word).foregroundColor(.pink)
            } else if Double(word) != nil {
                result = result + Text(word).foregroundColor(.orange)
            } else {
                result = result + Text(word).foregroundColor(.primary)
            }
            word = ""
        }

        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if isInString {
                strText.append(c)
                if c == "\"" {
                    result = result + Text(strText).foregroundColor(.green)
                    strText = ""
                    isInString = false
                }
                i += 1
                continue
            }
            if c == "\"" {
                flushWord()
                isInString = true
                strText = String(c)
                i += 1
                continue
            }
            if c.isLetter || c.isNumber || c == "_" || c == "$" {
                word.append(c)
                i += 1
                continue
            }
            flushWord()
            result = result + Text(String(c)).foregroundStyle(.secondary)
            i += 1
        }
        if isInString { result = result + Text(strText).foregroundColor(.green) }
        flushWord()
        return result
    }
}
