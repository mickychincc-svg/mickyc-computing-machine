import SwiftUI

// MARK: - Stage Status
enum StageStatus: String, CaseIterable {
    case pending = "pending"
    case inProgress = "in-progress"
    case completed = "completed"
    case blocked = "blocked"

    var label: String {
        switch self {
        case .pending:    return "Pending"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .blocked:    return "Blocked"
        }
    }

    var color: Color {
        switch self {
        case .pending:    return Color(hex: "#64748b")
        case .inProgress: return Color(hex: "#34d399")
        case .completed:  return Color(hex: "#60a5fa")
        case .blocked:    return Color(hex: "#f87171")
        }
    }

    var bgColor: Color {
        switch self {
        case .pending:    return Color(hex: "#1e293b")
        case .inProgress: return Color(hex: "#0f2a1e")
        case .completed:  return Color(hex: "#0f1f3d")
        case .blocked:    return Color(hex: "#2d1515")
        }
    }

    var dotColor: Color {
        switch self {
        case .pending:    return Color(hex: "#475569")
        case .inProgress: return Color(hex: "#10b981")
        case .completed:  return Color(hex: "#3b82f6")
        case .blocked:    return Color(hex: "#ef4444")
        }
    }

    var icon: String {
        switch self {
        case .pending:    return "clock"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed:  return "checkmark.circle.fill"
        case .blocked:    return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Reminder Type
enum ReminderType: String, CaseIterable {
    case holiday = "holiday"
    case birthday = "birthday"
    case meeting = "meeting"
    case deadline = "deadline"
    case personal = "personal"

    var label: String {
        switch self {
        case .holiday:  return "Holiday"
        case .birthday: return "Birthday"
        case .meeting:  return "Meeting"
        case .deadline: return "Deadline"
        case .personal: return "Personal"
        }
    }

    var emoji: String {
        switch self {
        case .holiday:  return "🎉"
        case .birthday: return "🎂"
        case .meeting:  return "📅"
        case .deadline: return "⏰"
        case .personal: return "✨"
        }
    }

    var color: Color {
        switch self {
        case .holiday:  return Color(hex: "#f59e0b")
        case .birthday: return Color(hex: "#ec4899")
        case .meeting:  return Color(hex: "#6366f1")
        case .deadline: return Color(hex: "#ef4444")
        case .personal: return Color(hex: "#10b981")
        }
    }
}

// MARK: - Recurrence Type
enum RecurrenceType: String, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var label: String {
        switch self {
        case .none:    return "One-time"
        case .daily:   return "Every Day"
        case .weekly:  return "Every Week"
        case .monthly: return "Every Month"
        }
    }

    var icon: String {
        switch self {
        case .none:    return "calendar.badge.clock"
        case .daily:   return "sun.max.fill"
        case .weekly:  return "calendar.badge.plus"
        case .monthly: return "calendar"
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Date Helpers
extension Date {
    var formattedShort: String {
        formatted(.dateTime.month(.abbreviated).day().year())
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
