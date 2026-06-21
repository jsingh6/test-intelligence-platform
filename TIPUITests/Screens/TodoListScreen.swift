import XCTest

struct TodoListScreen {
    let app: XCUIApplication

    var addButton: XCUIElement { app.buttons["add-todo-button"] }
    var list: XCUIElement      { app.collectionViews.firstMatch }

    @discardableResult
    func navigate() -> Self {
        app.tabBars.buttons["Todos"].tap()
        _ = addButton.waitForExistence(timeout: 3)
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
        app.staticTexts
            .matching(identifier: "badge-\(priority.lowercased())")
            .firstMatch
            .waitForExistence(timeout: 2)
    }

    func rowWithTitle(_ title: String) -> XCUIElement {
        app.staticTexts[title]
    }
}
