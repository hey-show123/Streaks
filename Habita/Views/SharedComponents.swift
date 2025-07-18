import SwiftUI

// 難易度選択ボタン
struct DifficultyButton: View {
    let difficulty: HabitDifficulty
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : difficulty.color)
                
                Text(difficulty.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                
                Text("\(difficulty.points)pt")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.currentTheme.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? difficulty.color : themeManager.currentTheme.secondaryBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// カラーピッカー
struct ColorPicker: View {
    @Binding var selectedColor: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var colors: [String] {
        // テーマで利用可能なカラーを取得
        return themeManager.availableCardColors
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
            ForEach(colors.sorted(), id: \.self) { colorName in
                if let color = themeManager.getCardColor(for: colorName) {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(themeManager.currentTheme.textColor, lineWidth: selectedColor == colorName ? 3 : 0)
                        )
                        .overlay(
                            Group {
                                if selectedColor == colorName {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                        .scaleEffect(selectedColor == colorName ? 1.2 : 1.0)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedColor = colorName
                            }
                        }
                }
            }
        }
        .padding(.vertical)
    }
}

// 曜日選択コンポーネント
struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Int>
    @StateObject private var themeManager = ThemeManager.shared
    let color: Color = .blue // デフォルトカラー
    
    let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7) { day in
                Button(action: {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                }) {
                    Text(weekdaySymbols[day])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedDays.contains(day) ? .white : themeManager.currentTheme.textColor)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(day) ? color : themeManager.currentTheme.secondaryBackgroundColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
} 