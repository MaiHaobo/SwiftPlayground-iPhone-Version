import SwiftUI

@main
struct SwiftPlaygroundApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var docs = DocsStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                PlaygroundsHome()
                    .environmentObject(session)
                    .environmentObject(docs)
                    .tabItem {
                        Label("首页", systemImage: "square.grid.2x2.fill")
                    }
                NewDocTab()
                    .environmentObject(session)
                    .environmentObject(docs)
                    .tabItem {
                        Label("新建", systemImage: "plus.circle.fill")
                    }
                SettingsTab()
                    .environmentObject(session)
                    .environmentObject(docs)
                    .tabItem {
                        Label("设置", systemImage: "gearshape.fill")
                    }
            }
        }
    }
}
