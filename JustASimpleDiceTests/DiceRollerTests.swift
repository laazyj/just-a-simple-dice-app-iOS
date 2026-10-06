import SwiftUI
import Testing
import UIKit
@testable import JustASimpleDice

@MainActor
struct DiceRollerTests {

    @Test func landsOnFinalRandomFace() async {
        let roller = DiceRoller(tickDuration: .zero, randomFace: { 5 })
        await roller.roll()
        #expect(roller.value == 5)
        #expect(roller.isRolling == false)
    }

    @Test func ignoresRollWhileAlreadyRolling() async {
        var faceCalls = 0
        let roller = DiceRoller(tickDuration: .milliseconds(20), tickCount: 10) {
            faceCalls += 1
            return 3
        }
        async let first: Void = roller.roll()
        async let second: Void = roller.roll()
        _ = await (first, second)
        // One roll's worth of faces: 10 shuffle ticks plus the final face.
        #expect(faceCalls == 11)
    }

    @Test func isRollingWhileTumblingAndClearedAfter() async {
        final class Box { var roller: DiceRoller? }
        let box = Box()
        var observedRollingDuringTumble = false
        let roller = DiceRoller(tickDuration: .zero) {
            observedRollingDuringTumble = box.roller?.isRolling ?? false
            return 4
        }
        box.roller = roller
        await roller.roll()
        #expect(observedRollingDuringTumble)
        #expect(roller.isRolling == false)
    }

    @Test func realRandomnessIsFair() async throws {
        let roller = DiceRoller(tickDuration: .zero, tickCount: 0)
        let rolls = 6_000
        var counts = [Int](repeating: 0, count: 6)
        for _ in 0..<rolls {
            await roller.roll()
            try #require((1...6).contains(roller.value))
            counts[roller.value - 1] += 1
        }
        // Pearson's chi-squared test against a uniform die (5 degrees of
        // freedom). A fair die exceeds 40 with probability ~1.5e-7, so this
        // won't flake, but it catches a missing face or a mapping bias (e.g.
        // modulo) that makes one face even ~20% too likely.
        let expected = Double(rolls) / 6
        let chiSquared = counts.reduce(0.0) { sum, observed in
            let delta = Double(observed) - expected
            return sum + delta * delta / expected
        }
        #expect(chiSquared < 40, "Face counts \(counts) look biased (χ² = \(chiSquared))")
    }
}

struct DieViewTests {

    @Test func pipCountMatchesFaceValue() {
        for face in 1...6 {
            #expect(DieView.pipPositions(for: face).count == face)
        }
    }

    @Test func pipsStayInsideTheDieFace() {
        for face in 1...6 {
            for pip in DieView.pipPositions(for: face) {
                #expect(pip.x > 0.1 && pip.x < 0.9)
                #expect(pip.y > 0.1 && pip.y < 0.9)
            }
        }
    }

    // Pip geometry is covered above; this checks the view actually draws
    // from its value.
    @MainActor
    @Test func eachValueRendersADifferentFace() throws {
        let images = try (1...6).map { face in
            let renderer = ImageRenderer(content: DieView(value: face).frame(width: 120, height: 120))
            renderer.scale = 1
            return try #require(renderer.uiImage?.pngData(), "Face \(face) didn't render")
        }
        #expect(Set(images).count == 6, "Two faces rendered identically")
    }
}
