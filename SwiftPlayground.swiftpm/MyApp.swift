import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// 入口视图：仅允许在 iPhone 上使用，其他设备显示提示
struct RootView: View {
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            PlaygroundsHome()
                .preferredColorScheme(.dark)
        } else {
            UnsupportedDeviceView()
        }
    }
}

/// iPad 等其他设备上显示的提示页
struct UnsupportedDeviceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.gen3")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("仅支持 iPhone")
                .font(.title2.bold())
            Text("本 App 是专为 iPhone 打造的 Swift 游乐场，请在 iPhone 上打开。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
