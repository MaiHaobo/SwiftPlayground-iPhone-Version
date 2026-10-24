import SwiftUI

// MARK: - 代码编辑器 + 控制台

struct PlaygroundEditor: View {
    let doc: PlaygroundDocument
    @State private var code: String = ""
    @State private var lines: [ConsoleLine] = []
    @State private var autoRun = true

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                codeEditor
                    .frame(height: geo.size.height * 0.55)
                Divider()
                consoleSection
            }
        }
        .background(Color(white: 0.11).ignoresSafeArea())
        .navigationTitle(doc.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    run()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.cyan)
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
            doc.storedCode = newValue
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
        .background(Color(white: 0.13))
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
                                .foregroundColor(Color(white: 0.4))
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
        .background(Color(white: 0.09))
    }

    private func run() {
        let interp = Interpreter()
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
            "return", "break", "continue", "true", "false", "import", "print"
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
            return Text(line).foregroundColor(Color(white: 0.45))
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
                result = result + Text(word).foregroundColor(.white)
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
            if c.isLetter || c.isNumber || c == "_" {
                word.append(c)
                i += 1
                continue
            }
            flushWord()
            result = result + Text(String(c)).foregroundColor(Color(white: 0.75))
            i += 1
        }
        if isInString { result = result + Text(strText).foregroundColor(.green) }
        flushWord()
        return result
    }
}
