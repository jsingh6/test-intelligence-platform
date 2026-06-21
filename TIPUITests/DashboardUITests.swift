import XCTest

// @test-ids: PR1-B004-TC01, PR1-B004-TC02
final class DashboardUITests: TIPUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        loginToDashboard()
    }

    // PR1-B004-TC01 — High Priority stat reflects correct count of incomplete high-priority todos
    func testHighPriorityStatShowsCorrectCount__PR1_B004_TC01() {
        // Baseline: 0 high-priority todos
        let dash = dashboardScreen.navigate()
        XCTAssertEqual(dash.highPriorityCount(), 0,
                       "High Priority count should start at 0 on a clean slate")

        // Add one high and one low — only the high should count
        todoListScreen.navigate()
        addTodo(title: "High One", priority: "High")
        addTodo(title: "Low One",  priority: "Low")

        dash.navigate()
        XCTAssertEqual(dash.highPriorityCount(), 1,
                       "High Priority count should be 1 after adding one High-priority todo")
    }

    // PR1-B004-TC02 — High Priority count updates immediately when a high-priority todo is completed
    func testHighPriorityCountDropsWhenTodoCompleted__PR1_B004_TC02() {
        todoListScreen.navigate()
        addTodo(title: "Complete Me", priority: "High")

        let dash = dashboardScreen.navigate()
        XCTAssertEqual(dash.highPriorityCount(), 1,
                       "Count should be 1 before completing the todo")

        // Complete the todo by tapping its circle button
        todoListScreen.navigate()
        let circleButton = app.buttons.matching(NSPredicate(format: "label == 'circle'")).firstMatch
        XCTAssertTrue(circleButton.waitForExistence(timeout: 3))
        circleButton.tap()

        dash.navigate()
        XCTAssertEqual(dash.highPriorityCount(), 0,
                       "High Priority count should drop to 0 after completing the high-priority todo")
    }
}
