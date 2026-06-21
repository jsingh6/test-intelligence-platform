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
        XCTAssertTrue(emailField.waitForExistence(timeout: 3), "Login screen did not appear")
        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()
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
