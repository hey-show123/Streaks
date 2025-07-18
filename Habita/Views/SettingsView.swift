import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    
    @State private var selectedThemePreset: ThemePreset
    @State private var showingThemeDetails = false
    @State private var showingPrivacyPolicy = false
    @State private var showingHelp = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var exportedFileURL: URL?
    
    @StateObject private var iCloudManager = ICloudManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var soundManager = SoundManager.shared
    @EnvironmentObject var habitManager: HabitManager
    
    init() {
        _selectedThemePreset = State(initialValue: ThemeManager.shared.selectedPreset)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // テーマ設定セクション
                        SettingsSectionView(title: "テーマ") {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 16) {
                                    // テーマプリセット選択
                                    ForEach(ThemePreset.allCases, id: \.self) { preset in
                                        ThemePresetRow(
                                            preset: preset,
                                            isSelected: selectedThemePreset == preset,
                                            onTap: {
                                                performHapticFeedback(.light)
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedThemePreset = preset
                                                    themeManager.selectedPreset = preset
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .frame(maxHeight: 400)  // 最大高さを設定
                        }
                        
                        // 通知設定セクション
                        SettingsSectionView(title: "通知") {
                            VStack(spacing: 16) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    title: "通知を有効にする",
                                    isOn: $notificationsEnabled,
                                    iconColor: .orange
                                )
                                
                                if notificationsEnabled {
                                    SettingsToggleRow(
                                        icon: "moon.stars.fill",
                                        title: "寝る前の気分記録通知",
                                        isOn: .constant(true),  // 一時的に固定
                                        iconColor: .indigo
                                    )
                                    
                                    SettingsActionRow(
                                        icon: "gearshape.2.fill",
                                        title: "通知設定",
                                        subtitle: "設定アプリで管理",
                                        iconColor: .blue,
                                        action: openNotificationSettings
                                    )
                                }
                            }
                        }
                        
                        // フィードバック設定セクション
                        SettingsSectionView(title: "フィードバック") {
                            VStack(spacing: 16) {
                                SettingsToggleRow(
                                    icon: "speaker.wave.2.fill",
                                    title: "サウンド",
                                    isOn: $soundEnabled,
                                    iconColor: .purple
                                )
                                
                                SettingsToggleRow(
                                    icon: "iphone.radiowaves.left.and.right",
                                    title: "触覚フィードバック",
                                    isOn: $hapticEnabled,
                                    iconColor: .pink
                                )
                            }
                        }
                        
                        // データ管理セクション
                        SettingsSectionView(title: "データ管理") {
                            VStack(spacing: 16) {
                                SettingsActionRow(
                                    icon: "square.and.arrow.up.fill",
                                    title: "データをエクスポート",
                                    iconColor: .green,
                                    action: exportData
                                )
                                
                                SettingsActionRow(
                                    icon: "square.and.arrow.down.fill",
                                    title: "データをインポート",
                                    iconColor: .blue,
                                    action: { showingImportSheet = true }
                                )
                                
                                SettingsActionRow(
                                    icon: "icloud.and.arrow.up.fill",
                                    title: "iCloudと同期",
                                    subtitle: iCloudManager.isCloudAccountAvailable ? 
                                        (iCloudManager.isSyncing ? "同期中..." : 
                                         (iCloudManager.lastSyncDate != nil ? "最終同期: \(formatDate(iCloudManager.lastSyncDate!))" : "未同期")) 
                                        : "iCloudが利用できません",
                                    iconColor: .cyan,
                                    action: syncWithiCloud
                                )
                            }
                        }
                        
                        // サポートセクション
                        SettingsSectionView(title: "サポート") {
                            VStack(spacing: 16) {
                                SettingsActionRow(
                                    icon: "questionmark.circle.fill",
                                    title: "ヘルプ",
                                    iconColor: .indigo,
                                    action: { showingHelp = true }
                                )
                                
                                SettingsActionRow(
                                    icon: "hand.raised.fill",
                                    title: "プライバシーポリシー",
                                    iconColor: .mint,
                                    action: { showingPrivacyPolicy = true }
                                )
                                
                                SettingsActionRow(
                                    icon: "star.fill",
                                    title: "アプリを評価",
                                    iconColor: .yellow,
                                    action: rateApp
                                )
                                
                                SettingsActionRow(
                                    icon: "square.and.arrow.up.fill",
                                    title: "友達に共有",
                                    iconColor: .orange,
                                    action: shareApp
                                )
                            }
                        }
                        
                        // バージョン情報
                        VStack(spacing: 8) {
                            Text("Habita")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text("バージョン 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Text("Made with ❤️")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            DocumentPicker(
                onPick: { url in
                    importData(from: url)
                }
            )
        }
        .alert("iCloud同期", isPresented: .constant(iCloudManager.syncError != nil)) {
            Button("OK") {
                iCloudManager.syncError = nil
            }
        } message: {
            Text(iCloudManager.syncError ?? "")
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func exportData() {
        // データをJSONとしてエクスポート
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(habitManager.habits)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let filename = "Habita_backup_\(dateFormatter.string(from: Date())).json"
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)
            
            exportedFileURL = tempURL
            showingExportSheet = true
            
            soundManager.playComplete()
        } catch {
            print("エクスポートエラー: \(error)")
            soundManager.playError()
        }
    }
    
    private func importData(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let habits = try decoder.decode([Habit].self, from: data)
            
            // 既存のデータと統合
            for habit in habits {
                if !habitManager.habits.contains(where: { $0.id == habit.id }) {
                    habitManager.habits.append(habit)
                }
            }
            
            habitManager.saveHabits()
            soundManager.playComplete()
        } catch {
            print("インポートエラー: \(error)")
            soundManager.playError()
        }
    }
    
    private func syncWithiCloud() {
        guard iCloudManager.isCloudAccountAvailable else {
            iCloudManager.checkAccountStatus()
            return
        }
        
        soundManager.playTap()
        
        // デバッグ用：習慣データの状態を確認
        print("=== iCloud同期開始 ===")
        print("習慣数: \(habitManager.habits.count)")
        
        for (index, habit) in habitManager.habits.enumerated() {
            print("習慣 \(index): \(habit.name)")
            print("  - 完了記録数: \(habit.completionRecords.count)")
            print("  - メモ長さ: \(habit.notes.count)")
        }
        
        // 同期開始
        iCloudManager.syncData(habits: habitManager.habits)
        
        // 同期後にデータを取得
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            iCloudManager.fetchData { habits in
                if !habits.isEmpty {
                    // 取得したデータと既存データをマージ
                    for habit in habits {
                        if !habitManager.habits.contains(where: { $0.id == habit.id }) {
                            habitManager.habits.append(habit)
                        }
                    }
                    habitManager.saveHabits()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }
    
    private func rateApp() {
        // SKStoreReviewControllerを使用してアプリ内でレビューをリクエスト
        if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
        
        soundManager.playTap()
    }
    
    private func shareApp() {
        let text = "Habitaで習慣を管理しよう！シンプルで美しい習慣管理アプリです。"
        let url = URL(string: "https://apps.apple.com/app/habita/id1234567890")!
        
        let activityVC = UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// 設定セクションビュー
struct SettingsSectionView<Content: View>: View {
    let title: String
    let content: Content
    @StateObject private var themeManager = ThemeManager.shared
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
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

// テーマプリセット行
struct ThemePresetRow: View {
    let preset: ThemePreset
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var presetTheme: Theme {
        Theme.themes[preset] ?? Theme.themes[.light]!
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // カラープレビュー
                HStack(spacing: 8) {
                    Circle()
                        .fill(presetTheme.primaryColor)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(presetTheme.accentColor)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(presetTheme.backgroundColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(themeManager.currentTheme.secondaryTextColor.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Text(preset.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 設定トグル行
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let iconColor: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(themeManager.currentTheme.primaryColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// 設定アクション行
struct SettingsActionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let iconColor: Color
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 設定リンク行
struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let url: URL
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Link(destination: url) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
} 