import SwiftUI
import AudioToolbox

struct HabitGridView: View {
    let habits: [Habit]
    let pageIndex: Int
    @Binding var showingAddHabit: Bool
    @EnvironmentObject var habitManager: HabitManager
    @StateObject private var themeManager = ThemeManager.shared
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader { geometry in
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<6) { position in
                    if let habit = habits.first(where: { $0.position == position }) {
                        HabitCardView(habit: habit)
                            .frame(height: (geometry.size.height - 60) / 3)
                    } else {
                        AddHabitButton(pageIndex: pageIndex, position: position)
                            .frame(height: (geometry.size.height - 60) / 3)
                            .onTapGesture {
                                showingAddHabit = true
                            }
                    }
                }
            }
            .padding()
        }
    }
}

// 集中線エフェクトビュー
struct FocusLinesView: View {
    let focusLines: [HabitCardView.FocusLine]
    let focusLinesReversing: Bool
    let cardColor: Color
    
    var body: some View {
        ForEach(focusLines) { line in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            cardColor.opacity(1.0),  // 明るくした色の代わりに不透明度を高くする
                            cardColor.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: line.length * (focusLinesReversing ? (1 - line.progress) : line.progress), height: 6)
                .offset(x: focusLinesReversing 
                    ? (line.offset * line.progress) 
                    : (line.offset * (1 - line.progress)))
                .rotationEffect(.degrees(line.angle))
                .scaleEffect(x: focusLinesReversing ? -1 : 1)
                .shadow(color: cardColor.opacity(0.5), radius: 2, x: 0, y: 0)
                .overlay(
                    // 白のオーバーレイで明るさを追加
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
    }
}

// 改善された習慣カードビュー
struct HabitCardView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    @State private var showingDetail = false
    @State private var showingTimer = false
    @State private var longPressTriggered = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var completionProgress: CGFloat = 0
    @State private var showCompletionAnimation = false
    @State private var completionOpacity: Double = 0
    @State private var cardRotation: Double = 0
    @State private var particleScale: CGFloat = 0
    @State private var completedAnimationScale: CGFloat = 1.0
    @State private var fillScale: CGFloat = 0
    @State private var isRotating: Bool = false  // 回転中かどうかを追跡
    @State private var isAnimatingCompletion: Bool = false  // 完了アニメーション中かどうか
    @State private var showingMoodSelection = false
    @State private var selectedMood: String? = nil
    @State private var showingMotivation = false
    @State private var motivationMessage = ""
    @State private var pendingCompletion = false
    @State private var showingPointsAnimation = false
    @State private var earnedPoints = 0
    @State private var pointsAnimationOffset: CGFloat = 0
    @State private var pointsAnimationOpacity: Double = 0
    @State private var cardZIndex: Double = 0  // カードのzIndexを管理
    @State private var longPressProgress: CGFloat = 0  // 長押しプログレス
    
    // 震動効果用の新しい状態変数
    @State private var shakeOffset: CGFloat = 0
    @State private var isShaking = false
    @State private var shakeTimer: Timer?
    
    // 集中線用の状態変数
    @State private var focusLines: [FocusLine] = []
    @State private var focusLinesReversing = false
    @State private var focusLineScale: CGFloat = 0
    
    // 集中線の構造体
    struct FocusLine: Identifiable {
        let id = UUID()
        let angle: Double
        let length: CGFloat
        let offset: CGFloat
        var progress: CGFloat = 0
    }
    
    var isCompletedToday: Bool {
        habit.isCompletedToday()
    }
    
    var todaysMood: String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habit.completionRecords.first { record in
            calendar.isDate(record.date, inSameDayAs: today)
        }?.mood
    }
    
    var cardColor: Color {
        // テーマベースのカードカラーシステム
        if let themeColor = themeManager.getCardColor(for: habit.color) {
            return themeColor
        }
        
        // フォールバック：従来の色システム
        switch habit.color {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "green":
            return .green
        case "blue":
            return .blue
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "gray":
            return .gray
        default:
            return .blue
        }
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                cardColor,
                cardColor.opacity(0.7)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var typeIndicatorColor: Color {
        switch habit.type {
        case .positive:
            return .green
        case .negative:
            return .red
        case .timed:
            return .blue
        }
    }
    
    var typeIndicatorIcon: String {
        switch habit.type {
        case .positive:
            return "checkmark.circle.fill"
        case .negative:
            return "xmark.octagon.fill"
        case .timed:
            return "timer"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 集中線エフェクト（カードの背後に配置）
                if !focusLines.isEmpty {
                    FocusLinesView(
                        focusLines: focusLines,
                        focusLinesReversing: focusLinesReversing,
                        cardColor: cardColor
                    )
                }
                
                // メインカード
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        isAnimatingCompletion
                            ? LinearGradient(
                                gradient: Gradient(colors: [cardColor.opacity(0.6), cardColor.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )  // 長押し時の色と同じ不透明度
                            : (isCompletedToday
                                ? cardGradient
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        themeManager.currentTheme.cardBackgroundColor,
                                        themeManager.currentTheme.secondaryBackgroundColor
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                    )
                    .overlay(
                        // 回転中は枠線を非表示
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                isCompletedToday
                                    ? cardColor.opacity(0.4)
                                    : cardColor.opacity(0.3),
                                lineWidth: isCompletedToday ? 3 : 2
                            )
                            .opacity(isRotating ? 0 : 1)  // 回転中は透明に
                            .animation(.easeInOut(duration: 0.2), value: isRotating)
                    )
                    .shadow(
                        color: isCompletedToday
                            ? cardColor.opacity(0.4)
                            : themeManager.currentTheme.shadowColor,
                        radius: isPressed ? 5 : (isCompletedToday ? 15 : 10),
                        x: 0,
                        y: isPressed ? 2 : 5
                    )
                    .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
                    .scaleEffect(completedAnimationScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cardRotation)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completedAnimationScale)
                    .offset(x: shakeOffset)  // 震動効果を追加
                
                // 長押し進行インジケーター（カード全体を満たす）
                if isPressed && fillScale > 0 {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(cardColor.opacity(0.6))
                        .scaleEffect(x: fillScale, y: 1, anchor: .leading)
                        .animation(.linear(duration: 1.0), value: fillScale)
                        .allowsHitTesting(false)
                }
                
                // 完了時の光沢エフェクト
                if isCompletedToday {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                HabitCardContent(
                    habit: habit,
                    isCompletedToday: isCompletedToday,
                    isPressed: isPressed,
                    todaysMood: todaysMood,
                    cardColor: cardColor,
                    typeIndicatorColor: typeIndicatorColor,
                    typeIndicatorIcon: typeIndicatorIcon,
                    scaleEffect: scaleEffect,
                    longPressProgress: longPressProgress
                )
                
                // 達成時のパーティクルエフェクト
                if showCompletionAnimation {
                    ZStack {
                        ForEach(0..<12) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [cardColor, cardColor.opacity(0.3)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 15, height: 15)
                                .scaleEffect(particleScale)
                                .opacity(1 - Double(particleScale))
                                .offset(
                                    x: cos(Double(index) * .pi / 6) * 60 * particleScale,
                                    y: sin(Double(index) * .pi / 6) * 60 * particleScale
                                )
                        }
                    }
                }
                
                // 達成時のチェックマークオーバーレイ
                if showCompletionAnimation {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(scaleEffect * 1.2)
                        .opacity(completionOpacity)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                // ポイント獲得アニメーション
                if showingPointsAnimation {
                    VStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            Text("+\(earnedPoints) pt")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.7))
                        )
                        .scaleEffect(pointsAnimationOpacity)
                        .opacity(pointsAnimationOpacity)
                        .offset(y: pointsAnimationOffset)
                    }
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .zIndex(cardZIndex)  // zIndexを適用
            .onTapGesture {
                if !longPressTriggered {
                    showingDetail = true
                }
                longPressTriggered = false
            }
            .onLongPressGesture(
                minimumDuration: 1.0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                    if pressing {
                        completionProgress = 0
                        fillScale = 0
                        longPressProgress = 0
                        
                        // 完了済みでない場合のみ震動効果と集中線を開始
                        if !isCompletedToday {
                            // 震動効果を開始
                            startShaking()
                            
                            // 集中線を生成
                            generateFocusLines()
                        }
                        
                        // fillScaleのアニメーションを開始
                        DispatchQueue.main.async {
                            withAnimation(.linear(duration: 1.0)) {
                                fillScale = 1.0
                                longPressProgress = 1.0
                            }
                            
                            // 完了済みでない場合のみ集中線アニメーション
                            if !isCompletedToday {
                                // 集中線アニメーション
                                withAnimation(.easeIn(duration: 1.0)) {
                                    for index in focusLines.indices {
                                        focusLines[index].progress = 1.0
                                    }
                                }
                            }
                        }
                    } else {
                        // 完了済みでない場合のみ震動を停止
                        if !isCompletedToday {
                            // 震動を停止
                            stopShaking()
                            
                            // 集中線を逆走させる
                            if !focusLines.isEmpty {
                                focusLinesReversing = true
                                withAnimation(.easeOut(duration: 0.3)) {
                                    for index in focusLines.indices {
                                        focusLines[index].progress = 1.0
                                    }
                                }
                                
                                // 逆走後に集中線をクリア
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    focusLines.removeAll()
                                    focusLinesReversing = false
                                }
                            }
                        }
                        
                        // 中断時はリセット
                        withAnimation(.easeOut(duration: 0.2)) {
                            fillScale = 0
                            longPressProgress = 0
                        }
                        completionProgress = 0
                    }
                },
                perform: {
                    // 完了済みでない場合のみ震動と集中線をクリア
                    if !isCompletedToday {
                        // 震動を停止
                        stopShaking()
                        
                        // 集中線をクリア
                        focusLines.removeAll()
                        focusLinesReversing = false
                    }
                    
                    longPressTriggered = true
                    performHapticFeedback(.heavy)
                    
                    // 完了済みの場合はUndo処理
                    if isCompletedToday {
                        // 簡単なアニメーション
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scaleEffect = 0.8
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                scaleEffect = 1.0
                            }
                        }
                        
                        // トグル処理（未完了に戻す）
                        habitManager.toggleCompletion(for: habit)
                    } else {
                        // タイマータイプの場合は、タイマー画面を表示
                        if habit.type == .timed {
                            showingTimer = true
                        } else {
                            // 気分選択の設定を確認
                            if habitManager.askMoodOnCompletion {
                                // 完了処理を保留して気分選択を表示
                                pendingCompletion = true
                                showingMoodSelection = true
                            } else {
                                // 気分選択なしで直接完了処理
                                completionWithAnimation(mood: nil)
                            }
                        }
                    }
                    
                    completionProgress = 0
                    fillScale = 0
                }
            )
            .sheet(isPresented: $showingDetail) {
                HabitDetailView(habit: habit)
            }
            .sheet(isPresented: $showingTimer) {
                TimerView(habit: habit)
            }
            .sheet(isPresented: $showingMoodSelection) {
                MoodSelectionView(
                    selectedMood: $selectedMood,
                    isPresented: $showingMoodSelection,
                    onComplete: { mood in
                        completionWithAnimation(mood: mood)
                    }
                )
                .presentationDetents([.height(300)])
                .presentationBackground(.clear)
                .onDisappear {
                    if pendingCompletion && selectedMood == nil {
                        // スキップされた場合も完了処理を実行
                        completionWithAnimation(mood: nil)
                    }
                }
            }
            .overlay(
                // モチベーションメッセージのオーバーレイ
                Group {
                    if showingMotivation {
                        VStack {
                            Text(motivationMessage)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(cardColor)
                                        .shadow(radius: 10)
                                )
                                .scaleEffect(showingMotivation ? 1 : 0)
                                .opacity(showingMotivation ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showingMotivation)
                        }
                        .padding()
                    }
                }
            )
        }
    }
    
    private func performHapticFeedback(_ type: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: type)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func completionWithAnimation(mood: String?) {
        // アニメーション処理
        // カードを最前面に
        withAnimation {
            cardZIndex = 1000
        }
        
        // スケールアニメーション（縮小）
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scaleEffect = 1.15  // 1.3から1.15に縮小
        }
        
        // 回転開始と同時に枠線を非表示とカードの色を変更
        isRotating = true
        isAnimatingCompletion = true
        
        // カード回転アニメーション（2回転 = 720度）
        withAnimation(.easeInOut(duration: 1.2)) {
            cardRotation = 720
        }
        
        // パーティクルエフェクト
        showCompletionAnimation = true
        particleScale = 0
        completionOpacity = 1
        
        withAnimation(.easeOut(duration: 1.0)) {
            particleScale = 2.0
        }
        
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            completionOpacity = 0
        }
        
        // 完了後のカードスケール
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                completedAnimationScale = 1.02  // 1.05から1.02に縮小
            }
            
            // 枠線を再表示
            isRotating = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    completedAnimationScale = 1.0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scaleEffect = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showCompletionAnimation = false
            // アニメーションなしで瞬時にリセット
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                cardRotation = 0
            }
            isAnimatingCompletion = false
            
            // zIndexを元に戻す
            withAnimation {
                cardZIndex = 0
            }
            
            // ポイント計算
            let basePoints = habit.difficulty.points
            var bonusMultiplier = 1.0
            
            // ストリークボーナス
            let currentStreak = habitManager.habits.first { $0.id == habit.id }?.currentStreak ?? 0
            if currentStreak >= 6 { // 明日で7日になる
                bonusMultiplier += 0.2
            }
            if currentStreak >= 29 { // 明日で30日になる
                bonusMultiplier += 0.3
            }
            
            earnedPoints = Int(Double(basePoints) * bonusMultiplier)
            
            // ポイントアニメーション
            showingPointsAnimation = true
            pointsAnimationOffset = 0
            pointsAnimationOpacity = 0
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                pointsAnimationOpacity = 1
                pointsAnimationOffset = -30
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    pointsAnimationOpacity = 0
                    pointsAnimationOffset = -60
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingPointsAnimation = false
                }
            }
            
            // アニメーション後に完了処理
            habitManager.toggleCompletion(for: habit, mood: mood)
            
            // ストリークをチェックしてモチベーションメッセージを表示
            let updatedHabit = habitManager.habits.first { $0.id == habit.id }
            if let message = habitManager.getMotivationMessage(for: updatedHabit?.currentStreak ?? 0) {
                motivationMessage = message
                showingMotivation = true
                
                // サウンドフィードバック
                AudioServicesPlaySystemSound(1520) // Actuate Pop
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showingMotivation = false
                    }
                }
            }
            
            pendingCompletion = false
            selectedMood = nil
        }
    }
    
    // 震動効果を開始
    private func startShaking() {
        isShaking = true
        shakeTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            withAnimation(.linear(duration: 0.02)) {
                shakeOffset = CGFloat.random(in: -2...2)
            }
        }
    }
    
    // 震動効果を停止
    private func stopShaking() {
        isShaking = false
        shakeTimer?.invalidate()
        shakeTimer = nil
        withAnimation(.linear(duration: 0.1)) {
            shakeOffset = 0
        }
    }
    
    // 集中線を生成
    private func generateFocusLines() {
        focusLines.removeAll()
        focusLinesReversing = false
        
        // 16本の集中線を生成（12本から増加）
        for i in 0..<16 {
            let angle = Double(i) * 22.5 // 22.5度ごとに配置（360/16）
            let length = CGFloat.random(in: 100...150)  // より長い線に
            let offset = CGFloat.random(in: 120...180)  // より遠くから開始
            
            focusLines.append(FocusLine(
                angle: angle,
                length: length,
                offset: offset,
                progress: 0
            ))
        }
    }
}

// カードコンテンツビュー
struct HabitCardContent: View {
    let habit: Habit
    let isCompletedToday: Bool
    let isPressed: Bool
    let todaysMood: String?
    let cardColor: Color
    let typeIndicatorColor: Color
    let typeIndicatorIcon: String
    let scaleEffect: CGFloat
    let longPressProgress: CGFloat
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // タイプインジケーター（上部）
            HStack {
                // 今日の気分を左上に表示（サイズを調整）
                if let mood = todaysMood {
                    Text(mood)
                        .font(.system(size: 16))
                        .padding(3)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 26, height: 26)
                        )
                }
                
                Spacer()
                
                // 難易度バッジ
                HStack(spacing: 4) {
                    Image(systemName: habit.difficulty.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(habit.difficulty.points)pt")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(isCompletedToday ? .white : habit.difficulty.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(habit.difficulty.color.opacity(isCompletedToday ? 0.3 : 0.2))
                )
                
                ZStack {
                    Circle()
                        .fill(typeIndicatorColor.opacity(isCompletedToday ? 0.3 : 0.2))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: typeIndicatorIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isCompletedToday ? .white : typeIndicatorColor)
                }
            }
            
            Spacer(minLength: 0)
            
            // メインアイコン
            Group {
                if isCompletedToday {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: habit.type == .timed ? 50 : 60, height: habit.type == .timed ? 50 : 60)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: habit.type == .timed ? 42 : 50, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                    }
                } else {
                    ZStack {
                        // 長押し時の円形プログレスバー
                        if isPressed && longPressProgress > 0 {
                            Circle()
                                .stroke(
                                    Color.white.opacity(0.3),
                                    lineWidth: 4
                                )
                                .frame(width: habit.type == .timed ? 58 : 68, height: habit.type == .timed ? 58 : 68)
                            
                            Circle()
                                .trim(from: 0, to: longPressProgress)
                                .stroke(
                                    Color.white,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: habit.type == .timed ? 58 : 68, height: habit.type == .timed ? 58 : 68)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1.0), value: longPressProgress)
                        }
                        
                        Circle()
                            .fill(cardColor.opacity(0.1))
                            .frame(width: habit.type == .timed ? 50 : 60, height: habit.type == .timed ? 50 : 60)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: habit.type == .timed ? 26 : 32, weight: .medium))
                            .foregroundColor(isPressed ? .white : cardColor)
                            .scaleEffect(scaleEffect)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scaleEffect)
                    }
                }
            }
            
            // 習慣名
            Text(habit.name)
                .font(.system(size: habit.type == .timed ? 14 : 16, weight: .semibold))
                .foregroundColor(isCompletedToday || isPressed ? .white : themeManager.currentTheme.textColor)
                .lineLimit(habit.type == .timed ? 1 : 2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .minimumScaleFactor(0.9)
                .shadow(color: (isCompletedToday || isPressed) ? Color.black.opacity(0.3) : Color.clear, radius: 1, x: 0, y: 1)
            
            // ストリークとステータス
            VStack(spacing: 4) {
                if habit.currentStreak > 0 && habit.type != .timed {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                        Text("\(habit.currentStreak)")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(isCompletedToday || isPressed ? .white : cardColor)
                    .shadow(color: (isCompletedToday || isPressed) ? Color.black.opacity(0.3) : Color.clear, radius: 1, x: 0, y: 1)
                }
                
                // タイマータイプ用の表示
                if habit.type == .timed {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(formatDuration(habit.timerDuration))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor((isCompletedToday || isPressed) ? .white.opacity(0.9) : themeManager.currentTheme.secondaryTextColor)
                    .shadow(color: (isCompletedToday || isPressed) ? Color.black.opacity(0.3) : Color.clear, radius: 1, x: 0, y: 1)
                    
                    if habit.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                            Text("\(habit.currentStreak)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(isCompletedToday || isPressed ? .white : cardColor)
                        .shadow(color: (isCompletedToday || isPressed) ? Color.black.opacity(0.3) : Color.clear, radius: 1, x: 0, y: 1)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)分"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)時間"
            }
            return "\(hours)時間\(remainingMinutes)分"
        }
    }
}

// 改善された習慣追加ボタン
struct AddHabitButton: View {
    let pageIndex: Int
    let position: Int
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(themeManager.currentTheme.cardBackgroundColor.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [10],
                                dashPhase: isHovered ? 10 : 0
                            )
                        )
                        .foregroundColor(themeManager.currentTheme.accentColor.opacity(0.5))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isHovered)
                )
                .shadow(
                    color: themeManager.currentTheme.shadowColor.opacity(0.1),
                    radius: 5,
                    x: 0,
                    y: 2
                )
            
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.accentColor.opacity(0.7))
                    .rotationEffect(.degrees(isHovered ? 90 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHovered)
                
                Text("習慣を追加")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct HabitGridView_Previews: PreviewProvider {
    static var previews: some View {
        HabitGridView(
            habits: [
                Habit(name: "運動", icon: "figure.run", color: "orange", type: .positive, position: 0),
                Habit(name: "読書", icon: "book.fill", color: "blue", type: .positive, position: 1),
                Habit(name: "瞑想", icon: "brain.head.profile", color: "purple", type: .timed, position: 2),
                Habit(name: "禁煙", icon: "nosmoking", color: "red", type: .negative, position: 3)
            ],
            pageIndex: 0,
            showingAddHabit: .constant(false)
        )
        .environmentObject(HabitManager())
    }
} 