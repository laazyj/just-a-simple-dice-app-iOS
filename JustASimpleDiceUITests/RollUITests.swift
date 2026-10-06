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

    @MainActor
    func testPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["rollButton"].waitForExistence(timeout: 15))

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
