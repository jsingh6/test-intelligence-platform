import XCTest

struct TodoListScreen {
    let app: XCUIApplication

    var addButton: XCUIElement { app.buttons["add-todo-button"] }
    var list: XCUIElement      { app.collectionViews.firstMatch }

    @discardableResult
    func navigate() -> Self {
        app.tabBars.buttons["Todos"].tap()
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Todos tab did not load — add button not found")
        return self
    }

    @discardableResult
    func tapAdd() -> TodoAddEditScreen {
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
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
