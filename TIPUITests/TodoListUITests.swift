import XCTest

// @test-ids: PR1-B003-TC01, PR1-B003-TC02, PR1-B003-TC03, PR1-B006-TC01
final class TodoListUITests: TIPUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        loginToTodos()
    }

    // PR1-B003-TC01 — Low priority todo shows gray "Low" pill badge
    func testLowPriorityTodoShowsLowBadge__PR1_B003_TC01() {
        addTodo(title: "Low Task", priority: "Low")

        XCTAssertTrue(todoListScreen.hasBadge(priority: "low"),
                      "A Low badge should appear in the list after adding a low-priority todo")
    }

    // PR1-B003-TC02 — Medium priority todo shows orange "Medium" pill badge
    func testMediumPriorityTodoShowsMediumBadge__PR1_B003_TC02() {
        addTodo(title: "Medium Task", priority: "Medium")

        XCTAssertTrue(todoListScreen.hasBadge(priority: "medium"),
                      "A Medium badge should appear in the list after adding a medium-priority todo")
    }

    // PR1-B003-TC03 — High priority todo shows red "High" pill badge
    func testHighPriorityTodoShowsHighBadge__PR1_B003_TC03() {
        addTodo(title: "High Task", priority: "High")

        XCTAssertTrue(todoListScreen.hasBadge(priority: "high"),
                      "A High badge should appear in the list after adding a high-priority todo")
    }

    // PR1-B006-TC01 — Long notes text is clamped to one line next to the priority badge
    func testLongNotesAreTruncatedToSingleLine__PR1_B006_TC01() {
        let longNotes = String(repeating: "This is a very long note. ", count: 10)
        addTodo(title: "Task With Notes", priority: "High", notes: longNotes)

        let row = todoListScreen.rowWithTitle("Task With Notes")
        XCTAssertTrue(row.waitForExistence(timeout: 3),
                      "Todo row should appear in the list")

        // Notes cell must not overflow — the row height should be compact (< 80pt)
        XCTAssertLessThan(row.frame.height, 80,
                          "Row with truncated notes should stay compact")
    }
}
