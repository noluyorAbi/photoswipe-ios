import Foundation

/// Lifetime cleanup totals, accumulated across sessions in UserDefaults.
struct LifetimeStats: Equatable {
    var freedBytes: Int64 = 0
    var deletedCount: Int = 0
    var duplicatesRemoved: Int = 0
    var sessions: Int = 0
}

final class StatsStore {
    private let defaults = UserDefaults.standard
    private enum Key {
        static let freed = "stats.freedBytes"
        static let deleted = "stats.deletedCount"
        static let dupes = "stats.duplicatesRemoved"
        static let sessions = "stats.sessions"
    }

    func load() -> LifetimeStats {
        LifetimeStats(
            freedBytes: defaults.object(forKey: Key.freed) as? Int64 ?? 0,
            deletedCount: defaults.integer(forKey: Key.deleted),
            duplicatesRemoved: defaults.integer(forKey: Key.dupes),
            sessions: defaults.integer(forKey: Key.sessions)
        )
    }

    /// Record one completed cleanup. `duplicates` counts deletions that came
    /// from the duplicate flow (a subset of `deleted`).
    @discardableResult
    func record(freed: Int64, deleted: Int, duplicates: Int = 0) -> LifetimeStats {
        var s = load()
        s.freedBytes += freed
        s.deletedCount += deleted
        s.duplicatesRemoved += duplicates
        s.sessions += 1
        defaults.set(s.freedBytes, forKey: Key.freed)
        defaults.set(s.deletedCount, forKey: Key.deleted)
        defaults.set(s.duplicatesRemoved, forKey: Key.dupes)
        defaults.set(s.sessions, forKey: Key.sessions)
        return s
    }

    func reset() {
        [Key.freed, Key.deleted, Key.dupes, Key.sessions].forEach { defaults.removeObject(forKey: $0) }
    }
}
