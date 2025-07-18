import SwiftUI

struct MoodSelectionView: View {
    @Binding var selectedMood: String?
    @Binding var isPresented: Bool
    @StateObject private var themeManager = ThemeManager.shared
    let onComplete: (String) -> Void
    
    let moods = [
        ("😊", "最高"),
        ("😌", "良い"),
        ("😐", "普通"),
        ("😕", "微妙"),
        ("😤", "頑張った")
    ]
    
    @State private var animationScale: [CGFloat] = Array(repeating: 1.0, count: 5)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("今日の気分はどうでしたか？")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("習慣を達成した今の気持ちを記録しましょう")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 15) {
                ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                    VStack(spacing: 8) {
                        Text(mood.0)
                            .font(.system(size: 45))
                            .scaleEffect(animationScale[index])
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    animationScale[index] = 1.3
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        animationScale[index] = 1.0
                                    }
                                }
                                
                                performHapticFeedback(.light)
                                selectedMood = mood.0
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onComplete(mood.0)
                                    isPresented = false
                                }
                            }
                        
                        Text(mood.1)
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            
            Button("スキップ") {
                isPresented = false
            }
            .font(.system(size: 16))
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            .padding(.top, 10)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(themeManager.currentTheme.cardBackgroundColor)
                .shadow(
                    color: themeManager.currentTheme.shadowColor,
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .padding(40)
        .onAppear {
            // 波打つアニメーション
            for index in 0..<moods.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        animationScale[index] = 1.1
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            animationScale[index] = 1.0
                        }
                    }
                }
            }
        }
    }
    
    private func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct MoodSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        MoodSelectionView(
            selectedMood: .constant(nil),
            isPresented: .constant(true),
            onComplete: { _ in }
        )
    }
} 