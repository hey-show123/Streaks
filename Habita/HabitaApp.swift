//
//  HabitaApp.swift
//  Habita
//
//  Created by 山﨑祥平 on 2025/07/13.
//

import SwiftUI

@main
struct HabitaApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light)
                .onAppear {
                    setupAppearance()
                    setupNotifications()
                }
        }
    }
    
    private func setupAppearance() {
        // ナビゲーションバーの外観設定
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeManager.currentTheme.backgroundColor)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(themeManager.currentTheme.textColor)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(themeManager.currentTheme.textColor)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // タブバーの外観設定
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(themeManager.currentTheme.backgroundColor)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setupNotifications() {
        // 通知カテゴリーを設定
        notificationManager.setupNotificationCategories()
        
        // 通知の権限をリクエスト
        notificationManager.requestAuthorization { granted in
            if granted {
                print("通知の権限が許可されました")
            } else {
                print("通知の権限が拒否されました")
            }
        }
        
        // バッジ数をリセット
        notificationManager.resetBadgeCount()
    }
}
