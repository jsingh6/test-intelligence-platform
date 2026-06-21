import SwiftUI

// @test-ids: PR1-B003-TC01, PR1-B003-TC02, PR1-B006-TC01, PR1-B006-TC02
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
                TodoAddEditView(mode: .add) { title, notes, priority in
                    viewModel.add(title: title, notes: notes, priority: priority)
                }
            }
            .sheet(item: $viewModel.editingTodo) { todo in
                TodoAddEditView(mode: .edit(todo)) { title, notes, priority in
                    var updated = todo
                    updated.title = title
                    updated.notes = notes
                    updated.priority = priority
                    viewModel.update(updated)
                }
            }
        }
    }
}

private struct PriorityBadge: View {
    let priority: Todo.Priority

    var color: Color {
        switch priority {
        case .low:    return .gray
        case .medium: return .orange
        case .high:   return .red
        }
    }

    var body: some View {
        Text(priority.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
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
                HStack(spacing: 6) {
                    PriorityBadge(priority: todo.priority)
                    if !todo.notes.isEmpty {
                        Text(todo.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
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
