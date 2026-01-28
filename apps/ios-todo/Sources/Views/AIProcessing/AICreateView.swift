import SwiftUI

// MARK: - AI Create View (AI Split)

struct AICreateView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var taskInput = ""
    @State private var enableAISplit = true

    var body: some View {
        ZStack {
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Task input card
                        taskInputCard

                        // AI Smart Split card
                        aiSplitCard

                        // Features list
                        featuresListView
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }

                // Bottom area
                bottomAreaView
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

            Text("Create Task")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    // MARK: - Task Input Card

    private var taskInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What do you want to accomplish?")
                .font(.system(size: 14))
                .foregroundStyle(TodoTheme.textSecondary)

            TextEditor(text: $taskInput)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(16)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    // MARK: - AI Split Card

    private var aiSplitCard: some View {
        HStack(spacing: 14) {
            // AI icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(TodoTheme.accentGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Smart Split")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Automatically break down complex tasks")
                    .font(.system(size: 13))
                    .foregroundStyle(TodoTheme.textTertiary)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $enableAISplit)
                .labelsHidden()
                .tint(TodoTheme.accentPurple)
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [TodoTheme.accentPurple.opacity(0.8), TodoTheme.accentPink.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }

    // MARK: - Features List

    private var featuresListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(text: "Automatic subtask generation")
            featureRow(text: "Visual progress tracking")
            featureRow(text: "Smart time estimation")
        }
    }

    private func featureRow(text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TodoTheme.accentGreen.opacity(0.2))
                    .frame(width: 22, height: 22)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(TodoTheme.accentGreen)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(TodoTheme.textSecondary)
        }
    }

    // MARK: - Bottom Area

    private var bottomAreaView: some View {
        VStack(spacing: 16) {
            Button {
                createTask()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                    Text("Create with AI")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(TodoTheme.accentGradientVertical)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: TodoTheme.accentPurple.opacity(0.4), radius: 20, y: 8)
            }
            .disabled(taskInput.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(taskInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 40)
    }

    private func createTask() {
        guard !taskInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        dismiss()
        Task {
            await appModel.processTaskWithAI(input: taskInput)
        }
    }
}

// MARK: - Preview

#Preview {
    AICreateView()
        .environment(AppModel())
}
