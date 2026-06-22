import XCTest

struct TodoAddEditScreen {
    let app: XCUIApplication

    var titleField: XCUIElement    { app.textFields["title-field"] }
    var notesField: XCUIElement    { app.textViews["notes-field"].exists
                                        ? app.textViews["notes-field"]
                                        : app.textFields["notes-field"] }
    // Use firstMatch — XCUITest subscript matches by label, not identifier,
    // and SwiftUI does not propagate accessibilityIdentifier as the label on Picker.
    var priorityPicker: XCUIElement { app.segmentedControls.firstMatch }
    var saveButton: XCUIElement    { app.buttons["Save"] }
    var cancelButton: XCUIElement  { app.buttons["Cancel"] }

    func waitForAppearance() {
        XCTAssertTrue(titleField.waitForExistence(timeout: 8), "Add/Edit form did not appear within 8s")
    }

    @discardableResult
    func enterTitle(_ title: String) -> Self {
        waitForAppearance()
        titleField.tap()
        // Wait for keyboard — sheet animation may still be running when field exists
        if !app.keyboards.firstMatch.waitForExistence(timeout: 5) {
            titleField.tap()
            _ = app.keyboards.firstMatch.waitForExistence(timeout: 3)
        }
        titleField.typeText(title)
        // Dismiss keyboard via Return so the picker and Save are not obscured.
        // The title TextField has .onSubmit { } which makes Return dismiss keyboard.
        titleField.typeText("\n")
        return self
    }

    @discardableResult
    func enterNotes(_ notes: String) -> Self {
        let field = notesField
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Notes field not found")
        field.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 3)
        field.typeText(notes)
        return self
    }

    @discardableResult
    func selectPriority(_ priority: String) -> Self {
        XCTAssertTrue(priorityPicker.waitForExistence(timeout: 5), "Priority picker not found")
        priorityPicker.buttons[priority].tap()
        return self
    }

    func selectedPriority() -> String? {
        _ = priorityPicker.waitForExistence(timeout: 5)
        for label in ["Low", "Medium", "High"] {
            if priorityPicker.buttons[label].isSelected { return label }
        }
        return nil
    }

    func isPriorityPickerVisible() -> Bool {
        priorityPicker.waitForExistence(timeout: 5)
    }

    func save() {
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button not found")
        // Fail fast if title is empty — a disabled Save means enterTitle didn't work
        XCTAssertTrue(saveButton.isEnabled, "Save button is disabled — title field may be empty or untouched")
        saveButton.tap()
    }

    func cancel() {
        cancelButton.tap()
    }
}
