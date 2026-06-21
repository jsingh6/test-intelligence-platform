import Foundation

// @test-ids: DASH-001
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var greeting = ""
    @Published var stats: DashboardStats = .empty

    struct DashboardStats {
        let totalTodos: Int
        let completedTodos: Int

        static let empty = DashboardStats(totalTodos: 0, completedTodos: 0)
    }

    func load(user: User?, todos: [Todo]) {
        let name = user?.displayName ?? "there"
        greeting = "Hello, \(name)"
        stats = DashboardStats(
            totalTodos: todos.count,
            completedTodos: todos.filter(\.isCompleted).count
        )
    }
}
