// swift-tools-version:5.8
// Swift Playground App — 仅支持在 iPhone 上运行

import PackageDescription

let package = Package(
    name: "MyPlayground",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "MyPlayground",
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
