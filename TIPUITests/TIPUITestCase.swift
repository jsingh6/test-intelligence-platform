import XCTest

// Base class for all TIP UI tests.
// Launches with --uitesting to wipe UserDefaults before each test,
// so every test starts from a fully clean state.
class TIPUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Screen accessors

    var loginScreen: LoginScreen       { LoginScreen(app: app) }
    var dashboardScreen: DashboardScreen { DashboardScreen(app: app) }
    var todoListScreen: TodoListScreen { TodoListScreen(app: app) }
    var addEditScreen: TodoAddEditScreen { TodoAddEditScreen(app: app) }

    // MARK: - Shared flows

    /// Login and land on Dashboard (default first tab).
    @discardableResult
    func loginToDashboard() -> DashboardScreen {
        return loginScreen.login()
    }

    /// Login then switch to the Todos tab.
    @discardableResult
    func loginToTodos() -> TodoListScreen {
        loginToDashboard()
        return todoListScreen.navigate()
    }

    /// Add a single todo from the Todos tab.
    /// Caller must already be on the Todos tab.
    @discardableResult
    func addTodo(title: String, priority: String = "Medium", notes: String = "") -> TodoListScreen {
        let form = todoListScreen.tapAdd().enterTitle(title)
        if !notes.isEmpty { _ = form.enterNotes(notes) }
        if priority != "Medium" { _ = form.selectPriority(priority) }
        form.save()
        return todoListScreen
    }

    /// Relaunch the app WITHOUT resetting state (for persistence tests).
    func relaunchKeepingData() -> XCUIApplication {
        app.terminate()
        let fresh = XCUIApplication()
        fresh.launchArguments = []
        fresh.launch()
        return fresh
    }
}
