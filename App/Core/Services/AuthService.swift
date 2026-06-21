import Foundation
import Combine

// @test-ids: AUTH-TC001, AUTH-TC002, AUTH-TC003
final class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    func login(email: String, password: String) async throws {
        // Stub: replace with real auth call
        let user = User(email: email, displayName: email.components(separatedBy: "@").first ?? email)
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
    }
}
