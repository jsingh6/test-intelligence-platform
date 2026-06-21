import XCTest

class TIPUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.terminate()                          // kill any lingering session
        app.launchArguments = ["--uitesting"]    // clears UserDefaults on launch
        app.launch()

        // Gate 1: app process is running in the foreground
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 15),
            "App did not reach runningForeground state within 15s"
        )

        // Gate 2: login screen is interactive (not just launched)
        XCTAssertTrue(
            app.textFields["email-field"].waitForExistence(timeout: 15),
            "Login screen email field did not appear within 15s"
        )
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    // MARK: - Screen accessors

    var loginScreen: LoginScreen         { LoginScreen(app: app) }
    var dashboardScreen: DashboardScreen { DashboardScreen(app: app) }
    var todoListScreen: TodoListScreen   { TodoListScreen(app: app) }
    var addEditScreen: TodoAddEditScreen { TodoAddEditScreen(app: app) }

    // MARK: - Shared flows

    @discardableResult
    func loginToDashboard() -> DashboardScreen {
        let dash = loginScreen.login()
        // Wait for Dashboard content, not just the tab bar — ensures the app is
        // fully rendered before any subsequent navigation attempts.
        XCTAssertTrue(
            app.navigationBars["Dashboard"].waitForExistence(timeout: 10),
            "Dashboard navigation bar did not appear after login"
        )
        return dash
    }

    @discardableResult
    func loginToTodos() -> TodoListScreen {
        loginToDashboard()
        return todoListScreen.navigate()
    }

    @discardableResult
    func addTodo(title: String, priority: String = "Medium", notes: String = "") -> TodoListScreen {
        let form = todoListScreen.tapAdd().enterTitle(title)
        if !notes.isEmpty { _ = form.enterNotes(notes) }
        if priority != "Medium" { _ = form.selectPriority(priority) }
        form.save()
        // Wait for the sheet to fully dismiss before returning
        XCTAssertTrue(
            app.navigationBars["Todos"].waitForExistence(timeout: 5),
            "Todos screen did not return after saving todo"
        )
        return todoListScreen
    }

    func relaunchKeepingData() -> XCUIApplication {
        app.terminate()
        let fresh = XCUIApplication()
        fresh.launchArguments = []
        fresh.launch()
        XCTAssertTrue(fresh.wait(for: .runningForeground, timeout: 15),
                      "Fresh app did not reach runningForeground")
        XCTAssertTrue(fresh.textFields["email-field"].waitForExistence(timeout: 15),
                      "Login screen did not appear after relaunch")
        return fresh
    }
}
