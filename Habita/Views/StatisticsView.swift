import SwiftUI
import Charts

struct StatisticsView: View {
    let habitManager: HabitManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedHabit: Habit?
    @State private var showingCompatibility = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
            ScrollView {
                    VStack(spacing: 24) {
                        // 全体の統計
                        OverallStatsSection(habitManager: habitManager)
                            .padding(.top, 20)
                    
                        // 習慣ごとの統計
                        HabitStatsSection(
                        habitManager: habitManager,
                            selectedHabit: $selectedHabit
                        )
                    
                        // 習慣相性診断
                        HabitCompatibilitySection(habitManager: habitManager)
                        
                        // ムード分析（曜日別パフォーマンスの上に配置）
                        MoodAnalysisSection(habitManager: habitManager)
                        
                        // 週間パフォーマンス
                        WeeklyPerformanceSection(habitManager: habitManager)
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light)
    }
}

// 全体の統計セクション
struct OverallStatsSection: View {
    let habitManager: HabitManager
    @StateObject private var themeManager = ThemeManager.shared
    
    var totalHabits: Int {
        habitManager.habits.count
    }
    
    var activeToday: Int {
        habitManager.habits.filter { $0.isCompletedToday() }.count
    }
    
    var overallCompletionRate: Double {
        let totalPossible = habitManager.habits.reduce(0) { sum, habit in
            sum + habit.targetDays.count * 4 // 過去4週間
        }
        let totalCompleted = habitManager.habits.reduce(0) { sum, habit in
            sum + habit.completionRecords.filter { record in
                record.date > Date().addingTimeInterval(-28 * 24 * 60 * 60)
            }.count
        }
        return totalPossible > 0 ? Double(totalCompleted) / Double(totalPossible) : 0
    }
    
    var nextLevel: UserLevel? {
        UserLevel.getNextLevel(after: habitManager.currentUserLevel)
    }
    
    var progressToNextLevel: Double {
        guard let next = nextLevel else { return 1.0 }
        let currentLevelPoints = habitManager.currentUserLevel.requiredPoints
        let pointsNeeded = next.requiredPoints - currentLevelPoints
        let pointsEarned = habitManager.totalUserPoints - currentLevelPoints
        return min(Double(pointsEarned) / Double(pointsNeeded), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // レベル進捗
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("現在のレベル")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        HStack(spacing: 12) {
                            Image(systemName: habitManager.currentUserLevel.icon)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(habitManager.currentUserLevel.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lv.\(habitManager.currentUserLevel.level)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                Text(habitManager.currentUserLevel.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("総ポイント")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            Text("\(habitManager.totalUserPoints)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }
                    }
                }
                
                if let next = nextLevel {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("次のレベル: \(next.title)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Spacer()
                            
                            Text("あと\(next.requiredPoints - habitManager.totalUserPoints)pt")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                habitManager.currentUserLevel.color,
                                                next.color
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progressToNextLevel, height: 12)
                            }
                        }
                        .frame(height: 12)
                    }
                }
            }
            .padding()
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
            
            // 全体統計
            Text("全体の統計")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                OverallStatCard(
                    title: "総習慣数",
                    value: "\(totalHabits)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                OverallStatCard(
                    title: "今日の達成",
                    value: "\(activeToday)/\(totalHabits)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                OverallStatCard(
                    title: "達成率",
                    value: "\(Int(overallCompletionRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
        }
        .padding()
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

// 統計カード（全体用）
struct OverallStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
                Image(systemName: icon)
                .font(.system(size: 24))
                    .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        )
    }
}

// 習慣ごとの統計セクション
struct HabitStatsSection: View {
    let habitManager: HabitManager
    @Binding var selectedHabit: Habit?
    @StateObject private var themeManager = ThemeManager.shared
    
    var sortedHabits: [Habit] {
        habitManager.habits.sorted { $0.totalPoints > $1.totalPoints }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("習慣別ランキング")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(sortedHabits.enumerated()), id: \.element.id) { index, habit in
                        HabitRankingCard(
                            habit: habit,
                            rank: index + 1,
                            statistics: habitManager.getStatistics(for: habit),
                            isSelected: selectedHabit?.id == habit.id
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedHabit = selectedHabit?.id == habit.id ? nil : habit
                            }
                        }
                    }
                }
            }
        }
        .padding()
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

struct HabitRankingCard: View {
    let habit: Habit
    let rank: Int
    let statistics: HabitStatistics
    let isSelected: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.7)
        case 3: return .orange
        default: return themeManager.currentTheme.secondaryTextColor
        }
    }
    
    var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "rosette"
        default: return "\(rank).circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // ランクバッジ
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(rankColor)
                }
            }
            
            // アイコン
            ZStack {
                Circle()
                    .fill((themeManager.getCardColor(for: habit.color) ?? .blue).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                    Image(systemName: habit.icon)
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.getCardColor(for: habit.color) ?? .blue)
            }
                    
                    Text(habit.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textColor)
                .lineLimit(1)
            
            // 難易度バッジ
            HStack(spacing: 4) {
                Image(systemName: habit.difficulty.icon)
                    .font(.system(size: 10))
                Text(habit.difficulty.displayName)
                    .font(.system(size: 10, weight: .medium))
                }
            .foregroundColor(habit.difficulty.color)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("\(habit.totalPoints) pt")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("\(statistics.currentStreak)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            }
        .frame(width: 120)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? (themeManager.getCardColor(for: habit.color) ?? .blue).opacity(0.2) : themeManager.currentTheme.secondaryBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? (themeManager.getCardColor(for: habit.color) ?? .blue) : Color.clear, lineWidth: 2)
                )
        )
    }
}

// 週間パフォーマンスセクション
struct WeeklyPerformanceSection: View {
    let habitManager: HabitManager
    @StateObject private var themeManager = ThemeManager.shared
    
    var weekdayPerformance: [(day: String, rate: Double)] {
        let calendar = Calendar.current
        let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
        var performance: [(String, Double)] = []
        
        for weekday in 0..<7 {
            var completed = 0
            var total = 0
            
            // 過去4週間の該当曜日をチェック
            for weekOffset in 0..<4 {
                let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date())!
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)!.start
                let targetDate = calendar.date(byAdding: .day, value: weekday, to: startOfWeek)!
                
                for habit in habitManager.habits {
                    if habit.isTargetDay(date: targetDate) {
                        total += 1
                        if habit.isCompleted(on: targetDate) {
                            completed += 1
                        }
                    }
                }
            }
            
            let rate = total > 0 ? Double(completed) / Double(total) : 0
            performance.append((weekdaySymbols[weekday], rate))
        }
        
        return performance
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("曜日別パフォーマンス")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack(spacing: 12) {
                ForEach(weekdayPerformance, id: \.day) { item in
                    VStack(spacing: 8) {
                        Text(item.day)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.secondaryBackgroundColor)
                                .frame(width: 30, height: 100)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    item.rate > 0.8 ? Color.green :
                                    item.rate > 0.6 ? Color.orange :
                                    Color.red
                                )
                                .frame(width: 30, height: CGFloat(item.rate * 100))
                        }
                        
                        Text("\(Int(item.rate * 100))%")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
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

// 習慣相性診断セクション
struct HabitCompatibilitySection: View {
    let habitManager: HabitManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingDetail = false
    
    var compatibilityPairs: [(habit1: Habit, habit2: Habit, score: Double)] {
        var pairs: [(Habit, Habit, Double)] = []
        let habits = habitManager.habits
        
        for i in 0..<habits.count {
            for j in i+1..<habits.count {
                let score = habitManager.calculateHabitCompatibility(habits[i], habits[j])
                if score > 0 {
                    pairs.append((habits[i], habits[j], score))
                }
            }
        }
        
        return pairs.sorted(by: { $0.2 > $1.2 }).prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("習慣の相性診断")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Button(action: { showingDetail = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            
            if compatibilityPairs.isEmpty {
                Text("まだ相性データがありません。\n複数の習慣を継続すると表示されます。")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(compatibilityPairs, id: \.habit1.id) { pair in
                        CompatibilityRow(
                            habit1: pair.habit1,
                            habit2: pair.habit2,
                            score: pair.score
                        )
                    }
                }
            }
        }
        .padding()
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
        .sheet(isPresented: $showingDetail) {
            CompatibilityDetailView()
        }
    }
}

// 習慣相性の行
struct CompatibilityRow: View {
    let habit1: Habit
    let habit2: Habit
    let score: Double
    @StateObject private var themeManager = ThemeManager.shared
    
    var compatibilityEmoji: String {
        switch score {
        case 0.8...1.0:
            return "🔥"
        case 0.6..<0.8:
            return "⭐"
        case 0.4..<0.6:
            return "👍"
        default:
            return "💫"
        }
    }
    
    var compatibilityText: String {
        switch score {
        case 0.8...1.0:
            return "最高の相性"
        case 0.6..<0.8:
            return "良い相性"
        case 0.4..<0.6:
            return "相性あり"
        default:
            return "関連あり"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 習慣1のアイコン
            ZStack {
                Circle()
                    .fill(Color(habit1.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: habit1.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(habit1.color))
            }
            
            Text("×")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            // 習慣2のアイコン
            ZStack {
                Circle()
                    .fill(Color(habit2.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: habit2.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(habit2.color))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(habit1.name) × \(habit2.name)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .lineLimit(1)
                    
                HStack(spacing: 4) {
                    Text(compatibilityEmoji)
                        .font(.system(size: 12))
                    Text("\(compatibilityText) (\(Int(score * 100))%)")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
                        Spacer()
        }
        .padding(.vertical, 8)
    }
}

// 相性診断の詳細説明
struct CompatibilityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("習慣の相性診断について")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("この機能は、複数の習慣が同じ日に達成される頻度を分析し、習慣間の相関関係を見つけます。")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                VStack(alignment: .leading, spacing: 12) {
                    CompatibilityExplanationRow(emoji: "🔥", text: "最高の相性 (80%以上)", description: "ほぼ常に一緒に達成される習慣")
                    CompatibilityExplanationRow(emoji: "⭐", text: "良い相性 (60-80%)", description: "頻繁に一緒に達成される習慣")
                    CompatibilityExplanationRow(emoji: "👍", text: "相性あり (40-60%)", description: "しばしば一緒に達成される習慣")
                    CompatibilityExplanationRow(emoji: "💫", text: "関連あり (40%未満)", description: "時々一緒に達成される習慣")
                }
                
                Text("ヒント")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.top)
                
                Text("相性の良い習慣は「習慣の連鎖」として活用できます。一つを達成したら、もう一つも続けて行うことで、両方の習慣が定着しやすくなります。")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                        Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
    }
                }
            }
        }
    }
}

struct CompatibilityExplanationRow: View {
    let emoji: String
    let text: String
    let description: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
    }
}

// ムード分析セクション
struct MoodAnalysisSection: View {
    let habitManager: HabitManager
    @StateObject private var themeManager = ThemeManager.shared
    
    var moodData: [(mood: String, count: Int)] {
        var moodCounts: [String: Int] = [:]
        
        for habit in habitManager.habits {
            for record in habit.completionRecords {
                if let mood = record.mood {
                    moodCounts[mood, default: 0] += 1
                }
            }
        }
        
        return moodCounts.map { (mood: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        }
        
    var totalMoodRecords: Int {
        moodData.reduce(0) { $0 + $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("気分の記録")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if moodData.isEmpty {
                Text("まだ気分の記録がありません。\n習慣を完了するときに気分を記録してみましょう。")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                HStack(spacing: 20) {
                    ForEach(moodData.prefix(5), id: \.mood) { item in
                        VStack(spacing: 8) {
                            Text(item.mood)
                                .font(.system(size: 30))
                            
                            Text("\(item.count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text("\(Int(Double(item.count) / Double(totalMoodRecords) * 100))%")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                if let mostFrequentMood = moodData.first {
                    Text("最も多い気分は「\(mostFrequentMood.mood)」です！")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            }
        .padding()
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

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView(habitManager: HabitManager())
    }
} 