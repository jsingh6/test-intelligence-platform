import SwiftUI

// @test-ids: TODO-001, TODO-002, TODO-003
struct TodoListView: View {
    @EnvironmentObject private var viewModel: TodoViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.todos) { todo in
                    TodoRowView(todo: todo) {
                        viewModel.toggleCompletion(for: todo)
                    } onEdit: {
                        viewModel.beginEditing(todo)
                    }
                }
                .onDelete(perform: viewModel.delete)
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                TodoAddEditView(mode: .add) { title, notes in
                    viewModel.add(title: title, notes: notes)
                }
            }
            .sheet(item: $viewModel.editingTodo) { todo in
                TodoAddEditView(mode: .edit(todo)) { title, notes in
                    var updated = todo
                    updated.title = title
                    updated.notes = notes
                    viewModel.update(updated)
                }
            }
        }
    }
}

private struct TodoRowView: View {
    let todo: Todo
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
