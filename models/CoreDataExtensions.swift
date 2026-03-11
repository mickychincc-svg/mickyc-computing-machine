import CoreData
import Foundation

// MARK: - Task Extensions
extension Task {
    var wrappedTitle: String { title ?? "Untitled" }
    var wrappedDescription: String { taskDescription ?? "" }
    var wrappedCreatedAt: Date { createdAt ?? Date() }
    var wrappedCompletedAt: Date? { completedAt }

    var sortedStages: [Stage] {
        let set = stages as? Set<Stage> ?? []
        return set.sorted { $0.order < $1.order }
    }

    var currentStage: Stage? {
        sortedStages.first(where: { $0.wrappedStatus != StageStatus.completed.rawValue })
    }

    var progressFraction: Double {
        let all = sortedStages
        guard !all.isEmpty else { return 0 }
        let done = all.filter { $0.wrappedStatus == StageStatus.completed.rawValue }.count
        return Double(done) / Double(all.count)
    }

    var progressPercent: Int { Int(progressFraction * 100) }

    var allStagesDone: Bool {
        let stages = sortedStages
        return !stages.isEmpty && stages.allSatisfy { $0.wrappedStatus == StageStatus.completed.rawValue }
    }

    static func fetchActive(userID: String) -> NSFetchRequest<Task> {
        let request = NSFetchRequest<Task>(entityName: "Task")
        request.predicate = NSPredicate(format: "isCompleted == false AND userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        return request
    }

    static func fetchCompleted(userID: String) -> NSFetchRequest<Task> {
        let request = NSFetchRequest<Task>(entityName: "Task")
        request.predicate = NSPredicate(format: "isCompleted == true AND userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        return request
    }
}

// MARK: - Stage Extensions
extension Stage {
    var wrappedName: String { name ?? "Unnamed Stage" }
    var wrappedStatus: String { status ?? StageStatus.pending.rawValue }
    var wrappedDueDate: Date? { dueDate }

    var sortedUpdates: [StageUpdate] {
        let set = updates as? Set<StageUpdate> ?? []
        return set.sorted { $0.wrappedDate > $1.wrappedDate }
    }

    var sortedDailyNotes: [DailyNote] {
        let set = dailyNotes as? Set<DailyNote> ?? []
        return set.sorted { $0.wrappedDate > $1.wrappedDate }
    }

    var statusEnum: StageStatus {
        StageStatus(rawValue: wrappedStatus) ?? .pending
    }
}

// MARK: - StageUpdate Extensions
extension StageUpdate {
    var wrappedNote: String { note ?? "" }
    var wrappedStatus: String { status ?? StageStatus.pending.rawValue }
    var wrappedDate: Date { date ?? Date() }
}

// MARK: - DailyNote Extensions
extension DailyNote {
    var wrappedContent: String { content ?? "" }
    var wrappedDate: Date { date ?? Date() }
}

// MARK: - Reminder Extensions
extension Reminder {
    var wrappedTitle: String { title ?? "Untitled" }
    var wrappedNote: String { reminderNote ?? "" }
    var wrappedDate: Date { date ?? Date() }
    var wrappedType: String { type ?? ReminderType.personal.rawValue }
    var wrappedRecurrence: String { recurrence ?? RecurrenceType.none.rawValue }

    var typeEnum: ReminderType { ReminderType(rawValue: wrappedType) ?? .personal }
    var recurrenceEnum: RecurrenceType { RecurrenceType(rawValue: wrappedRecurrence) ?? .none }

    var daysAway: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: nextOccurrence)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var nextOccurrence: Date {
        let cal = Calendar.current
        var ref = wrappedDate
        let now = cal.startOfDay(for: Date())
        switch recurrenceEnum {
        case .none:
            return ref
        case .daily:
            while cal.startOfDay(for: ref) < now {
                ref = cal.date(byAdding: .day, value: 1, to: ref) ?? ref
            }
        case .weekly:
            while cal.startOfDay(for: ref) < now {
                ref = cal.date(byAdding: .weekOfYear, value: 1, to: ref) ?? ref
            }
        case .monthly:
            while cal.startOfDay(for: ref) < now {
                ref = cal.date(byAdding: .month, value: 1, to: ref) ?? ref
            }
        }
        return ref
    }

    var isUpcoming: Bool {
        Calendar.current.startOfDay(for: nextOccurrence) >= Calendar.current.startOfDay(for: Date())
    }

    static func fetchAll(userID: String) -> NSFetchRequest<Reminder> {
        let request = NSFetchRequest<Reminder>(entityName: "Reminder")
        request.predicate = NSPredicate(format: "userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return request
    }
}
