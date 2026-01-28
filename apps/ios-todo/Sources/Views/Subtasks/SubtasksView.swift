import SwiftUI

// MARK: - Subtasks View

struct SubtasksView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let task: TodoTask

    var body: some View {
        ZStack {
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 16) {
                        // Main task card
                        mainTaskCard

                        // Subtasks section
                        subtasksSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Task Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                // Edit action
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    // MARK: - Main Task Card

    private var mainTaskCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with AI tag and status
            HStack {
                if task.isAIGenerated {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("AI")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(TodoTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                Text("In Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TodoTheme.accentYellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(TodoTheme.accentOrange.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Title
            Text(task.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(6)

            // Progress section
            VStack(spacing: 10) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 13))
                        .foregroundStyle(TodoTheme.textSecondary)

                    Spacer()

                    Text("\(task.completedSubtasksCount)/\(task.subtasks.count) completed")
                        .font(.system(size: 13))
                        .foregroundStyle(TodoTheme.textSecondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [TodoTheme.accentPurple, TodoTheme.accentGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * task.progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    // MARK: - Subtasks Section

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("Subtasks")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    // Add subtask
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 16))
                        Text("Add")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(TodoTheme.accentPurple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }

            // Subtask items
            ForEach(task.subtasks) { subtask in
                subtaskRow(subtask)
            }
        }
    }

    private func subtaskRow(_ subtask: SubTask) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Checkbox
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    subtask.isCompleted.toggle()
                    subtask.completedAt = subtask.isCompleted ? Date() : nil
                }
            } label: {
                ZStack {
                    if subtask.isCompleted {
                        Circle()
                            .fill(TodoTheme.accentGreen)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                    }
                }
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(subtask.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(subtask.isCompleted ? TodoTheme.textTertiary : .white)
                    .strikethrough(subtask.isCompleted, color: TodoTheme.textTertiary)

                HStack(spacing: 8) {
                    if let minutes = subtask.estimatedMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(minutes) min")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(TodoTheme.textTertiary)
                    }

                    if subtask.isCompleted, let completedAt = subtask.completedAt {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 11))
                            Text(completedAt.formatted(.dateTime.month().day()))
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(TodoTheme.accentGreen)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(subtask.isCompleted ? TodoTheme.completedBackground : TodoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(subtask.isCompleted ? TodoTheme.completedBorder : TodoTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubtasksView(task: TodoTask.sampleWithSubtasks)
    }
    .environment(AppModel())
}
