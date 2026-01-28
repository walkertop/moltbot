import SwiftUI

// MARK: - AI Processing View

struct AIProcessingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var orbitRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    private let processingSteps = [
        "Analyzing task complexity...",
        "Identifying subtasks...",
        "Estimating time & priority...",
        "Generating action plan...",
    ]

    var body: some View {
        ZStack {
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            // Floating particles
            particlesView

            VStack(spacing: 32) {
                Spacer()

                // AI Orb animation
                aiOrbView

                // Processing text
                processingTextView

                // Steps preview
                stepsPreviewView

                // Fun fact
                funFactView

                // Cancel hint
                cancelHintView

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - AI Orb

    private var aiOrbView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            TodoTheme.accentPurple.opacity(0.3),
                            TodoTheme.accentPink.opacity(0.15),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)

            // Orbit ring 1
            Circle()
                .stroke(TodoTheme.accentPurple.opacity(0.3), lineWidth: 1)
                .frame(width: 160, height: 160)
                .overlay(
                    Circle()
                        .fill(TodoTheme.accentPurple)
                        .frame(width: 12, height: 12)
                        .shadow(color: TodoTheme.accentPurple.opacity(0.8), radius: 10)
                        .offset(y: -80)
                )
                .rotationEffect(.degrees(orbitRotation))

            // Orbit ring 2
            Circle()
                .stroke(TodoTheme.accentPink.opacity(0.3), lineWidth: 1)
                .frame(width: 140, height: 140)
                .overlay(
                    Circle()
                        .fill(TodoTheme.accentPink)
                        .frame(width: 8, height: 8)
                        .shadow(color: TodoTheme.accentPink.opacity(0.8), radius: 8)
                        .offset(y: 70)
                )
                .rotationEffect(.degrees(-orbitRotation * 1.5))

            // Center orb
            ZStack {
                Circle()
                    .fill(TodoTheme.accentGradient)
                    .frame(width: 90, height: 90)
                    .shadow(color: TodoTheme.accentPurple.opacity(0.8), radius: 40)
                    .scaleEffect(pulseScale)

                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 180, height: 180)
    }

    // MARK: - Processing Text

    private var processingTextView: some View {
        VStack(spacing: 12) {
            Text("AI is analyzing your task...")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Text("Breaking down into manageable steps")
                .font(.system(size: 15))
                .foregroundStyle(TodoTheme.textTertiary)
        }
    }

    // MARK: - Steps Preview

    private var stepsPreviewView: some View {
        VStack(spacing: 10) {
            ForEach(Array(processingSteps.enumerated()), id: \.offset) { index, step in
                stepRow(index: index, text: step)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
        .frame(maxWidth: 320)
    }

    private func stepRow(index: Int, text: String) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(stepColor(for: index))
                .frame(width: 8, height: 8)
                .shadow(color: stepColor(for: index).opacity(0.8), radius: 8)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(stepTextColor(for: index))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Check mark for completed steps
            if index < appModel.aiProcessingStep {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(TodoTheme.accentGreen)
            }
        }
    }

    private func stepColor(for index: Int) -> Color {
        if index < appModel.aiProcessingStep {
            return TodoTheme.accentGreen
        } else if index == appModel.aiProcessingStep {
            return TodoTheme.accentPurple
        } else {
            return .white.opacity(0.3)
        }
    }

    private func stepTextColor(for index: Int) -> Color {
        if index <= appModel.aiProcessingStep {
            return index < appModel.aiProcessingStep ? TodoTheme.textSecondary : .white
        } else {
            return TodoTheme.textMuted
        }
    }

    // MARK: - Fun Fact

    private var funFactView: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundStyle(TodoTheme.accentYellow)

            Text("AI has analyzed 10,000+ tasks!")
                .font(.system(size: 13))
                .foregroundStyle(TodoTheme.accentYellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TodoTheme.accentOrange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(TodoTheme.accentOrange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Cancel Hint

    private var cancelHintView: some View {
        Button {
            appModel.cancelAIProcessing()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                Text("Tap to cancel")
                    .font(.system(size: 13))
            }
            .foregroundStyle(TodoTheme.textMuted)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Particles

    private var particlesView: some View {
        ZStack {
            ForEach(0 ..< 6, id: \.self) { index in
                Circle()
                    .fill(particleColor(for: index))
                    .frame(width: particleSize(for: index), height: particleSize(for: index))
                    .position(particlePosition(for: index))
            }
        }
    }

    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [
            TodoTheme.accentPurple.opacity(0.4),
            TodoTheme.accentPink.opacity(0.4),
            TodoTheme.accentGreen.opacity(0.3),
            TodoTheme.accentOrange.opacity(0.3),
            TodoTheme.accentPurple.opacity(0.2),
            TodoTheme.accentPink.opacity(0.2),
        ]
        return colors[index % colors.count]
    }

    private func particleSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [6, 4, 8, 5, 10, 7]
        return sizes[index % sizes.count]
    }

    private func particlePosition(for index: Int) -> CGPoint {
        let positions: [CGPoint] = [
            CGPoint(x: 50, y: 200),
            CGPoint(x: 380, y: 250),
            CGPoint(x: 40, y: 600),
            CGPoint(x: 390, y: 550),
            CGPoint(x: 60, y: 400),
            CGPoint(x: 370, y: 420),
        ]
        return positions[index % positions.count]
    }

    // MARK: - Animations

    private func startAnimations() {
        // Orbit rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Preview

#Preview {
    AIProcessingView()
        .environment(AppModel())
}
