import SwiftUI

struct EditHabitView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var selectedType: HabitType
    @State private var selectedDifficulty: HabitDifficulty
    @State private var selectedFrequency: HabitFrequency
    @State private var selectedDays: Set<Int>
    @State private var timerMinutes: Int
    @State private var isReminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var notes: String
    @State private var selectedPageIndex: Int
    
    @State private var showingIconPicker = false
    @State private var showingDeleteAlert = false
    
    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColor = State(initialValue: habit.color)
        _selectedType = State(initialValue: habit.type)
        _selectedDifficulty = State(initialValue: habit.difficulty)
        _selectedFrequency = State(initialValue: habit.frequency)
        _selectedDays = State(initialValue: habit.targetDays)
        _timerMinutes = State(initialValue: Int(habit.timerDuration / 60))
        _isReminderEnabled = State(initialValue: habit.isReminderEnabled)
        _reminderTime = State(initialValue: habit.reminderTime ?? Date())
        _notes = State(initialValue: habit.notes)
        _selectedPageIndex = State(initialValue: habit.pageIndex)
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                typeAndDifficultySection
                timerSection
                frequencySection
                colorSection
                reminderSection
                memoSection
                pageSection
                deleteSection
            }
            .navigationTitle("習慣を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPicker(selectedIcon: $selectedIcon, color: Color(selectedColor))
            }
            .alert("習慣を削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    habitManager.deleteHabit(habit)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この習慣を削除してもよろしいですか？\n削除後は元に戻せません。")
            }
        }
    }
    
    // 基本情報セクション
    private var basicInfoSection: some View {
        Section("基本情報") {
            TextField("習慣の名前", text: $name)
            
            // アイコン選択
            HStack {
                Text("アイコン")
                Spacer()
                Button(action: { showingIconPicker = true }) {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(Color(selectedColor))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // タイプと難易度セクション
    private var typeAndDifficultySection: some View {
        Section("タイプと難易度") {
            Picker("習慣のタイプ", selection: $selectedType) {
                ForEach(HabitType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            
            // 難易度選択
            VStack(alignment: .leading, spacing: 12) {
                Text("難易度")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                HStack(spacing: 12) {
                    ForEach(HabitDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyButton(
                            difficulty: difficulty,
                            isSelected: selectedDifficulty == difficulty,
                            action: { selectedDifficulty = difficulty }
                        )
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // タイマーセクション
    @ViewBuilder
    private var timerSection: some View {
        if selectedType == .timed {
            Section("タイマー設定") {
                Stepper(value: $timerMinutes, in: 1...120) {
                    HStack {
                        Text("目標時間")
                        Spacer()
                        Text("\(timerMinutes)分")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // 頻度セクション
    private var frequencySection: some View {
        Section("頻度") {
            Picker("頻度", selection: $selectedFrequency) {
                ForEach(HabitFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            
            if selectedFrequency == .weekly || selectedFrequency == .custom {
                // 曜日選択
                WeekdayPicker(selectedDays: $selectedDays)
            }
        }
    }
    
    // カラーセクション
    private var colorSection: some View {
        Section("カラー") {
            ColorPicker(selectedColor: $selectedColor)
        }
    }
    
    // リマインダーセクション
    private var reminderSection: some View {
        Section("リマインダー") {
            Toggle("リマインダーを設定", isOn: $isReminderEnabled)
            
            if isReminderEnabled {
                DatePicker("時刻", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }
    
    // メモセクション
    private var memoSection: some View {
        Section("メモ") {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
        }
    }
    
    // ページセクション
    private var pageSection: some View {
        Section("表示ページ") {
            Picker("ページ", selection: $selectedPageIndex) {
                ForEach(0..<4) { index in
                    Text("ページ \(index + 1)").tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // 削除セクション
    private var deleteSection: some View {
        Section {
            Button(action: { showingDeleteAlert = true }) {
                HStack {
                    Spacer()
                    Text("習慣を削除")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedHabit = habit
        updatedHabit.name = name
        updatedHabit.icon = selectedIcon
        updatedHabit.color = selectedColor
        updatedHabit.type = selectedType
        updatedHabit.difficulty = selectedDifficulty
        updatedHabit.frequency = selectedFrequency
        updatedHabit.targetDays = selectedDays
        updatedHabit.timerDuration = selectedType == .timed ? TimeInterval(timerMinutes * 60) : 0
        updatedHabit.reminderTime = isReminderEnabled ? reminderTime : nil
        updatedHabit.isReminderEnabled = isReminderEnabled
        updatedHabit.notes = notes
        updatedHabit.pageIndex = selectedPageIndex
        
        habitManager.updateHabit(updatedHabit)
        dismiss()
    }
}

struct EditHabitView_Previews: PreviewProvider {
    static var previews: some View {
        EditHabitView(habit: Habit(
            name: "運動",
            icon: "figure.run",
            color: "orange"
        ))
        .environmentObject(HabitManager())
    }
}

 