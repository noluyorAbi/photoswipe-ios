import Foundation

/// Photos swiped to trash but not yet deleted. Persisted so a run can be paused
/// (or the app quit) without losing the queue — you can delete the batch
/// swiped so far at any time, then keep going.
final class PendingTrashStore {
    private let key = "pendingTrashIDs"
    private let defaults = UserDefaults.standard
    private(set) var ids: Set<String>

    init() { ids = Set(defaults.stringArray(forKey: key) ?? []) }

    func add(_ id: String) { ids.insert(id); persist() }
    func remove(_ id: String) { ids.remove(id); persist() }
    func clear() { ids.removeAll(); persist() }

    private func persist() { defaults.set(Array(ids), forKey: key) }
}
