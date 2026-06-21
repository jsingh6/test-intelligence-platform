import XCTest

// @test-ids: PR1-B001-TC01, PR1-B001-TC02, PR1-B001-TC03, PR1-B001-TC04,
//            PR1-B002-TC01, PR1-B002-TC02
final class TodoAddEditUITests: TIPUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        loginToTodos()
    }

    // PR1-B001-TC01 — Add form shows segmented picker with Low/Medium/High, default Medium
    func testAddFormShowsPriorityPickerDefaultsMedium__PR1_B001_TC01() {
        let form = todoListScreen.tapAdd()

        XCTAssertTrue(form.isPriorityPickerVisible(),
                      "Priority segmented control must be visible in the add form")
        XCTAssertTrue(form.priorityPicker.buttons["Low"].exists,    "Low segment missing")
        XCTAssertTrue(form.priorityPicker.buttons["Medium"].exists, "Medium segment missing")
        XCTAssertTrue(form.priorityPicker.buttons["High"].exists,   "High segment missing")
        XCTAssertEqual(form.selectedPriority(), "Medium",
                       "Medium should be the default selection")
    }

    // PR1-B001-TC02 — User can select Low priority and the saved todo shows a Low badge
    // Note: checking isSelected on SwiftUI segmented buttons is unreliable (accessibility
    // state may lag). Verify via the visible outcome (badge in list) instead.
    func testSelectLowPriorityInAddForm__PR1_B001_TC02() {
        todoListScreen
            .tapAdd()
            .enterTitle("Low Priority Task")
            .selectPriority("Low")
            .save()

        XCTAssertTrue(todoListScreen.hasBadge(priority: "low"),
                      "Low segment should be selected — saved todo must show a Low badge")
    }

    // PR1-B001-TC03 — User can select High priority and the saved todo shows a High badge
    func testSelectHighPriorityInAddForm__PR1_B001_TC03() {
        todoListScreen
            .tapAdd()
            .enterTitle("High Priority Task")
            .selectPriority("High")
            .save()

        XCTAssertTrue(todoListScreen.hasBadge(priority: "high"),
                      "High segment should be selected — saved todo must show a High badge")
    }

    // PR1-B001-TC04 — Selected priority is persisted when form is saved
    func testSelectedPriorityIsSavedOnSubmit__PR1_B001_TC04() {
        addTodo(title: "High Task", priority: "High")

        XCTAssertTrue(todoListScreen.hasBadge(priority: "high"),
                      "High priority badge should appear on the saved todo row")
    }

    // PR1-B002-TC01 — Edit form pre-selects existing todo's priority
    func testEditFormPreSelectsCurrentPriority__PR1_B002_TC01() {
        addTodo(title: "Low Task", priority: "Low")

        // Pencil buttons are identified as "edit-<uuid>" — grab the first one
        let pencilButton = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'edit-'")).firstMatch
        XCTAssertTrue(pencilButton.waitForExistence(timeout: 3), "Edit button not found in row")
        pencilButton.tap()

        let form = addEditScreen
        XCTAssertTrue(form.isPriorityPickerVisible())
        XCTAssertEqual(form.selectedPriority(), "Low",
                       "Edit form should pre-select the todo's current priority")
    }

    // PR1-B002-TC02 — Changing priority in edit form and saving persists new priority
    func testChangePriorityInEditFormPersists__PR1_B002_TC02() {
        addTodo(title: "Medium Task", priority: "Medium")

        let pencilButton = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'edit-'")).firstMatch
        XCTAssertTrue(pencilButton.waitForExistence(timeout: 3), "Edit button not found in row")
        pencilButton.tap()

        addEditScreen
            .selectPriority("High")
            .save()

        XCTAssertTrue(todoListScreen.hasBadge(priority: "high"),
                      "Badge should update to High after editing and saving")
    }
}
