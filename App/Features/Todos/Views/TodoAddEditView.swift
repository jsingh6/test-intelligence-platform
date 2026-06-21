import SwiftUI

// @test-ids: TODO-002, TODO-004
struct TodoAddEditView: View {
    enum Mode {
        case add
        case edit(Todo)
    }

    let mode: Mode
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var notes: String

    init(mode: Mode, onSave: @escaping (String, String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .edit(let todo) = mode {
            _title = State(initialValue: todo.title)
            _notes = State(initialValue: todo.notes)
        } else {
            _title = State(initialValue: "")
            _notes = State(initialValue: "")
        }
    }

    var navigationTitle: String {
        if case .edit = mode { return "Edit Todo" }
        return "New Todo"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("What needs to be done?", text: $title)
                }
                Section("Notes") {
                    TextField("Additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, notes)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
