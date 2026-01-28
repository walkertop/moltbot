import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            TaskListView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
