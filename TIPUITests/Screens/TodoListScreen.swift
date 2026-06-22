import XCTest

struct TodoListScreen {
    let app: XCUIApplication

    var list: XCUIElement { app.collectionViews.firstMatch }

    @discardableResult
    func navigate() -> Self {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar not found")

        // iOS 17+ VoiceOver labels tab buttons as "Todos, tab 2 of 3" not just "Todos",
        // so exact-match subscript and boundBy-index are both unreliable.
        // CONTAINS predicate handles both short and long label forms.
        let todosBtn = tabBar.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Todos'")
        ).firstMatch
        XCTAssertTrue(todosBtn.waitForExistence(timeout: 10), "Todos tab button not found")
        todosBtn.tap()

        XCTAssertTrue(
            app.navigationBars["Todos"].waitForExistence(timeout: 10),
            "Todos navigation bar did not appear after tapping Todos tab"
        )
        return self
    }

    @discardableResult
    func tapAdd() -> TodoAddEditScreen {
        let addBtn = app.navigationBars["Todos"].buttons.firstMatch
        XCTAssertTrue(addBtn.waitForExistence(timeout: 5), "Add (+) button not found in Todos nav bar")
        addBtn.tap()
        return TodoAddEditScreen(app: app)
    }

    func rowCount() -> Int {
        list.cells.count
    }

    func hasBadge(priority: String) -> Bool {
        // Match by the badge's visible text — Text inside .clipShape() does not
        // reliably surface accessibilityIdentifier as a queryable staticText node.
        let label = priority.prefix(1).uppercased() + priority.dropFirst().lowercased()
        return app.staticTexts[label].waitForExistence(timeout: 5)
    }

    func hasBadgeIn(_ otherApp: XCUIApplication, priority: String) -> Bool {
        let label = priority.prefix(1).uppercased() + priority.dropFirst().lowercased()
        return otherApp.staticTexts[label].waitForExistence(timeout: 5)
    }

    func rowWithTitle(_ title: String) -> XCUIElement {
        app.staticTexts[title]
    }
}
