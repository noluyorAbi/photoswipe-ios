import SwiftUI

func byteString(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: max(0, bytes), countStyle: .file)
}

/// Compact lifetime-stats hero shown atop the picker. Tap → detailed sheet.
struct StatsHeroCard: View {
    let stats: LifetimeStats
    var onTap: () -> Void
    @State private var appear = false

    var body: some View {
        Button {
            Haptics.tap(); onTap()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text("STORAGE RECLAIMED")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Theme.textDim)

                Text(byteString(stats.freedBytes))
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.gradient(Theme.keep, Theme.album))
                    .contentTransition(.numericText())
                    .scaleEffect(appear ? 1 : 0.85, anchor: .leading)
                    .opacity(appear ? 1 : 0)

                HStack(spacing: 8) {
                    miniPill("trash.fill", Theme.trash, "\(stats.deletedCount) deleted")
                    miniPill("square.on.square.dashed", Theme.album, "\(stats.duplicatesRemoved) dupes")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Theme.gradient(Theme.keep.opacity(0.12), Theme.album.opacity(0.10)))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Theme.gradient(Theme.keep.opacity(0.4), Theme.album.opacity(0.3)), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textDim)
                    .padding(18)
            }
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .onAppear { withAnimation(.phase.delay(0.1)) { appear = true } }
    }

    private func miniPill(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text).font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(color.opacity(0.14), in: Capsule())
    }
}

/// Full analytics sheet.
struct StatsView: View {
    @ObservedObject var vm: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    rows
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Theme.bg0)
            .navigationTitle("Your impact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(Theme.album)
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private var hero: some View {
        VStack(spacing: 6) {
            Image(systemName: "internaldrive.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.gradient(Theme.keep, Theme.album))
            Text(byteString(vm.stats.freedBytes))
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("freed across \(vm.stats.sessions) cleanup\(vm.stats.sessions == 1 ? "" : "s")")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var rows: some View {
        VStack(spacing: 0) {
            row("trash.fill", Theme.trash, "Photos deleted", vm.stats.deletedCount)
            divider
            row("square.on.square.dashed", Theme.album, "Duplicates removed", vm.stats.duplicatesRemoved)
            divider
            row("checkmark.circle.fill", Theme.keep, "Cleanup sessions", vm.stats.sessions)
            divider
            resetRow
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.stroke))
    }

    private var divider: some View {
        Rectangle().fill(Theme.stroke).frame(height: 1).padding(.horizontal, 18)
    }

    private func row(_ icon: String, _ color: Color, _ label: String, _ value: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(Circle().fill(color.opacity(0.14)))
            Text(label)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            AnimatedCount(value: value, color: color)
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
    }

    private var resetRow: some View {
        Button {
            if confirmReset { Haptics.warning(); vm.resetStats(); confirmReset = false }
            else { Haptics.tap(); confirmReset = true }
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text(confirmReset ? "Tap again to confirm reset" : "Reset analytics")
                Spacer()
            }
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundStyle(confirmReset ? Theme.trash : Theme.textDim)
            .padding(.horizontal, 18).padding(.vertical, 15)
        }
    }
}
