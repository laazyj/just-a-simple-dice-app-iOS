import Foundation
import Observation

@MainActor
@Observable
final class DiceRoller {
    private(set) var value = 1
    private(set) var isRolling = false

    private let tickDuration: Duration
    private let tickCount: Int
    private let randomFace: @MainActor () -> Int

    init(
        tickDuration: Duration = .milliseconds(80),
        tickCount: Int = 10,
        randomFace: @escaping @MainActor () -> Int = { Int.random(in: 1...6) }
    ) {
        self.tickDuration = tickDuration
        self.tickCount = tickCount
        self.randomFace = randomFace
    }

    func roll() async {
        guard !isRolling else { return }
        isRolling = true
        for _ in 0..<tickCount {
            value = randomFace()
            try? await Task.sleep(for: tickDuration)
        }
        value = randomFace()
        isRolling = false
    }
}
