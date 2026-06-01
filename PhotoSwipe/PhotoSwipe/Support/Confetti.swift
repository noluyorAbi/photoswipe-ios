import SwiftUI

/// One-shot confetti burst for rare, celebratory moments (finishing a review).
/// Lightweight: a fixed set of pieces that fall + spin once, then fade.
struct ConfettiBurst: View {
    var trigger: Int                 // bump to fire again
    var colors: [Color] = [Theme.keep, Theme.favorite, Theme.album, Theme.trash, .white]

    @State private var pieces: [Piece] = []

    struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let color: Color
        let rotation: Double
        let size: CGFloat
        let drift: CGFloat
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    ConfettiPiece(piece: p, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onChange(of: trigger) { _, _ in fire(in: geo.size) }
            .onAppear { fire(in: geo.size) }
        }
        .allowsHitTesting(false)
    }

    private func fire(in size: CGSize) {
        guard size.width > 0 else { return }
        pieces = (0..<70).map { i in
            Piece(
                x: .random(in: 0...size.width),
                delay: Double.random(in: 0...0.25),
                color: colors[i % colors.count],
                rotation: .random(in: 0...360),
                size: .random(in: 7...13),
                drift: .random(in: -60...60)
            )
        }
    }
}

private struct ConfettiPiece: View {
    let piece: ConfettiBurst.Piece
    let height: CGFloat
    @State private var fall = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(fall ? piece.rotation + 360 : piece.rotation))
            .position(x: piece.x + (fall ? piece.drift : 0),
                      y: fall ? height + 40 : -40)
            .opacity(fall ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 1.6).delay(piece.delay)) { fall = true }
            }
    }
}
