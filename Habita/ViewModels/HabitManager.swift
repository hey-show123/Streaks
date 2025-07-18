import Foundation
import SwiftUI
import Combine

@MainActor
class HabitManager: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var totalUserPoints: Int = 0
    @Published var currentUserLevel: UserLevel = .beginner
    
    // UserDefaults keys
    private let habitsKey = "habits"
    private let pointsKey = "userPoints"
    private let userDefaults = UserDefaults.standard
    
    // 気分記録の設定（通知ベースにするため）
    @AppStorage("askMoodOnCompletion") var askMoodOnCompletion: Bool = false  // デフォルトは false（聞かない）
    @AppStorage("moodNotificationEnabled") var moodNotificationEnabled: Bool = true  // 寝る前の通知はデフォルトでオン
    @AppStorage("moodNotificationTime") var moodNotificationTime: Date = {
        // デフォルトは22:00（午後10時）
        let components = DateComponents(hour: 22, minute: 0)
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadHabits()
        loadUserPoints()
        setupAutoSave()
        updateStreaks()
        updateUserLevel()
    }
    
    // 自動保存の設定
    private func setupAutoSave() {
        $habits
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveHabits()
            }
            .store(in: &cancellables)
        
        $totalUserPoints
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveUserPoints()
            }
            .store(in: &cancellables)
    }
    
    // 習慣の保存
    func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            userDefaults.set(encoded, forKey: habitsKey)
        }
    }
    
    // 習慣の読み込み
    private func loadHabits() {
        guard let data = userDefaults.data(forKey: habitsKey),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else {
            // デモデータをロード
            loadDemoData()
            return
        }
        habits = decoded
    }
    
    // ユーザーポイントの保存
    private func saveUserPoints() {
        userDefaults.set(totalUserPoints, forKey: pointsKey)
    }
    
    // ユーザーポイントの読み込み
    private func loadUserPoints() {
        totalUserPoints = userDefaults.integer(forKey: pointsKey)
    }
    
    // ユーザーレベルの更新
    private func updateUserLevel() {
        currentUserLevel = UserLevel.getLevelForPoints(totalUserPoints)
    }
    
    // デモデータのロード
    private func loadDemoData() {
        habits = [
            Habit(
                name: "朝の運動",
                icon: "figure.run",
                color: "orange",
                type: .positive,
                difficulty: .medium,
                pageIndex: 0,
                position: 0
            ),
            Habit(
                name: "読書",
                icon: "book.fill",
                color: "blue",
                type: .positive,
                difficulty: .easy,
                pageIndex: 0,
                position: 1
            ),
            Habit(
                name: "瞑想",
                icon: "brain.head.profile",
                color: "purple",
                type: .timed,
                difficulty: .hard,
                timerDuration: 600, // 10分
                pageIndex: 0,
                position: 2
            ),
            Habit(
                name: "ジャンクフード禁止",
                icon: "xmark.circle.fill",
                color: "red",
                type: .negative,
                difficulty: .hard,
                pageIndex: 0,
                position: 3
            )
        ]
    }
    
    // 特定のページの習慣を取得
    func habitsForPage(_ pageIndex: Int) -> [Habit] {
        habits.filter { $0.pageIndex == pageIndex }
            .sorted { $0.position < $1.position }
    }
    
    // 習慣を追加
    func addHabit(_ habit: Habit) {
        // 空いている位置を探す
        var newHabit = habit
        let pageHabits = habitsForPage(habit.pageIndex)
        
        if pageHabits.count < 6 {
            // 空いている最小の位置を見つける
            let occupiedPositions = Set(pageHabits.map { $0.position })
            for position in 0..<6 {
                if !occupiedPositions.contains(position) {
                    newHabit.position = position
                    break
                }
            }
            habits.append(newHabit)
            
            // 通知をスケジュール
            if newHabit.isReminderEnabled, let reminderTime = newHabit.reminderTime {
                scheduleNotification(for: newHabit, at: reminderTime)
            }
        }
    }
    
    // 習慣を削除
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        // 通知をキャンセル
        NotificationManager.shared.cancelNotification(for: habit.id)
    }
    
    // 習慣を更新
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            
            // 通知を更新
            NotificationManager.shared.cancelNotification(for: habit.id)
            if habit.isReminderEnabled, let reminderTime = habit.reminderTime {
                scheduleNotification(for: habit, at: reminderTime)
            }
        }
    }
    
    // 通知をスケジュール
    private func scheduleNotification(for habit: Habit, at time: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        NotificationManager.shared.scheduleHabitReminder(for: habit, at: components)
    }
    
    // 習慣を完了/未完了にする
    func toggleCompletion(for habit: Habit, on date: Date = Date(), mood: String? = nil) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        if habit.isCompleted(on: targetDate) {
            // 完了を取り消す
            habits[index].completionRecords.removeAll { record in
                calendar.isDate(record.date, inSameDayAs: targetDate)
            }
            habits[index].totalCompletions = max(0, habits[index].totalCompletions - 1)
            
            // ポイントを減算
            let pointsToRemove = habit.difficulty.points
            habits[index].totalPoints = max(0, habits[index].totalPoints - pointsToRemove)
            totalUserPoints = max(0, totalUserPoints - pointsToRemove)
            
            // 削除サウンドを再生
            SoundManager.shared.playDelete()
        } else {
            // 完了にする
            let record = CompletionRecord(date: targetDate, mood: mood)
            habits[index].completionRecords.append(record)
            habits[index].totalCompletions += 1
            
            // ポイントを加算
            let basePoints = habit.difficulty.points
            var bonusMultiplier = 1.0
            
            // ストリークボーナス
            if habits[index].currentStreak >= 7 {
                bonusMultiplier += 0.2 // 7日以上で20%ボーナス
            }
            if habits[index].currentStreak >= 30 {
                bonusMultiplier += 0.3 // 30日以上でさらに30%ボーナス
            }
            
            let earnedPoints = Int(Double(basePoints) * bonusMultiplier)
            habits[index].totalPoints += earnedPoints
            totalUserPoints += earnedPoints
            
            // 完了サウンドを再生
            SoundManager.shared.playComplete()
            
            // ポイント獲得サウンドも再生
            if earnedPoints > basePoints {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    SoundManager.shared.playCoin()
                }
            }
        }
        
        // ストリークを更新
        let previousStreak = habits[index].currentStreak
        updateStreak(for: &habits[index])
        
        // 連続記録達成通知
        let newStreak = habits[index].currentStreak
        if !habit.isCompleted(on: targetDate) && newStreak > previousStreak {
            // マイルストーン達成時に通知
            if [7, 14, 30, 60, 100, 365].contains(newStreak) {
                NotificationManager.shared.sendStreakAchievementNotification(
                    habit: habits[index],
                    streakCount: newStreak
                )
                
                // 達成サウンドを再生
                SoundManager.shared.playAchievement()
            }
        }
        
        // ユーザーレベルを更新
        let previousLevel = currentUserLevel.level
        updateUserLevel()
        
        // レベルアップ時の処理
        if currentUserLevel.level > previousLevel {
            // レベルアップサウンドを再生
            SoundManager.shared.playLevelUp()
        }
    }
    
    // タイマー付き習慣を完了
    func completeTimedHabit(_ habit: Habit, duration: TimeInterval, mood: String? = nil) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        let record = CompletionRecord(date: Date(), duration: duration, mood: mood)
        habits[index].completionRecords.append(record)
        habits[index].totalCompletions += 1
        
        // ポイントを加算（時間達成ボーナス付き）
        let basePoints = habit.difficulty.points
        var bonusMultiplier = 1.0
        
        // 目標時間達成ボーナス
        if duration >= habit.timerDuration {
            bonusMultiplier += 0.5 // 目標時間達成で50%ボーナス
        }
        
        // ストリークボーナス
        if habits[index].currentStreak >= 7 {
            bonusMultiplier += 0.2
        }
        if habits[index].currentStreak >= 30 {
            bonusMultiplier += 0.3
        }
        
        let earnedPoints = Int(Double(basePoints) * bonusMultiplier)
        habits[index].totalPoints += earnedPoints
        totalUserPoints += earnedPoints
        
        updateStreak(for: &habits[index])
        updateUserLevel()
    }
    
    // ストリークの更新
    private func updateStreak(for habit: inout Habit) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 完了記録を日付順にソート
        let sortedRecords = habit.completionRecords
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
            .removingDuplicates()
        
        var currentStreak = 0
        var checkDate = today
        
        // 今日から遡って連続日数を計算
        for recordDate in sortedRecords {
            if recordDate == checkDate {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if recordDate < checkDate {
                break
            }
        }
        
        habit.currentStreak = currentStreak
        habit.bestStreak = max(habit.bestStreak, currentStreak)
    }
    
    // 全習慣のストリークを更新
    private func updateStreaks() {
        for index in habits.indices {
            updateStreak(for: &habits[index])
        }
    }
    
    // 統計情報を取得
    func getStatistics(for habit: Habit) -> HabitStatistics {
        let calendar = Calendar.current
        let now = Date()
        let _ = calendar.date(byAdding: .day, value: -6, to: now)!
        
        // 過去7日間の完了率
        var last7DaysCompleted = 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                if habit.isCompleted(on: date) && habit.isTargetDay(date: date) {
                    last7DaysCompleted += 1
                }
            }
        }
        let last7DaysCompletion = Double(last7DaysCompleted) / 7.0 * 100
        
        // 過去30日間の完了率
        let _ = calendar.date(byAdding: .day, value: -29, to: now)!
        var last30DaysCompleted = 0
        var targetDaysCount = 0
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
            if habit.isTargetDay(date: date) {
                    targetDaysCount += 1
                if habit.isCompleted(on: date) {
                        last30DaysCompleted += 1
                    }
                }
            }
        }
        
        let last30DaysCompletion = targetDaysCount > 0 ? Double(last30DaysCompleted) / Double(targetDaysCount) * 100 : 0
        
        return HabitStatistics(
            currentStreak: habit.currentStreak,
            bestStreak: habit.bestStreak,
            totalCompletions: habit.totalCompletions,
            last7DaysCompletion: last7DaysCompletion,
            last30DaysCompletion: last30DaysCompletion
        )
    }
    
    // モチベーションメッセージを取得
    func getMotivationMessage(for streak: Int) -> String? {
        switch streak {
        case 3:
            return "3日連続達成！🎯 良いスタートです！"
        case 7:
            return "1週間達成！🌟 習慣が身についてきました！"
        case 14:
            return "2週間継続！💪 素晴らしい成果です！"
        case 21:
            return "3週間達成！🚀 習慣化まであと少し！"
        case 30:
            return "1ヶ月達成！🏆 習慣として定着しました！"
        case 50:
            return "50日連続！✨ 驚異的な継続力です！"
        case 100:
            return "100日達成！🎊 レジェンド級の偉業です！"
        case 365:
            return "1年継続！🌈 あなたは習慣の達人です！"
        default:
            if streak > 0 && streak % 100 == 0 {
                return "\(streak)日連続！🎉 信じられない記録です！"
            }
            return nil
        }
    }
    
    // 習慣の相性スコアを計算
    func calculateHabitCompatibility(_ habit1: Habit, _ habit2: Habit) -> Double {
        let calendar = Calendar.current
        let _ = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        var bothCompleted = 0
        var totalDays = 0
        
        // 過去30日間で両方の習慣が実行された日数を計算
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let habit1ShouldComplete = habit1.isTargetDay(date: date)
                let habit2ShouldComplete = habit2.isTargetDay(date: date)
                
                if habit1ShouldComplete && habit2ShouldComplete {
                    totalDays += 1
                    if habit1.isCompleted(on: date) && habit2.isCompleted(on: date) {
                        bothCompleted += 1
                    }
                }
            }
        }
        
        return totalDays > 0 ? Double(bothCompleted) / Double(totalDays) : 0
    }
}

// 統計情報
struct HabitStatistics {
    let currentStreak: Int
    let bestStreak: Int
    let totalCompletions: Int
    let last7DaysCompletion: Double
    let last30DaysCompletion: Double
}

// 重複を削除する拡張
extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result = [Element]()
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
} 