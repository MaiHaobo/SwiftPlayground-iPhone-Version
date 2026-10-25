import Foundation

// MARK: - 错误类型

struct PlayError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

// MARK: - 控制台输出行

struct ConsoleLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isError: Bool
}

// MARK: - 视图树节点（解释器产出，SwiftUI 渲染）

final class ViewNode {
    enum Kind {
        case text(String)
        case stack(axis: String, children: [ViewNode])   // v / h / z
        case shape(String, Int?)                          // circle / rect
        case button(String, Int)                          // label, handlerId
        case spacer
        case divider
    }
    var kind: Kind
    var font: String?
    var color: String?
    var bg: String?
    var padding = false
    var spacing: Int?

    init(kind: Kind) { self.kind = kind }
}

// MARK: - 作用域（引用类型，闭包可捕获并修改变量）

final class Scope {
    var vars: [String: Value] = [:]
    init(_ d: [String: Value] = [:]) { vars = d }
}

// MARK: - 运行时值

enum Value {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case array([Value])
    case range(Int, Int, closed: Bool)
    case function(FuncDecl)
    case closure([String], [Stmt], Scope)
    case view(ViewNode)
    case enumCase(String)
    case instance(String, [String: Value])              // struct 实例（值语义）
    case enumValue(String?, String, [Value])            // 用户枚举：类型名, case 名, 关联值
    case void

    var typeName: String {
        switch self {
        case .int: return "Int"
        case .double: return "Double"
        case .string: return "String"
        case .bool: return "Bool"
        case .array: return "Array"
        case .range: return "Range"
        case .function, .closure: return "Function"
        case .view: return "View"
        case .enumCase: return "EnumCase"
        case .instance(let n, _): return n
        case .enumValue(let t, _, _): return t ?? "Enum"
        case .void: return "Void"
        }
    }

    func truthy() throws -> Bool {
        guard case .bool(let b) = self else {
            throw PlayError(message: "条件必须是 Bool 类型，而不是 \(typeName)")
        }
        return b
    }
}

struct FuncDecl {
    let name: String
    let params: [String]
    let body: [Stmt]
}

// MARK: - 字符串插值片段

enum StrPart: Equatable {
    case lit(String)
    case expr(String)
}

// MARK: - 词法单元

struct Token {
    enum Kind: Equatable {
        case num(Double)
        case str([StrPart])
        case ident(String)
        case op(String)
        case newline
        case eof
    }
    let kind: Kind
}

// MARK: - 抽象语法树

indirect enum Expr {
    case num(Double)
    case string([StrPart])
    case bool(Bool)
    case ident(String)
    case arrayLit([Expr])
    case closureLit([String], [Stmt])
    case enumCase(String)
    case unary(String, Expr)
    case binary(String, Expr, Expr)
    case call(String, [Expr])
    case invoke(Expr, [Expr])
    case method(Expr, String, [Expr])
    case member(Expr, String)
    case index(Expr, Expr)
}

enum Stmt {
    case varDecl(String, Bool, Expr)
    case assign(String, Expr)
    case memberAssign(Expr, Expr)          // instance.field = value
    case expr(Expr)
    case ifStmt(Expr, [Stmt], [Stmt]?)
    case forStmt(String, Expr, [Stmt])
    case whileStmt(Expr, [Stmt])
    case funcDecl(FuncDecl)
    case structDecl(String, [(String, Expr?)], [FuncDecl])
    case enumDecl(String, [(String, Int)])
    case switchStmt(Expr, [SwitchCase])
    case ret(Expr?)
    case brk
    case cont
}

// switch 的一个分支：多个模式（逗号分隔），每个模式可带 let 绑定
struct SwitchCase {
    var patterns: [Expr]        // nil 视为 default（放空数组 + isDefault）
    var binds: [[String]]       // 与 patterns 一一对应的 let 绑定名
    var isDefault: Bool
    var body: [Stmt]
}

// MARK: - 词法分析器

final class Lexer {
    private let src: [Character]
    private var i = 0
    init(_ source: String) { src = Array(source) }

    private var eof: Bool { i >= src.count }
    private var cur: Character { eof ? "\0" : src[i] }
    private var next: Character { i + 1 < src.count ? src[i + 1] : "\0" }
    private func advance() -> Character { let c = cur; i += 1; return c }

    func tokenize() throws -> [Token] {
        var toks: [Token] = []
        while !eof {
            let c = cur
            if c == "\n" { advance(); toks.append(Token(kind: .newline)); continue }
            if c == " " || c == "\t" || c == "\r" { advance(); continue }
            if c == "/" && next == "/" { while !eof && cur != "\n" { advance() }; continue }
            if c == "/" && next == "*" {
                advance(); advance()
                while !eof && !(cur == "*" && next == "/") { advance() }
                i += 2; continue
            }
            if c.isNumber || (c == "." && next.isNumber) {
                toks.append(Token(kind: .num(try lexNumber()))); continue
            }
            if c == "\"" { toks.append(Token(kind: .str(try lexString()))); continue }
            if c.isLetter || c == "_" || c == "$" { toks.append(Token(kind: .ident(lexIdent()))); continue }
            let three = String(c) + String(next) + String(i + 2 < src.count ? src[i + 2] : "\0")
            if three == "..." { i += 3; toks.append(Token(kind: .op("..."))); continue }
            let two = String(c) + String(next)
            if ["..<", "==", "!=", "<=", ">=", "&&", "||", "+=", "-=", "*=", "/="].contains(two) {
                i += 2; toks.append(Token(kind: .op(two))); continue
            }
            if "+-*/%<>=(){}[],.!:;".contains(c) {
                advance(); toks.append(Token(kind: .op(String(c)))); continue
            }
            let unsupported = ["@": "@propertyWrapper（如 @State）", "#": "#Preview / #if 等编译指令", "?": "可选值 Optional", "&": "取地址"]
            if let hint = unsupported[String(c)] {
                throw PlayError(message: "暂不支持 Swift 全部语法：这里出现了 \(hint)。本 App 内置的是 Swift 子集解释器，支持的语法见「设置」页；真正的 SwiftUI 工程需要 Xcode 编译。")
            }
            throw PlayError(message: "无法识别的字符：\(c)")
        }
        toks.append(Token(kind: .eof))
        return toks
    }

    private func lexNumber() throws -> Double {
        var s = ""
        while !eof {
            if cur.isNumber {
                s.append(advance())
            } else if cur == "." && !s.contains(".") && next != "." {
                s.append(advance())
            } else {
                break
            }
        }
        guard let v = Double(s) else { throw PlayError(message: "非法数字：\(s)") }
        return v
    }

    private func lexIdent() -> String {
        var s = ""
        while !eof, cur.isLetter || cur.isNumber || cur == "_" || cur == "$" { s.append(advance()) }
        return s
    }

    private func lexString() throws -> [StrPart] {
        advance()
        var parts: [StrPart] = []
        var lit = ""
        while !eof {
            let c = advance()
            if c == "\"" {
                if !lit.isEmpty { parts.append(.lit(lit)) }
                return parts
            }
            if c == "\\" {
                if eof { break }
                let e = advance()
                switch e {
                case "n": lit.append("\n")
                case "t": lit.append("\t")
                case "\\": lit.append("\\")
                case "\"": lit.append("\"")
                case "(":
                    if !lit.isEmpty { parts.append(.lit(lit)); lit = "" }
                    var depth = 1, expr = ""
                    while !eof && depth > 0 {
                        let ch = advance()
                        if ch == "(" { depth += 1 }
                        if ch == ")" { depth -= 1; if depth == 0 { break } }
                        expr.append(ch)
                    }
                    parts.append(.expr(expr))
                default: lit.append(e)
                }
            } else {
                lit.append(c)
            }
        }
        throw PlayError(message: "字符串缺少结束引号")
    }
}

// MARK: - 语法分析器

final class Parser {
    private var toks: [Token]
    private var p = 0
    init(_ toks: [Token]) { self.toks = toks }

    private let keywords: Set<String> = [
        "var", "let", "func", "if", "else", "for", "in", "while",
        "return", "break", "continue", "true", "false", "import",
        "struct", "enum", "switch", "case", "default"
    ]

    // 支持尾随闭包的视图构造器
    private let viewTypes: Set<String> = ["VStack", "HStack", "ZStack", "Group", "Button"]
    // 支持尾随闭包的数组方法
    private let closureMethods: Set<String> = ["map", "filter", "reduce"]

    private var cur: Token { toks[p] }
    private var isEOF: Bool { if case .eof = cur.kind { return true }; return false }
    private func advance() -> Token { let t = toks[p]; if p < toks.count - 1 { p += 1 }; return t }

    private func isOp(_ o: String) -> Bool {
        if case .op(let v) = cur.kind, v == o { return true }
        return false
    }

    private func eatNewlines() {
        while case .newline = cur.kind { _ = advance() }
    }

    private func describe(_ t: Token) -> String {
        switch t.kind {
        case .num(let n): return "\(n)"
        case .str: return "字符串"
        case .ident(let v): return v
        case .op(let v): return v
        case .newline: return "换行"
        case .eof: return "结尾"
        }
    }

    private func expectOp(_ o: String) throws {
        eatNewlines()
        guard isOp(o) else { throw PlayError(message: "期望 «\(o)»，但遇到了 «\(describe(cur))»") }
        _ = advance()
    }

    private func expectIdent() throws -> String {
        eatNewlines()
        guard case .ident(let v) = cur.kind else {
            throw PlayError(message: "期望标识符，但遇到了 «\(describe(cur))»")
        }
        _ = advance()
        return v
    }

    private var atLineEnd: Bool {
        if case .newline = cur.kind { return true }
        if case .eof = cur.kind { return true }
        return isOp("}")
    }

    private func skipTypeAnnotation() throws {
        try expectOp(":")
        eatNewlines()
        while true {
            if case .ident = cur.kind { _ = advance() }
            else if isOp(".") || isOp("?") { _ = advance() }
            else if isOp("[") { _ = advance(); if isOp("]") { _ = advance() } }
            else { break }
        }
    }

    func parseProgram() throws -> [Stmt] {
        var stmts: [Stmt] = []
        eatNewlines()
        while !isEOF {
            stmts.append(try parseStatement())
            eatNewlines()
        }
        return stmts
    }

    private func parseStatement() throws -> Stmt {
        if case .ident(let word) = cur.kind {
            switch word {
            case "var", "let":
                _ = advance()
                let name = try expectIdent()
                if isOp(":") { try skipTypeAnnotation() }
                try expectOp("=")
                return .varDecl(name, word == "var", try parseExpr())
            case "func":
                return .funcDecl(try parseFunc())
            case "if": return try parseIf()
            case "for":
                _ = advance()
                let varName = try expectIdent()
                guard case .ident(let kw) = advance().kind, kw == "in" else {
                    throw PlayError(message: "for 循环需要 «in»")
                }
                let seq = try parseExpr()
                return .forStmt(varName, seq, try parseBlock())
            case "while":
                _ = advance()
                let cond = try parseExpr()
                return .whileStmt(cond, try parseBlock())
            case "return":
                _ = advance()
                if atLineEnd { return .ret(nil) }
                return .ret(try parseExpr())
            case "break": _ = advance(); return .brk
            case "continue": _ = advance(); return .cont
            case "import":
                _ = advance()
                while !isEOF { if case .newline = cur.kind { break }; _ = advance() }
                return .expr(.bool(true))
            case "struct": return try parseStructDecl()
            case "enum": return try parseEnumDecl()
            case "switch": return try parseSwitch()
            default: break
            }
        }
        let e = try parseExpr()
        if case .op(let o) = cur.kind, ["+=", "-=", "*=", "/="].contains(o) {
            _ = advance()
            guard case .ident(let name) = e else { throw PlayError(message: "复合赋值只能用于变量") }
            return .assign(name, .binary(String(o.prefix(1)), e, try parseExpr()))
        }
        if isOp("=") {
            _ = advance()
            if case .member = e {
                return .memberAssign(e, try parseExpr())
            }
            guard case .ident(let name) = e else { throw PlayError(message: "只能给变量赋值") }
            return .assign(name, try parseExpr())
        }
        return .expr(e)
    }

    // MARK: struct / enum / switch

    private func parseStructDecl() throws -> Stmt {
        _ = advance() // struct
        let name = try expectIdent()
        try expectOp("{")
        var fields: [(String, Expr?)] = []
        var methods: [FuncDecl] = []
        eatNewlines()
        while !isOp("}") && !isEOF {
            guard case .ident(let kw) = cur.kind else {
                throw PlayError(message: "struct 里只能有属性（var/let）和方法（func）")
            }
            if kw == "var" || kw == "let" {
                _ = advance()
                let fname = try expectIdent()
                if isOp(":") { try skipTypeAnnotation() }
                var def: Expr? = nil
                if isOp("=") { _ = advance(); def = try parseExpr() }
                fields.append((fname, def))
                if isOp(",") || isOp(";") { _ = advance(); eatNewlines(); continue }
            } else if kw == "func" {
                methods.append(try parseFunc())
            } else {
                throw PlayError(message: "struct 里只能有属性（var/let）和方法（func）")
            }
            eatNewlines()
        }
        try expectOp("}")
        return .structDecl(name, fields, methods)
    }

    private func parseEnumDecl() throws -> Stmt {
        _ = advance() // enum
        let name = try expectIdent()
        try expectOp("{")
        var cases: [(String, Int)] = []
        eatNewlines()
        while !isOp("}") && !isEOF {
            guard case .ident(let kw) = cur.kind, kw == "case" else {
                throw PlayError(message: "enum 里目前只支持 case 定义")
            }
            _ = advance()
            eatNewlines()
            while true {
                let cname = try expectIdent()
                var assoc = 0
                if isOp("(") {
                    _ = advance(); eatNewlines()
                    assoc = 1
                    while !isOp(")") {
                        if isOp(",") { assoc += 1 }
                        _ = advance(); eatNewlines()
                    }
                    _ = advance()
                }
                cases.append((cname, assoc))
                if isOp(",") { _ = advance(); eatNewlines(); continue }
                break
            }
            eatNewlines()
        }
        try expectOp("}")
        return .enumDecl(name, cases)
    }

    private func parseSwitch() throws -> Stmt {
        _ = advance() // switch
        let subject = try parseExpr()
        try expectOp("{")
        var cases: [SwitchCase] = []
        eatNewlines()
        while !isOp("}") && !isEOF {
            var isDefault = false
            if case .ident(let kw) = cur.kind, kw == "case" {
                _ = advance()
            } else if case .ident(let kw) = cur.kind, kw == "default" {
                _ = advance()
                isDefault = true
            } else {
                throw PlayError(message: "switch 里需要 case 或 default")
            }
            var patterns: [Expr] = []
            var binds: [[String]] = []
            if !isDefault {
                eatNewlines()
                while true {
                    let (pat, b) = try parsePattern()
                    patterns.append(pat)
                    binds.append(b)
                    if isOp(",") { _ = advance(); eatNewlines(); continue }
                    break
                }
            }
            try expectOp(":")
            eatNewlines()
            var body: [Stmt] = []
            while !isOp("}") && !isEOF {
                // 停在下一个 case / default 前
                if case .ident(let w) = cur.kind, w == "case" || w == "default" { break }
                body.append(try parseStatement())
                eatNewlines()
            }
            cases.append(SwitchCase(patterns: patterns, binds: binds, isDefault: isDefault, body: body))
            eatNewlines()
        }
        try expectOp("}")
        return .switchStmt(subject, cases)
    }

    // 模式：.caseName / .caseName(let a, let b) / 字面量与表达式
    private func parsePattern() throws -> (Expr, [String]) {
        if isOp(".") {
            _ = advance()
            let cname = try expectIdent()
            var binds: [String] = []
            if isOp("(") {
                _ = advance(); eatNewlines()
                while !isOp(")") {
                    if case .ident(let w) = cur.kind, (w == "let" || w == "var") { _ = advance() }
                    binds.append(try expectIdent())
                    if isOp(",") { _ = advance(); eatNewlines() }
                }
                _ = advance()
            }
            return (.enumCase(cname), binds)
        }
        let e = try parseExpr()
        return (e, [])
    }

    private func parseIf() throws -> Stmt {
        _ = advance()
        let cond = try parseExpr()
        let body = try parseBlock()
        var elseBody: [Stmt]? = nil
        if case .ident(let v) = cur.kind, v == "else" {
            _ = advance()
            if case .ident(let w) = cur.kind, w == "if" {
                elseBody = [try parseIf()]
            } else {
                elseBody = try parseBlock()
            }
        }
        return .ifStmt(cond, body, elseBody)
    }

    private func parseFunc() throws -> FuncDecl {
        _ = advance() // func
        let name = try expectIdent()
        try expectOp("(")
        var params: [String] = []
        eatNewlines()
        while !isOp(")") {
            var pname = try expectIdent()
            if pname == "_", case .ident = cur.kind { pname = try expectIdent() }  // 外部标签 _ it
            params.append(pname)
            if isOp(":") { try skipTypeAnnotation() }
            if isOp(",") { _ = advance(); eatNewlines() }
        }
        _ = advance()
        if isOp("->") { _ = advance(); try skipTypeAnnotation() }
        return FuncDecl(name: name, params: params, body: try parseBlock())
    }

    private func parseBlock() throws -> [Stmt] {
        try expectOp("{")
        var stmts: [Stmt] = []
        eatNewlines()
        while !isOp("}") && !isEOF {
            stmts.append(try parseStatement())
            eatNewlines()
        }
        try expectOp("}")
        return stmts
    }

    // MARK: 闭包字面量 { params in body } / { expr }

    private func parseClosure() throws -> Expr {
        _ = advance() // {
        eatNewlines()
        var params: [String] = []

        if isOp("(") {
            _ = advance(); eatNewlines()
            while !isOp(")") {
                params.append(try expectIdent())
                if isOp(",") { _ = advance(); eatNewlines() }
            }
            _ = advance(); eatNewlines()
            guard case .ident(let w) = advance().kind, w == "in" else {
                throw PlayError(message: "闭包参数列表后需要 «in»")
            }
        } else if case .ident(let first) = cur.kind, first != "in", !keywords.contains(first) {
            // 向前看：是 "a in" / "a, b in" 参数列表吗？
            var q = p, ok = false
            while q < toks.count {
                if case .ident(let t) = toks[q].kind, t == "in" { ok = true; break }
                if case .op(let o) = toks[q].kind, o == "," { q += 1; continue }
                if case .ident = toks[q].kind { q += 1; continue }
                break
            }
            if ok {
                while true {
                    params.append(try expectIdent())
                    if isOp(",") { _ = advance(); eatNewlines(); continue }
                    guard case .ident(let w) = advance().kind, w == "in" else {
                        throw PlayError(message: "闭包参数列表后需要 «in»")
                    }
                    break
                }
            }
        }

        var body: [Stmt] = []
        eatNewlines()
        while !isOp("}") && !isEOF {
            body.append(try parseStatement())
            eatNewlines()
        }
        try expectOp("}")
        return .closureLit(params, body)
    }

    // MARK: 表达式（优先级递降）

    func parseExpr() throws -> Expr {
        let lhs = try parseOr()
        if case .op(let v) = cur.kind, v == "..<" || v == "..." {
            _ = advance()
            let rhs = try parseOr()
            return .binary(v, lhs, rhs)
        }
        return lhs
    }

    private func parseBinary(_ ops: [String], _ next: () throws -> Expr) throws -> Expr {
        var lhs = try next()
        while case .op(let v) = cur.kind, ops.contains(v) {
            _ = advance()
            lhs = .binary(v, lhs, try next())
        }
        return lhs
    }

    private func parseOr() throws -> Expr { try parseBinary(["||"], parseAnd) }
    private func parseAnd() throws -> Expr { try parseBinary(["&&"], parseEquality) }
    private func parseEquality() throws -> Expr { try parseBinary(["==", "!="], parseComparison) }
    private func parseComparison() throws -> Expr { try parseBinary(["<", ">", "<=", ">="], parseAdditive) }
    private func parseAdditive() throws -> Expr { try parseBinary(["+", "-"], parseMultiplicative) }
    private func parseMultiplicative() throws -> Expr { try parseBinary(["*", "/", "%"], parseUnary) }

    private func parseUnary() throws -> Expr {
        if isOp("!") { _ = advance(); return .unary("!", try parseUnary()) }
        if isOp("-") { _ = advance(); return .unary("-", try parseUnary()) }
        if isOp("+") { _ = advance(); return try parseUnary() }
        return try parsePostfix()
    }

    private func parsePostfix() throws -> Expr {
        var e = try parsePrimary()
        while true {
            if isOp(".") {
                _ = advance()
                let name = try expectIdent()
                if isOp("(") {
                    e = .method(e, name, try parseArgs())
                } else if isOp("{"), closureMethods.contains(name) {
                    e = .method(e, name, [try parseClosure()])
                } else {
                    e = .member(e, name)
                }
            } else if isOp("(") {
                e = .invoke(e, try parseArgs())
            } else if isOp("[") {
                _ = advance()
                let idx = try parseExpr()
                try expectOp("]")
                e = .index(e, idx)
            } else if isOp("{") {
                // 尾随闭包：视图构造器或数组方法
                if case .call(let n, let a) = e, viewTypes.contains(n) {
                    e = .call(n, a + [try parseClosure()])
                } else if case .method(let b, let m, let a) = e, closureMethods.contains(m) {
                    e = .method(b, m, a + [try parseClosure()])
                } else {
                    break
                }
            } else if case .newline = cur.kind {
                // 换行后若紧跟 «.»，视为跨行的链式调用延续
                let saved = p
                eatNewlines()
                if isOp(".") { continue }
                p = saved
                break
            } else {
                break
            }
        }
        return e
    }

    private func parseArgs() throws -> [Expr] {
        try expectOp("(")
        var args: [Expr] = []
        eatNewlines()
        while !isOp(")") {
            if case .ident(let v) = cur.kind, !keywords.contains(v),
               p + 1 < toks.count, case .op(let o) = toks[p + 1].kind, o == ":" {
                _ = advance(); _ = advance()
            }
            args.append(try parseExpr())
            eatNewlines()
            if isOp(",") { _ = advance(); eatNewlines() }
        }
        _ = advance()
        return args
    }

    private func parsePrimary() throws -> Expr {
        eatNewlines()
        switch cur.kind {
        case .num(let n): _ = advance(); return .num(n)
        case .str(let parts): _ = advance(); return .string(parts)
        case .op(let v) where v == "(":
            _ = advance()
            let e = try parseExpr()
            try expectOp(")")
            return e
        case .op(let v) where v == "[":
            _ = advance()
            var items: [Expr] = []
            eatNewlines()
            while !isOp("]") {
                items.append(try parseExpr())
                eatNewlines()
                if isOp(",") { _ = advance(); eatNewlines() }
            }
            _ = advance()
            return .arrayLit(items)
        case .op(let v) where v == "{":
            return try parseClosure()
        case .op(let v) where v == ".":
            _ = advance()
            let name = try expectIdent()
            return .enumCase(name)
        case .ident(let v):
            _ = advance()
            if v == "true" { return .bool(true) }
            if v == "false" { return .bool(false) }
            if isOp("(") { return .call(v, try parseArgs()) }
            if isOp("{"), viewTypes.contains(v) {
                return .call(v, [try parseClosure()])
            }
            return .ident(v)
        default:
            throw PlayError(message: "意外的符号 «\(describe(cur))»")
        }
    }
}

// MARK: - 解释器

final class Interpreter {
    private(set) var output: [ConsoleLine] = []
    private var scopes: [Scope] = [Scope()]
    private var funcs: [String: FuncDecl] = [:]
    private var structs: [String: (fields: [(String, Expr?)], methods: [String: FuncDecl])] = [:]
    private var enums: [String: [(String, Int)]] = [:]
    private var steps = 0
    private let maxSteps = 500_000
    private var lastValue: Value = .void
    private var viewStacks: [[ViewNode]] = []
    private var buttonHandlers: [Int: Value] = [:]
    private var nextButtonId = 0

    /// Live View 回调：setLiveView(...) 时触发
    var liveViewHandler: ((ViewNode) -> Void)?
    /// 最近一次 setLiveView 的视图树
    private(set) var lastLiveView: ViewNode?

    func run(_ code: String) throws {
        let tokens = try Lexer(code).tokenize()
        let stmts = try Parser(tokens).parseProgram()
        scopes = [Scope()]
        funcs = [:]
        structs = [:]
        enums = [:]
        steps = 0
        output = []
        viewStacks = []
        buttonHandlers = [:]
        nextButtonId = 0
        lastValue = .void
        _ = try exec(stmts)
    }

    /// 点击预览里的按钮
    func tapButton(_ id: Int) throws {
        guard let closure = buttonHandlers[id] else { return }
        _ = try callValue(closure, [])
    }

    private enum Flow { case normal, ret(Value?), brk, cont }

    private func tick() throws {
        steps += 1
        if steps > maxSteps { throw PlayError(message: "运行步数超过上限，可能存在死循环") }
    }

    private func exec(_ stmts: [Stmt]) throws -> Flow {
        for s in stmts {
            let f = try execStmt(s)
            if case .normal = f { continue }
            return f
        }
        return .normal
    }

    private func setVar(_ name: String, _ v: Value) throws {
        for idx in scopes.indices.reversed() {
            if scopes[idx].vars[name] != nil { scopes[idx].vars[name] = v; return }
        }
        scopes[scopes.count - 1].vars[name] = v
    }

    private func lookupOrNull(_ name: String) -> Value? {
        for scope in scopes.reversed() {
            if let v = scope.vars[name] { return v }
        }
        return nil
    }

    private func execStmt(_ s: Stmt) throws -> Flow {
        try tick()
        switch s {
        case .varDecl(let name, _, let e):
            let v = try eval(e)
            scopes[scopes.count - 1].vars[name] = v
            return .normal
        case .assign(let name, let e):
            let v = try eval(e)
            for idx in scopes.indices.reversed() {
                if scopes[idx].vars[name] != nil { scopes[idx].vars[name] = v; return .normal }
            }
            throw PlayError(message: "未定义的变量：\(name)")
        case .expr(let e):
            let v = try eval(e)
            lastValue = v
            if case .view(let node) = v, !viewStacks.isEmpty {
                viewStacks[viewStacks.count - 1].append(node)
            }
            return .normal
        case .ifStmt(let cond, let body, let elseBody):
            if try eval(cond).truthy() { return try exec(body) }
            if let eb = elseBody { return try exec(eb) }
            return .normal
        case .whileStmt(let cond, let body):
            while try eval(cond).truthy() {
                try tick()
                let f = try exec(body)
                if case .brk = f { break }
                if case .ret(let v) = f { return .ret(v) }
            }
            return .normal
        case .forStmt(let name, let seq, let body):
            let v = try eval(seq)
            var items: [Value] = []
            switch v {
            case .range(let a, let b, let closed):
                if b - a > 1_000_000 { throw PlayError(message: "循环范围过大") }
                if closed { if a <= b { items = (a...b).map { .int($0) } } }
                else { if a < b { items = (a..<b).map { .int($0) } } }
            case .array(let arr): items = arr
            case .string(let str): items = str.map { .string(String($0)) }
            default: throw PlayError(message: "for...in 需要范围、数组或字符串")
            }
            for item in items {
                try tick()
                scopes[scopes.count - 1].vars[name] = item
                let f = try exec(body)
                if case .brk = f { break }
                if case .ret(let rv) = f { return .ret(rv) }
            }
            return .normal
        case .funcDecl(let fd):
            funcs[fd.name] = fd
            scopes[scopes.count - 1].vars[fd.name] = .function(fd)
            return .normal
        case .structDecl(let name, let fields, let methods):
            structs[name] = (fields, Dictionary(uniqueKeysWithValues: methods.map { ($0.name, $0) }))
            return .normal
        case .enumDecl(let name, let cases):
            enums[name] = cases
            return .normal
        case .memberAssign(let target, let e):
            let v = try eval(e)
            guard case .member(let base, let field) = target else {
                throw PlayError(message: "只能给属性赋值")
            }
            guard case .ident(let root) = base else {
                throw PlayError(message: "目前只支持一层属性赋值，如 point.x = 5")
            }
            guard let cur = lookupOrNull(root) else {
                throw PlayError(message: "未定义的变量：\(root)")
            }
            guard case .instance(let tn, var fs) = cur else {
                throw PlayError(message: "«\(cur.typeName)» 的属性不能赋值")
            }
            guard fs.keys.contains(field) else {
                throw PlayError(message: "«\(tn)» 没有属性 «\(field)»")
            }
            fs[field] = v
            try setVar(root, .instance(tn, fs))
            return .normal
        case .switchStmt(let subjectExpr, let cases):
            let subject = try eval(subjectExpr)
            for c in cases {
                if c.isDefault {
                    return try exec(c.body)
                }
                for (idx, pat) in c.patterns.enumerated() {
                    let binds = c.binds[idx]
                    if let matched = try matchPattern(pat, subject, binds) {
                        scopes.append(Scope(matched))
                        defer { scopes.removeLast() }
                        return try exec(c.body)
                    }
                }
            }
            return .normal
        case .ret(let e):
            return .ret(e == nil ? nil : try eval(e!))
        case .brk: return .brk
        case .cont: return .cont
        }
    }

    private func callFunc(_ fd: FuncDecl, _ vals: [Value]) throws -> Value {
        guard vals.count == fd.params.count else {
            throw PlayError(message: "函数 \(fd.name) 需要 \(fd.params.count) 个参数，但传入了 \(vals.count) 个")
        }
        let saved = lastValue
        defer { lastValue = saved }
        scopes.append(Scope(Dictionary(uniqueKeysWithValues: zip(fd.params, vals))))
        defer { scopes.removeLast() }
        let f = try exec(fd.body)
        if case .ret(let v) = f { return v ?? .void }
        return lastValue
    }

    private func callValue(_ c: Value, _ vals: [Value]) throws -> Value {
        switch c {
        case .closure(let params, let body, let env):
            let effective = params.isEmpty ? (0..<vals.count).map { "$\($0)" } : params
            guard vals.count == effective.count else {
                throw PlayError(message: "闭包需要 \(effective.count) 个参数，但传入了 \(vals.count) 个")
            }
            let saved = lastValue
            defer { lastValue = saved }
            scopes.append(env)
            scopes.append(Scope(Dictionary(uniqueKeysWithValues: zip(effective, vals))))
            defer { scopes.removeLast(); scopes.removeLast() }
            let f = try exec(body)
            if case .ret(let v) = f { return v ?? .void }
            return lastValue
        case .function(let fd):
            return try callFunc(fd, vals)
        default:
            throw PlayError(message: "\(c.typeName) 不是可调用的值")
        }
    }

    // MARK: 求值

    private func eval(_ e: Expr) throws -> Value {
        try tick()
        switch e {
        case .num(let n):
            return n == n.rounded() ? .int(Int(n)) : .double(n)
        case .bool(let b): return .bool(b)
        case .enumCase(let name): return .enumCase(name)
        case .ident(let name):
            if let v = lookupOrNull(name) { return v }
            throw PlayError(message: "未定义的变量：\(name)")
        case .string(let parts):
            var s = ""
            for part in parts {
                switch part {
                case .lit(let l): s += l
                case .expr(let src): s += stringify(try evalInline(src))
                }
            }
            return .string(s)
        case .arrayLit(let items):
            return .array(try items.map { try eval($0) })
        case .closureLit(let params, let body):
            return .closure(params, body, scopes[scopes.count - 1])
        case .unary(let op, let inner):
            let v = try eval(inner)
            switch (op, v) {
            case ("-", .int(let n)): return .int(-n)
            case ("-", .double(let d)): return .double(-d)
            case ("!", let x): return .bool(!(try x.truthy()))
            default: throw PlayError(message: "运算符 \(op) 无法用于 \(v.typeName)")
            }
        case .binary(let op, let l, let r):
            return try evalBinary(op, l, r)
        case .call(let name, let argExprs):
            let vals = try argExprs.map { try eval($0) }
            if let sd = structs[name] {
                return try makeInstance(name, sd.fields, sd.methods, vals)
            }
            if let fd = funcs[name] { return try callFunc(fd, vals) }
            if let v = lookupOrNull(name), case .closure = v { return try callValue(v, vals) }
            return try callBuiltin(name, vals)
        case .invoke(let callableExpr, let argExprs):
            // 枚举带关联值构造：Name.case(a, b)
            if case .member(let base, let cname) = callableExpr,
               case .ident(let tname) = base, let cases = enums[tname],
               cases.contains(where: { $0.0 == cname }) {
                let vals = try argExprs.map { try eval($0) }
                return .enumValue(tname, cname, vals)
            }
            let c = try eval(callableExpr)
            let vals = try argExprs.map { try eval($0) }
            return try callValue(c, vals)
        case .member(let baseExpr, let name):
            // 枚举类型引用：Name.case → 枚举值
            if case .ident(let tname) = baseExpr, let cases = enums[tname] {
                guard cases.contains(where: { $0.0 == name }) else {
                    throw PlayError(message: "«\(tname)» 没有 case «\(name)»")
                }
                return .enumValue(tname, name, [])
            }
            let v = try eval(baseExpr)
            if case .instance(_, let fs) = v {
                guard let f = fs[name] else {
                    throw PlayError(message: "«\(v.typeName)» 没有属性 «\(name)»")
                }
                return f
            }
            switch (v, name) {
            case (.array(let a), "count"): return .int(a.count)
            case (.string(let s), "count"): return .int(s.count)
            case (.array(let a), "first"): return a.first ?? .void
            case (.array(let a), "last"): return a.last ?? .void
            default:
                // 兜底：变量不存在时按枚举值处理（如 Color.red）
                if case .ident(let b) = baseExpr, lookupOrNull(b) == nil {
                    return .enumCase(name)
                }
                throw PlayError(message: "«\(v.typeName)» 没有属性 «\(name)»")
            }
        case .method(let baseExpr, let name, let argExprs):
            return try evalMethod(baseExpr, name, argExprs)
        case .index(let baseExpr, let idxExpr):
            let b = try eval(baseExpr)
            guard case .int(let idx) = try eval(idxExpr) else {
                throw PlayError(message: "下标必须是 Int")
            }
            switch b {
            case .array(let a):
                guard idx >= 0 && idx < a.count else {
                    throw PlayError(message: "下标越界：\(idx)（数组长度 \(a.count)）")
                }
                return a[idx]
            case .string(let str):
                let chars = Array(str)
                guard idx >= 0 && idx < chars.count else {
                    throw PlayError(message: "下标越界：\(idx)（字符串长度 \(chars.count)）")
                }
                return .string(String(chars[idx]))
            default: throw PlayError(message: "«\(b.typeName)» 不支持下标")
            }
        }
    }

    // MARK: struct 实例与 switch 匹配

    private func makeInstance(_ name: String, _ fields: [(String, Expr?)], _ methods: [String: FuncDecl], _ vals: [Value]) throws -> Value {
        var fs: [String: Value] = [:]
        if vals.count == fields.count {
            for (i, f) in fields.enumerated() { fs[f.0] = vals[i] }
        } else if vals.count < fields.count {
            // 按顺序给前 k 个字段赋值，其余用默认值
            for (i, f) in fields.enumerated() {
                if i < vals.count { fs[f.0] = vals[i] }
                else if let def = f.1 { fs[f.0] = try eval(def) }
                else { throw PlayError(message: "\(name) 的属性 «\(f.0)» 没有默认值，需要传入") }
            }
        } else {
            throw PlayError(message: "\(name) 需要 \(fields.count) 个属性值，但传入了 \(vals.count) 个")
        }
        _ = methods
        return .instance(name, fs)
    }

    /// 模式匹配：匹配成功返回要绑定的变量（否则返回 nil）
    private func matchPattern(_ pat: Expr, _ subject: Value, _ binds: [String]) throws -> [String: Value]? {
        switch pat {
        case .enumCase(let pname):
            switch subject {
            case .enumCase(let s):
                if s == pname { return binds.isEmpty ? [:] : nil }
                return nil
            case .enumValue(_, let s, let assoc):
                guard s == pname else { return nil }
                if binds.isEmpty { return [:] }
                guard binds.count == assoc.count else {
                    throw PlayError(message: "case \(pname) 有 \(assoc.count) 个关联值，但绑定了 \(binds.count) 个")
                }
                return Dictionary(uniqueKeysWithValues: zip(binds, assoc))
            default: return nil
            }
        default:
            let pv = try eval(pat)
            if try valuesEqual(pv, subject) { return [:] }
            return nil
        }
    }

    private func valuesEqual(_ a: Value, _ b: Value) throws -> Bool {
        switch (a, b) {
        case (.int(let x), .int(let y)): return x == y
        case (.string(let x), .string(let y)): return x == y
        case (.bool(let x), .bool(let y)): return x == y
        case (.enumCase(let x), .enumCase(let y)): return x == y
        case (.enumCase(let x), .enumValue(_, let y, _)): return x == y
        case (.enumValue(_, let x, _), .enumCase(let y)): return x == y
        case (.enumValue(_, let x, let ax), .enumValue(_, let y, let ay)): return x == y && ax.count == ay.count
        case (.double(let x), .double(let y)): return x == y
        case (.int(let x), .double(let y)), (.double(let y), .int(let x)): return Double(x) == y
        default: return false
        }
    }

    private func evalMethod(_ baseExpr: Expr, _ name: String, _ argExprs: [Expr]) throws -> Value {
        // 枚举带关联值构造：Animal.cat(3)（被解析成方法调用形式）
        // 注意要在求值 base 之前检查——类型名本身不是变量
        if case .ident(let tname) = baseExpr, let cases = enums[tname] {
            guard cases.contains(where: { $0.0 == name }) else {
                throw PlayError(message: "«\(tname)» 没有 case «\(name)»")
            }
            let cargs = try argExprs.map { try eval($0) }
            return .enumValue(tname, name, cargs)
        }

        let base = try eval(baseExpr)
        let args = try argExprs.map { try eval($0) }

        // struct 实例方法：字段作为可见变量，self 指向实例
        if case .instance(let tn, let fs) = base, let sd = structs[tn], let fd = sd.methods[name] {
            guard args.count == fd.params.count else {
                throw PlayError(message: "方法 \(name) 需要 \(fd.params.count) 个参数，但传入了 \(args.count) 个")
            }
            let saved = lastValue
            defer { lastValue = saved }
            scopes.append(Scope(fs))
            scopes.append(Scope(Dictionary(uniqueKeysWithValues: zip(fd.params, args))))
            scopes[scopes.count - 1].vars["self"] = base
            defer { scopes.removeLast(); scopes.removeLast() }
            let f = try exec(fd.body)
            if case .ret(let v) = f { return v ?? .void }
            return lastValue
        }

        // 视图修饰符
        if case .view(let node) = base {
            switch name {
            case "font":
                node.font = try caseName(args.first)
                return .view(node)
            case "foregroundColor", "foregroundStyle", "tint":
                node.color = try caseName(args.first)
                return .view(node)
            case "background":
                node.bg = try caseName(args.first)
                return .view(node)
            case "padding":
                node.padding = true
                return .view(node)
            default: break
            }
        }

        switch (base, name) {
        case (.array(var a), "append"):
            guard args.count == 1 else { throw PlayError(message: "append 需要 1 个参数") }
            a.append(args[0])
            try storeBack(baseExpr, .array(a))
            return .void
        case (.array(let a), "reversed"): return .array(a.reversed())
        case (.array(let a), "sorted"): return .array(try sortValues(a))
        case (.array(let a), "map"):
            guard args.count == 1 else { throw PlayError(message: "map 需要 1 个闭包") }
            return .array(try a.map { try callValue(args[0], [$0]) })
        case (.array(let a), "filter"):
            guard args.count == 1 else { throw PlayError(message: "filter 需要 1 个闭包") }
            var out: [Value] = []
            for item in a { if try callValue(args[0], [item]).truthy() { out.append(item) } }
            return .array(out)
        case (.array(let a), "reduce"):
            guard args.count == 2 else { throw PlayError(message: "reduce 需要 2 个参数") }
            var acc = args[0]
            for item in a { acc = try callValue(args[1], [acc, item]) }
            return acc
        case (.array(let a), "joined"):
            return .string(a.map(stringify).joined(separator: args.first.map(stringify) ?? ""))
        case (.string(let s), "uppercased"): return .string(s.uppercased())
        case (.string(let s), "lowercased"): return .string(s.lowercased())
        case (.string(let s), "hasPrefix"): return .bool(s.hasPrefix(stringify(args[0])))
        case (.string(let s), "hasSuffix"): return .bool(s.hasSuffix(stringify(args[0])))
        default: throw PlayError(message: "«\(base.typeName)» 没有方法 «\(name)»")
        }
    }

    private func caseName(_ v: Value?) throws -> String {
        guard case .some(.enumCase(let s)) = v else {
            throw PlayError(message: "这里需要一个如 .red / .title 的枚举值")
        }
        return s
    }

    private func evalInline(_ src: String) throws -> Value {
        let toks = try Lexer(src).tokenize()
        return try eval(try Parser(toks).parseExpr())
    }

    private func storeBack(_ expr: Expr, _ v: Value) throws {
        if case .ident(let n) = expr { try setVar(n, v) }
        else { throw PlayError(message: "该方法只能用于简单变量") }
    }

    private func sortValues(_ a: [Value]) throws -> [Value] {
        if a.allSatisfy({ if case .int = $0 { return true }; return false }) {
            return a.map { if case .int(let n) = $0 { return n }; return 0 }.sorted().map { .int($0) }
        }
        if a.allSatisfy({ if case .string = $0 { return true }; return false }) {
            return a.map { if case .string(let s) = $0 { return s }; return "" }.sorted().map { .string($0) }
        }
        throw PlayError(message: "sorted 只支持整数或字符串数组")
    }

    private func evalBinary(_ op: String, _ lExpr: Expr, _ rExpr: Expr) throws -> Value {
        if op == "&&" {
            if !(try eval(lExpr).truthy()) { return .bool(false) }
            return .bool(try eval(rExpr).truthy())
        }
        if op == "||" {
            if try eval(lExpr).truthy() { return .bool(true) }
            return .bool(try eval(rExpr).truthy())
        }
        if op == "..<" || op == "..." {
            guard case .int(let a) = try eval(lExpr), case .int(let b) = try eval(rExpr) else {
                throw PlayError(message: "范围两端必须是 Int")
            }
            return .range(a, b, closed: op == "...")
        }
        let l = try eval(lExpr), r = try eval(rExpr)
        if case .int(let a) = l, case .int(let b) = r {
            switch op {
            case "+": return .int(a + b)
            case "-": return .int(a - b)
            case "*": return .int(a * b)
            case "/":
                if b == 0 { throw PlayError(message: "除以零") }
                return .int(a / b)
            case "%":
                if b == 0 { throw PlayError(message: "除以零") }
                return .int(a % b)
            case "==": return .bool(a == b)
            case "!=": return .bool(a != b)
            case "<": return .bool(a < b)
            case ">": return .bool(a > b)
            case "<=": return .bool(a <= b)
            case ">=": return .bool(a >= b)
            default: break
            }
        }
        let isNum = { (v: Value) in
            if case .int = v { return true }
            if case .double = v { return true }
            return false
        }
        if isNum(l) && isNum(r) {
            let a = doubleOf(l), b = doubleOf(r)
            switch op {
            case "+": return .double(a + b)
            case "-": return .double(a - b)
            case "*": return .double(a * b)
            case "/":
                if b == 0 { throw PlayError(message: "除以零") }
                return .double(a / b)
            case "==": return .bool(a == b)
            case "!=": return .bool(a != b)
            case "<": return .bool(a < b)
            case ">": return .bool(a > b)
            case "<=": return .bool(a <= b)
            case ">=": return .bool(a >= b)
            default: break
            }
        }
        if case .string(let a) = l, case .string(let b) = r {
            switch op {
            case "+": return .string(a + b)
            case "==": return .bool(a == b)
            case "!=": return .bool(a != b)
            case "<": return .bool(a < b)
            case ">": return .bool(a > b)
            case "<=": return .bool(a <= b)
            case ">=": return .bool(a >= b)
            default: break
            }
        }
        if case .array(let a) = l, case .array(let b) = r, op == "+" {
            return .array(a + b)
        }
        if op == "==" || op == "!=" {
            let same = try valuesEqual(l, r)
            return .bool(op == "==" ? same : !same)
        }
        throw PlayError(message: "运算符 \(op) 无法用于 \(l.typeName) 和 \(r.typeName)")
    }

    private func doubleOf(_ v: Value) -> Double {
        if case .int(let n) = v { return Double(n) }
        if case .double(let d) = v { return d }
        return 0
    }

    // MARK: 内置函数（含视图构造器）

    private func callBuiltin(_ name: String, _ args: [Value]) throws -> Value {
        switch name {
        case "print":
            output.append(ConsoleLine(text: args.map(stringify).joined(separator: " "), isError: false))
            return .void

        // ---- 视图 ----
        case "Text":
            guard args.count == 1 else { throw PlayError(message: "Text 需要 1 个参数") }
            return .view(ViewNode(kind: .text(stringify(args[0]))))
        case "VStack", "HStack", "ZStack", "Group":
            let axis = name == "HStack" ? "h" : (name == "ZStack" ? "z" : "v")
            var spacing: Int? = nil
            for v in args { if case .int(let n) = v { spacing = n } }
            guard let closure = args.last else { throw PlayError(message: "\(name) 需要一个闭包") }
            viewStacks.append([])
            defer { viewStacks.removeLast() }
            _ = try callValue(closure, [])
            let children = viewStacks[viewStacks.count - 1]
            let node = ViewNode(kind: .stack(axis: axis, children: children))
            node.spacing = spacing
            return .view(node)
        case "Circle", "Rectangle", "RoundedRectangle":
            let shapeName = name == "Circle" ? "circle" : "rect"
            return .view(ViewNode(kind: .shape(shapeName, nil)))
        case "Spacer":
            return .view(ViewNode(kind: .spacer))
        case "Divider":
            return .view(ViewNode(kind: .divider))
        case "Button":
            guard let label = args.first else { throw PlayError(message: "Button 需要 1 个文本参数") }
            guard let closure = args.last, case .closure = closure else {
                throw PlayError(message: "Button 需要一个动作闭包")
            }
            let id = nextButtonId
            nextButtonId += 1
            buttonHandlers[id] = closure
            return .view(ViewNode(kind: .button(stringify(label), id)))
        case "Color":
            return args.first ?? .void
        case "setLiveView":
            guard case .some(.view(let node)) = args.first else {
                throw PlayError(message: "setLiveView 需要 1 个视图参数")
            }
            lastLiveView = node
            liveViewHandler?(node)
            return .void

        // ---- 类型转换与数学 ----
        case "Int":
            switch args.first {
            case .int(let n): return .int(n)
            case .double(let d): return .int(Int(d))
            case .string(let s):
                guard let n = Int(s.trimmingCharacters(in: .whitespaces)) else {
                    throw PlayError(message: "无法把 «\(s)» 转成 Int")
                }
                return .int(n)
            default: throw PlayError(message: "Int() 需要 1 个参数")
            }
        case "Double":
            switch args.first {
            case .int(let n): return .double(Double(n))
            case .double(let d): return .double(d)
            case .string(let s):
                guard let d = Double(s.trimmingCharacters(in: .whitespaces)) else {
                    throw PlayError(message: "无法把 «\(s)» 转成 Double")
                }
                return .double(d)
            default: throw PlayError(message: "Double() 需要 1 个参数")
            }
        case "String":
            return .string(stringify(args.first ?? .void))
        case "sqrt":
            guard case .some(let v) = args.first else { throw PlayError(message: "sqrt() 需要 1 个参数") }
            return .double(sqrt(doubleOf(v)))
        case "abs":
            guard case .some(let v) = args.first else { throw PlayError(message: "abs() 需要 1 个参数") }
            if case .int(let n) = v { return .int(abs(n)) }
            return .double(abs(doubleOf(v)))
        case "max":
            guard args.count == 2 else { throw PlayError(message: "max() 需要 2 个参数") }
            return doubleOf(args[0]) >= doubleOf(args[1]) ? args[0] : args[1]
        case "min":
            guard args.count == 2 else { throw PlayError(message: "min() 需要 2 个参数") }
            return doubleOf(args[0]) <= doubleOf(args[1]) ? args[0] : args[1]
        case "count":
            switch args.first {
            case .array(let a): return .int(a.count)
            case .string(let s): return .int(s.count)
            default: throw PlayError(message: "count() 需要数组或字符串")
            }
        default:
            throw PlayError(message: "未知函数：\(name)")
        }
    }

    func stringify(_ v: Value) -> String {
        switch v {
        case .int(let n): return String(n)
        case .double(let d):
            if d == d.rounded() && abs(d) < 1e15 { return String(Int(d)) }
            return String(d)
        case .string(let s): return s
        case .bool(let b): return b ? "true" : "false"
        case .array(let a): return "[" + a.map(stringify).joined(separator: ", ") + "]"
        case .range(let a, let b, let closed): return closed ? "\(a)...\(b)" : "\(a)..<\(b)"
        case .function, .closure: return "(Function)"
        case .view: return "(View)"
        case .enumCase(let s): return ".\(s)"
        case .instance(let n, let fs):
            let parts = fs.map { "\($0.key): \(stringify($0.value))" }.sorted().joined(separator: ", ")
            return "\(n)(\(parts))"
        case .enumValue(let t, let c, let assoc):
            let prefix = (t?.isEmpty == false) ? "\(t!)." : "."
            if assoc.isEmpty { return prefix + c }
            return prefix + c + "(" + assoc.map(stringify).joined(separator: ", ") + ")"
        case .void: return "()"
        }
    }
}
