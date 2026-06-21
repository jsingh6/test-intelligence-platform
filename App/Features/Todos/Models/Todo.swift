import Foundation

// @test-ids: TODO-001, TODO-002
struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, notes: String = "", isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}
