import SwiftUI
import Photos

/// What the user chose to review this session. Drives filtering + sort of the
/// working asset set (or, for `.duplicates`, the scan flow).
enum PhotoSource: Hashable {
    case all
    case screenshots
    case largest
    case year(Int)
    case duplicates

    var title: String {
        switch self {
        case .all: return "All Photos"
        case .screenshots: return "Screenshots"
        case .largest: return "Largest First"
        case .year(let y): return String(y)
        case .duplicates: return "Find Duplicates"
        }
    }

    var icon: String {
        switch self {
        case .all: return "photo.stack.fill"
        case .screenshots: return "camera.viewfinder"
        case .largest: return "arrow.up.right.square.fill"
        case .year: return "calendar"
        case .duplicates: return "square.on.square.dashed"
        }
    }

    var tint: Color {
        switch self {
        case .all: return Theme.album
        case .screenshots: return Theme.favorite
        case .largest: return Theme.trash
        case .year: return Theme.keep
        case .duplicates: return Color(red: 0.72, green: 0.55, blue: 1.0)
        }
    }

    var isDuplicates: Bool { if case .duplicates = self { return true }; return false }
}

/// Pre-computed counts for the picker tiles. Cheap — derived from one library
/// pass over the in-memory asset array.
struct LibraryFacets {
    var total = 0
    var screenshots = 0
    var years: [(year: Int, count: Int)] = []
}
