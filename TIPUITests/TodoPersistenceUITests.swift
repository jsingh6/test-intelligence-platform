import XCTest

// @test-ids: PR1-B005-TC01, PR1-B005-TC02, PR1-B005-TC03, PR1-B005-TC04
final class TodoPersistenceUITests: TIPUITestCase {

    // Helper: add a todo, terminate the app, relaunch (no state reset), log in again.
    // Returns a new XCUIApplication for assertions in the fresh session.
    private func addTodoThenRelaunch(title: String, priority: String) -> XCUIApplication {
        loginToTodos()
        addTodo(title: title, priority: priority)

        let freshApp = relaunchKeepingData()
        // Log in again (auth session does not persist across relaunches)
        let loginOnFresh = LoginScreen(app: freshApp)
        loginOnFresh.login()
        // Navigate to Todos
        freshApp.tabBars.buttons["Todos"].tap()
        return freshApp
    }

    // PR1-B005-TC01 — High priority persists after app restart
    func testHighPriorityPersistsAfterRestart__PR1_B005_TC01() {
        let freshApp = addTodoThenRelaunch(title: "Persist High", priority: "High")

        let badge = freshApp.staticTexts.matching(identifier: "badge-high").firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3),
                      "High priority badge should survive app termination and relaunch")
    }

    // PR1-B005-TC02 — Medium priority persists after app restart
    func testMediumPriorityPersistsAfterRestart__PR1_B005_TC02() {
        let freshApp = addTodoThenRelaunch(title: "Persist Medium", priority: "Medium")

        let badge = freshApp.staticTexts.matching(identifier: "badge-medium").firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3),
                      "Medium priority badge should survive app termination and relaunch")
    }

    // PR1-B005-TC03 — Low priority persists after app restart
    func testLowPriorityPersistsAfterRestart__PR1_B005_TC03() {
        let freshApp = addTodoThenRelaunch(title: "Persist Low", priority: "Low")

        let badge = freshApp.staticTexts.matching(identifier: "badge-low").firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3),
                      "Low priority badge should survive app termination and relaunch")
    }

    // PR1-B005-TC04 — Updated priority (changed via edit) persists after restart
    func testUpdatedPriorityPersistsAfterRestart__PR1_B005_TC04() {
        loginToTodos()
        addTodo(title: "Edit Then Restart", priority: "Low")

        // Edit: change priority from Low → High
        let pencil = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'edit-'")).firstMatch
        XCTAssertTrue(pencil.waitForExistence(timeout: 3), "Edit button not found in row")
        pencil.tap()
        addEditScreen.selectPriority("High").save()

        // Relaunch and verify
        let freshApp = relaunchKeepingData()
        LoginScreen(app: freshApp).login()
        freshApp.tabBars.buttons["Todos"].tap()

        let badge = freshApp.staticTexts.matching(identifier: "badge-high").firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3),
                      "Updated High priority should survive termination and relaunch")
    }
}
