import Testing

@testable import MoltTodo

@Suite("Todo Task Tests")
struct TodoTaskTests {
    @Test("Task creation with default values")
    func testTaskCreation() {
        let task = TodoTask(title: "Test task")

        #expect(task.title == "Test task")
        #expect(task.isCompleted == false)
        #expect(task.subtasks.isEmpty)
        #expect(task.priority == .medium)
    }

    @Test("Task progress calculation")
    func testTaskProgress() {
        let task = TodoTask(
            title: "Test task",
            subtasks: [
                SubTask(title: "Subtask 1", isCompleted: true),
                SubTask(title: "Subtask 2", isCompleted: false),
                SubTask(title: "Subtask 3", isCompleted: true),
            ]
        )

        #expect(task.progress == 2.0 / 3.0)
        #expect(task.completedSubtasksCount == 2)
    }

    @Test("Task completion toggle")
    func testTaskCompletionToggle() {
        let task = TodoTask(title: "Test task")

        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)

        task.isCompleted = true
        task.completedAt = Date()

        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)
    }
}
