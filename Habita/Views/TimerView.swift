import SwiftUI
import AudioToolbox

struct TimerView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var timeRemaining: TimeInterval
    @State private var isActive = false
    @State private var showingCompletion = false
    @State private var progress: Double = 1.0
    @State private var showingMoodSelection = false
    @State private var selectedMood: String? = nil
    
    init(habit: Habit) {
        self.habit = habit
        self._timeRemaining = State(initialValue: habit.timerDuration)
    }
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
            VStack(spacing: 40) {
                // タイマー表示
                ZStack {
                    // 背景の円
                    Circle()
                            .stroke(
                                themeManager.currentTheme.secondaryBackgroundColor,
                                lineWidth: 20
                            )
                        .frame(width: 250, height: 250)
                    
                        // 進行状況の円
                    Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        themeManager.getCardColor(for: habit.color) ?? .blue,
                                        (themeManager.getCardColor(for: habit.color) ?? .blue).opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(
                                    lineWidth: 20,
                                    lineCap: .round
                                )
                            )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: progress)
                    
                VStack(spacing: 10) {
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 60, weight: .light, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text(habit.name)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                }
                
                // コントロールボタン
                    HStack(spacing: 40) {
                    // リセットボタン
                    Button(action: resetTimer) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(themeManager.currentTheme.secondaryBackgroundColor)
                                )
                    }
                    
                        // 開始/停止ボタン
                    Button(action: toggleTimer) {
                            Image(systemName: isActive ? "pause.fill" : "play.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                                .background(
                                    Circle()
                                        .fill(themeManager.getCardColor(for: habit.color) ?? .blue)
                                        .shadow(
                                            color: (themeManager.getCardColor(for: habit.color) ?? .blue).opacity(0.3),
                                            radius: 10,
                                            x: 0,
                                            y: 5
                                        )
                                )
                    }
                        .scaleEffect(isActive ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isActive)
                    
                    // 完了ボタン
                        Button(action: completeTimer) {
                        Image(systemName: "checkmark")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(themeManager.currentTheme.secondaryBackgroundColor)
                                )
                        }
                        .opacity(timeRemaining < habit.timerDuration ? 1 : 0.5)
                        .disabled(timeRemaining == habit.timerDuration)
                }
                
                Spacer()
            }
            .padding()
            }
            .navigationTitle("タイマー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            .onReceive(timer) { _ in
                if isActive && timeRemaining > 0 {
                    timeRemaining -= 1
                    progress = timeRemaining / habit.timerDuration
                    
                    if timeRemaining == 0 {
                        // タイマー完了
                        isActive = false
                        performHapticFeedback(.heavy)
                        AudioServicesPlaySystemSound(1005) // タイマー完了音
                        
                        // 気分選択の設定を確認
                        if habitManager.askMoodOnCompletion {
                            showingMoodSelection = true
                        } else {
                            // 気分選択なしで直接完了処理
                            completeWithMood()
                }
                    }
                }
            }
            .sheet(isPresented: $showingMoodSelection) {
                MoodSelectionView(
                    selectedMood: $selectedMood,
                    isPresented: $showingMoodSelection,
                    onComplete: { mood in
                        selectedMood = mood
                        completeWithMood()
                    }
                )
                .presentationDetents([.height(300)])
                .presentationBackground(.clear)
            .onDisappear {
                    if selectedMood == nil {
                        // スキップされた場合も完了処理
                        completeWithMood()
                    }
                }
            }
            .alert("習慣を完了しました！", isPresented: $showingCompletion) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                let duration = habit.timerDuration - timeRemaining
                Text("\(timeString(from: duration))実施しました")
            }
        }
    }
    
    private func toggleTimer() {
        isActive.toggle()
        performHapticFeedback(.light)
        
        if isActive {
            AudioServicesPlaySystemSound(1103) // 開始音
        } else {
            AudioServicesPlaySystemSound(1104) // 停止音
        }
    }
    
    private func resetTimer() {
        isActive = false
        timeRemaining = habit.timerDuration
        progress = 1.0
        performHapticFeedback(.medium)
    }
    
    private func completeTimer() {
        isActive = false
        performHapticFeedback(.heavy)
        
        // 気分選択の設定を確認
        if habitManager.askMoodOnCompletion {
            showingMoodSelection = true
        } else {
            // 気分選択なしで直接完了処理
            completeWithMood()
        }
    }
    
    private func completeWithMood() {
        let duration = habit.timerDuration - timeRemaining
        habitManager.completeTimedHabit(habit, duration: duration, mood: selectedMood)
        
        // モチベーションメッセージをチェック
        let updatedHabit = habitManager.habits.first { $0.id == habit.id }
        if habitManager.getMotivationMessage(for: updatedHabit?.currentStreak ?? 0) != nil {
            // メッセージがある場合は、アラートで表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingCompletion = true
            }
        } else {
            showingCompletion = true
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(habit: Habit(
            name: "瞑想",
            icon: "brain.head.profile",
            color: "purple",
            type: .timed,
            timerDuration: 600
        ))
        .environmentObject(HabitManager())
    }
} 