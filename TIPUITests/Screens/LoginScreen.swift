import XCTest

struct LoginScreen {
    let app: XCUIApplication

    var emailField: XCUIElement    { app.textFields["email-field"] }
    var passwordField: XCUIElement { app.secureTextFields["password-field"] }
    var loginButton: XCUIElement   { app.buttons["login-button"] }
    var errorText: XCUIElement     { app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'required'")).firstMatch }

    func isVisible() -> Bool {
        emailField.waitForExistence(timeout: 3)
    }

    @discardableResult
    func login(email: String = "user@example.com", password: String = "password") -> DashboardScreen {
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Login screen did not appear")
        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()
        // Wait for the login transition to complete before callers try to interact with tabs.
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5),
                      "Tab bar did not appear after login")
        return DashboardScreen(app: app)
    }

    func loginExpectingError(email: String, password: String) {
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap(); emailField.typeText(email)
        }
        if !password.isEmpty {
            passwordField.tap(); passwordField.typeText(password)
        }
        loginButton.tap()
    }
}
