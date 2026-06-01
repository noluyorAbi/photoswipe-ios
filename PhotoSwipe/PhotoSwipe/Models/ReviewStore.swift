import Foundation

/// Persists which assets the user has already decided on, so sessions resume
/// instead of re-showing the same photos. Skipped photos are NOT stored — they
/// come back next time.
final class ReviewStore {
    private let key = "reviewedAssetIDs"
    private let defaults = UserDefaults.standard
    private(set) var reviewed: Set<String>

    init() {
        reviewed = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func isReviewed(_ id: String) -> Bool { reviewed.contains(id) }

    func mark(_ id: String) {
        reviewed.insert(id)
        persist()
    }

    func unmark(_ id: String) {
        reviewed.remove(id)
        persist()
    }

    func reset() {
        reviewed.removeAll()
        persist()
    }

    private func persist() {
        defaults.set(Array(reviewed), forKey: key)
    }
}
