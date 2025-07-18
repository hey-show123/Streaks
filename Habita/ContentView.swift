//
//  ContentView.swift
//  Streaks
//
//  Created by 山﨑祥平 on 2025/07/13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var habitManager = HabitManager()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var currentPage = 0
    @State private var showingAddHabit = false
    @State private var showingSettings = false
    @State private var showingStatistics = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.currentTheme.backgroundColor,
                        themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ヘッダー
                    HeaderView(
                        showingSettings: $showingSettings,
                        showingStatistics: $showingStatistics
                    )
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 習慣グリッド
                    TabView(selection: $currentPage) {
                        ForEach(0..<4) { pageIndex in
                            HabitGridView(
                                habits: habitManager.habitsForPage(pageIndex),
                                pageIndex: pageIndex,
                                showingAddHabit: $showingAddHabit
                            )
                            .tag(pageIndex)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width / 3
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                    )
                    
                    // ページインジケーター
                    PageIndicator(currentPage: $currentPage)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(habitManager: habitManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView(habitManager: habitManager)
            }
        }
        .environmentObject(habitManager)
        .environmentObject(themeManager)
    }
}

// 改善されたヘッダービュー
struct HeaderView: View {
    @Binding var showingSettings: Bool
    @Binding var showingStatistics: Bool
    @EnvironmentObject var habitManager: HabitManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var titleScale: CGFloat = 1.0
    @State private var showLevelProgress = false
    
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
        VStack(spacing: 16) {
            // レベル表示
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // レベルアイコン
                    ZStack {
                        Circle()
                            .fill(habitManager.currentUserLevel.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: habitManager.currentUserLevel.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(habitManager.currentUserLevel.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lv.\(habitManager.currentUserLevel.level) \(habitManager.currentUserLevel.title)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            Text("\(habitManager.totalUserPoints) pt")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showLevelProgress.toggle()
                    }
                }
                
                // プログレスバー
                if showLevelProgress, let next = nextLevel {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("次のレベルまで")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Spacer()
                            
                            Text("\(next.requiredPoints - habitManager.totalUserPoints) pt")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 6)
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
                                    .frame(width: geometry.size.width * progressToNextLevel, height: 8)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressToNextLevel)
                            }
                        }
                        .frame(height: 8)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
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
            
            // 既存のヘッダー
        HStack {
            // 設定ボタン
            Button(action: { 
                performHapticFeedback(.light)
                showingSettings = true 
            }) {
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.cardBackgroundColor)
                        .frame(width: 44, height: 44)
                        .shadow(
                            color: themeManager.currentTheme.shadowColor,
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // タイトル
            VStack(spacing: 4) {
                Text("Habita")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .scaleEffect(titleScale)
                
                Text(getCurrentDateString())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                    titleScale = 1.05
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                    titleScale = 1.0
                }
            }
            
            Spacer()
            
            // 統計ボタン
            Button(action: { 
                performHapticFeedback(.light)
                showingStatistics = true 
            }) {
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.cardBackgroundColor)
                        .frame(width: 44, height: 44)
                        .shadow(
                            color: themeManager.currentTheme.shadowColor,
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        return formatter.string(from: Date())
    }
    
    private func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// 改善されたページインジケーター
struct PageIndicator: View {
    @Binding var currentPage: Int
    @StateObject private var themeManager = ThemeManager.shared
    @State private var indicatorScales: [CGFloat] = Array(repeating: 1.0, count: 4)
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(
                        currentPage == index
                            ? themeManager.currentTheme.primaryColor
                            : themeManager.currentTheme.secondaryTextColor.opacity(0.3)
                    )
                    .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                    .scaleEffect(indicatorScales[index])
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: indicatorScales[index])
                    .onTapGesture {
                        performHapticFeedback(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            currentPage = index
                        }
                        
                        // タップアニメーション
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            indicatorScales[index] = 1.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                indicatorScales[index] = 1.0
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(themeManager.currentTheme.cardBackgroundColor)
                .shadow(
                    color: themeManager.currentTheme.shadowColor,
                    radius: 5,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// スケールボタンスタイル
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
