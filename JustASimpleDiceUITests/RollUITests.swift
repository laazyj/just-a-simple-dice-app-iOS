import XCTest

final class RollUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRollButtonRollsAndSettlesOnAValidFace() throws {
        let app = XCUIApplication()
        app.launch()

        let die = app.otherElements["die"]
        XCTAssertTrue(die.waitForExistence(timeout: 15))

        let rollButton = app.buttons["rollButton"]
        XCTAssertTrue(rollButton.exists)
        XCTAssertTrue(rollButton.isEnabled)

        rollButton.tap()

        // The button disables during the tumble; wait for it to come back.
        let reEnabled = NSPredicate(format: "isEnabled == true")
        expectation(for: reEnabled, evaluatedWith: rollButton)
        waitForExpectations(timeout: 10)

        let face = die.value as? String
        XCTAssertNotNil(face)
        XCTAssertTrue(
            (1...6).map(String.init).contains(face ?? ""),
            "Die should show a face between 1 and 6, got \(face ?? "nil")"
        )
    }
}
