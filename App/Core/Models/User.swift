import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let displayName: String

    init(id: UUID = UUID(), email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}
