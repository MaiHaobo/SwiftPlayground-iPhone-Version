import SwiftUI

// MARK: - 全局会话：跨 Tab 共享的实时预览状态

final class SessionStore: ObservableObject {
    @Published var title: String = ""
    @Published var liveNode: ViewNode?
    @Published var interpreter: Interpreter?
}
