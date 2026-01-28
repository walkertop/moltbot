import Foundation
import SwiftData

// MARK: - Data Store Service

@MainActor
@Observable
final class DataStore {
    static let shared = DataStore()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    private init() {}

    // MARK: - Setup

    func setup() throws {
        let schema = Schema([
            PersistentTask.self,
            PersistentSubTask.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = modelContainer?.mainContext
    }

    // MARK: - Task Operations

    func fetchAllTasks() -> [TodoTask] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<PersistentTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let persistentTasks = try context.fetch(descriptor)
            return persistentTasks.map { $0.toTodoTask() }
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }

    func saveTask(_ task: TodoTask) {
        guard let context = modelContext else { return }

        // Check if task already exists
        let taskId = task.id
        let descriptor = FetchDescriptor<PersistentTask>(
            predicate: #Predicate { $0.id == taskId }
        )

        do {
            let existing = try context.fetch(descriptor)
            if let existingTask = existing.first {
                existingTask.update(from: task)
                // Update subtasks
                for subtask in task.subtasks {
                    if let existingSubtask = existingTask.subtasks.first(where: { $0.id == subtask.id }) {
                        existingSubtask.title = subtask.title
                        existingSubtask.isCompleted = subtask.isCompleted
                        existingSubtask.estimatedMinutes = subtask.estimatedMinutes
                        existingSubtask.completedAt = subtask.completedAt
                    }
                }
            } else {
                let persistentTask = PersistentTask.from(task)
                context.insert(persistentTask)
            }
            try context.save()
        } catch {
            print("Failed to save task: \(error)")
        }
    }

    func deleteTask(_ task: TodoTask) {
        guard let context = modelContext else { return }

        let taskId = task.id
        let descriptor = FetchDescriptor<PersistentTask>(
            predicate: #Predicate { $0.id == taskId }
        )

        do {
            let existing = try context.fetch(descriptor)
            if let existingTask = existing.first {
                context.delete(existingTask)
                try context.save()
            }
        } catch {
            print("Failed to delete task: \(error)")
        }
    }

    func deleteAllTasks() {
        guard let context = modelContext else { return }

        do {
            try context.delete(model: PersistentTask.self)
            try context.save()
        } catch {
            print("Failed to delete all tasks: \(error)")
        }
    }

    // MARK: - Subtask Operations

    func updateSubtask(_ subtask: SubTask, in task: TodoTask) {
        guard let context = modelContext else { return }

        let taskId = task.id
        let descriptor = FetchDescriptor<PersistentTask>(
            predicate: #Predicate { $0.id == taskId }
        )

        do {
            let existing = try context.fetch(descriptor)
            if let existingTask = existing.first {
                if let existingSubtask = existingTask.subtasks.first(where: { $0.id == subtask.id }) {
                    existingSubtask.title = subtask.title
                    existingSubtask.isCompleted = subtask.isCompleted
                    existingSubtask.estimatedMinutes = subtask.estimatedMinutes
                    existingSubtask.completedAt = subtask.completedAt
                    try context.save()
                }
            }
        } catch {
            print("Failed to update subtask: \(error)")
        }
    }

    // MARK: - Migration

    func seedSampleDataIfNeeded() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<PersistentTask>()

        do {
            let count = try context.fetchCount(descriptor)
            if count == 0 {
                // Insert sample data for first launch
                for task in TodoTask.samples {
                    let persistentTask = PersistentTask.from(task)
                    context.insert(persistentTask)
                }
                try context.save()
                print("Seeded sample data")
            }
        } catch {
            print("Failed to seed sample data: \(error)")
        }
    }
}
