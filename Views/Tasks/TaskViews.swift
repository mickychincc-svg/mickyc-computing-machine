import SwiftUI

// MARK: - Task Root
struct TaskRootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @State private var showNewTask = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                TaskListView(showNewTask: $showNewTask)
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#060d1a"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#60a5fa"))
                    }
                }
            }
            .sheet(isPresented: $showNewTask) {
                NewTaskSheet()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Task List
struct TaskListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @Binding var showNewTask: Bool

    @StateObject private var vm: TaskViewModel

    init(showNewTask: Binding<Bool>) {
        self._showNewTask = showNewTask
        // Will be replaced via onAppear
        self._vm = StateObject(wrappedValue: TaskViewModel(
            context: PersistenceController.shared.container.viewContext,
            userID: UserDefaults.standard.string(forKey: "trackflow_logged_in_user_id") ?? ""
        ))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                if let task = vm.activeTask {
                    ActiveTaskCard(task: task, vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                } else {
                    EmptyTaskView(showNewTask: $showNewTask)
                        .padding(.top, 60)
                }

                if !vm.completedTasks.isEmpty {
                    CompletedTasksSection(tasks: vm.completedTasks, vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                Spacer(minLength: 40)
            }
        }
        .refreshable { vm.fetch() }
    }
}

// MARK: - Active Task Card
struct ActiveTaskCard: View {
    let task: Task
    @ObservedObject var vm: TaskViewModel
    @State private var showCompleteAlert = false
    @State private var selectedStage: Stage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header badge
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "#10b981")).frame(width: 7, height: 7)
                    Text("ACTIVE TASK")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#10b981"))
                        .kerning(2)
                }
                Spacer()
                if task.allStagesDone {
                    Button {
                        showCompleteAlert = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Complete")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#34d399"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#0f2a1e"))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "#10b981"), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().background(Color(hex: "#1e3a5f"))

            // Task info
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.wrappedTitle)
                            .font(.custom("Georgia-Bold", size: 22))
                            .foregroundColor(.white)
                        if !task.wrappedDescription.isEmpty {
                            Text(task.wrappedDescription)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#64748b"))
                                .lineLimit(2)
                        }
                        Text("Started \(task.wrappedCreatedAt.formattedShort)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#334155"))
                            .padding(.top, 2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(task.progressPercent)%")
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(Color(hex: "#3b82f6"))
                        Text("\(task.stages?.count ?? 0 - task.sortedStages.filter{$0.wrappedStatus == StageStatus.completed.rawValue}.count) left")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#475569"))
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#0f1e35"))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * task.progressFraction, height: 6)
                            .animation(.spring(response: 0.5), value: task.progressFraction)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Current Stage only
            if let current = task.currentStage {
                Divider().background(Color(hex: "#1e3a5f"))
                CurrentStageView(stage: current, task: task, vm: vm)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            } else if task.allStagesDone {
                Divider().background(Color(hex: "#1e3a5f"))
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#10b981"))
                        .font(.system(size: 18))
                    Text("All stages completed! Tap 'Complete' to finish.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#34d399"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color(hex: "#0a1628"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .alert("Complete Task?", isPresented: $showCompleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Complete", role: .destructive) { vm.completeTask() }
        } message: {
            Text("Mark \"\(task.wrappedTitle)\" as complete? You can then start a new task.")
        }
    }
}

// MARK: - Current Stage View
struct CurrentStageView: View {
    let stage: Stage
    let task: Task
    @ObservedObject var vm: TaskViewModel
    @State private var showUpdateSheet = false
    @State private var showDailyNoteSheet = false

    var stageIndex: Int {
        task.sortedStages.firstIndex(where: { $0.id == stage.id }) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Stage label
            HStack(spacing: 6) {
                Text("CURRENT STAGE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#475569"))
                    .kerning(2)
                Spacer()
                Text("Stage \(stageIndex + 1) of \(task.sortedStages.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "#334155"))
            }

            // Stage name + status
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(stage.statusEnum.bgColor)
                        .frame(width: 36, height: 36)
                    Image(systemName: stage.statusEnum.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(stage.statusEnum.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.wrappedName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    if let due = stage.wrappedDueDate {
                        Text("Due \(due.formattedShort)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "#475569"))
                    }
                }
                Spacer()
                StatusBadge(status: stage.statusEnum)
            }

            // Daily notes (last 2)
            let notes = stage.sortedDailyNotes
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S NOTES")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#334155"))
                        .kerning(2)
                    ForEach(notes.prefix(2)) { note in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color(hex: "#1e3a5f"))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.wrappedContent)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "#94a3b8"))
                                    .lineLimit(2)
                                Text(note.wrappedDate.formattedShort)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color(hex: "#334155"))
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "#0f1e35"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    showDailyNoteSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 13))
                        Text("Daily Note")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#a78bfa"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#1e1040"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: "#6366f1").opacity(0.4), lineWidth: 1))
                }

                Button {
                    showUpdateSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 13))
                        Text("Update Status")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#60a5fa"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#0f1e35"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                }
            }

            // Navigation to all stages
            NavigationLink {
                AllStagesView(task: task, vm: vm)
            } label: {
                HStack {
                    Text("View all \(task.sortedStages.count) stages")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#475569"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#334155"))
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showUpdateSheet) {
            UpdateStageSheet(stage: stage, vm: vm)
        }
        .sheet(isPresented: $showDailyNoteSheet) {
            DailyNoteSheet(stage: stage, vm: vm)
        }
    }
}

// MARK: - All Stages View
struct AllStagesView: View {
    let task: Task
    @ObservedObject var vm: TaskViewModel

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(task.sortedStages.enumerated()), id: \.element.id) { i, stage in
                        StageRowView(stage: stage, index: i, vm: vm)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("All Stages")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Stage Row
struct StageRowView: View {
    let stage: Stage
    let index: Int
    @ObservedObject var vm: TaskViewModel
    @State private var isExpanded = false
    @State private var showUpdateSheet = false
    @State private var showDailyNoteSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(stage.statusEnum.bgColor)
                            .frame(width: 32, height: 32)
                        if stage.wrappedStatus == StageStatus.completed.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#60a5fa"))
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(stage.statusEnum.color)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stage.wrappedName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        if let due = stage.wrappedDueDate {
                            Text("Due \(due.formattedShort)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(hex: "#475569"))
                        }
                    }
                    Spacer()
                    StatusBadge(status: stage.statusEnum)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#334155"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            if isExpanded {
                Divider().background(Color(hex: "#0f1e35"))
                VStack(alignment: .leading, spacing: 10) {
                    // Updates
                    if !stage.sortedUpdates.isEmpty {
                        Text("STATUS HISTORY")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#334155"))
                            .kerning(2)
                        ForEach(stage.sortedUpdates) { update in
                            StageUpdateRow(update: update)
                        }
                    }
                    // Daily Notes
                    if !stage.sortedDailyNotes.isEmpty {
                        Text("DAILY NOTES")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#334155"))
                            .kerning(2)
                        ForEach(stage.sortedDailyNotes) { note in
                            DailyNoteRow(note: note)
                        }
                    }
                    // Buttons
                    HStack(spacing: 8) {
                        ActionButton(label: "Daily Note", icon: "pencil.and.outline",
                                     color: Color(hex: "#a78bfa")) { showDailyNoteSheet = true }
                        ActionButton(label: "Update", icon: "arrow.up.circle",
                                     color: Color(hex: "#60a5fa")) { showUpdateSheet = true }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .padding(.top, 10)
            }
        }
        .background(Color(hex: "#0a1628"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(stage.wrappedStatus == StageStatus.inProgress.rawValue
                    ? Color(hex: "#10b981").opacity(0.3)
                    : Color(hex: "#1e293b"), lineWidth: 1))
        .sheet(isPresented: $showUpdateSheet) { UpdateStageSheet(stage: stage, vm: vm) }
        .sheet(isPresented: $showDailyNoteSheet) { DailyNoteSheet(stage: stage, vm: vm) }
    }
}

// MARK: - Update Stage Sheet
struct UpdateStageSheet: View {
    let stage: Stage
    @ObservedObject var vm: TaskViewModel
    @Environment(\.dismiss) var dismiss
    @State private var status: StageStatus
    @State private var note = ""
    @State private var date = Date()

    init(stage: Stage, vm: TaskViewModel) {
        self.stage = stage
        self.vm = vm
        _status = State(initialValue: stage.statusEnum)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Status picker
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Status")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(StageStatus.allCases, id: \.self) { s in
                                    StatusOptionButton(s: s, selected: status == s) { status = s }
                                }
                            }
                        }
                        // Date
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Date")
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#0a1628"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                        }
                        // Note
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Notes *")
                            TextEditor(text: $note)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color(hex: "#0a1628"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                                .foregroundColor(.white)
                                .colorScheme(.dark)
                                .overlay(
                                    Group {
                                        if note.isEmpty {
                                            Text("What's the status? Any blockers?")
                                                .foregroundColor(Color(hex: "#334155"))
                                                .padding(16)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                        }

                        PrimaryButton(label: "Save Update") {
                            vm.updateStage(stage, status: status, note: note, date: date)
                            dismiss()
                        }
                        .disabled(note.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(note.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Update: \(stage.wrappedName)")
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

// MARK: - Daily Note Sheet
struct DailyNoteSheet: View {
    let stage: Stage
    @ObservedObject var vm: TaskViewModel
    @Environment(\.dismiss) var dismiss
    @State private var content = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        SheetSectionHeader("Date")
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#0a1628"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SheetSectionHeader("Daily Note")
                        TextEditor(text: $content)
                            .frame(minHeight: 140)
                            .padding(12)
                            .background(Color(hex: "#0a1628"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                            .foregroundColor(.white)
                            .colorScheme(.dark)
                            .overlay(
                                Group {
                                    if content.isEmpty {
                                        Text("What did you work on today?")
                                            .foregroundColor(Color(hex: "#334155"))
                                            .padding(16)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                    }

                    PrimaryButton(label: "Add Daily Note", color: Color(hex: "#6366f1")) {
                        vm.addDailyNote(to: stage, content: content, date: date)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(content.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Daily Note — \(stage.wrappedName)")
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

// MARK: - New Task Sheet
struct NewTaskSheet: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var desc  = ""
    @State private var stages: [(id: UUID, name: String, dueDate: Date?)] = [
        (UUID(), "", nil)
    ]

    private var vm: TaskViewModel {
        TaskViewModel(context: context, userID: authVM.currentUserID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Task Title *")
                            StyledTextField(placeholder: "e.g. Product Launch Q1", text: $title)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            SheetSectionHeader("Description")
                            StyledTextField(placeholder: "Brief overview…", text: $desc, multiline: true)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SheetSectionHeader("Stages")
                                Spacer()
                                Button {
                                    stages.append((UUID(), "", nil))
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Stage")
                                    }
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: "#60a5fa"))
                                }
                            }
                            ForEach(stages.indices, id: \.self) { i in
                                StageFormRow(
                                    index: i,
                                    name: Binding(get: { stages[i].name }, set: { stages[i].name = $0 }),
                                    dueDate: Binding(get: { stages[i].dueDate }, set: { stages[i].dueDate = $0 }),
                                    canDelete: stages.count > 1,
                                    onDelete: { stages.remove(at: i) }
                                )
                            }
                        }
                        PrimaryButton(label: "Create Task") {
                            let vm2 = TaskViewModel(context: context, userID: authVM.currentUserID)
                            vm2.createTask(
                                title: title,
                                description: desc,
                                stages: stages.map { (name: $0.name, dueDate: $0.dueDate) }
                            )
                            dismiss()
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
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

// MARK: - Completed Tasks Section
struct CompletedTasksSection: View {
    let tasks: [Task]
    @ObservedObject var vm: TaskViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: "#3b82f6")).frame(width: 6, height: 6)
                Text("COMPLETED (\(tasks.count))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#3b82f6"))
                    .kerning(2)
            }
            ForEach(tasks) { task in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#60a5fa"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.wrappedTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        if let completedAt = task.wrappedCompletedAt {
                            Text("Completed \(completedAt.formattedShort)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "#334155"))
                        }
                    }
                    Spacer()
                    Text("\(task.sortedStages.count) stages")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "#3b82f6"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#0a1628"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e293b"), lineWidth: 1))
                .opacity(0.65)
            }
        }
    }
}

// MARK: - Empty State
struct EmptyTaskView: View {
    @Binding var showNewTask: Bool
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "#0a1628"))
                    .frame(width: 72, height: 72)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#1e293b"), lineWidth: 1))
                Image(systemName: "flag")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(Color(hex: "#1e3a5f"))
            }
            Text("No Active Task")
                .font(.custom("Georgia-Bold", size: 22))
                .foregroundColor(.white)
            Text("Create a new task to get started.\nOnly one task can be active at a time.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#475569"))
                .multilineTextAlignment(.center)
            Button { showNewTask = true } label: {
                Text("Create First Task")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 40)
    }
}
