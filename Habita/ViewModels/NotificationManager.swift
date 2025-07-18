//
//  NotificationManager.swift
//  Habita
//
//  Created by 山﨑祥平 on 2025/07/13.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        checkAuthorizationStatus()
    }
    
    // 通知の権限状態を確認
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // 通知の許可をリクエスト
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    // 習慣のリマインダーを設定
    func scheduleHabitReminder(for habit: Habit, at time: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = "習慣のリマインダー"
        content.body = "「\(habit.name)」の時間です！今日も頑張りましょう！"
        content.sound = .default
        content.badge = 1
        
        // カテゴリーを設定（アクション付き通知用）
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = ["habitId": habit.id.uuidString]
        
        // トリガーを作成（毎日指定時刻）
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        
        // リクエストを作成
        let request = UNNotificationRequest(
            identifier: "habit_\(habit.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        // 通知をスケジュール
        notificationCenter.add(request) { error in
            if let error = error {
                print("通知のスケジュール失敗: \(error)")
            }
        }
    }
    
    // 夜の気分記録リマインダー
    func scheduleNightMoodReminder(at time: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = "今日はどんな一日でしたか？"
        content.body = "寝る前に今日の気分を記録しましょう"
        content.sound = .default
        content.categoryIdentifier = "MOOD_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "night_mood_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("気分記録通知のスケジュール失敗: \(error)")
            }
        }
    }
    
    // 週次レポート通知
    func scheduleWeeklyReport() {
        let content = UNMutableNotificationContent()
        content.title = "週間レポートが準備できました！"
        content.body = "今週の習慣達成状況を確認しましょう"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REPORT"
        
        // 毎週日曜日の朝9時に通知
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // 日曜日
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_report",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("週次レポート通知のスケジュール失敗: \(error)")
            }
        }
    }
    
    // 連続記録達成通知
    func sendStreakAchievementNotification(habit: Habit, streakCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 おめでとうございます！"
        content.body = "「\(habit.name)」を\(streakCount)日連続で達成しました！"
        content.sound = .default
        content.categoryIdentifier = "STREAK_ACHIEVEMENT"
        
        // 即座に通知
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    // 特定の習慣の通知をキャンセル
    func cancelNotification(for habitId: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["habit_\(habitId.uuidString)"]
        )
    }
    
    // すべての通知をキャンセル
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // ペンディング中の通知を取得
    func fetchPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingNotifications = requests
            }
        }
    }
    
    // 通知のカテゴリーを設定（アクション付き通知用）
    func setupNotificationCategories() {
        // 習慣リマインダーのアクション
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_HABIT",
            title: "完了",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_HABIT",
            title: "後で",
            options: []
        )
        
        let habitCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 気分記録のアクション
        let recordMoodAction = UNNotificationAction(
            identifier: "RECORD_MOOD",
            title: "記録する",
            options: [.foreground]
        )
        
        let moodCategory = UNNotificationCategory(
            identifier: "MOOD_REMINDER",
            actions: [recordMoodAction],
            intentIdentifiers: [],
            options: []
        )
        
        // カテゴリーを登録
        notificationCenter.setNotificationCategories([habitCategory, moodCategory])
    }
    
    // バッジ数をリセット
    func resetBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
} 