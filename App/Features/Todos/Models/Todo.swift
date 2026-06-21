import Foundation

// @test-ids: TODO-001, TODO-002
struct Todo: Identifiable, Codable, Equatable {
    enum Priority: String, Codable, CaseIterable {
        case low, medium, high

        var label: String { rawValue.capitalized }
        var color: String {
            switch self {
            case .low:    return "gray"
            case .medium: return "orange"
            case .high:   return "red"
            }
        }
    }

    let id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var priority: Priority
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        priority: Priority = .medium
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = Date()
    }
}
