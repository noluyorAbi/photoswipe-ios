import Foundation
import Photos

/// One decision the user made on a photo. Drives the undo stack and the
/// pending-delete set that gets committed at review time.
enum Decision: Equatable {
    case keep
    case trash
    case favorite
    case skip   // decide later — not persisted, reappears next session
    case album(localIdentifier: String, title: String)
}

struct SwipeAction: Identifiable, Equatable {
    let id = UUID()
    let asset: PHAsset
    let decision: Decision

    static func == (lhs: SwipeAction, rhs: SwipeAction) -> Bool {
        lhs.id == rhs.id
    }
}
