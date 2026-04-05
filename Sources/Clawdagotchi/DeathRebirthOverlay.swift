import SwiftUI

struct DeathRebirthOverlay: View {
    let stats: TamagotchiViewModel.DeathStats
    let onRebirth: (String) -> Void

    @State private var stage: Int = 1
    @State private var newName: String = ""
    @State private var showStats: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)

            if stage == 1 {
                gameOverView
                    .transition(.opacity)
            } else {
                newCrabView
                    .transition(.opacity)
            }
        }
        .onAppear {
            newName = stats.name
            withAnimation(.easeIn(duration: 0.6).delay(0.4)) {
                showStats = true
            }
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 12) {
            Text("GAME OVER")
                .font(.system(.title2, design: .monospaced, weight: .bold))
                .foregroundStyle(.red)
                .tracking(4)

            Rectangle()
                .fill(Color(white: 0.2))
                .frame(width: 100, height: 1)

            if showStats {
                Text(stats.name.uppercased())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(white: 0.4))
                    .transition(.opacity.combined(with: .move(edge: .top)))

                HStack(spacing: 24) {
                    statTile(value: "\(stats.days)", label: "DAYS")
                    statTile(value: "\(stats.level)", label: "LEVEL")
                    statTile(value: "\(stats.xp)", label: "XP")
                }
                .transition(.opacity)

                Rectangle()
                    .fill(Color(white: 0.1))
                    .frame(width: 100, height: 1)
                    .transition(.opacity)

                Text("gone quiet... forgotten")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color(white: 0.2))
                    .transition(.opacity)
            }

            Spacer().frame(height: 16)

            Text("tap to continue")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color(white: 0.25))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(white: 0.15), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.4)) {
                stage = 2
            }
        }
    }

    private var newCrabView: some View {
        VStack(spacing: 10) {
            Text("🥚")
                .font(.system(size: 48))

            Text("A NEW CRAB AWAITS")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(red: 0.48, green: 0.44, blue: 1.0))
                .tracking(2)

            Text("name your new companion")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color(white: 0.35))

            TextField("", text: $newName)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(white: 0.7))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(white: 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color(red: 0.23, green: 0.23, blue: 0.42), lineWidth: 1)
                )
                .frame(width: 140)

            Button {
                onRebirth(newName.isEmpty ? "Clawd" : newName)
            } label: {
                Text("HATCH")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(white: 0.75))
                    .tracking(1)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.16, green: 0.1, blue: 0.42))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(red: 0.35, green: 0.29, blue: 0.67), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Text("lifetime stats preserved")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color(white: 0.2))
                .padding(.top, 8)
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(Color(white: 0.55))
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color(white: 0.27))
                .tracking(1)
        }
    }
}
