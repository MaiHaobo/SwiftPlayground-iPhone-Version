import Foundation

// MARK: - 内置示例代码

extension PlaygroundDocument {
    var defaultCode: String {
        switch id {
        case "hello":
            return """
            // 欢迎来到 Swift 游乐场！
            // 点击右上角的 ▶ 运行这段代码
            // 修改代码后会在「自动运行」模式下实时刷新

            print("你好，iPhone！")

            var 名字 = "游乐场"
            print("欢迎来到 \\(名字)")

            var count = 1024
            print("你有 \\(count) 条新消息")
            """
        case "loops":
            return """
            // 用循环打印一个星号金字塔
            for i in 1...9 {
                var line = ""
                for _ in 1...i {
                    line += "*"
                }
                print(line)
            }

            // 用 while 找出平方小于 200 的偶数
            var n = 1
            while n * n < 200 {
                if n % 2 == 0 {
                    print("\\(n) 的平方是 \\(n * n)（偶数）")
                }
                n += 1
            }
            """
        case "funcs":
            return """
            // 定义你自己的函数
            func greet(name) {
                return "你好, " + name + "!"
            }

            print(greet(name: "小明"))
            print(greet(name: "Swift 学习者"))

            func square(n) {
                return n * n
            }

            var total = 0
            for i in 1...100 {
                total += square(i)
            }
            print("1 到 100 的平方和是 \\(total)")
            """
        case "arrays":
            return """
            // 数组操作
            var fruits = ["苹果", "香蕉", "橘子"]
            fruits.append("葡萄")
            print("一共 \\(fruits.count) 种水果：\\(fruits)")

            for fruit in fruits {
                if fruit == "葡萄" {
                    print("找到我最爱的 \\(fruit)！")
                } else {
                    print("普通水果：\\(fruit)")
                }
            }

            var scores = [88, 42, 95, 67]
            print("排序前：\\(scores)")
            print("排序后：\\(scores.sorted())")
            print("最高分：\\(scores.sorted().last)")
            """
        case "tests":
            return """
            // 语法测试场：打开即自动运行
            // 每行 ✅ = 通过，❌ = 有问题
            // 想测新语法就把检查加在最后

            var passed = 0
            var failed = 0

            func ok(_ cond: Bool, _ name: String) {
                if cond {
                    passed += 1
                    print("✅ " + name)
                } else {
                    failed += 1
                    print("❌ " + name)
                }
            }

            // ---- 基础运算 ----
            ok(1 + 2 * 3 == 7, "运算优先级")
            ok(10 % 3 == 1, "取余")
            ok(7 / 2 == 3, "整数除法")

            // ---- 变量与字符串 ----
            var greeting = "你好"
            ok(greeting + "，世界" == "你好，世界", "字符串拼接")
            var name = "Swift"
            ok("Hi \\(name)!" == "Hi Swift!", "字符串插值")
            ok("Hello".uppercased() == "HELLO", "uppercased")
            ok("HelloWorld".hasPrefix("Hello"), "hasPrefix")

            // ---- 数组与闭包 ----
            var nums = [3, 1, 2]
            ok(nums.count == 3, "count")
            ok(nums.sorted()[0] == 1, "sorted + 下标")
            ok(nums[1] == 1, "下标读取")
            ok(nums.map { $0 * 2 }[2] == 4, "map")
            ok(nums.filter { $0 > 1 }.count == 2, "filter")
            ok(nums.reduce(0) { $0 + $1 } == 6, "reduce")
            nums.append(9)
            ok(nums.last == 9, "append + last")

            var double = { $0 * 2 }
            ok(double(21) == 42, "闭包调用")

            // ---- 循环与控制流 ----
            var sum = 0
            for i in 1...10 { sum += i }
            ok(sum == 55, "for-in 范围")
            var n = 1
            while n * n < 50 { n += 1 }
            ok(n == 8, "while")
            if sum > 50 && !(2 > 3) { ok(true, "if + 逻辑") } else { ok(false, "if + 逻辑") }

            // ---- 函数与递归 ----
            func fact(_ m: Int) -> Int {
                if m <= 1 { return 1 }
                return m * fact(m - 1)
            }
            ok(fact(5) == 120, "递归")

            // ---- struct ----
            struct Item {
                var title: String
                var price: Int = 0
                func desc() { print("「\\(title)」\\(price)元") }
            }
            var book = Item(title: "Swift书", price: 42)
            book.desc()
            ok(book.price == 42, "struct 属性")
            book.price = 50
            ok(book.price == 50, "struct 属性赋值")

            // ---- enum + switch ----
            enum Shape2 {
                case circle, rect(Int)
            }
            var s2 = Shape2.rect(4)
            switch s2 {
            case .circle:
                ok(false, "switch 匹配")
            case .rect(let side):
                ok(side == 4, "switch 关联值绑定")
            }

            print("——————")
            print("通过 \\(passed) 项，失败 \\(failed) 项")
            """
        case "models":
            return """
            // 批次1：struct / enum / switch / 下标
            struct Item {
                var name: String
                var price: Int
                func info() { print("\\(name) 卖 \\(price) 元") }
            }

            var cart = [Item(name: "苹果", price: 5), Item(name: "书", price: 30)]
            cart[0].info()
            cart[1].info()

            var total = 0
            for it in cart { total += it.price }
            print("合计: \\(total)")

            enum Level {
                case low, mid, high(Int)
            }

            var lv = Level.high(9)
            switch lv {
            case .low: print("低级")
            case .mid: print("中级")
            case .high(let v): print("高级! 值是 \\(v)")
            }

            cart[0].name = "大苹果"
            print(cart[0].name)
            """
        case "ui":
            return """
            // Live View 实时预览！
            // 写 SwiftUI 风格的界面，点上方「预览」查看效果
            // 点预览里的按钮可以交互

            import SwiftUI

            var count = 0

            func update() {
                setLiveView(VStack(spacing: 16) {
                    Text("计数器演示")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("当前次数：\\(count)")
                        .font(.headline)
                    Button("点我 +1") {
                        count += 1
                        update()
                    }
                    Divider()
                    HStack {
                        Circle().foregroundColor(.orange)
                        RoundedRectangle().foregroundColor(.green)
                    }
                    Text("学 SwiftUI，就在 iPhone 上")
                        .font(.caption)
                        .foregroundColor(.purple)
                })
            }

            update()
            """
        default:
            return """
            // 空白游乐场 — 随便写点什么吧！

            print("Hello, Swift!")

            """
        }
    }
}
