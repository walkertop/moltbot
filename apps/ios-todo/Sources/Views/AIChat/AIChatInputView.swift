import SwiftUI

// MARK: - AI Chat Input View

struct AIChatInputView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var glowAnimation = false

    private let quickPrompts = [
        "Write code",
        "Explain concept",
        "Design UI",
    ]

    var body: some View {
        ZStack {
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Spacer()

                // AI Logo with glow
                aiLogoView

                // Welcome text
                welcomeTextView

                // Quick prompts
                quickPromptsView

                Spacer()

                // Input bar
                inputBarView
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
        }
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

    // MARK: - AI Logo

    private var aiLogoView: some View {
        ZStack {
            // Outer glow rings
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            TodoTheme.accentPurple.opacity(0.4),
                            TodoTheme.accentPink.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 140, height: 140)
                .scaleEffect(glowAnimation ? 1.1 : 1.0)
                .opacity(glowAnimation ? 0.5 : 0.8)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            TodoTheme.accentPurple.opacity(0.6),
                            TodoTheme.accentPink.opacity(0.4),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
                .scaleEffect(glowAnimation ? 1.05 : 1.0)

            // Center logo
            ZStack {
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
                    .frame(width: 80, height: 80)
                    .shadow(color: TodoTheme.accentPurple.opacity(0.6), radius: 30, y: 10)

                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 160)
    }

    // MARK: - Welcome Text

    private var welcomeTextView: some View {
        VStack(spacing: 8) {
            Text("How can I help you today?")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)

            Text("Ask me anything or try a quick prompt")
                .font(.system(size: 15))
                .foregroundStyle(TodoTheme.textTertiary)
        }
        .padding(.top, 32)
    }

    // MARK: - Quick Prompts

    private var quickPromptsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking")
                .font(.system(size: 13))
                .foregroundStyle(TodoTheme.textMuted)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                    } label: {
                        Text(prompt)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Input Bar

    private var inputBarView: some View {
        HStack(spacing: 12) {
            // Text field
            HStack(spacing: 12) {
                TextField("Type your message...", text: $inputText)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .tint(TodoTheme.accentPurple)

                // Voice button
                Button {
                    appModel.showVoiceInput = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(TodoTheme.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )

            // Send button
            Button {
                submitMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        inputText.isEmpty
                            ? AnyShapeStyle(Color.white.opacity(0.15))
                            : AnyShapeStyle(TodoTheme.accentGradient)
                    )
                    .clipShape(Circle())
                    .shadow(
                        color: inputText.isEmpty ? .clear : TodoTheme.accentPurple.opacity(0.4),
                        radius: 16, y: 4
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func submitMessage() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else { return }

        Task {
            await appModel.startAIChatProcessing(input: trimmedInput)
        }
    }
}

// MARK: - Preview

#Preview {
    AIChatInputView()
        .environment(AppModel())
}
