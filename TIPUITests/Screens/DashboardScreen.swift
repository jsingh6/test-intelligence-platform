import XCTest

struct DashboardScreen {
    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Dashboard"].firstMatch }
    var highPriorityStat: XCUIElement { app.staticTexts["stat-high-priority"] }
    var totalStat: XCUIElement        { app.staticTexts["stat-total"] }
    var completedStat: XCUIElement    { app.staticTexts["stat-completed"] }

    func isVisible() -> Bool {
        app.tabBars.buttons["Dashboard"].isSelected
    }

    @discardableResult
    func navigate() -> Self {
        app.tabBars.buttons["Dashboard"].tap()
        _ = highPriorityStat.waitForExistence(timeout: 3)
        return self
    }

    func highPriorityCount() -> Int {
        _ = highPriorityStat.waitForExistence(timeout: 3)
        return Int(highPriorityStat.label) ?? 0
    }

    func totalCount() -> Int {
        _ = totalStat.waitForExistence(timeout: 3)
        return Int(totalStat.label) ?? 0
    }
}
