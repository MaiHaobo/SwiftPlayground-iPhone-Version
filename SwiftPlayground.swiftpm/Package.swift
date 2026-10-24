// swift-tools-version:5.8
// SwiftPlayground — 专为 iPhone 打造的 Swift 游乐场

import PackageDescription

let package = Package(
    name: "SwiftPlayground",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "SwiftPlayground",
            targets: ["AppModule"],
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .pencilAndPaperCircle),
            supportedDeviceFamilies: [
                .pad, // 仍需包含 pad 以便包能被 Swift Playgrounds 打包，运行时由代码强制限定 iPhone
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeLeft,
                .landscapeRight
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
