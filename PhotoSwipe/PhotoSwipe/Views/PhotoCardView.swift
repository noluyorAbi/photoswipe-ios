import SwiftUI
import Photos

/// A single photo card: lazily-loaded image with a glass edge and a colored
/// glow + stamp that grows with the active swipe direction.
struct PhotoCardView: View {
    let asset: PHAsset
    var translation: CGSize = .zero
    var isTop: Bool = true

    @State private var image: UIImage?
    @State private var appeared = false
    private let service = PhotoLibraryService()

    private var hShift: CGFloat { translation.width / Theme.swipeThreshold }   // +keep / -trash
    private var vShift: CGFloat { -translation.height / Theme.swipeThreshold }  // +favorite

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(Theme.card)

                if let image {
                    // Blurred fill behind, full photo fitted in front — shows
                    // landscape / sideways photos completely, no harsh crop.
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 24)
                        .overlay(Color.black.opacity(0.22))

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 1.04)
                } else {
                    ProgressView().tint(.white.opacity(0.55))
                }

                if image != nil {
                    metadataScrim
                    if isTop { intentLayer }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(glowColor.opacity(isTop ? min(glowStrength, 0.9) : 0), lineWidth: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
        }
        .cardShadow()
        .task(id: asset.localIdentifier) { await loadImage() }
    }

    // MARK: Layers

    private var metadataScrim: some View {
        VStack {
            Spacer()
            LinearGradient(colors: [.clear, .black.opacity(0.6)],
                           startPoint: .center, endPoint: .bottom)
                .frame(height: 150)
                .overlay(alignment: .bottomLeading) {
                    if let date = asset.creationDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(20)
                    }
                }
        }
        .allowsHitTesting(false)
    }

    private var glowColor: Color {
        if vShift > abs(hShift) { return Theme.favorite }
        return hShift >= 0 ? Theme.keep : Theme.trash
    }
    private var glowStrength: Double {
        Double(max(abs(hShift), max(vShift, 0)))
    }

    private var intentLayer: some View {
        ZStack {
            stamp("KEEP", Theme.keep, rotation: -16, alignment: .topLeading,
                  opacity: max(0, hShift))
            stamp("NOPE", Theme.trash, rotation: 16, alignment: .topTrailing,
                  opacity: max(0, -hShift))
            // up = favorite, down = later (skip)
            if translation.height <= 0 {
                stamp("FAVORITE", Theme.favorite, rotation: 0, alignment: .top,
                      opacity: max(0, vShift))
            } else {
                stamp("LATER", .white.opacity(0.9), rotation: 0, alignment: .bottom,
                      opacity: max(0, translation.height / Theme.swipeThreshold))
            }
        }
        .padding(24)
    }

    private func stamp(_ text: String, _ color: Color, rotation: Double,
                       alignment: Alignment, opacity: Double) -> some View {
        let o = min(opacity, 1)
        return Text(text)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 3))
            .shadow(color: color.opacity(0.5 * o), radius: 12)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(0.85 + 0.15 * o)
            .opacity(o)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    private func loadImage() async {
        let scale = UIScreen.main.scale
        let bounds = UIScreen.main.bounds.size
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        if let img = await service.requestImage(for: asset, targetSize: size, contentMode: .aspectFit) {
            image = img
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { appeared = true }
        }
    }
}
