import Testing
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

    @Test func everyFaceAppearsWithRealRandomness() async {
        let roller = DiceRoller(tickDuration: .zero)
        var seenFaces = Set<Int>()
        for _ in 0..<100 {
            await roller.roll()
            #expect((1...6).contains(roller.value))
            seenFaces.insert(roller.value)
        }
        #expect(seenFaces == Set(1...6))
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
}
