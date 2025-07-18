//
//  SoundManager.swift
//  Habita
//
//  Created by 山﨑祥平 on 2025/07/13.
//

import Foundation
import AVFoundation
import SwiftUI

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isSoundEnabled = true
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    // サウンドの種類
    enum SoundType: String {
        case tap = "tap"
        case complete = "complete"
        case achievement = "achievement"
        case delete = "delete"
        case error = "error"
        case notification = "notification"
        case levelUp = "levelup"
        case coin = "coin"
    }
    
    init() {
        // UserDefaultsから設定を読み込み
        isSoundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        
        // オーディオセッションの設定
        setupAudioSession()
        
        // サウンドファイルをプリロード
        preloadSounds()
    }
    
    // オーディオセッションの設定
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("オーディオセッションの設定エラー: \(error)")
        }
    }
    
    // サウンドファイルをプリロード
    private func preloadSounds() {
        let sounds: [(SoundType, String)] = [
            (.tap, "tap.wav"),
            (.complete, "complete.wav"),
            (.achievement, "achievement.wav"),
            (.delete, "delete.wav"),
            (.error, "error.wav"),
            (.notification, "notification.wav"),
            (.levelUp, "levelup.wav"),
            (.coin, "coin.wav")
        ]
        
        for (type, filename) in sounds {
            if let url = Bundle.main.url(forResource: filename, withExtension: nil) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[type.rawValue] = player
                } catch {
                    // サウンドファイルが利用できない場合は警告のみ出力
                    print("⚠️ サウンドファイル未配置: \(filename)")
                }
            } else {
                print("⚠️ サウンドファイル未配置: \(filename)")
            }
        }
    }
    
    // サウンドを再生
    func play(_ soundType: SoundType, volume: Float = 0.5) {
        guard isSoundEnabled else { return }
        
        DispatchQueue.main.async {
            if let player = self.audioPlayers[soundType.rawValue] {
                player.volume = volume
                player.play()
            } else {
                // サウンドファイルが利用できない場合、システムサウンドを使用
                self.playSystemSound(for: soundType)
            }
        }
    }
    
    // 短いタップ音
    func playTap() {
        play(.tap, volume: 0.3)
    }
    
    // 完了音
    func playComplete() {
        play(.complete, volume: 0.6)
    }
    
    // 達成音
    func playAchievement() {
        play(.achievement, volume: 0.8)
    }
    
    // 削除音
    func playDelete() {
        play(.delete, volume: 0.4)
    }
    
    // エラー音
    func playError() {
        play(.error, volume: 0.5)
    }
    
    // 通知音
    func playNotification() {
        play(.notification, volume: 0.6)
    }
    
    // レベルアップ音
    func playLevelUp() {
        play(.levelUp, volume: 0.8)
    }
    
    // コイン獲得音
    func playCoin() {
        play(.coin, volume: 0.5)
    }
    
    // サウンドの有効/無効を切り替え
    func toggleSound() {
        isSoundEnabled.toggle()
        UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
    }
    
    // カスタムサウンドを追加（将来の拡張用）
    func addCustomSound(name: String, url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[name] = player
        } catch {
            print("カスタムサウンドの追加エラー: \(error)")
        }
    }
    
    // バイブレーション付きサウンド
    func playWithHaptic(_ soundType: SoundType, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        play(soundType)
        
        // 触覚フィードバックも同時に実行
        let generator = UIImpactFeedbackGenerator(style: hapticStyle)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // システムサウンドを再生（フォールバック用）
    private func playSystemSound(for soundType: SoundType) {
        let systemSoundID: SystemSoundID
        
        switch soundType {
        case .tap:
            systemSoundID = 1104 // Tock
        case .complete:
            systemSoundID = 1054 // Chime
        case .achievement:
            systemSoundID = 1025 // Fanfare
        case .delete:
            systemSoundID = 1053 // Low Pop
        case .error:
            systemSoundID = 1073 // Error
        case .notification:
            systemSoundID = 1007 // Ding
        case .levelUp:
            systemSoundID = 1026 // Celebration
        case .coin:
            systemSoundID = 1057 // Coin
        }
        
        AudioServicesPlaySystemSound(systemSoundID)
    }
} 