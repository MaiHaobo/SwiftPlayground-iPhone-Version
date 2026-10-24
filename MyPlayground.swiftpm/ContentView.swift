import SwiftUI

/// iPhone 主界面：一个简单的 SwiftUI 演示应用
struct ContentView: View {
    @State private var count = 0
    @State private var newItem = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("点击计数")
                        Spacer()
                        Text("\(count)")
                            .font(.title3.bold())
                            .monospacedDigit()
                            .foregroundStyle(.tint)
                    }
                    Button {
                        count += 1
                    } label: {
                        Label("点我加一", systemImage: "hand.tap.fill")
                    }
                    Button(role: .destructive) {
                        count = 0
                    } label: {
                        Label("归零", systemImage: "arrow.counterclockwise")
                    }
                }

                Section {
                    HStack {
                        TextField("输入待办事项", text: $newItem)
                            .onSubmit(addItem)
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newItem.isEmpty)
                    }
                    ForEach(TodoStore.items, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                    }
                } header: {
                    Text("待办清单")
                }
            }
            .navigationTitle("SwiftPlayground")
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        TodoStore.items.append(trimmed)
        newItem = ""
    }
}

enum TodoStore {
    static var items: [String] = []
}
