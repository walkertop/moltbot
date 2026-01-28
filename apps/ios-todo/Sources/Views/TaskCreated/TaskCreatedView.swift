import SwiftUI

// MARK: - Task Created View

struct TaskCreatedView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let task: TodoTask

    @State private var checkmarkScale: CGFloat = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Success icon
                successIconView

                // Success text
                successTextView

                // Task preview card
                taskPreviewCard

                // Action buttons
                actionButtonsView

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Success Icon

    private var successIconView: some View {
        ZStack {
            Circle()
                .fill(TodoTheme.successGradient)
                .frame(width: 120, height: 120)
                .shadow(color: TodoTheme.accentGreen.opacity(0.5), radius: 40, y: 12)

            Image(systemName: "checkmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(checkmarkScale)
        }
    }

    // MARK: - Success Text

    private var successTextView: some View {
        VStack(spacing: 8) {
            Text("Task Created!")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("Your task has been added successfully")
                .font(.system(size: 16))
                .foregroundStyle(TodoTheme.textSecondary)
        }
        .opacity(contentOpacity)
    }

    // MARK: - Task Preview Card

    private var taskPreviewCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(TodoTheme.accentPurple.opacity(0.3))
                        .frame(width: 48, height: 48)

                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 20))
                        .foregroundStyle(TodoTheme.accentPurple)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if task.isAIGenerated {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("AI Generated")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(TodoTheme.accentPurple)
                    }
                }
            }

            // Details
            VStack(spacing: 16) {
                if let dueDate = task.dueDate {
                    detailRow(icon: "calendar", label: "Due Date", value: dueDate.formatted(.dateTime.month().day().hour().minute()))
                }

                if let reminderDate = task.reminderDate {
                    detailRow(icon: "bell.fill", label: "Reminder", value: reminderDate.formatted(.dateTime.hour().minute()))
                }

                detailRow(icon: "flag.fill", label: "Priority", value: task.priority.label, valueColor: Color(hex: task.priority.color))

                if !task.subtasks.isEmpty {
                    detailRow(icon: "list.bullet", label: "Subtasks", value: "\(task.subtasks.count) items")
                }
            }
        }
        .padding(24)
        .glassCard(cornerRadius: 28)
        .frame(maxWidth: 380)
        .opacity(contentOpacity)
    }

    private func detailRow(icon: String, label: String, value: String, valueColor: Color = .white) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(TodoTheme.textTertiary)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(TodoTheme.textTertiary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Edit button
            Button {
                // TODO: Navigate to edit
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18))
                    Text("Edit")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }

            // Done button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .accentButton(cornerRadius: 16)
            }
        }
        .opacity(contentOpacity)
    }

    // MARK: - Animations

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            checkmarkScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            contentOpacity = 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    TaskCreatedView(task: TodoTask.sampleWithSubtasks)
        .environment(AppModel())
}
