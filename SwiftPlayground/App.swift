import SwiftUI

@main
struct SwiftPlaygroundApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                PlaygroundsHome()
                    .environmentObject(session)
                    .tabItem {
                        Label("游乐场", systemImage: "square.grid.2x2.fill")
                    }
                PreviewTab()
                    .environmentObject(session)
                    .tabItem {
                        Label("预览", systemImage: "eye")
                    }
                AboutTab()
                    .tabItem {
                        Label("关于", systemImage: "info.circle")
                    }
            }
        }
    }
}
