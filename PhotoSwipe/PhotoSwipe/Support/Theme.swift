import SwiftUI

// MARK: - Palette

enum Theme {
    // Deep, slightly-blue near-black. Not flat #000 — has life.
    static let bg0 = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let bg1 = Color(red: 0.07, green: 0.07, blue: 0.10)

    static let card = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let stroke = Color.white.opacity(0.08)

    // Sharp accents, each with a gradient pair for glows.
    static let keep   = Color(red: 0.17, green: 0.85, blue: 0.50)
    static let keep2  = Color(red: 0.08, green: 0.72, blue: 0.40)
    static let trash  = Color(red: 1.00, green: 0.30, blue: 0.43)
    static let trash2 = Color(red: 0.88, green: 0.18, blue: 0.33)
    static let favorite  = Color(red: 1.00, green: 0.76, blue: 0.24)
    static let favorite2 = Color(red: 1.00, green: 0.60, blue: 0.12)
    static let album  = Color(red: 0.43, green: 0.55, blue: 1.00)
    static let album2 = Color(red: 0.29, green: 0.42, blue: 1.00)

    static let textDim = Color.white.opacity(0.5)

    static let cardCorner: CGFloat = 30
    static let swipeThreshold: CGFloat = 105

    static func gradient(_ a: Color, _ b: Color) -> LinearGradient {
        LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Motion tokens
// Golden curve feel translated to SwiftUI. High-freq = snappy; rare = expressive.

extension Animation {
    /// Card settle / return — snappy with a touch of life.
    static let cardSpring = Animation.spring(response: 0.34, dampingFraction: 0.78)
    /// Fling-off easing (exit). Fast accelerate.
    static let fling = Animation.easeIn(duration: 0.26)
    /// Press micro-interaction.
    static let press = Animation.spring(response: 0.22, dampingFraction: 0.6)
    /// Phase / view transitions — expressive (rare).
    static let phase = Animation.spring(response: 0.5, dampingFraction: 0.82)
}

// MARK: - Shared modifiers

extension View {
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.5), radius: 28, x: 0, y: 18)
    }
}

// MARK: - Pressable button style (scale + soft press)

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.9
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.press, value: configuration.isPressed)
    }
}

// MARK: - Aurora background
// Slow-drifting accent blobs over the dark base. Subtle, alive, never noticed.

struct AuroraBackground: View {
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: [Theme.bg1, Theme.bg0],
                               startPoint: .top, endPoint: .bottom)

                blob(Theme.album, size: 460)
                    .position(x: w * (drift ? 0.20 : 0.30), y: h * (drift ? 0.10 : 0.04))
                blob(Theme.keep, size: 380)
                    .position(x: w * (drift ? 0.85 : 0.78), y: h * (drift ? 0.92 : 0.98))
                blob(Theme.favorite, size: 300)
                    .position(x: w * (drift ? 0.82 : 0.92), y: h * (drift ? 0.08 : 0.12))
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func blob(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(0.20), .clear],
                                 center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
            .blur(radius: 50)
    }
}

// MARK: - Animated count (smooth numeric roll)

struct AnimatedCount: View {
    let value: Int
    var font: Font = .title3.weight(.bold)
    var color: Color = .white

    var body: some View {
        Text("\(value)")
            .font(font.monospacedDigit())
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(value)))
            .animation(.snappy(duration: 0.4), value: value)
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
