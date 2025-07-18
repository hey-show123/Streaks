import SwiftUI

struct IconPicker: View {
    @Binding var selectedIcon: String
    @State private var selectedCategory: IconCategory = .health
    @StateObject private var themeManager = ThemeManager.shared
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // カテゴリータブ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(IconCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            category: category,
                            isSelected: selectedCategory == category,
                            color: color
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // アイコングリッド
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 20) {
                    ForEach(selectedCategory.icons, id: \.self) { icon in
                        IconButton(
                            icon: icon,
                            isSelected: selectedIcon == icon,
                            color: color
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedIcon = icon
                            }
                            performHapticFeedback(.light)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// アイコンカテゴリー
enum IconCategory: String, CaseIterable {
    case health = "健康"
    case fitness = "フィットネス"
    case food = "食事"
    case work = "仕事"
    case study = "学習"
    case lifestyle = "ライフスタイル"
    case social = "ソーシャル"
    case nature = "自然"
    case tech = "テクノロジー"
    case symbols = "シンボル"
    
    var displayName: String {
        return rawValue
    }
    
    var icons: [String] {
        switch self {
        case .health:
            return [
                "heart.fill", "heart.circle.fill", "heart.text.square.fill",
                "pills.fill", "cross.case.fill", "bandage.fill",
                "bed.double.fill", "lungs.fill", "brain.head.profile",
                "eye.fill", "ear.fill", "mouth.fill",
                "stethoscope", "medical.thermometer.fill", "syringe.fill",
                "drop.fill", "humidity.fill", "allergens"
            ]
        case .fitness:
            return [
                "figure.run", "figure.walk", "figure.roll",
                "figure.yoga", "figure.pilates", "figure.strengthtraining.traditional",
                "figure.strengthtraining.functional", "figure.cooldown", "figure.core.training",
                "dumbbell.fill", "sportscourt.fill", "baseball.fill",
                "basketball.fill", "football.fill", "soccerball",
                "tennis.racket", "bicycle", "skateboard.fill",
                "snowboard.fill", "figure.pool.swim", "figure.surfing"
            ]
        case .food:
            return [
                "fork.knife", "cup.and.saucer.fill", "wineglass.fill",
                "mug.fill", "takeoutbag.and.cup.and.straw.fill", "birthday.cake.fill",
                "carrot.fill", "leaf.fill", "fish.fill",
                "apple", "orange", "grapes.fill",
                "banana", "strawberry", "cherry.fill"
            ]
        case .work:
            return [
                "briefcase.fill", "bag.fill", "folder.fill",
                "doc.text.fill", "doc.richtext.fill", "chart.bar.fill",
                "chart.pie.fill", "chart.line.uptrend.xyaxis", "dollarsign.circle.fill",
                "creditcard.fill", "banknote.fill", "building.2.fill",
                "desktopcomputer", "laptopcomputer", "printer.fill",
                "paperplane.fill", "tray.full.fill", "archivebox.fill"
            ]
        case .study:
            return [
                "book.fill", "book.closed.fill", "books.vertical.fill",
                "graduationcap.fill", "pencil", "pencil.and.ruler.fill",
                "highlighter", "eraser.fill", "paperclip",
                "bookmark.fill", "magazine.fill", "newspaper.fill",
                "doc.text.magnifyingglass", "brain", "lightbulb.fill",
                "atom", "function", "sum"
            ]
        case .lifestyle:
            return [
                "house.fill", "sofa.fill", "lamp.table.fill",
                "shower.fill", "bathtub.fill", "washer.fill",
                "music.note", "headphones", "speaker.wave.3.fill",
                "tv.fill", "gamecontroller.fill", "puzzlepiece.fill",
                "paintbrush.fill", "paintpalette.fill", "camera.fill",
                "photo.fill", "scissors", "hammer.fill"
            ]
        case .social:
            return [
                "person.fill", "person.2.fill", "person.3.fill",
                "bubble.left.fill", "bubble.right.fill", "phone.fill",
                "video.fill", "envelope.fill", "paperplane.fill",
                "gift.fill", "heart.text.square.fill", "hand.wave.fill",
                "hand.thumbsup.fill", "hands.clap.fill", "figure.2.arms.open",
                "party.popper.fill", "crown.fill", "star.fill"
            ]
        case .nature:
            return [
                "sun.max.fill", "moon.fill", "moon.stars.fill",
                "sparkles", "cloud.fill", "cloud.rain.fill",
                "cloud.sun.fill", "snowflake", "wind",
                "leaf.fill", "tree.fill", "flame.fill",
                "drop.fill", "tortoise.fill", "bird.fill",
                "fish.fill", "butterfly.fill", "flower.fill"
            ]
        case .tech:
            return [
                "iphone", "ipad", "applewatch",
                "airpods", "homepod.fill", "appletv.fill",
                "wifi", "antenna.radiowaves.left.and.right", "battery.100",
                "powerplug.fill", "keyboard.fill", "mouse.fill",
                "cpu.fill", "memorychip.fill", "display",
                "printer.fill", "scanner.fill", "camera.fill"
            ]
        case .symbols:
            return [
                "star.fill", "circle.fill", "square.fill",
                "triangle.fill", "diamond.fill", "hexagon.fill",
                "seal.fill", "checkmark.circle.fill", "xmark.circle.fill",
                "plus.circle.fill", "minus.circle.fill", "multiply.circle.fill",
                "flag.fill", "bell.fill", "tag.fill",
                "bolt.fill", "sparkle", "wand.and.stars"
            ]
        }
    }
}

// カテゴリータブ
struct CategoryTab: View {
    let category: IconCategory
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : themeManager.currentTheme.secondaryBackgroundColor)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : themeManager.currentTheme.secondaryTextColor.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// アイコンボタン
struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            action()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : themeManager.currentTheme.secondaryBackgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.clear : themeManager.currentTheme.secondaryTextColor.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                    .scaleEffect(scale)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct IconPicker_Previews: PreviewProvider {
    static var previews: some View {
        IconPicker(selectedIcon: .constant("star.fill"), color: .blue)
    }
} 