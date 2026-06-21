import SwiftUI

// @test-ids: DASH-001
struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var todoViewModel: TodoViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(authService.currentUser?.displayName ?? "there")")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Here's your overview")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Stats") {
                    StatRow(label: "Total Todos", value: "\(todoViewModel.todos.count)")
                    StatRow(label: "Completed", value: "\(todoViewModel.todos.filter(\.isCompleted).count)")
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
