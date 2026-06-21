import XCTest

struct TodoListScreen {
    let app: XCUIApplication

    var list: XCUIElement { app.collectionViews.firstMatch }

    @discardableResult
    func navigate() -> Self {
        // Use index-based tab selection (position 1 = Todos) rather than label
        // matching, which can be brittle across iOS versions and locales.
        let todosTab = app.tabBars.firstMatch.buttons.element(boundBy: 1)
        XCTAssertTrue(todosTab.waitForExistence(timeout: 5), "Todos tab button not found")
        todosTab.tap()

        // Verify navigation completed — retry once if the tap didn't register
        // (can happen if the previous tab's transition was still in flight)
        if !app.navigationBars["Todos"].waitForExistence(timeout: 5) {
            todosTab.tap()
            XCTAssertTrue(
                app.navigationBars["Todos"].waitForExistence(timeout: 8),
                "Todos navigation bar did not appear after two tap attempts"
            )
        }
        return self
    }

    @discardableResult
    func tapAdd() -> TodoAddEditScreen {
        // The "+" button is the only button in the Todos nav bar
        let addBtn = app.navigationBars["Todos"].buttons.firstMatch
        XCTAssertTrue(addBtn.waitForExistence(timeout: 5), "Add (+) button not found in nav bar")
        addBtn.tap()
        return TodoAddEditScreen(app: app)
    }

    func rowCount() -> Int {
        list.cells.count
    }

    func hasBadge(priority: String) -> Bool {
        // Match by visible label text — more reliable than accessibilityIdentifier
        // on a Text view inside .clipShape() which may not surface to the a11y tree.
        let label = priority.prefix(1).uppercased() + priority.dropFirst().lowercased()
        return app.staticTexts[label].waitForExistence(timeout: 5)
    }

    func rowWithTitle(_ title: String) -> XCUIElement {
        app.staticTexts[title]
    }
}
