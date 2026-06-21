import XCTest

final class TIPUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // @tc-id: AUTH-TC001
    func testLoginWithValidCredentialsShowsDashboard() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText("user@example.com")
        passwordField.tap()
        passwordField.typeText("password")
        app.buttons["Log In"].tap()
        XCTAssertTrue(app.staticTexts["Dashboard"].waitForExistence(timeout: 3))
    }

    // @tc-id: AUTH-TC003
    func testLogoutReturnsToLoginScreen() {
        testLoginWithValidCredentialsShowsDashboard()
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Log Out"].tap()
        XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 3))
    }
}
