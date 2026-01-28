import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var model = appModel

        NavigationStack(path: $model.navigationPath) {
            TaskListView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case let .taskDetail(task):
                        SubtasksView(task: task)
                    case let .subtasks(task):
                        SubtasksView(task: task)
                    }
                }
        }
        .preferredColorScheme(.dark)
        // AI Chat Input sheet
        .fullScreenCover(isPresented: $model.showAIChatInput) {
            AIChatInputView()
        }
        // AI Chat Processing sheet
        .fullScreenCover(isPresented: $model.showAIChatProcessing) {
            AIChatProcessingView(userMessage: appModel.aiChatUserMessage)
        }
        // AI Chat Complete sheet
        .fullScreenCover(isPresented: $model.showAIChatComplete) {
            AIChatCompleteView(
                userMessage: appModel.aiChatUserMessage,
                aiResponse: appModel.aiChatResponse
            )
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
