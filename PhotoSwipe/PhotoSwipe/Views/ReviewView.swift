import SwiftUI

/// End-of-deck celebration + summary. Animated counts, freed-space estimate, a
/// confetti burst, and a single primary CTA that commits queued deletions via
/// PhotoKit's own confirmation sheet. Also handles the "nothing left in this
/// filter" case.
struct ReviewView: View {
    @ObservedObject var vm: SwipeDeckViewModel
    @State private var appear = false
    @State private var confetti = 0

    private var nothingReviewed: Bool { vm.history.isEmpty && vm.assets.isEmpty }

    var body: some View {
        if nothingReviewed {
            allClearState
        } else {
            summary
        }
    }

    // MARK: Summary

    private var summary: some View {
        ZStack {
            VStack(spacing: 22) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 66))
                    .foregroundStyle(Theme.gradient(Theme.keep, Theme.keep2))
                    .shadow(color: Theme.keep.opacity(0.5), radius: 20)
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)

                VStack(spacing: 4) {
                    Text("ALL CAUGHT UP")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(2).foregroundStyle(Theme.textDim)
                    Text("Library swept")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 12)

                if vm.estimatedFreeBytes > 0 { freeBanner }

                statsCard
                    .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)

                Spacer()
                ctaStack
            }
            .padding(.horizontal, 22)

            ConfettiBurst(trigger: confetti)
        }
        .onAppear {
            withAnimation(.phase) { appear = true }
            Haptics.success()
            confetti += 1
        }
    }

    private var freeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "internaldrive.fill")
            Text("~\(byteString(vm.estimatedFreeBytes)) to free")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
        }
        .foregroundStyle(Theme.trash)
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background(Theme.trash.opacity(0.14), in: Capsule())
        .opacity(appear ? 1 : 0)
    }

    // MARK: Stats

    private var statsCard: some View {
        VStack(spacing: 0) {
            statRow("heart.fill", Theme.keep, "Kept", vm.keptCount)
            divider
            statRow("star.fill", Theme.favorite, "Favorited", vm.favoritedCount)
            divider
            statRow("rectangle.stack.fill", Theme.album, "Filed to albums", vm.albumedCount)
            divider
            statRow("clock.arrow.circlepath", .white.opacity(0.7), "Skipped for later", vm.skippedCount)
            divider
            statRow("trash.fill", Theme.trash, "To delete", vm.pendingTrash.count)
        }
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.stroke))
        .padding(.horizontal, 6)
    }

    private var divider: some View {
        Rectangle().fill(Theme.stroke).frame(height: 1).padding(.horizontal, 18)
    }

    private func statRow(_ icon: String, _ color: Color, _ label: String, _ count: Int) -> some View {
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
            AnimatedCount(value: count, color: color)
        }
        .padding(.horizontal, 18).padding(.vertical, 13)
    }

    // MARK: CTA

    private var ctaStack: some View {
        VStack(spacing: 12) {
            Button { Task { await vm.commitDeletions() } } label: {
                HStack(spacing: 10) {
                    if vm.isCommitting { ProgressView().tint(.white) }
                    else if !vm.pendingTrash.isEmpty { Image(systemName: "trash.fill") }
                    Text(vm.pendingTrash.isEmpty ? "Done" : "Delete \(vm.pendingTrash.count) photos")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(vm.pendingTrash.isEmpty
                            ? Theme.gradient(Theme.keep, Theme.keep2)
                            : Theme.gradient(Theme.trash, Theme.trash2),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(.white)
                .shadow(color: (vm.pendingTrash.isEmpty ? Theme.keep : Theme.trash).opacity(0.4),
                        radius: 16, y: 8)
            }
            .buttonStyle(PressableStyle(scale: 0.97))
            .disabled(vm.isCommitting)

            HStack(spacing: 18) {
                Button("Undo last") { Haptics.tap(.medium); vm.undo() }
                    .disabled(!vm.canUndo)
                    .opacity(vm.canUndo ? 1 : 0.35)
                Button("Back to filters") { Haptics.tap(); vm.backToPicker() }
            }
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .tint(Theme.textDim)
        }
        .padding(.horizontal, 6).padding(.bottom, 18)
    }

    // MARK: Nothing-to-review

    private var allClearState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 54))
                .foregroundStyle(Theme.gradient(Theme.keep, Theme.album))
            Text("Nothing left here")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("You've reviewed everything in this filter.")
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textDim)
                .padding(.horizontal, 40)
            Button("Back to filters") { Haptics.tap(); vm.backToPicker() }
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22).padding(.vertical, 13)
                .background(Theme.gradient(Theme.album, Theme.album2), in: Capsule())
                .buttonStyle(PressableStyle())
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}
