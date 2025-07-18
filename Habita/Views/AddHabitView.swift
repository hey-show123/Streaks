import SwiftUI

struct AddHabitView: View {
    @ObservedObject var habitManager: HabitManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "blue"
    @State private var selectedType = HabitType.positive
    @State private var selectedDifficulty = HabitDifficulty.medium
    @State private var selectedFrequency = HabitFrequency.daily
    @State private var selectedDays = Set(0...6)
    @State private var timerMinutes = 10
    @State private var isReminderEnabled = false
    @State private var reminderTime = Date()
    @State private var notes = ""
    @State private var selectedPageIndex = 0
    
    @State private var showingIconPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                // 基本情報
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
                
                // タイプと難易度
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
                
                // タイマー設定（タイムド習慣の場合）
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
                
                // 頻度設定
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
                
                // カラー選択
                Section("カラー") {
                    ColorPicker(selectedColor: $selectedColor)
                }
                
                // リマインダー
                Section("リマインダー") {
                    Toggle("リマインダーを設定", isOn: $isReminderEnabled)
                    
                    if isReminderEnabled {
                        DatePicker("時刻", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                // メモ
                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                // ページ選択
                Section("表示ページ") {
                    Picker("ページ", selection: $selectedPageIndex) {
                        ForEach(0..<4) { index in
                            Text("ページ \(index + 1)").tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("新しい習慣")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addHabit()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPicker(selectedIcon: $selectedIcon, color: Color(selectedColor))
            }
        }
    }
    
    private func addHabit() {
        let habit = Habit(
            name: name,
            icon: selectedIcon,
            color: selectedColor,
            type: selectedType,
            difficulty: selectedDifficulty,
            frequency: selectedFrequency,
            targetDays: selectedDays,
            timerDuration: selectedType == .timed ? TimeInterval(timerMinutes * 60) : 0,
            reminderTime: isReminderEnabled ? reminderTime : nil,
            isReminderEnabled: isReminderEnabled,
            notes: notes,
            pageIndex: selectedPageIndex
        )
        
        habitManager.addHabit(habit)
        dismiss()
    }
}



// プレビューカード
struct PreviewCard: View {
    let name: String
    let icon: String
    let color: Color
    let type: HabitType
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // タイプインジケーター
            HStack {
                Image(systemName: type == .positive ? "checkmark.circle.fill" : type == .negative ? "xmark.octagon.fill" : "timer")
                    .font(.system(size: 14))
                Text(type.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(type == .positive ? .green : type == .negative ? .red : .blue)
            
            // アイコン
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
            }
            
            // 名前
            Text(name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.cardBackgroundColor)
                .shadow(
                    color: themeManager.currentTheme.shadowColor,
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
    }
}

// フォームセクション
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    @StateObject private var themeManager = ThemeManager.shared
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .textCase(.uppercase)
            
            VStack(spacing: 16) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.cardBackgroundColor)
                    .shadow(
                        color: themeManager.currentTheme.shadowColor,
                        radius: 5,
                        x: 0,
                        y: 2
                    )
            )
        }
    }
}

// カスタムテキストフィールド
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.textColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.secondaryBackgroundColor)
        )
    }
}

// タイプボタン
struct TypeButton: View {
    let type: HabitType
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var typeColor: Color {
        switch type {
        case .positive: return .green
        case .negative: return .red
        case .timed: return .blue
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type == .positive ? "checkmark.circle.fill" : type == .negative ? "xmark.octagon.fill" : "timer")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : typeColor)
                
                Text(type.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? typeColor : themeManager.currentTheme.secondaryBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// カラーボタン
struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isSelected ? themeManager.currentTheme.textColor : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Group {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 曜日ボタン
struct DayButton: View {
    let day: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var daySymbol: String {
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        return symbols[day]
    }
    
    var body: some View {
        Button(action: action) {
            Text(daySymbol)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? color : themeManager.currentTheme.secondaryBackgroundColor)
                )
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
}





struct AddHabitView_Previews: PreviewProvider {
    static var previews: some View {
        AddHabitView(habitManager: HabitManager())
            .environmentObject(ThemeManager.shared)
    }
} 