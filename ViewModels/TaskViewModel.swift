import CoreData
import SwiftUI

class TaskViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    private let userID: String

    @Published var activeTask: Task?
    @Published var completedTasks: [Task] = []

    init(context: NSManagedObjectContext, userID: String) {
        self.context = context
        self.userID  = userID
        fetch()
    }

    func fetch() {
        activeTask = (try? context.fetch(Task.fetchActive(userID: userID)))?.first
        completedTasks = (try? context.fetch(Task.fetchCompleted(userID: userID))) ?? []
    }

    // MARK: - Create Task
    func createTask(title: String, description: String,
                    stages: [(name: String, dueDate: Date?)]) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let task = Task(context: context)
        task.id                 = UUID()
        task.title              = title.trimmingCharacters(in: .whitespaces)
        task.taskDescription    = description.trimmingCharacters(in: .whitespaces)
        task.createdAt          = Date()
        task.isCompleted        = false
        task.userID             = userID

        for (i, s) in stages.enumerated() {
            guard !s.name.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let stage = Stage(context: context)
            stage.id      = UUID()
            stage.name    = s.name.trimmingCharacters(in: .whitespaces)
            stage.dueDate = s.dueDate
            stage.status  = StageStatus.pending.rawValue
            stage.order   = Int32(i)
            stage.task    = task
        }
        save()
    }

    // MARK: - Update Stage Status
    func updateStage(_ stage: Stage, status: StageStatus, note: String, date: Date) {
        guard !note.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let update = StageUpdate(context: context)
        update.id     = UUID()
        update.status = status.rawValue
        update.note   = note.trimmingCharacters(in: .whitespaces)
        update.date   = date
        update.stage  = stage
        stage.status  = status.rawValue
        save()
    }

    // MARK: - Add Daily Note
    func addDailyNote(to stage: Stage, content: String, date: Date = Date()) {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let note = DailyNote(context: context)
        note.id      = UUID()
        note.content = content.trimmingCharacters(in: .whitespaces)
        note.date    = date
        note.stage   = stage
        save()
    }

    // MARK: - Complete Task
    func completeTask() {
        guard let task = activeTask else { return }
        task.isCompleted  = true
        task.completedAt  = Date()
        save()
    }

    // MARK: - Delete Task
    func deleteTask(_ task: Task) {
        context.delete(task)
        save()
    }

    private func save() {
        do {
            try context.save()
            fetch()
        } catch {
            print("Save error: \(error)")
        }
    }
}
