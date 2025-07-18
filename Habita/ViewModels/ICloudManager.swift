//
//  ICloudManager.swift
//  Habita
//
//  Created by 山﨑祥平 on 2025/07/13.
//

import Foundation
import CloudKit
import SwiftUI

class ICloudManager: ObservableObject {
    static let shared = ICloudManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isCloudAccountAvailable = false
    
    // Team IDを含む正しいコンテナIDを使用
    private let container = CKContainer(identifier: "iCloud.9P9L6C2L47.hey-show.Habita")
    private let privateDatabase: CKDatabase
    private let recordType = "Habit"
    
    init() {
        self.privateDatabase = container.privateCloudDatabase
        
        // デバッグ: コンテナ情報を出力
        print("=== CloudKit Container Info ===")
        print("Container Identifier: \(container.containerIdentifier ?? "nil")")
        
        checkAccountStatus()
        // CloudKitゾーンを初期化
        initializeCloudKitZone()
    }
    
    // CloudKitゾーンの初期化
    private func initializeCloudKitZone() {
        // デフォルトゾーンを使用するため、特別な初期化は不要
        // ただし、スキーマの作成を促すため、空のクエリを実行
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        
        operation.recordFetchedBlock = { _ in
            // レコードが取得された場合は何もしない
        }
        
        operation.queryCompletionBlock = { (cursor, error) in
            if let error = error as? CKError {
                print("CloudKit初期化エラー: \(error.localizedDescription)")
                if error.code == .unknownItem {
                    print("スキーマが未作成の可能性があります")
                }
            } else {
                print("CloudKit初期化成功")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    // アカウントの状態を確認
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudAccountAvailable = true
                case .noAccount:
                    self?.isCloudAccountAvailable = false
                    self?.syncError = "iCloudアカウントが設定されていません"
                case .restricted:
                    self?.isCloudAccountAvailable = false
                    self?.syncError = "iCloudアクセスが制限されています"
                case .couldNotDetermine:
                    self?.isCloudAccountAvailable = false
                    self?.syncError = "iCloudの状態を確認できません"
                default:
                    self?.isCloudAccountAvailable = false
                }
            }
        }
    }
    
    // データを同期
    func syncData(habits: [Habit]) {
        guard isCloudAccountAvailable else {
            syncError = "iCloudが利用できません"
            return
        }
        
        isSyncing = true
        syncError = nil
        
        // 既存のレコードを削除
        deleteAllRecords { [weak self] in
            // 新しいレコードを保存
            self?.saveHabits(habits)
        }
    }
    
    // 習慣をiCloudに保存
    private func saveHabits(_ habits: [Habit]) {
        let records = habits.map { habit in
            let record = CKRecord(recordType: recordType)
            record["id"] = habit.id.uuidString
            record["name"] = habit.name
            record["icon"] = habit.icon
            record["color"] = habit.color
            record["type"] = habit.type.rawValue
            record["difficulty"] = habit.difficulty.rawValue
            record["frequency"] = habit.frequency.rawValue
            record["targetCount"] = habit.targetCount
            record["currentStreak"] = habit.currentStreak
            record["bestStreak"] = habit.bestStreak
            record["totalCompletions"] = habit.totalCompletions
            record["totalPoints"] = habit.totalPoints
            record["createdDate"] = habit.createdDate
            record["notes"] = habit.notes
            record["pageIndex"] = habit.pageIndex
            record["position"] = habit.position
            
            // 通知関連のプロパティ
            record["isReminderEnabled"] = habit.isReminderEnabled
            if let reminderTime = habit.reminderTime {
                record["reminderTime"] = reminderTime
            }
            
            // 完了記録を保存（CloudKitではDate配列として保存）
            // 最新の365日分のみを保存してレコードサイズを制限
            let recentCompletions = habit.completionRecords
                .sorted { $0.date > $1.date }
                .prefix(365)
                .map { $0.date }
            
            if !recentCompletions.isEmpty {
                record["completionDates"] = recentCompletions as CKRecordValue
            }
            
            return record
        }
        
        // レコードを小さなバッチに分けて保存
        let batchSize = 50
        for i in stride(from: 0, to: records.count, by: batchSize) {
            let endIndex = min(i + batchSize, records.count)
            let batch = Array(records[i..<endIndex])
            
            let operation = CKModifyRecordsOperation(recordsToSave: batch, recordIDsToDelete: nil)
            operation.savePolicy = .allKeys
            operation.perRecordSaveBlock = { recordID, result in
                switch result {
                case .success(let record):
                    print("Successfully saved record: \(record.recordID)")
                case .failure(let error):
                    print("Failed to save record \(recordID): \(error)")
                }
            }
            
            operation.modifyRecordsCompletionBlock = { [weak self] (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecord.ID]?, error: Error?) in
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    
                    if let error = error {
                        if let ckError = error as? CKError {
                            print("CloudKit Error Code: \(ckError.code.rawValue)")
                            print("CloudKit Error Description: \(ckError.localizedDescription)")
                            
                            // より詳細なエラー情報を取得
                            switch ckError.code {
                            case .networkUnavailable:
                                self?.syncError = "ネットワークに接続できません"
                            case .networkFailure:
                                self?.syncError = "ネットワークエラーが発生しました"
                            case .quotaExceeded:
                                self?.syncError = "iCloudの容量が不足しています"
                            case .zoneNotFound:
                                self?.syncError = "CloudKitゾーンが見つかりません"
                            case .unknownItem:
                                self?.syncError = "不明なアイテムです"
                            case .invalidArguments:
                                self?.syncError = "無効な引数です"
                            case .serverRecordChanged:
                                self?.syncError = "サーバーのレコードが変更されました"
                            case .limitExceeded:
                                self?.syncError = "レコードサイズが制限を超えています"
                            case .batchRequestFailed:
                                // 部分的なエラーの詳細を取得
                                if let partialErrors = ckError.partialErrorsByItemID {
                                    for (recordID, partialError) in partialErrors {
                                        print("Partial error for record \(recordID): \(partialError)")
                                    }
                                }
                                self?.syncError = "一部のレコードの同期に失敗しました"
                            default:
                                self?.syncError = "同期エラー: \(error.localizedDescription)"
                            }
                        } else {
                            self?.syncError = "同期エラー: \(error.localizedDescription)"
                        }
                    } else {
                        self?.lastSyncDate = Date()
                        self?.syncError = nil
                    }
                }
            }
            
            privateDatabase.add(operation)
        }
    }
    
    // iCloudからデータを取得
    func fetchData(completion: @escaping ([Habit]) -> Void) {
        guard isCloudAccountAvailable else {
            completion([])
            return
        }
        
        isSyncing = true
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (matchResults, _)):
                    let records = matchResults.compactMap { _, result in
                        try? result.get()
                    }
                self?.isSyncing = false
                
                let habits = records.compactMap { record -> Habit? in
                    guard let idString = record["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let name = record["name"] as? String,
                          let icon = record["icon"] as? String,
                          let color = record["color"] as? String,
                          let typeString = record["type"] as? String,
                          let type = HabitType(rawValue: typeString),
                          let difficultyString = record["difficulty"] as? String,
                          let difficulty = HabitDifficulty(rawValue: difficultyString),
                          let frequencyString = record["frequency"] as? String,
                          let frequency = HabitFrequency(rawValue: frequencyString),
                          let targetCount = record["targetCount"] as? Int,
                          let currentStreak = record["currentStreak"] as? Int,
                          let bestStreak = record["bestStreak"] as? Int,
                          let totalCompletions = record["totalCompletions"] as? Int,
                          let totalPoints = record["totalPoints"] as? Int,
                          let createdDate = record["createdDate"] as? Date,
                          let pageIndex = record["pageIndex"] as? Int,
                          let position = record["position"] as? Int else {
                        return nil
                    }
                    
                    var habit = Habit(
                        id: id,
                        name: name,
                        icon: icon,
                        color: color,
                        type: type,
                        difficulty: difficulty,
                        frequency: frequency,
                        targetCount: targetCount,
                        pageIndex: pageIndex,
                        position: position
                    )
                    
                    habit.currentStreak = currentStreak
                    habit.bestStreak = bestStreak
                    habit.totalCompletions = totalCompletions
                    habit.totalPoints = totalPoints
                    habit.createdDate = createdDate
                    habit.notes = record["notes"] as? String ?? ""
                    
                    // 通知関連のプロパティを復元
                    habit.isReminderEnabled = record["isReminderEnabled"] as? Bool ?? false
                    habit.reminderTime = record["reminderTime"] as? Date
                    
                    // 完了履歴を復元（CloudKitからはDateのみ復元）
                    if let completionDates = record["completionDates"] as? [Date] {
                        habit.completionRecords = completionDates.map { date in
                            CompletionRecord(date: date)
                        }
                    }
                    
                    return habit
                }
                
                // 同期後に通知を再スケジュール
                for habit in habits {
                    if habit.isReminderEnabled, let reminderTime = habit.reminderTime {
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
                        NotificationManager.shared.scheduleHabitReminder(for: habit, at: components)
                    }
                }
                
                self?.lastSyncDate = Date()
                completion(habits)
                    
                case .failure(let error):
                    self?.syncError = "取得エラー: \(error.localizedDescription)"
                    completion([])
                }
            }
        }
    }
    
    // 全レコードを削除
    private func deleteAllRecords(completion: @escaping () -> Void) {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let (matchResults, _)):
                let recordIDs = matchResults.compactMap { id, result -> CKRecord.ID? in
                    if case .success(let record) = result {
                        return record.recordID
                    }
                    return nil
                }
            
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
                operation.modifyRecordsCompletionBlock = { _, _, _ in
                    completion()
                }
                
                self.privateDatabase.add(operation)
                
            case .failure(_):
                completion()
            }
        }
    }
} 