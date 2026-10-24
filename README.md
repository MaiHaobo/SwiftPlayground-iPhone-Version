# SwiftPlayground-iPhone-Version

一个**专为 iPhone 打造**的 Swift Playgrounds 风格 App —— 官方的 Swift Playgrounds 主要面向 iPad/Mac，本项目把「写代码 + 运行代码」的游乐场体验完整搬到 iPhone 上，且**仅支持 iPhone** 运行。

## ✨ 功能

- 📝 **代码编辑器**：深色主题、Swift 语法高亮（关键字 / 字符串 / 数字 / 注释）
- ▶️ **一键运行**：内置纯 Swift 实现的 **Swift 子集解释器**，无需编译器，在 iPhone 上直接执行代码
- 🖥️ **实时控制台**：`print` 输出实时显示，支持错误定位提示
- ⚡ **自动运行**：边写边跑，和官方 Playground 的实时体验一致
- 📚 **内置示例游乐场**：入门代码、循环与图形、函数与数学、数组与条件、空白游乐场
- 💾 **自动保存**：代码自动存到本地，随时接着写

## 🧩 解释器支持的语法子集

| 类别 | 支持 |
|------|------|
| 变量 | `var` / `let`（含中文标识符） |
| 类型 | `Int`、`Double`、`String`、`Bool`、数组、范围 |
| 运算 | `+ - * / %`、比较、`&&` `\|\|` `!`、`+=` 等复合赋值 |
| 流程 | `if / else`、`for-in`、`while`、`break` / `continue` |
| 函数 | 自定义函数、参数、`return` |
| 字符串 | 插值 `\(表达式)`、`count`、`uppercased()` 等 |
| 数组 | 字面量、`append`、`count`、`sorted`、`reversed` |
| 内置函数 | `print`、`Int`、`Double`、`String`、`sqrt`、`abs`、`max`、`min` |

## 📱 如何在 iPhone 上运行

1. 在 iPhone 上安装 Apple 官方 **[Swift Playgrounds](https://apps.apple.com/app/swift-playgrounds/id908519492)** App（免费）。
2. 把本仓库中的 `SwiftPlayground.swiftpm` 文件夹通过 iCloud Drive / AirDrop / 「文件」App 传到 iPhone（可下载仓库 ZIP 后解压）。
3. 在「文件」App 中**轻点** `SwiftPlayground.swiftpm`，它会自动在 Swift Playgrounds 中打开。
4. 点击 ▶️ 运行，即可开始写代码。

> 也可以在 Mac 上用 Xcode 15+ 打开 `.swiftpm` 开发后同步到 iPhone。

## 🔒 仅支持 iPhone

- App 启动时检测设备类型，只有 **iPhone** 显示游乐场界面，iPad 等设备显示「仅支持 iPhone」提示页。

## 📂 项目结构

```
SwiftPlayground.swiftpm/
├── Package.swift            # Swift Playground App 包描述（iOS 16+）
├── MyApp.swift              # App 入口 + 设备检测（仅 iPhone 放行）
├── PlaygroundsHome.swift    # 首页（游乐场卡片列表）
├── PlaygroundEditor.swift   # 代码编辑器 + 控制台 + 语法高亮
├── Interpreter.swift        # Swift 子集解释器（词法 → 语法 → 求值）
└── Samples.swift            # 内置示例代码
```

## ⚠️ 说明

内置解释器是 Swift 的一个教学子集，并非完整 Swift 编译器；不支持结构体/类定义、闭包、可选值等高级特性。适合学习编程基础语法与算法思维。
