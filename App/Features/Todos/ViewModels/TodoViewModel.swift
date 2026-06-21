import Foundation

// @test-ids: TODO-001, TODO-002, TODO-003, TODO-004
@MainActor
final class TodoViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var editingTodo: Todo?
    @Published var isShowingAddSheet = false

    private let storageKey = "tip.todos"

    init() { load() }

    func add(title: String, notes: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        todos.append(Todo(title: title, notes: notes))
        save()
    }

    func update(_ todo: Todo) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index] = todo
        save()
    }

    func delete(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
        save()
    }

    func toggleCompletion(for todo: Todo) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isCompleted.toggle()
        save()
    }

    func beginEditing(_ todo: Todo) {
        editingTodo = todo
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(todos) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Todo].self, from: data)
        else { return }
        todos = decoded
    }
}
