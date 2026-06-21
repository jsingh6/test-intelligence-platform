import SwiftUI

@main
struct TIPApp: App {
    @StateObject private var authService = AuthService()

    init() {
        if CommandLine.arguments.contains("--uitesting") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        }
    }

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                AppTabView()
                    .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
