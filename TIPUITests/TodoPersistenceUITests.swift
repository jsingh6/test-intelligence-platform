import XCTest

// @test-ids: PR1-B005-TC01, PR1-B005-TC02, PR1-B005-TC03, PR1-B005-TC04
final class TodoPersistenceUITests: TIPUITestCase {

    // Add a todo, kill the app, relaunch without resetting state, log in again.
    // Returns the fresh XCUIApplication for badge assertions.
    private func addTodoThenRelaunch(title: String, priority: String) -> XCUIApplication {
        loginToTodos()
        addTodo(title: title, priority: priority)

        let freshApp = relaunchKeepingData()
        LoginScreen(app: freshApp).login()
        // Wait for Dashboard to confirm login completed on the fresh session
        XCTAssertTrue(
            freshApp.navigationBars["Dashboard"].waitForExistence(timeout: 10),
            "Dashboard did not appear after relaunch login"
        )
        // Navigate to Todos using CONTAINS predicate (same strategy as TodoListScreen)
        let tabBar = freshApp.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar not found after relaunch")
        let todosBtn = tabBar.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Todos'")
        ).firstMatch
        XCTAssertTrue(todosBtn.waitForExistence(timeout: 10), "Todos tab not found after relaunch")
        todosBtn.tap()
        XCTAssertTrue(
            freshApp.navigationBars["Todos"].waitForExistence(timeout: 10),
            "Todos screen did not load after relaunch"
        )
        return freshApp
    }

    // PR1-B005-TC01 — High priority persists after app restart
    func testHighPriorityPersistsAfterRestart__PR1_B005_TC01() {
        let freshApp = addTodoThenRelaunch(title: "Persist High", priority: "High")
        XCTAssertTrue(freshApp.staticTexts["High"].waitForExistence(timeout: 5),
                      "High priority badge should survive app termination and relaunch")
    }

    // PR1-B005-TC02 — Medium priority persists after app restart
    func testMediumPriorityPersistsAfterRestart__PR1_B005_TC02() {
        let freshApp = addTodoThenRelaunch(title: "Persist Medium", priority: "Medium")
        XCTAssertTrue(freshApp.staticTexts["Medium"].waitForExistence(timeout: 5),
                      "Medium priority badge should survive app termination and relaunch")
    }

    // PR1-B005-TC03 — Low priority persists after app restart
    func testLowPriorityPersistsAfterRestart__PR1_B005_TC03() {
        let freshApp = addTodoThenRelaunch(title: "Persist Low", priority: "Low")
        XCTAssertTrue(freshApp.staticTexts["Low"].waitForExistence(timeout: 5),
                      "Low priority badge should survive app termination and relaunch")
    }

    // PR1-B005-TC04 — Updated priority (changed via edit) persists after restart
    func testUpdatedPriorityPersistsAfterRestart__PR1_B005_TC04() {
        loginToTodos()
        addTodo(title: "Edit Then Restart", priority: "Low")

        // Edit: change Low → High
        let pencil = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'edit-'")
        ).firstMatch
        XCTAssertTrue(pencil.waitForExistence(timeout: 5), "Edit button not found")
        pencil.tap()
        addEditScreen.selectPriority("High").save()

        // Relaunch and verify High badge persists
        let freshApp = relaunchKeepingData()
        LoginScreen(app: freshApp).login()
        XCTAssertTrue(
            freshApp.navigationBars["Dashboard"].waitForExistence(timeout: 10),
            "Dashboard did not appear after relaunch"
        )
        let todosBtn = freshApp.tabBars.firstMatch.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Todos'")
        ).firstMatch
        XCTAssertTrue(todosBtn.waitForExistence(timeout: 10), "Todos tab not found")
        todosBtn.tap()
        XCTAssertTrue(
            freshApp.navigationBars["Todos"].waitForExistence(timeout: 10),
            "Todos screen did not load"
        )
        XCTAssertTrue(freshApp.staticTexts["High"].waitForExistence(timeout: 5),
                      "Updated High priority should survive termination and relaunch")
    }
}
