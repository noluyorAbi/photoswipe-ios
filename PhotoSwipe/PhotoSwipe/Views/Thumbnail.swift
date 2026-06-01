import SwiftUI
import Photos

/// Small square async thumbnail for grids and duplicate strips.
struct Thumbnail: View {
    let asset: PHAsset
    var side: CGFloat = 88
    @State private var image: UIImage?
    private let service = PhotoLibraryService()

    var body: some View {
        ZStack {
            Rectangle().fill(Theme.card)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task(id: asset.localIdentifier) {
            let scale = UIScreen.main.scale
            image = await service.requestImage(
                for: asset, targetSize: CGSize(width: side * scale, height: side * scale))
        }
    }
}
