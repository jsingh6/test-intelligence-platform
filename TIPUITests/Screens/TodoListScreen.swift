import XCTest

struct TodoListScreen {
    let app: XCUIApplication

    var addButton: XCUIElement { app.buttons["add-todo-button"] }
    var list: XCUIElement      { app.collectionViews.firstMatch }

    @discardableResult
    func navigate() -> Self {
        app.tabBars.buttons["Todos"].tap()
        // Wait for the Todos navigation bar — more reliable than the toolbar button
        // whose accessibilityIdentifier may not surface through SwiftUI's nav bar.
        XCTAssertTrue(
            app.navigationBars["Todos"].waitForExistence(timeout: 5),
            "Todos tab did not load"
        )
        return self
    }

    @discardableResult
    func tapAdd() -> TodoAddEditScreen {
        // The "+" toolbar button lives in the nav bar; find it as the sole button there.
        let addBtn = app.navigationBars["Todos"].buttons.firstMatch
        XCTAssertTrue(addBtn.waitForExistence(timeout: 3), "Add (+) button not found in nav bar")
        addBtn.tap()
        return TodoAddEditScreen(app: app)
    }

    func rowCount() -> Int {
        list.cells.count
    }

    func hasBadge(priority: String) -> Bool {
        // Text inside .clipShape() doesn't reliably surface accessibilityIdentifier
        // as a queryable staticText. Match by the visible label ("Low"/"Medium"/"High")
        // which is unique in the list once the add/edit sheet is dismissed.
        let label = priority.prefix(1).uppercased() + priority.dropFirst().lowercased()
        return app.staticTexts[label].waitForExistence(timeout: 3)
    }

    func rowWithTitle(_ title: String) -> XCUIElement {
        app.staticTexts[title]
    }
}
