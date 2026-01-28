import Foundation
import SwiftData

// MARK: - Persistent Task Model (SwiftData)

@Model
final class PersistentTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String
    var isCompleted: Bool
    var dueDate: Date?
    var reminderDate: Date?
    var priorityRaw: String
    var createdAt: Date
    var completedAt: Date?
    var isAIGenerated: Bool

    @Relationship(deleteRule: .cascade, inverse: \PersistentSubTask.task)
    var subtasks: [PersistentSubTask]

    var priority: TodoTask.Priority {
        get { TodoTask.Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        priority: TodoTask.Priority = .medium,
        subtasks: [PersistentSubTask] = [],
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        isAIGenerated: Bool = false
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.priorityRaw = priority.rawValue
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

// MARK: - Persistent SubTask Model

@Model
final class PersistentSubTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var estimatedMinutes: Int?
    var completedAt: Date?

    var task: PersistentTask?

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

// MARK: - Conversion Extensions

extension PersistentTask {
    @MainActor
    func toTodoTask() -> TodoTask {
        let task = TodoTask(
            id: id,
            title: title,
            description: taskDescription,
            isCompleted: isCompleted,
            dueDate: dueDate,
            reminderDate: reminderDate,
            priority: priority,
            subtasks: subtasks.map { $0.toSubTask() },
            createdAt: createdAt,
            completedAt: completedAt,
            isAIGenerated: isAIGenerated
        )
        return task
    }

    @MainActor
    static func from(_ task: TodoTask) -> PersistentTask {
        PersistentTask(
            id: task.id,
            title: task.title,
            taskDescription: task.description,
            isCompleted: task.isCompleted,
            dueDate: task.dueDate,
            reminderDate: task.reminderDate,
            priority: task.priority,
            subtasks: task.subtasks.map { PersistentSubTask.from($0) },
            createdAt: task.createdAt,
            completedAt: task.completedAt,
            isAIGenerated: task.isAIGenerated
        )
    }

    @MainActor
    func update(from task: TodoTask) {
        title = task.title
        taskDescription = task.description
        isCompleted = task.isCompleted
        dueDate = task.dueDate
        reminderDate = task.reminderDate
        priority = task.priority
        completedAt = task.completedAt
    }
}

extension PersistentSubTask {
    @MainActor
    func toSubTask() -> SubTask {
        SubTask(
            id: id,
            title: title,
            isCompleted: isCompleted,
            estimatedMinutes: estimatedMinutes,
            completedAt: completedAt
        )
    }

    @MainActor
    static func from(_ subtask: SubTask) -> PersistentSubTask {
        PersistentSubTask(
            id: subtask.id,
            title: subtask.title,
            isCompleted: subtask.isCompleted,
            estimatedMinutes: subtask.estimatedMinutes,
            completedAt: subtask.completedAt
        )
    }
}
