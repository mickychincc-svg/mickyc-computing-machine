import SwiftUI

// MARK: - App Background
struct AppBackground: View {
    var body: some View {
        Color(hex: "#060d1a").ignoresSafeArea()
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: StageStatus
    var body: some View {
        Text(status.label)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(status.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(status.bgColor)
            .clipShape(Capsule())
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let dot: String
    let label: String
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(Color(hex: dot)).frame(width: 6, height: 6)
            Text(count != nil ? "\(label) (\(count!))" : label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: dot))
                .kerning(2)
        }
        .padding(.vertical, 6)
        .background(Color(hex: "#060d1a"))
    }
}

// MARK: - Sheet Section Header
struct SheetSectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(Color(hex: "#475569"))
            .kerning(0.5)
    }
}

// MARK: - Styled Text Field
struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var multiline = false

    var body: some View {
        Group {
            if multiline {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding(12)
                    .foregroundColor(.white)
                    .colorScheme(.dark)
                    .overlay(
                        Group {
                            if text.isEmpty {
                                Text(placeholder)
                                    .foregroundColor(Color(hex: "#334155"))
                                    .padding(16)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
            }
        }
        .background(Color(hex: "#0a1628"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
        .font(.system(size: 15))
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let label: String
    var color: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color != nil
                    ? AnyView(color!)
                    : AnyView(LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                             startPoint: .leading, endPoint: .trailing)))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

// MARK: - Status Option Button
struct StatusOptionButton: View {
    let s: StageStatus
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Circle().fill(s.dotColor).frame(width: 7, height: 7)
                Text(s.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selected ? s.color : Color(hex: "#475569"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(selected ? s.bgColor : Color(hex: "#0f1e35"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(selected ? s.dotColor : Color(hex: "#1e293b"), lineWidth: 1.5))
        }
    }
}

// MARK: - Stage Form Row
struct StageFormRow: View {
    let index: Int
    @Binding var name: String
    @Binding var dueDate: Date?
    let canDelete: Bool
    let onDelete: () -> Void
    @State private var hasDueDate = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color(hex: "#1e3a5f")).frame(width: 26, height: 26)
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#60a5fa"))
                }
                TextField("Stage name", text: $name)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "#475569"))
                            .font(.system(size: 18))
                    }
                }
            }
            HStack {
                Toggle("Due date", isOn: $hasDueDate)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#64748b"))
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#3b82f6")))
                if hasDueDate {
                    DatePicker("", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .labelsHidden()
                }
            }
            .onChange(of: hasDueDate) { on in
                if !on { dueDate = nil } else if dueDate == nil { dueDate = Date() }
            }
        }
        .padding(12)
        .background(Color(hex: "#0f1e35"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Stage Update Row
struct StageUpdateRow: View {
    let update: StageUpdate
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(StageStatus(rawValue: update.wrappedStatus)?.dotColor ?? Color(hex: "#475569"))
                .frame(width: 7, height: 7)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    StatusBadge(status: StageStatus(rawValue: update.wrappedStatus) ?? .pending)
                    Text(update.wrappedDate.formattedShort)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "#334155"))
                }
                Text(update.wrappedNote)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#94a3b8"))
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Daily Note Row
struct DailyNoteRow: View {
    let note: DailyNote
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6366f1"))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(note.wrappedDate.formattedShort)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "#334155"))
                Text(note.wrappedContent)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#94a3b8"))
                    .lineLimit(4)
            }
        }
        .padding(10)
        .background(Color(hex: "#0a1628"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#1e3a5f").opacity(0.5), lineWidth: 1))
        .padding(.vertical, 2)
    }
}
