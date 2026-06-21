import XCTest

struct TodoAddEditScreen {
    let app: XCUIApplication

    var titleField: XCUIElement    { app.textFields["title-field"] }
    var notesField: XCUIElement    { app.textFields["notes-field"] }
    // Use firstMatch — XCUITest subscript matches by label, not identifier,
    // and SwiftUI does not propagate accessibilityIdentifier as the label on Picker.
    var priorityPicker: XCUIElement { app.segmentedControls.firstMatch }
    var saveButton: XCUIElement    { app.buttons["Save"] }
    var cancelButton: XCUIElement  { app.buttons["Cancel"] }

    func waitForAppearance() {
        XCTAssertTrue(titleField.waitForExistence(timeout: 3), "Add/Edit form did not appear")
    }

    @discardableResult
    func enterTitle(_ title: String) -> Self {
        waitForAppearance()
        titleField.tap()
        titleField.typeText(title)
        return self
    }

    @discardableResult
    func enterNotes(_ notes: String) -> Self {
        notesField.tap()
        notesField.typeText(notes)
        return self
    }

    @discardableResult
    func selectPriority(_ priority: String) -> Self {
        XCTAssertTrue(priorityPicker.waitForExistence(timeout: 3))
        priorityPicker.buttons[priority].tap()
        return self
    }

    func selectedPriority() -> String? {
        _ = priorityPicker.waitForExistence(timeout: 3)
        for label in ["Low", "Medium", "High"] {
            if priorityPicker.buttons[label].isSelected { return label }
        }
        return nil
    }

    func isPriorityPickerVisible() -> Bool {
        priorityPicker.waitForExistence(timeout: 3)
    }

    func save() {
        saveButton.tap()
    }

    func cancel() {
        cancelButton.tap()
    }
}
