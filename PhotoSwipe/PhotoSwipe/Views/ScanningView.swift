import SwiftUI

/// Duplicate-scan progress. A determinate ring driven by `vm.scanProgress`.
struct ScanningView: View {
    @ObservedObject var vm: SwipeDeckViewModel

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: vm.scanProgress)
                    .stroke(Theme.gradient(Theme.album, Theme.keep),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy(duration: 0.25), value: vm.scanProgress)
                Text("\(Int(vm.scanProgress * 100))%")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 140, height: 140)

            VStack(spacing: 4) {
                Text("Scanning for duplicates")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text("Comparing photos on-device")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .padding(40)
    }
}
