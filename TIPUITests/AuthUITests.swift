import XCTest

// @test-ids: AUTH-TC001
final class AuthUITests: TIPUITestCase {

    // AUTH-TC001 — Successful login navigates to Dashboard
    func testLoginWithValidCredentials__AUTH_TC001() {
        let screen = loginScreen
        XCTAssertTrue(screen.isVisible(), "Login screen should be shown at launch")

        screen.login(email: "user@example.com", password: "password")

        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 4),
            "Tab bar should appear after successful login"
        )
        XCTAssertTrue(
            app.navigationBars["Dashboard"].waitForExistence(timeout: 4),
            "Dashboard should be the first screen after login"
        )
    }
}
