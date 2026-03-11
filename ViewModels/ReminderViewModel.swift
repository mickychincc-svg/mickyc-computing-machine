import CoreData
import SwiftUI
import UserNotifications

class ReminderViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    private let userID: String

    @Published var reminders: [Reminder] = []

    var upcoming: [Reminder] { reminders.filter { $0.isUpcoming }.sorted { $0.nextOccurrence < $1.nextOccurrence } }
    var past:     [Reminder] { reminders.filter { !$0.isUpcoming }.sorted { $0.wrappedDate > $1.wrappedDate } }

    init(context: NSManagedObjectContext, userID: String) {
        self.context = context
        self.userID  = userID
        fetch()
        requestNotificationPermission()
    }

    func fetch() {
        reminders = (try? context.fetch(Reminder.fetchAll(userID: userID))) ?? []
    }

    // MARK: - Create / Update Reminder
    func save(reminder: Reminder? = nil,
              title: String, note: String, date: Date,
              type: ReminderType, recurrence: RecurrenceType) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let r = reminder ?? Reminder(context: context)
        if reminder == nil { r.id = UUID() }
        r.title         = title.trimmingCharacters(in: .whitespaces)
        r.reminderNote  = note.trimmingCharacters(in: .whitespaces)
        r.date          = date
        r.type          = type.rawValue
        r.recurrence    = recurrence.rawValue
        r.userID        = userID

        do {
            try context.save()
            scheduleNotification(for: r)
            fetch()
        } catch { print("Reminder save error: \(error)") }
    }

    // MARK: - Delete
    func delete(_ reminder: Reminder) {
        cancelNotification(id: reminder.id?.uuidString ?? "")
        context.delete(reminder)
        try? context.save()
        fetch()
    }

    // MARK: - Local Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    private func scheduleNotification(for reminder: Reminder) {
        let center = UNUserNotificationCenter.current()
        let id = reminder.id?.uuidString ?? UUID().uuidString
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = reminder.typeEnum.emoji + " " + reminder.wrappedTitle
        content.body  = reminder.wrappedNote.isEmpty ? "You have a reminder today!" : reminder.wrappedNote
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                    from: reminder.nextOccurrence)
        let trigger: UNNotificationTrigger

        switch reminder.recurrenceEnum {
        case .none:
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        case .daily:
            var dailyComps = DateComponents()
            dailyComps.hour   = comps.hour ?? 9
            dailyComps.minute = comps.minute ?? 0
            trigger = UNCalendarNotificationTrigger(dateMatching: dailyComps, repeats: true)
        case .weekly:
            var weeklyComps = DateComponents()
            weeklyComps.weekday = comps.weekday
            weeklyComps.hour    = comps.hour ?? 9
            weeklyComps.minute  = comps.minute ?? 0
            trigger = UNCalendarNotificationTrigger(dateMatching: weeklyComps, repeats: true)
        case .monthly:
            var monthlyComps = DateComponents()
            monthlyComps.day    = comps.day
            monthlyComps.hour   = comps.hour ?? 9
            monthlyComps.minute = comps.minute ?? 0
            trigger = UNCalendarNotificationTrigger(dateMatching: monthlyComps, repeats: true)
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
