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
        default:
            return """
            // 空白游乐场 — 随便写点什么吧！

            print("Hello, Swift!")

            """
        }
    }
}
