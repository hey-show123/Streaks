import SwiftUI
import Charts

struct HabitDetailView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingEditView = false
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "週"
        case month = "月"
        case year = "年"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    var statistics: HabitStatistics {
        habitManager.getStatistics(for: habit)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダーカード
                        HeaderCard(habit: habit, statistics: statistics)
                            .padding(.top, 20)
                        
                        // 統計セクション
                        StatsSection(statistics: statistics)
                        
                        // 完了履歴グラフ
                        CompletionHistorySection(
                            habit: habit,
                            selectedTimeRange: $selectedTimeRange
                        )
                        
                        // カレンダービュー
                        CalendarSection(habit: habit)
                        
                        // 詳細情報
                        DetailInfoSection(habit: habit)
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("編集") {
                        showingEditView = true
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditHabitView(habit: habit)
                    .environmentObject(habitManager)
            }
        }
        .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light)
    }
}

// ヘッダーカード
struct HeaderCard: View {
    let habit: Habit
    let statistics: HabitStatistics
    @StateObject private var themeManager = ThemeManager.shared
    
    var typeColor: Color {
        switch habit.type {
        case .positive: return .green
        case .negative: return .red
        case .timed: return .blue
        }
    }
    
    // 色変換ヘルパー
    var habitColor: Color {
        switch habit.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // タイプインジケーター
            HStack {
                Image(systemName: habit.type == .positive ? "checkmark.circle.fill" : habit.type == .negative ? "xmark.octagon.fill" : "timer")
                    .font(.system(size: 16))
                Text(habit.type.displayName)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(typeColor)
            
            // アイコン
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 50))
                    .foregroundColor(habitColor)
            }
            
            // ストリーク情報
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text("\(statistics.currentStreak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                Text("現在のストリーク")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
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

// 統計セクション
struct StatsSection: View {
    let statistics: HabitStatistics
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("統計")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "最高記録",
                    value: "\(statistics.bestStreak)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "総完了回数",
                    value: "\(statistics.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "7日間",
                    value: "\(Int(statistics.last7DaysCompletion))%",
                    icon: "calendar",
                    color: .blue
                )
                
                StatCard(
                    title: "30日間",
                    value: "\(Int(statistics.last30DaysCompletion))%",
                    icon: "calendar.badge.clock",
                    color: .purple
                )
            }
        }
    }
}

// 統計カード
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.secondaryBackgroundColor)
        )
    }
}

// 完了履歴グラフセクション
struct CompletionHistorySection: View {
    let habit: Habit
    @Binding var selectedTimeRange: HabitDetailView.TimeRange
    @StateObject private var themeManager = ThemeManager.shared
    
    // 色変換ヘルパー
    var habitColor: Color {
        switch habit.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default: return .blue
        }
    }
    
    var chartData: [(date: Date, completed: Bool)] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days + 1, to: endDate)!
        
        var data: [(Date, Bool)] = []
        
        for dayOffset in 0..<selectedTimeRange.days {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                let isCompleted = habit.isCompleted(on: date)
                data.append((date, isCompleted))
            }
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("完了履歴")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Picker("", selection: $selectedTimeRange) {
                    ForEach(HabitDetailView.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            // グラフ
            if #available(iOS 16.0, *) {
                Chart(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("日付", item.date, unit: .day),
                        y: .value("完了", item.completed ? 1 : 0)
                    )
                    .foregroundStyle(item.completed ? habitColor : Color.gray.opacity(0.3))
                }
                .frame(height: 150)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentTheme.cardBackgroundColor)
                )
            } else {
                // iOS 16未満の場合の代替表示
                HStack(spacing: 4) {
                    ForEach(chartData, id: \.date) { item in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.completed ? habitColor : Color.gray.opacity(0.3))
                            .frame(height: 60)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentTheme.cardBackgroundColor)
                )
            }
        }
    }
}

// カレンダーセクション
struct CalendarSection: View {
    let habit: Habit
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedMonth = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カレンダー")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // 月の選択
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
                
                Spacer()
                
                Text(monthYearString(from: selectedMonth))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            .padding(.horizontal)
            
            // カレンダーグリッド
            CalendarGrid(habit: habit, selectedMonth: selectedMonth)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentTheme.cardBackgroundColor)
                )
        }
    }
    
    private func changeMonth(_ direction: Int) {
        withAnimation {
            selectedMonth = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) ?? selectedMonth
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
}

// カレンダーグリッド
struct CalendarGrid: View {
    let habit: Habit
    let selectedMonth: Date
    @StateObject private var themeManager = ThemeManager.shared
    
    // 色変換ヘルパー
    var habitColor: Color {
        switch habit.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default: return .blue
        }
    }
    
    var monthDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? Date()
        let numberOfDays = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        VStack(spacing: 12) {
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日付グリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isCompleted: habit.isCompleted(on: date),
                            isTargetDay: habit.isTargetDay(date: date),
                            habitColor: habitColor
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }
}

// 日付セル
struct DayCell: View {
    let date: Date
    let isCompleted: Bool
    let isTargetDay: Bool
    let habitColor: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isCompleted ? habitColor : 
                    isTargetDay ? themeManager.currentTheme.secondaryBackgroundColor :
                    Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isToday ? themeManager.currentTheme.primaryColor : Color.clear,
                            lineWidth: 2
                        )
                )
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .semibold : .regular))
                .foregroundColor(
                    isCompleted ? .white :
                    isTargetDay ? themeManager.currentTheme.textColor :
                    themeManager.currentTheme.secondaryTextColor
                )
        }
        .frame(height: 36)
    }
}

// 詳細情報セクション
struct DetailInfoSection: View {
    let habit: Habit
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細情報")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 16) {
                InfoRow(label: "作成日", value: formatDate(habit.createdDate))
                
                if habit.frequency != .daily {
                    InfoRow(label: "頻度", value: habit.frequency.displayName)
                }
                
                if habit.type == .timed {
                    InfoRow(label: "目標時間", value: formatDuration(habit.timerDuration))
                }
                
                if habit.isReminderEnabled, let reminderTime = habit.reminderTime {
                    InfoRow(label: "リマインダー", value: formatTime(reminderTime))
                }
                
                if !habit.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メモ")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text(habit.notes)
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.cardBackgroundColor)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// 情報行
struct InfoRow: View {
    let label: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
}

struct HabitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailView(habit: Habit(
            name: "運動",
            icon: "figure.run",
            color: "orange"
        ))
        .environmentObject(HabitManager())
    }
} 