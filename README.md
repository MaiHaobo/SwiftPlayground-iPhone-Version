# SwiftPlayground-iPhone-Version

一个**专为 iPhone 打造**的 Swift Playgrounds 风格 App —— 官方 Swift Playgrounds 只支持 iPad/Mac，本项目让 iPhone 用户也能拥有「写代码 + 运行代码」的游乐场体验。

> 标准工程，用 **Xcode 打开 `SwiftPlayground.xcodeproj`** 即可；仓库自带 GitHub Actions 工作流，每次推送自动编译出 IPA。

## ✨ 功能

- 📝 **代码编辑器**：深色主题、Swift 语法高亮（关键字 / 字符串 / 数字 / 注释）
- ▶️ **一键运行**：内置纯 Swift 实现的 **Swift 子集解释器**，无需编译器，直接执行代码
- 🖥️ **实时控制台**：`print` 输出实时显示，错误红字提示
- ⚡ **自动运行**：边写边跑，和官方 Playground 的实时体验一致
- 📚 **内置示例游乐场**：入门代码、循环与图形、函数与数学、数组与条件、空白游乐场
- 💾 **自动保存**：代码自动存到本地
- 📱 **仅 iPhone**：工程里 `TARGETED_DEVICE_FAMILY = 1`，且运行时检测设备，iPad 打开会显示提示页

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

## 📂 项目结构

```
SwiftPlayground.xcodeproj/         # Xcode 工程（双击打开）
SwiftPlayground/
├── App.swift                      # App 入口 + 设备检测（仅 iPhone 放行）
├── PlaygroundsHome.swift          # 首页（游乐场卡片列表）
├── PlaygroundEditor.swift         # 代码编辑器 + 控制台 + 语法高亮
├── Interpreter.swift              # Swift 子集解释器（词法 → 语法 → 求值）
└── Samples.swift                  # 内置示例代码
.github/workflows/build-ipa.yml    # GitHub Actions：自动编译 IPA
```

## 🏗️ 自动编译 IPA

仓库已配置 GitHub Actions（`.github/workflows/build-ipa.yml`）：

1. 每次推送到 `main` 分支（或手动点击 Run workflow）会触发编译；
2. 在仓库 **Actions** 页进入对应运行，在底部 **Artifacts** 下载 `SwiftPlayground-iPhone-unsigned-ipa`；
3. 得到的是**未签名 IPA**，需要自签后安装到 iPhone，常见方式：
   - **AltStore / SideStore**（免费 Apple ID，7 天有效）
   - **Sideloadly**（电脑上用 Apple ID 签名安装）
   - **爱思助手 / 巨魔 TrollStore** 等
   - 或在 Xcode 中打开工程，插上 iPhone 直接 ⌘R 运行（推荐，最简单）

## ⚠️ 说明

内置解释器是 Swift 的教学子集，不支持结构体/类定义、闭包、可选值等高级特性，适合学习编程基础语法与算法思维。
