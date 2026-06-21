import XCTest

struct LoginScreen {
    let app: XCUIApplication

    var emailField: XCUIElement    { app.textFields["email-field"] }
    var passwordField: XCUIElement { app.secureTextFields["password-field"] }
    var loginButton: XCUIElement   { app.buttons["login-button"] }

    func isVisible() -> Bool {
        emailField.waitForExistence(timeout: 5)
    }

    @discardableResult
    func login(email: String = "user@example.com", password: String = "password") -> DashboardScreen {
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Login email field not found")

        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()

        // Wait for tab bar — confirms login transition completed
        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 10),
            "Tab bar did not appear after tapping Log In"
        )
        return DashboardScreen(app: app)
    }

    func loginExpectingError(email: String, password: String) {
        if emailField.waitForExistence(timeout: 5) {
            emailField.tap()
            emailField.typeText(email)
        }
        if !password.isEmpty {
            passwordField.tap()
            passwordField.typeText(password)
        }
        loginButton.tap()
    }
}
