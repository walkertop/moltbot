import SwiftUI

// MARK: - Task Card View

struct TaskCardView: View {
    @Environment(AppModel.self) private var appModel
    let task: TodoTask

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            checkboxView

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(task.isCompleted ? TodoTheme.textTertiary : TodoTheme.textPrimary)
                    .strikethrough(task.isCompleted, color: TodoTheme.textTertiary)

                // Meta info
                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        metaTag(
                            icon: "calendar",
                            text: dueDate.formatted(.dateTime.month().day())
                        )
                    }

                    if task.reminderDate != nil {
                        metaTag(icon: "bell.fill", text: "Reminder")
                    }

                    if task.isAIGenerated {
                        aiTag
                    }

                    if !task.subtasks.isEmpty {
                        subtasksTag
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Checkbox

    private var checkboxView: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                appModel.toggleTaskCompletion(task)
            }
        } label: {
            ZStack {
                if task.isCompleted {
                    Circle()
                        .fill(TodoTheme.accentGreen)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meta Tags

    private func metaTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12))
        }
        .foregroundStyle(TodoTheme.textTertiary)
    }

    private var aiTag: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
            Text("AI")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(TodoTheme.accentPurple)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(TodoTheme.accentPurple.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var subtasksTag: some View {
        HStack(spacing: 4) {
            Image(systemName: "list.bullet")
                .font(.system(size: 10))
            Text("\(task.completedSubtasksCount)/\(task.subtasks.count)")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(TodoTheme.textTertiary)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TodoTheme.backgroundGradient
            .ignoresSafeArea()

        VStack(spacing: 12) {
            TaskCardView(task: TodoTask.samples[0])
            TaskCardView(task: TodoTask.samples[1])
            TaskCardView(task: TodoTask.sampleWithSubtasks)
        }
        .padding()
    }
    .environment(AppModel())
}
