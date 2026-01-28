import Foundation

// MARK: - TodoTask Model

@MainActor
@Observable
final class TodoTask: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var dueDate: Date?
    var reminderDate: Date?
    var priority: Priority
    var subtasks: [SubTask]
    var createdAt: Date
    var completedAt: Date?
    var isAIGenerated: Bool

    enum Priority: String, CaseIterable, Sendable {
        case high
        case medium
        case low

        var color: String {
            switch self {
            case .high: "#EF4444"
            case .medium: "#F59E0B"
            case .low: "#22C55E"
            }
        }

        var label: String {
            switch self {
            case .high: "High"
            case .medium: "Medium"
            case .low: "Low"
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        priority: Priority = .medium,
        subtasks: [SubTask] = [],
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        isAIGenerated: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.priority = priority
        self.subtasks = subtasks
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.isAIGenerated = isAIGenerated
    }

    var progress: Double {
        guard !subtasks.isEmpty else { return isCompleted ? 1.0 : 0.0 }
        let completed = subtasks.filter(\.isCompleted).count
        return Double(completed) / Double(subtasks.count)
    }

    var completedSubtasksCount: Int {
        subtasks.filter(\.isCompleted).count
    }
}

// MARK: - SubTask Model

@MainActor
@Observable
final class SubTask: Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var estimatedMinutes: Int?
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        estimatedMinutes: Int? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.estimatedMinutes = estimatedMinutes
        self.completedAt = completedAt
    }
}

// MARK: - AI Task Response

struct AITaskResponse: Sendable {
    let title: String
    let description: String?
    let dueDate: Date?
    let reminderDate: Date?
    let priority: TodoTask.Priority?
    let subtasks: [AISubtaskResponse]?
}

struct AISubtaskResponse: Sendable {
    let title: String
    let estimatedMinutes: Int?
}

// MARK: - Sample Data

extension TodoTask {
    @MainActor
    static let samples: [TodoTask] = [
        TodoTask(
            title: "Review project proposal",
            description: "Go through the Q1 project proposal and add comments",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            priority: .high
        ),
        {
            let task = TodoTask(
                title: "Buy groceries",
                description: "Weekly grocery shopping",
                isCompleted: true,
                priority: .low
            )
            task.completedAt = Date()
            return task
        }(),
        TodoTask(
            title: "Call mom for birthday",
            dueDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            reminderDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            priority: .medium
        ),
    ]

    @MainActor
    static let sampleWithSubtasks: TodoTask = {
        let task = TodoTask(
            title: "Plan and execute annual product launch event",
            description: "Coordinate with marketing team for the product launch",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            priority: .high,
            subtasks: [
                SubTask(title: "Research and book venue", isCompleted: true, estimatedMinutes: 120),
                SubTask(title: "Create marketing materials", isCompleted: true, estimatedMinutes: 180),
                SubTask(title: "Finalize guest list", isCompleted: true, estimatedMinutes: 60),
                SubTask(title: "Coordinate with catering team", estimatedMinutes: 90),
                SubTask(title: "Set up technical equipment", estimatedMinutes: 120),
            ],
            isAIGenerated: true
        )
        return task
    }()
}
