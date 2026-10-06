import Foundation
import Observation

@MainActor
@Observable
final class DiceRoller {
    static let dieCounts = 1...2

    /// The face showing on each die, one entry per die.
    private(set) var faces = [1]
    private(set) var isRolling = false

    /// How many dice are on the table, clamped to `dieCounts`. Changing it
    /// keeps the faces already showing; an added die shows a random face.
    /// Ignored mid-roll.
    var dieCount: Int {
        get { faces.count }
        set {
            let count = min(max(newValue, Self.dieCounts.lowerBound), Self.dieCounts.upperBound)
            guard !isRolling, count != faces.count else { return }
            faces = (0..<count).map { $0 < faces.count ? faces[$0] : randomFace() }
        }
    }

    var total: Int { faces.reduce(0, +) }

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
            faces = faces.map { _ in randomFace() }
            try? await Task.sleep(for: tickDuration)
        }
        faces = faces.map { _ in randomFace() }
        isRolling = false
    }
}
