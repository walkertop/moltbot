import SwiftUI

// MARK: - AI Chat Complete View

struct AIChatCompleteView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let userMessage: String
    let aiResponse: String

    @State private var showCompleteBadge = false
    @State private var ringAnimation = false
    @State private var showCopiedToast = false

    var body: some View {
        ZStack {
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Chat content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // User message bubble
                        userMessageBubble

                        // AI response with complete badge
                        aiCompleteResponseArea

                        // Animated ring decoration
                        completionRingView
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }

                // Bottom action buttons
                actionButtonsView
            }

            // Copied toast
            if showCopiedToast {
                copiedToastView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showCompleteBadge = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                ringAnimation = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                appModel.dismissAIChat()
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

            Text("AI Chat")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    // MARK: - User Message Bubble

    private var userMessageBubble: some View {
        HStack {
            Spacer()

            Text(userMessage)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            TodoTheme.accentPurple,
                            TodoTheme.accentPink,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 20
                    )
                )
        }
    }

    // MARK: - AI Complete Response

    private var aiCompleteResponseArea: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                TodoTheme.accentPurple.opacity(0.8),
                                TodoTheme.accentPink.opacity(0.8),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            // Response content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("AI Assistant")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TodoTheme.textTertiary)

                    Spacer()

                    // Complete badge
                    if showCompleteBadge {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Response Complete")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(TodoTheme.accentGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(TodoTheme.accentGreen.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Response text
                Text(aiResponse)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Completion Ring

    private var completionRingView: some View {
        HStack {
            Spacer()

            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                TodoTheme.accentGreen.opacity(0.3),
                                TodoTheme.accentPurple.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(ringAnimation ? 1.1 : 1.0)
                    .opacity(ringAnimation ? 0.6 : 1.0)

                // Inner ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                TodoTheme.accentGreen.opacity(0.5),
                                TodoTheme.accentPurple.opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(ringAnimation ? 1.05 : 1.0)

                // Center check
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(TodoTheme.accentGreen)
            }

            Spacer()
        }
        .padding(.vertical, 20)
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Copy button
            Button {
                copyToClipboard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 18))
                    Text("Copy")
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

            // Regenerate button
            Button {
                regenerateResponse()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18))
                    Text("Regenerate")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(TodoTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: TodoTheme.accentPurple.opacity(0.4), radius: 16, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Copied Toast

    private var copiedToastView: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(TodoTheme.accentGreen)

                Text("Copied to clipboard")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Spacer()
        }
        .padding(.top, 100)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = aiResponse

        withAnimation(.spring(response: 0.3)) {
            showCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3)) {
                showCopiedToast = false
            }
        }
    }

    private func regenerateResponse() {
        Task {
            await appModel.regenerateAIChatResponse()
        }
    }
}

// MARK: - Preview

#Preview {
    AIChatCompleteView(
        userMessage: "Help me plan my day",
        aiResponse: """
        Based on your request, I'll help you break down this task into manageable steps.

        Here's my analysis:

        1. **Understanding the Requirements**
           First, let's identify the core objectives and constraints.

        2. **Breaking Down into Subtasks**
           I've identified several key components that need attention.

        3. **Prioritization & Timeline**
           Each subtask has been assigned a priority level and estimated completion time.

        4. **Action Plan**
           Here's a structured approach to accomplish your goal efficiently.
        """
    )
    .environment(AppModel())
}
