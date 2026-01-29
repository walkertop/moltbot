import SwiftUI

// MARK: - Task List View (Main Screen)

struct TaskListView: View {
    @Environment(AppModel.self) private var appModel
    @State private var inputText = ""
    @State private var showVoiceInput = false

    var body: some View {
        ZStack {
            // Background gradient
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Task list
                taskListSection

                // Bottom input bar
                inputBarSection
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showVoiceInput) {
            VoiceInputView()
        }
        .sheet(isPresented: .init(
            get: { appModel.showAIProcessing },
            set: { appModel.showAIProcessing = $0 }
        )) {
            AIProcessingView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: .init(
            get: { appModel.showTaskCreated },
            set: { appModel.showTaskCreated = $0 }
        )) {
            if let task = appModel.currentTask {
                TaskCreatedView(task: task)
            }
        }
        .task {
            await appModel.requestNotificationPermission()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Tasks")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(TodoTheme.textPrimary)

                Text(Date(), format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 17))
                    .foregroundStyle(TodoTheme.textTertiary)
            }

            Spacer()

            // Terminal button
            Button {
                appModel.showTerminal = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "terminal")
                        .font(.system(size: 18))
                        .foregroundStyle(TodoTheme.textSecondary)
                }
            }

            // AI Chat button
            Button {
                appModel.showAIChatInput = true
            } label: {
                ZStack {
                    Circle()
                        .fill(TodoTheme.accentGradient)
                        .frame(width: 44, height: 44)
                        .shadow(color: TodoTheme.accentPurple.opacity(0.4), radius: 12, y: 4)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Task List

    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(appModel.tasks) { task in
                    TaskCardView(task: task)
                        .onTapGesture {
                            appModel.navigationPath.append(.subtasks(task))
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Input Bar

    private var inputBarSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Text input field
                TextField("Add a new task...", text: $inputText)
                    .font(.system(size: 16))
                    .foregroundStyle(TodoTheme.textPrimary)
                    .padding(.leading, 16)
                    .onSubmit {
                        submitTask()
                    }

                // Voice input button
                Button {
                    showVoiceInput = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(TodoTheme.accentGradient)
                        .clipShape(Circle())
                        .shadow(color: TodoTheme.accentPurple.opacity(0.4), radius: 16, y: 4)
                }
            }
            .frame(height: 56)
            .background(.ultraThinMaterial.opacity(0.3))
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    private func submitTask() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            await appModel.processTaskWithAI(input: inputText)
            inputText = ""
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TaskListView()
    }
    .environment(AppModel())
}
