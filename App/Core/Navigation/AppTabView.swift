import SwiftUI

struct AppTabView: View {
    @StateObject private var todoViewModel = TodoViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

            TodoListView()
                .tabItem {
                    Label("Todos", systemImage: "checklist")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(todoViewModel)
    }
}
