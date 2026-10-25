import SwiftUI
import UIKit

// MARK: - 代码编辑器 + 控制台（Live View 在「预览」Tab）

struct PlaygroundEditor: View {
    let doc: PlaygroundDocument
    @EnvironmentObject var session: SessionStore
    @State private var code: String = ""
    @State private var lines: [ConsoleLine] = []
    @State private var autoRun = true
    @State private var bottomPane = 0  // 0 控制台 / 1 预览
    @StateObject private var cloud = CloudRunner()

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                codeEditor
                    .frame(height: geo.size.height * 0.62)
                Divider()
                Picker("面板", selection: $bottomPane) {
                    Text("控制台").tag(0)
                    Text("预览").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                if bottomPane == 0 {
                    consoleSection
                } else {
                    PreviewPane()
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(doc.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    run()
                } label: {
                    Image(systemName: "play.fill")
                        .tint(.accentColor)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    runCloud()
                } label: {
                    if cloud.running {
                        ProgressView()
                    } else {
                        Image(systemName: "cloud.fill")
                            .tint(.purple)
                    }
                }
                .disabled(cloud.running)
            }
        }
        .onAppear {
            cloud.onLine = { text, isErr in
                var out = lines
                out.append(ConsoleLine(text: text, isError: isErr))
                lines = out
            }
            cloud.onFinished = { bottomPane = 0 }
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

    // MARK: 编辑器（系统 UITextView 单层富文本，光标天然对齐）

    private var codeEditor: some View {
        CodeEditorView(code: $code)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func runCloud() {
        bottomPane = 0
        lines.append(ConsoleLine(text: "—— 云端真编译开始 ——", isError: false))
        cloud.run(code: code)
    }

    private func run() {
        session.title = doc.title
        let interp = Interpreter()
        interp.liveViewHandler = { node in
            DispatchQueue.main.async {
                self.session.liveNode = node
            }
        }
        self.session.interpreter = interp
        do {
            try interp.run(code)
            lines = interp.output
        } catch {
            var out = interp.output
            out.append(ConsoleLine(text: "⛔ \(error)", isError: true))
            lines = out
        }
    }
}

// MARK: - 语法高亮（NSAttributedString）

enum Highlighter {
    static let keywords: Set<String> = [
        "var", "let", "func", "if", "else", "for", "in", "while",
        "return", "break", "continue", "true", "false", "import", "print",
        "VStack", "HStack", "ZStack", "Text", "Button", "Circle", "Rectangle",
        "setLiveView", "Spacer", "Divider"
    ]

    static func highlight(_ source: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let ls = source.components(separatedBy: "\n")
        for (idx, line) in ls.enumerated() {
            result.append(highlightLine(line))
            if idx < ls.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    private static func highlightLine(_ line: String) -> NSAttributedString {
        let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
            return NSAttributedString(string: line, attributes: [
                .font: font, .foregroundColor: UIColor.secondaryLabel
            ])
        }
        let result = NSMutableAttributedString()
        var word = ""
        var isInString = false
        var strText = ""

        func append(_ s: String, _ color: UIColor) {
            result.append(NSAttributedString(string: s, attributes: [
                .font: font, .foregroundColor: color
            ]))
        }

        func flushWord() {
            guard !word.isEmpty else { return }
            if keywords.contains(word) {
                append(word, .systemPink)
            } else if Double(word) != nil {
                append(word, .systemOrange)
            } else {
                append(word, .label)
            }
            word = ""
        }

        for c in line {
            if isInString {
                strText.append(c)
                if c == "\"" {
                    append(strText, .systemGreen)
                    strText = ""
                    isInString = false
                }
                continue
            }
            if c == "\"" {
                flushWord()
                isInString = true
                strText = String(c)
                continue
            }
            if c.isLetter || c.isNumber || c == "_" || c == "$" {
                word.append(c)
                continue
            }
            flushWord()
            append(String(c), .secondaryLabel)
        }
        if isInString { append(strText, .systemGreen) }
        flushWord()
        return result
    }
}

// MARK: - 系统文本视图编辑器（单层，杜绝光标错位）

struct CodeEditorView: UIViewRepresentable {
    @Binding var code: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        tv.backgroundColor = .clear
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.showsVerticalScrollIndicator = true
        // 长行不折行，横向滚动查看（类似 Xcode）
        tv.textContainer.widthTracksTextView = false
        tv.textContainer.size = CGSize(width: 100000, height: 0)
        tv.alwaysBounceHorizontal = true
        tv.showsHorizontalScrollIndicator = true
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 8, right: 12)
        tv.delegate = context.coordinator
        tv.attributedText = Highlighter.highlight(code)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != code {
            let offset = tv.contentOffset
            let sel = tv.selectedRange
            tv.attributedText = Highlighter.highlight(code)
            tv.contentOffset = offset
            if sel.location <= (tv.text as NSString).length {
                tv.selectedRange = sel
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditorView
        init(_ parent: CodeEditorView) { self.parent = parent }

        func textViewDidChange(_ tv: UITextView) {
            parent.code = tv.text
            // 保存并恢复滚动位置与光标，避免刷新高亮时视图跳动
            let offset = tv.contentOffset
            let sel = tv.selectedRange
            tv.attributedText = Highlighter.highlight(tv.text)
            tv.contentOffset = offset
            if sel.location <= (tv.text as NSString).length {
                tv.selectedRange = sel
            }
        }
    }
}
