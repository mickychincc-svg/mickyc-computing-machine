import SwiftUI

// MARK: - Reminder Root
struct ReminderRootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ReminderListView(showAddSheet: $showAddSheet)
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#060d1a"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#60a5fa"))
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                ReminderFormSheet(reminder: nil)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Reminder List
struct ReminderListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @Binding var showAddSheet: Bool

    @StateObject private var vm: ReminderViewModel

    init(showAddSheet: Binding<Bool>) {
        self._showAddSheet = showAddSheet
        self._vm = StateObject(wrappedValue: ReminderViewModel(
            context: PersistenceController.shared.container.viewContext,
            userID: UserDefaults.standard.string(forKey: "trackflow_logged_in_user_id") ?? ""
        ))
    }

    var body: some View {
        ScrollView {
            if vm.reminders.isEmpty {
                EmptyReminderView(showAddSheet: $showAddSheet)
                    .padding(.top, 80)
            } else {
                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    if !vm.upcoming.isEmpty {
                        Section {
                            ForEach(vm.upcoming) { reminder in
                                ReminderCard(reminder: reminder, vm: vm)
                                    .padding(.horizontal, 20)
                            }
                        } header: {
                            SectionHeader(dot: "#10b981", label: "UPCOMING", count: vm.upcoming.count)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }
                    }
                    if !vm.past.isEmpty {
                        Section {
                            ForEach(vm.past) { reminder in
                                ReminderCard(reminder: reminder, vm: vm, isPast: true)
                                    .padding(.horizontal, 20)
                            }
                        } header: {
                            SectionHeader(dot: "#334155", label: "PAST", count: vm.past.count)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .refreshable { vm.fetch() }
    }
}

// MARK: - Reminder Card
struct ReminderCard: View {
    let reminder: Reminder
    @ObservedObject var vm: ReminderViewModel
    var isPast: Bool = false
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(reminder.typeEnum.color.opacity(0.12))
                    .frame(width: 46, height: 46)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(reminder.typeEnum.color.opacity(0.3), lineWidth: 1))
                Text(reminder.typeEnum.emoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.wrappedTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                if !reminder.wrappedNote.isEmpty {
                    Text(reminder.wrappedNote)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#64748b"))
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(reminder.nextOccurrence.formattedShort)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "#475569"))

                    if !isPast {
                        let days = reminder.daysAway
                        Text(days == 0 ? "Today!" : "in \(days)d")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(reminder.typeEnum.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(reminder.typeEnum.color.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if reminder.recurrenceEnum != .none {
                        HStack(spacing: 3) {
                            Image(systemName: reminder.recurrenceEnum.icon)
                                .font(.system(size: 10))
                            Text(reminder.recurrenceEnum.label)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color(hex: "#475569"))
                    }
                }
            }

            Spacer()

            VStack(spacing: 6) {
                Button { showEdit = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#60a5fa"))
                        .frame(width: 30, height: 30)
                        .background(Color(hex: "#0f1e35"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                }
                Button { vm.delete(reminder) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#f87171"))
                        .frame(width: 30, height: 30)
                        .background(Color(hex: "#0f1e35"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#2d1515"), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "#0a1628"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(isPast ? Color(hex: "#1e293b") : Color(hex: "#1e3a5f"), lineWidth: 1))
        .opacity(isPast ? 0.55 : 1)
        .sheet(isPresented: $showEdit) {
            ReminderFormSheet(reminder: reminder, vm: vm)
        }
    }
}

// MARK: - Reminder Form Sheet
struct ReminderFormSheet: View {
    var reminder: Reminder?
    var vm: ReminderViewModel?
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss

    @State private var title      = ""
    @State private var note       = ""
    @State private var date       = Date()
    @State private var type       = ReminderType.personal
    @State private var recurrence = RecurrenceType.none

    var editVM: ReminderViewModel {
        vm ?? ReminderViewModel(context: context, userID: authVM.currentUserID)
    }

    init(reminder: Reminder?, vm: ReminderViewModel? = nil) {
        self.reminder = reminder
        self.vm       = vm
        if let r = reminder {
            _title      = State(initialValue: r.wrappedTitle)
            _note       = State(initialValue: r.wrappedNote)
            _date       = State(initialValue: r.wrappedDate)
            _type       = State(initialValue: r.typeEnum)
            _recurrence = State(initialValue: r.recurrenceEnum)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Title *")
                            StyledTextField(placeholder: "e.g. Mom's Birthday", text: $title)
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Date")
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#0a1628"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                        }

                        // Type
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Type")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ReminderType.allCases, id: \.self) { t in
                                    Button {
                                        type = t
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(t.emoji).font(.system(size: 16))
                                            Text(t.label)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(type == t ? t.color : Color(hex: "#475569"))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(type == t ? t.color.opacity(0.12) : Color(hex: "#0f1e35"))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(type == t ? t.color.opacity(0.5) : Color(hex: "#1e293b"), lineWidth: 1.5))
                                    }
                                }
                            }
                        }

                        // Recurrence
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Repeat")
                            VStack(spacing: 8) {
                                ForEach(RecurrenceType.allCases, id: \.self) { r in
                                    Button {
                                        recurrence = r
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: r.icon)
                                                .font(.system(size: 15))
                                                .foregroundColor(recurrence == r ? Color(hex: "#60a5fa") : Color(hex: "#475569"))
                                                .frame(width: 22)
                                            Text(r.label)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(recurrence == r ? .white : Color(hex: "#64748b"))
                                            Spacer()
                                            if recurrence == r {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(hex: "#60a5fa"))
                                                    .font(.system(size: 16))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 13)
                                        .background(recurrence == r ? Color(hex: "#0f1e35") : Color(hex: "#0a1628"))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(recurrence == r ? Color(hex: "#1e3a5f") : Color(hex: "#0f1e35"), lineWidth: 1))
                                    }
                                }
                            }
                        }

                        // Note
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Note (optional)")
                            StyledTextField(placeholder: "Additional details…", text: $note, multiline: true)
                        }

                        PrimaryButton(label: reminder == nil ? "Add Reminder" : "Save Changes") {
                            let useVM = vm ?? ReminderViewModel(context: context, userID: authVM.currentUserID)
                            useVM.save(reminder: reminder, title: title, note: note, date: date,
                                       type: type, recurrence: recurrence)
                            dismiss()
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(reminder == nil ? "Add Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#64748b"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Empty Reminder View
struct EmptyReminderView: View {
    @Binding var showAddSheet: Bool
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color(hex: "#0a1628"))
                    .frame(width: 72, height: 72)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#1e293b"), lineWidth: 1))
                Image(systemName: "bell").font(.system(size: 28, weight: .light))
                    .foregroundColor(Color(hex: "#1e3a5f"))
            }
            Text("No Reminders Yet").font(.custom("Georgia-Bold", size: 22)).foregroundColor(.white)
            Text("Add birthdays, holidays, meetings and more.")
                .font(.system(size: 14)).foregroundColor(Color(hex: "#475569")).multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Text("Add Reminder")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }
        }.padding(.horizontal, 40)
    }
}
