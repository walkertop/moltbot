import SwiftUI

// MARK: - Color Definitions

enum TodoTheme {
    // Primary gradient colors
    static let gradientStart = Color(hex: "#1a1a2e")
    static let gradientMid1 = Color(hex: "#16213e")
    static let gradientMid2 = Color(hex: "#0f3460")
    static let gradientEnd = Color(hex: "#533483")

    // Accent colors
    static let accentPurple = Color(hex: "#8B5CF6")
    static let accentPink = Color(hex: "#EC4899")
    static let accentGreen = Color(hex: "#22C55E")
    static let accentYellow = Color(hex: "#FBBF24")
    static let accentOrange = Color(hex: "#F59E0B")

    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.6)
    static let textMuted = Color.white.opacity(0.5)

    // Card colors
    static let cardBackground = Color.white.opacity(0.1)
    static let cardBackgroundLight = Color.white.opacity(0.15)
    static let cardBorder = Color.white.opacity(0.15)
    static let cardBorderLight = Color.white.opacity(0.2)

    // Completed task style
    static let completedBackground = Color(hex: "#22C55E").opacity(0.15)
    static let completedBorder = Color(hex: "#22C55E").opacity(0.3)
}

// MARK: - Gradients

extension TodoTheme {
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMid1, gradientMid2, gradientEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentPurple, accentPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradientVertical: LinearGradient {
        LinearGradient(
            colors: [accentPurple, accentPink],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [accentGreen, Color(hex: "#10B981")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifiers

extension View {
    func todoBackground() -> some View {
        background(TodoTheme.backgroundGradient)
    }

    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.3))
            .background(TodoTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(TodoTheme.cardBorder, lineWidth: 1)
            )
    }

    func accentButton(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(TodoTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: TodoTheme.accentPurple.opacity(0.4), radius: 16, y: 4)
    }

    func completedCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(TodoTheme.completedBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(TodoTheme.completedBorder, lineWidth: 1)
            )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
