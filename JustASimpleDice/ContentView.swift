import SwiftUI

struct ContentView: View {
    @State private var roller = DiceRoller()
    @State private var spinDegrees = 0.0

    var body: some View {
        ZStack {
            Color("FeltGreen")
                .ignoresSafeArea()
            VStack {
                Spacer()
                DieView(value: roller.value)
                    .frame(maxWidth: 220)
                    .rotation3DEffect(
                        .degrees(spinDegrees),
                        axis: (x: 0.4, y: 1.0, z: 0.3)
                    )
                    .scaleEffect(roller.isRolling ? 1.1 : 1.0)
                    .animation(.spring(duration: 0.3), value: roller.isRolling)
                Spacer()
                rollButton
                    .padding(.bottom, 48)
            }
            .padding()
        }
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
    }

    private func roll() {
        guard !roller.isRolling else { return }
        withAnimation(.easeOut(duration: 0.9)) {
            spinDegrees += 720
        }
        Task {
            await roller.roll()
        }
    }
}

#Preview {
    ContentView()
}
