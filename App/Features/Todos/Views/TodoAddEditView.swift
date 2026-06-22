import SwiftUI

// @test-ids: PR1-B001-TC01, PR1-B001-TC02, PR1-B001-TC03, PR1-B002-TC01, PR1-B002-TC02
struct TodoAddEditView: View {
    enum Mode {
        case add
        case edit(Todo)
    }

    let mode: Mode
    let onSave: (String, String, Todo.Priority) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var notes: String
    @State private var priority: Todo.Priority

    init(mode: Mode, onSave: @escaping (String, String, Todo.Priority) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .edit(let todo) = mode {
            _title    = State(initialValue: todo.title)
            _notes    = State(initialValue: todo.notes)
            _priority = State(initialValue: todo.priority)
        } else {
            _title    = State(initialValue: "")
            _notes    = State(initialValue: "")
            _priority = State(initialValue: .medium)
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
                        .accessibilityIdentifier("title-field")
                        .onSubmit { }  // allows Return key to dismiss keyboard
                }
                Section("Notes") {
                    TextField("Additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("notes-field")
                }
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Todo.Priority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("priority-picker")
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
                        onSave(title, notes, priority)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
