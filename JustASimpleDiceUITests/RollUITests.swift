import UIKit
import XCTest

final class RollUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches with the dice count forced through the argument domain, which
    /// overrides the saved preference without changing it.
    @MainActor
    private func launch(dieCount: Int) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-dieCount", "\(dieCount)"]
        app.launch()
        XCTAssertTrue(app.buttons["rollButton"].waitForExistence(timeout: 15))
        return app
    }

    /// Taps ROLL and waits for the tumble to finish.
    @MainActor
    private func roll(_ app: XCUIApplication) {
        let rollButton = app.buttons["rollButton"]
        XCTAssertTrue(rollButton.isEnabled)
        rollButton.tap()

        // The button disables during the tumble; wait for it to come back.
        let reEnabled = NSPredicate(format: "isEnabled == true")
        expectation(for: reEnabled, evaluatedWith: rollButton)
        waitForExpectations(timeout: 10)
    }

    @MainActor
    private func face(of die: XCUIElement) -> Int? {
        (die.value as? String).flatMap(Int.init)
    }

    @MainActor
    func testRollButtonRollsAndSettlesOnAValidFace() throws {
        let app = launch(dieCount: 1)
        XCTAssertFalse(app.otherElements["die2"].exists)
        XCTAssertFalse(app.otherElements["total"].exists)

        roll(app)

        let shown = face(of: app.otherElements["die1"])
        XCTAssertTrue(
            (1...6).contains(shown ?? 0),
            "Die should show a face from 1 to 6, got \(String(describing: shown))"
        )
    }

    @MainActor
    func testTwoDiceRollAndShowTheirTotal() throws {
        let app = launch(dieCount: 2)

        roll(app)

        let first = try XCTUnwrap(face(of: app.otherElements["die1"]))
        let second = try XCTUnwrap(face(of: app.otherElements["die2"]))
        XCTAssertTrue((1...6).contains(first) && (1...6).contains(second), "Faces out of range: \(first), \(second)")
        XCTAssertEqual(face(of: app.otherElements["total"]), first + second)
    }

    @MainActor
    func testDieCountChoiceIsRemembered() throws {
        let app = XCUIApplication()
        app.launch()
        let twoDice = app.buttons["dieCount2"]
        XCTAssertTrue(twoDice.waitForExistence(timeout: 15))
        twoDice.tap()
        XCTAssertTrue(app.otherElements["die2"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        XCTAssertTrue(app.otherElements["die2"].waitForExistence(timeout: 15))
    }

    @MainActor
    func testPassesAccessibilityAudit() throws {
        // One launch per layout (see launch(dieCount:)), over DiceRoller.dieCounts.
        for dieCount in 1...2 {
            try audit(launch(dieCount: dieCount))
        }
    }

    /// Saves the App Store screenshots when SCREENSHOTS_DIR is set, as
    /// scripts/capture-screenshots.sh does; skipped in normal test runs.
    @MainActor
    func testCaptureStoreScreenshots() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] else {
            throw XCTSkip("Set SCREENSHOTS_DIR to capture App Store screenshots")
        }
        XCUIDevice.shared.orientation = .portrait
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        for dieCount in 1...2 {
            let app = launch(dieCount: dieCount)
            // Reroll a few times for a photogenic result: a high single die,
            // or two different faces adding up to 7 or more.
            for _ in 0..<20 {
                roll(app)
                let faces = (1...dieCount).compactMap { face(of: app.otherElements["die\($0)"]) }
                if faces.reduce(0, +) >= 4 * dieCount - 1, Set(faces).count == dieCount { break }
            }
            // Let the spin and bounce settle.
            Thread.sleep(forTimeInterval: 1)
            let file = URL(fileURLWithPath: directory).appendingPathComponent("\(dieCount)-\(device).png")
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
        }
    }

    @MainActor
    private func audit(_ app: XCUIApplication) throws {
        // Every iOS audit type as of Xcode 26, one at a time: each call has
        // its own fixed time limit, which a single all-types audit can
        // overrun on a slow CI simulator ("Audit failed to complete in time").
        let auditTypes: [XCUIAccessibilityAuditType] = [
            .contrast, .elementDetection, .hitRegion, .sufficientElementDescription,
            .dynamicType, .textClipped, .trait,
        ]
        for auditType in auditTypes {
            try app.performAccessibilityAudit(for: auditType) { issue in
                // XCTest's own failure message only names the issue type;
                // log which element was flagged so CI failures are diagnosable.
                let element = issue.element?.description ?? "none"
                print("Accessibility audit issue: \(issue.detailedDescription) Element: \(element)")
                return false
            }
        }
    }
}
