import XCTest
@testable import TIP

final class TIPTests: XCTestCase {

    // @tc-id: AUTH-TC002
    @MainActor
    func testLoginValidationRejectsEmptyCredentials() async {
        let vm = LoginViewModel()
        let auth = AuthService()
        await vm.login(using: auth)
        XCTAssertNotNil(vm.errorMessage)
    }

    // @tc-id: TODO-TC001
    @MainActor
    func testAddTodoAppendsTodoToList() {
        let vm = TodoViewModel()
        vm.add(title: "Buy milk", notes: "")
        XCTAssertEqual(vm.todos.count, 1)
        XCTAssertEqual(vm.todos[0].title, "Buy milk")
    }

    // @tc-id: TODO-TC002
    @MainActor
    func testAddTodoWithEmptyTitleIsIgnored() {
        let vm = TodoViewModel()
        vm.add(title: "   ", notes: "")
        XCTAssertTrue(vm.todos.isEmpty)
    }

    // @tc-id: TODO-TC003
    @MainActor
    func testToggleCompletionFlipsIsCompleted() {
        let vm = TodoViewModel()
        vm.add(title: "Task", notes: "")
        let todo = vm.todos[0]
        vm.toggleCompletion(for: todo)
        XCTAssertTrue(vm.todos[0].isCompleted)
    }
}
