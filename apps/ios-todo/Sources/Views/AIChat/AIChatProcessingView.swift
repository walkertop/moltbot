import SwiftUI

// MARK: - AI Chat Processing View

struct AIChatProcessingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let userMessage: String

    @State private var displayedText = ""
    @State private var showCursor = true
    @State private var dotAnimation: Int = 0

    // Simulated AI response text
    private let fullResponse = """
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

                        // AI response area
                        aiResponseArea
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }

                // Bottom thinking indicator
                thinkingIndicatorView
            }
        }
        .onAppear {
            startTypingAnimation()
            startCursorAnimation()
            startDotAnimation()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                appModel.cancelAIChatProcessing()
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
                .clipShape(RoundedRectangle(cornerRadius: 20))
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

    // MARK: - AI Response Area

    private var aiResponseArea: some View {
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

            // Response text with cursor
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Assistant")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TodoTheme.textTertiary)

                HStack(alignment: .bottom, spacing: 2) {
                    Text(displayedText)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .lineSpacing(6)

                    // Blinking cursor
                    if displayedText.count < fullResponse.count {
                        Rectangle()
                            .fill(TodoTheme.accentPurple)
                            .frame(width: 2, height: 18)
                            .opacity(showCursor ? 1 : 0)
                    }
                }
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

    // MARK: - Thinking Indicator

    private var thinkingIndicatorView: some View {
        HStack(spacing: 8) {
            Text("AI is thinking")
                .font(.system(size: 14))
                .foregroundStyle(TodoTheme.textTertiary)

            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    TodoTheme.accentPurple,
                                    TodoTheme.accentPink,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotAnimation == index ? 1.3 : 1.0)
                        .opacity(dotAnimation == index ? 1.0 : 0.5)
                }
            }
        }
        .padding(.vertical, 20)
        .opacity(displayedText.count < fullResponse.count ? 1 : 0)
    }

    // MARK: - Animations

    private func startTypingAnimation() {
        let characters = Array(fullResponse)
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            guard currentIndex < characters.count else {
                timer.invalidate()
                // Navigate to complete view after finishing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appModel.completeAIChatProcessing(response: fullResponse)
                }
                return
            }

            displayedText.append(characters[currentIndex])
            currentIndex += 1
        }
    }

    private func startCursorAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                showCursor.toggle()
            }
        }
    }

    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotAnimation = (dotAnimation + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AIChatProcessingView(userMessage: "Help me plan my day")
        .environment(AppModel())
}
