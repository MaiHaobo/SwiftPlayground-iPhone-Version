# SwiftPlayground-iPhone-Version

一个仅支持在 **iPhone** 上运行的 Swift Playground App（`.swiftpm` 格式）。

## 如何在 iPhone 上运行

1. 在 iPhone 上安装 Apple 官方 **[Swift Playgrounds](https://apps.apple.com/app/swift-playgrounds/id908519492)** App（App Store 免费下载）。
2. 打开本仓库，下载 `MyPlayground.swiftpm` 文件（在 GitHub 网页端进入该文件夹，逐个下载不方便时，可下载整个仓库 ZIP 后用「文件」App 解压）。
   - 最简单方式：把 `.swiftpm` 文件夹通过 iCloud Drive / AirDrop / 「文件」App 传到 iPhone。
3. 在「文件」App 中**轻点** `MyPlayground.swiftpm`，它会自动在 Swift Playgrounds 中打开。
4. 点击 ▶️ 即可运行。

> 也可以在 Mac 上用 Xcode 15 或更高版本直接打开 `.swiftpm` 进行开发，再同步到 iPhone 运行。

## 仅支持 iPhone 的说明

本项目做了双重限制：

- **界面限制**：App 启动时检测设备类型，只有在 iPhone 上才显示主界面，iPad 等设备会看到「仅支持 iPhone」提示页。
- **工程配置**：`Package.swift` 中声明了支持的设备类型，并以竖屏为主。

## 项目结构

```
MyPlayground.swiftpm/
├── Package.swift      # Swift Playground App 包描述文件
├── MyApp.swift        # App 入口 + 设备类型检测（仅 iPhone 放行）
└── ContentView.swift  # 主界面（计数器 + 待办清单演示）
```

## 环境要求

- iPhone（iOS 16.0 或更高）
- Swift Playgrounds 4.0 或更高版本
