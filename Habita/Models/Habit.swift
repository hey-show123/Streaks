import Foundation
import SwiftUI

// 習慣のタイプ
enum HabitType: String, Codable, CaseIterable {
    case positive = "positive"     // 良い習慣を作る
    case negative = "negative"     // 悪い習慣を断つ
    case timed = "timed"          // 時間制限のある習慣
    
    var displayName: String {
        switch self {
        case .positive:
            return "ポジティブ習慣"
        case .negative:
            return "ネガティブ習慣"
        case .timed:
            return "タイムド習慣"
        }
    }
}

// 習慣の頻度
enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily:
            return "毎日"
        case .weekly:
            return "週ごと"
        case .custom:
            return "カスタム"
        }
    }
}

// 習慣の難易度
enum HabitDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy:
            return "かんたん"
        case .medium:
            return "ふつう"
        case .hard:
            return "むずかしい"
        }
    }
    
    var points: Int {
        switch self {
        case .easy:
            return 10
        case .medium:
            return 25
        case .hard:
            return 50
        }
    }
    
    var color: Color {
        switch self {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .easy:
            return "1.circle.fill"
        case .medium:
            return "2.circle.fill"
        case .hard:
            return "3.circle.fill"
        }
    }
}

// ユーザーレベル
struct UserLevel: Codable {
    let level: Int
    let title: String
    let requiredPoints: Int
    
    var icon: String {
        switch level {
        case 1: return "leaf.fill"
        case 2: return "sparkles"
        case 3: return "flame.fill"
        case 4: return "bolt.fill"
        case 5: return "star.fill"
        case 6: return "crown.fill"
        case 7: return "trophy.fill"
        case 8: return "rosette"
        default: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch level {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        case 4: return .purple
        case 5: return .yellow
        case 6: return .pink
        case 7: return .red
        case 8: return .indigo
        default: return .gray
        }
    }
    
    static let beginner = UserLevel(level: 1, title: "習慣初心者", requiredPoints: 0)
    
    static let levels: [UserLevel] = [
        UserLevel(level: 1, title: "習慣初心者", requiredPoints: 0),
        UserLevel(level: 2, title: "習慣見習い", requiredPoints: 100),
        UserLevel(level: 3, title: "習慣継続者", requiredPoints: 300),
        UserLevel(level: 4, title: "習慣マスター", requiredPoints: 600),
        UserLevel(level: 5, title: "習慣エキスパート", requiredPoints: 1000),
        UserLevel(level: 6, title: "習慣の達人", requiredPoints: 1500),
        UserLevel(level: 7, title: "習慣の鉄人", requiredPoints: 2000),
        UserLevel(level: 8, title: "習慣の神", requiredPoints: 3000)
    ]
    
    static func getLevelForPoints(_ points: Int) -> UserLevel {
        return levels.reversed().first { $0.requiredPoints <= points } ?? levels[0]
    }
    
    static func getNextLevel(after current: UserLevel) -> UserLevel? {
        return levels.first { $0.level == current.level + 1 }
    }
}

// 習慣モデル
struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var type: HabitType
    var difficulty: HabitDifficulty
    var frequency: HabitFrequency
    var targetDays: Set<Int> // 0 = 日曜日, 1 = 月曜日...
    var targetCount: Int // 目標回数（週に何回など）
    var timerDuration: TimeInterval // タイムド習慣の場合の時間（秒）
    var reminderTime: Date?
    var isReminderEnabled: Bool
    var notes: String
    var pageIndex: Int // どのページに表示するか（0-3）
    var position: Int // ページ内での位置（0-5）
    
    // 完了記録
    var completionRecords: [CompletionRecord]
    
    // 統計情報
    var currentStreak: Int
    var bestStreak: Int
    var totalCompletions: Int
    var totalPoints: Int // 獲得ポイントの合計
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "star.fill",
        color: String = "blue",
        type: HabitType = .positive,
        difficulty: HabitDifficulty = .medium,
        frequency: HabitFrequency = .daily,
        targetDays: Set<Int> = Set(0...6),
        targetCount: Int = 7,
        timerDuration: TimeInterval = 0,
        reminderTime: Date? = nil,
        isReminderEnabled: Bool = false,
        notes: String = "",
        pageIndex: Int = 0,
        position: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.difficulty = difficulty
        self.frequency = frequency
        self.targetDays = targetDays
        self.targetCount = targetCount
        self.timerDuration = timerDuration
        self.reminderTime = reminderTime
        self.isReminderEnabled = isReminderEnabled
        self.notes = notes
        self.pageIndex = pageIndex
        self.position = position
        self.completionRecords = []
        self.currentStreak = 0
        self.bestStreak = 0
        self.totalCompletions = 0
        self.totalPoints = 0
        self.createdDate = Date()
    }
    
    // 今日の完了状態を確認
    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return completionRecords.contains { record in
            calendar.isDate(record.date, inSameDayAs: today)
        }
    }
    
    // 特定の日の完了状態を確認
    func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        return completionRecords.contains { record in
            calendar.isDate(record.date, inSameDayAs: targetDate)
        }
    }
    
    // 今日が目標日かどうか
    func isTargetDay(date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1 // 0-6に変換
        return targetDays.contains(weekday)
    }
}

// 完了記録
struct CompletionRecord: Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval? // タイムド習慣の場合の実際の時間
    let note: String?
    let mood: String? // 気分の記録
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval? = nil,
        note: String? = nil,
        mood: String? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.note = note
        self.mood = mood
    }
} 