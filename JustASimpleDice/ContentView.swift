import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color("FeltGreen")
                .ignoresSafeArea()
            Text("Just a Simple Dice")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

#Preview {
    ContentView()
}
