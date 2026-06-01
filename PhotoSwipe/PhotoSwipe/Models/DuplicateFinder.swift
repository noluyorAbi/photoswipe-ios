import Photos
import CoreGraphics
import UIKit
import simd

/// A cluster of near-identical photos. `keeperID` is the suggested one to keep
/// (highest resolution); the rest start selected for deletion.
struct DuplicateGroup: Identifiable {
    let id = UUID()
    var assets: [PHAsset]
    var keeperID: String
    var trashIDs: Set<String>

    init(assets: [PHAsset]) {
        let keeper = assets.max(by: { $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight })
        self.assets = assets
        self.keeperID = keeper?.localIdentifier ?? assets.first?.localIdentifier ?? ""
        self.trashIDs = Set(assets.map(\.localIdentifier)).subtracting([keeperID])
    }
}

/// Finds duplicate / near-duplicate photos on-device using a perceptual
/// difference hash (dHash) plus PhotoKit burst grouping. dHash is deterministic
/// and works on simulator and device (unlike Vision feature prints). Compares
/// each asset only to a small time-sorted neighbour window to stay near-linear.
final class DuplicateFinder {
    private let service: PhotoLibraryService
    private let window = 8
    private let maxHamming = 10     // 64-bit dHash distance; 0 = identical
    private let maxColorDist: Float = 28  // avg-RGB euclidean; rejects same-shape/different-color
    private let cap = 2000

    /// Per-asset signature: grayscale structure hash + average color.
    private struct Sig { let hash: UInt64; let color: SIMD3<Float> }

    init(service: PhotoLibraryService) { self.service = service }

    func scan(_ input: [PHAsset], progress: @MainActor @escaping (Double) -> Void) async -> [DuplicateGroup] {
        let assets = Array(input.sorted {
            ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
        }.prefix(cap))
        guard assets.count >= 2 else { return [] }

        // 1. Signatures: dHash structure + average color (0 → 0.85)
        var sigs: [Sig?] = Array(repeating: nil, count: assets.count)
        for i in assets.indices {
            if let ui = await service.requestImage(for: assets[i], targetSize: CGSize(width: 160, height: 160)),
               let cg = Self.cgImage(from: ui), let hash = Self.dHash(cg) {
                sigs[i] = Sig(hash: hash, color: Self.avgColor(cg))
            }
            await progress(0.85 * Double(i + 1) / Double(assets.count))
        }

        // 2. Union-find over neighbour window + burst identity (0.85 → 1)
        var uf = UnionFind(count: assets.count)
        for i in assets.indices {
            let upper = min(i + window, assets.count - 1)
            if i < upper {
                for j in (i + 1)...upper {
                    if sameBurst(assets[i], assets[j]) || similar(sigs[i], sigs[j]) {
                        uf.union(i, j)
                    }
                }
            }
            await progress(0.85 + 0.15 * Double(i + 1) / Double(assets.count))
        }

        // 3. Build groups
        var buckets: [Int: [PHAsset]] = [:]
        for i in assets.indices { buckets[uf.find(i), default: []].append(assets[i]) }
        return buckets.values
            .filter { $0.count >= 2 }
            .map { DuplicateGroup(assets: $0.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) }
            .sorted { $0.assets.count > $1.assets.count }
    }

    private func sameBurst(_ a: PHAsset, _ b: PHAsset) -> Bool {
        guard let ba = a.burstIdentifier, let bb = b.burstIdentifier else { return false }
        return ba == bb
    }

    private func similar(_ a: Sig?, _ b: Sig?) -> Bool {
        guard let a, let b else { return false }
        guard (a.hash ^ b.hash).nonzeroBitCount <= maxHamming else { return false }
        let d = a.color - b.color
        return (d * d).sum() <= maxColorDist * maxColorDist   // structure AND color must match
    }

    /// Average color of the image, 0–255 per channel.
    private static func avgColor(_ cg: CGImage) -> SIMD3<Float> {
        var px: [UInt8] = [0, 0, 0, 0]
        let cs = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        if let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8,
                               bytesPerRow: 4, space: cs, bitmapInfo: info) {
            ctx.interpolationQuality = .medium
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return SIMD3<Float>(Float(px[0]), Float(px[1]), Float(px[2]))
    }

    private static func cgImage(from ui: UIImage) -> CGImage? {
        if let c = ui.cgImage { return c }
        let r = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 160))
        return r.image { _ in ui.draw(in: CGRect(x: 0, y: 0, width: 160, height: 160)) }.cgImage
    }

    /// 9×8 grayscale difference hash → 64 bits.
    private static func dHash(_ cg: CGImage) -> UInt64? {
        let w = 9, h = 8
        let cs = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return nil }
        let p = data.bindMemory(to: UInt8.self, capacity: w * h)
        var hash: UInt64 = 0
        var bit = 0
        for row in 0..<h {
            for col in 0..<8 {
                if p[row * w + col] < p[row * w + col + 1] { hash |= (UInt64(1) << UInt64(bit)) }
                bit += 1
            }
        }
        return hash
    }
}

private struct UnionFind {
    private var parent: [Int]
    init(count: Int) { parent = Array(0..<count) }
    mutating func find(_ x: Int) -> Int {
        var r = x
        while parent[r] != r { r = parent[r] }
        var c = x
        while parent[c] != c { let n = parent[c]; parent[c] = r; c = n }
        return r
    }
    mutating func union(_ a: Int, _ b: Int) {
        let ra = find(a), rb = find(b)
        if ra != rb { parent[ra] = rb }
    }
}
