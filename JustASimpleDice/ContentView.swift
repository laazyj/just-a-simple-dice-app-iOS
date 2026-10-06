import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("dieCount") private var dieCount = 1
    @ScaledMetric(relativeTo: .largeTitle) private var totalSize = 56.0
    @State private var roller = DiceRoller()
    @State private var spinDegrees = 0.0

    private static let singleDieWidth = 220.0
    private static let pairedDieWidth = 148.0
    private static let dieSpacing = 28.0

    private var isTwoDice: Bool { roller.faces.count > 1 }

    var body: some View {
        ZStack {
            Color("FeltGreen")
                .colorEffect(ShaderLibrary.feltTexture(.float(2)))
                .ignoresSafeArea()
            VStack {
                DieCountPicker(selection: $dieCount)
                    .disabled(roller.isRolling)
                Spacer()
                dice
                if isTwoDice {
                    total
                        .padding(.top, 36)
                }
                Spacer()
                rollButton
                    .padding(.bottom, 48)
            }
            .padding()
        }
        .onShake(perform: roll)
        .onChange(of: dieCount, initial: true) {
            roller.dieCount = dieCount
        }
    }

    private var dice: some View {
        HStack(spacing: Self.dieSpacing) {
            ForEach(roller.faces.indices, id: \.self) { index in
                DieView(value: roller.faces[index])
                    .accessibilityElement()
                    .accessibilityLabel(isTwoDice ? ["First die", "Second die"][index] : "Die")
                    .accessibilityValue("\(roller.faces[index])")
                    .accessibilityIdentifier("die\(index + 1)")
            }
        }
        .frame(maxWidth: isTwoDice ? 2 * Self.pairedDieWidth + Self.dieSpacing : Self.singleDieWidth)
        .rotation3DEffect(
            .degrees(spinDegrees),
            axis: (x: 0.4, y: 1.0, z: 0.3)
        )
        .scaleEffect(roller.isRolling && !reduceMotion ? 1.1 : 1.0)
        .animation(.spring(duration: 0.3), value: roller.isRolling)
    }

    private var total: some View {
        VStack(spacing: 2) {
            Text("Total")
                .font(.footnote.weight(.semibold))
                .tracking(2)
                .textCase(.uppercase)
            Text("\(roller.total)")
                .font(.system(size: totalSize, weight: .heavy))
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Total")
        .accessibilityValue("\(roller.total)")
        .accessibilityIdentifier("total")
    }

    private var rollButton: some View {
        Button(action: roll) {
            Text("ROLL")
                .font(.title2.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Color("FeltGreen"))
                .padding(.horizontal, 56)
                .padding(.vertical, 16)
                .background(Capsule().fill(.white))
        }
        .disabled(roller.isRolling)
        .opacity(roller.isRolling ? 0.6 : 1.0)
        .accessibilityIdentifier("rollButton")
        .accessibilityHint("Rolls the \(isTwoDice ? "dice" : "die"). You can also shake the device.")
    }

    private func roll() {
        guard !roller.isRolling else { return }
        // Vestibular-friendly: with Reduce Motion on, skip the 3D spin and
        // scale bounce; the face shuffle, haptic, and announcement remain.
        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.9)) {
                spinDegrees += 720
            }
        }
        Task {
            await roller.roll()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            let faces = roller.faces.map(String.init).joined(separator: " and ")
            let announcement = isTwoDice ? "Rolled \(faces), total \(roller.total)" : "Rolled \(faces)"
            AccessibilityNotification.Announcement(announcement).post()
        }
    }
}

/// A two-option switch between one and two dice, styled to sit on the felt.
private struct DieCountPicker: View {
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DiceRoller.dieCounts, id: \.self) { count in
                option(count, title: count == 1 ? "1 die" : "\(count) dice")
            }
        }
        .padding(4)
        // Opaque, so the white labels sit on a flat color rather than the
        // textured felt (the contrast audit flagged the translucent version).
        .background(Capsule().fill(Color("FeltGreenDark")))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Number of dice")
    }

    private func option(_ count: Int, title: String) -> some View {
        let isSelected = selection == count
        return Button {
            selection = count
        } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? Color("FeltGreen") : .white)
                .padding(.horizontal, 20)
                .frame(minWidth: 88, minHeight: 44)
                .background(Capsule().fill(isSelected ? .white : .clear))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("dieCount\(count)")
    }
}

#Preview("One die") {
    ContentView()
        .defaultAppStorage(UserDefaults(suiteName: "preview-one")!)
}

#Preview("Two dice") {
    let defaults = UserDefaults(suiteName: "preview-two")!
    defaults.set(2, forKey: "dieCount")
    return ContentView()
        .defaultAppStorage(defaults)
}
