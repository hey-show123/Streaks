import SwiftUI
import Combine

// テーマのプリセット
enum ThemePreset: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case sunset = "sunset"
    case ocean = "ocean"
    case forest = "forest"
    case lavender = "lavender"
    case midnight = "midnight"
    case sakura = "sakura"
    case autumn = "autumn"
    case mint = "mint"
    case coral = "coral"
    case aurora = "aurora"
    
    var displayName: String {
        switch self {
        case .system: return "システム"
        case .light: return "ライト"
        case .dark: return "ダーク"
        case .sunset: return "サンセット"
        case .ocean: return "オーシャン"
        case .forest: return "フォレスト"
        case .lavender: return "ラベンダー"
        case .midnight: return "ミッドナイト"
        case .sakura: return "さくら"
        case .autumn: return "秋"
        case .mint: return "ミント"
        case .coral: return "コーラル"
        case .aurora: return "オーロラ"
        }
    }
}

// テーマデータ
struct Theme {
    let preset: ThemePreset
    let primaryColor: Color
    let backgroundColor: Color
    let cardBackgroundColor: Color
    let secondaryBackgroundColor: Color
    let textColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    let shadowColor: Color
    let isDark: Bool
    
    // テーマに合わせたカラーパレット
    let cardColorPalette: [String: Color]
    
    static let themes: [ThemePreset: Theme] = [
        .light: Theme(
            preset: .light,
            primaryColor: Color(hex: "007AFF"),
            backgroundColor: Color(hex: "F2F2F7"),
            cardBackgroundColor: .white,
            secondaryBackgroundColor: Color(hex: "E5E5EA"),
            textColor: .primary,
            secondaryTextColor: .secondary,
            accentColor: Color(hex: "FF9500"),
            shadowColor: Color.black.opacity(0.1),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "FF3B30"),
                "orange": Color(hex: "FF9500"),
                "yellow": Color(hex: "FFCC00"),
                "green": Color(hex: "34C759"),
                "mint": Color(hex: "00C7BE"),
                "teal": Color(hex: "30B0C7"),
                "cyan": Color(hex: "32ADE6"),
                "blue": Color(hex: "007AFF"),
                "indigo": Color(hex: "5856D6"),
                "purple": Color(hex: "AF52DE"),
                "pink": Color(hex: "FF2D55"),
                "brown": Color(hex: "A2845E")
            ]
        ),
        .dark: Theme(
            preset: .dark,
            primaryColor: Color(hex: "0A84FF"),
            backgroundColor: Color(hex: "000000"),
            cardBackgroundColor: Color(hex: "1C1C1E"),
            secondaryBackgroundColor: Color(hex: "2C2C2E"),
            textColor: .white,
            secondaryTextColor: Color(hex: "8E8E93"),
            accentColor: Color(hex: "FF9F0A"),
            shadowColor: Color.black.opacity(0.3),
            isDark: true,
            cardColorPalette: [
                "red": Color(hex: "FF453A"),
                "orange": Color(hex: "FF9F0A"),
                "yellow": Color(hex: "FFD60A"),
                "green": Color(hex: "32D74B"),
                "mint": Color(hex: "63E6E2"),
                "teal": Color(hex: "40C8E0"),
                "cyan": Color(hex: "64D2FF"),
                "blue": Color(hex: "0A84FF"),
                "indigo": Color(hex: "5E5CE6"),
                "purple": Color(hex: "BF5AF2"),
                "pink": Color(hex: "FF375F"),
                "brown": Color(hex: "AC8E68")
            ]
        ),
        .sunset: Theme(
            preset: .sunset,
            primaryColor: Color(hex: "FF6B6B"),
            backgroundColor: Color(hex: "FFF5F5"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "FFE0E0"),
            textColor: Color(hex: "2D3436"),
            secondaryTextColor: Color(hex: "636E72"),
            accentColor: Color(hex: "FFA502"),
            shadowColor: Color(hex: "FF6B6B").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "EE5A6F"),
                "orange": Color(hex: "F0932B"),
                "yellow": Color(hex: "F6B93B"),
                "green": Color(hex: "FA983A"),
                "mint": Color(hex: "EB8CC6"),
                "teal": Color(hex: "E77F67"),
                "cyan": Color(hex: "E15F41"),
                "blue": Color(hex: "C44569"),
                "indigo": Color(hex: "546DE5"),
                "purple": Color(hex: "574B90"),
                "pink": Color(hex: "F8B500"),
                "brown": Color(hex: "D63031")
            ]
        ),
        .ocean: Theme(
            preset: .ocean,
            primaryColor: Color(hex: "00B4D8"),
            backgroundColor: Color(hex: "F0F9FF"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "CAF0F8"),
            textColor: Color(hex: "03045E"),
            secondaryTextColor: Color(hex: "0077B6"),
            accentColor: Color(hex: "90E0EF"),
            shadowColor: Color(hex: "00B4D8").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "E63946"),
                "orange": Color(hex: "F77F00"),
                "yellow": Color(hex: "FCBF49"),
                "green": Color(hex: "06D6A0"),
                "mint": Color(hex: "00B4D8"),
                "teal": Color(hex: "0096C7"),
                "cyan": Color(hex: "0077B6"),
                "blue": Color(hex: "023E8A"),
                "indigo": Color(hex: "03045E"),
                "purple": Color(hex: "7209B7"),
                "pink": Color(hex: "F72585"),
                "brown": Color(hex: "8B5A3C")
            ]
        ),
        .forest: Theme(
            preset: .forest,
            primaryColor: Color(hex: "52B788"),
            backgroundColor: Color(hex: "F1FAEE"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "D8F3DC"),
            textColor: Color(hex: "1B4332"),
            secondaryTextColor: Color(hex: "40916C"),
            accentColor: Color(hex: "95D5B2"),
            shadowColor: Color(hex: "52B788").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "E76F51"),
                "orange": Color(hex: "F4A261"),
                "yellow": Color(hex: "E9C46A"),
                "green": Color(hex: "2A9D8F"),
                "mint": Color(hex: "52B788"),
                "teal": Color(hex: "40916C"),
                "cyan": Color(hex: "2D6A4F"),
                "blue": Color(hex: "1B4332"),
                "indigo": Color(hex: "081C15"),
                "purple": Color(hex: "264653"),
                "pink": Color(hex: "E76F51"),
                "brown": Color(hex: "6F4518")
            ]
        ),
        .lavender: Theme(
            preset: .lavender,
            primaryColor: Color(hex: "9D4EDD"),
            backgroundColor: Color(hex: "F8F5FF"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "E7DEFC"),
            textColor: Color(hex: "240046"),
            secondaryTextColor: Color(hex: "7209B7"),
            accentColor: Color(hex: "C77DFF"),
            shadowColor: Color(hex: "9D4EDD").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "E07C7C"),
                "orange": Color(hex: "E6A0C4"),
                "yellow": Color(hex: "F1C0E8"),
                "green": Color(hex: "C9ADA7"),
                "mint": Color(hex: "A8DADC"),
                "teal": Color(hex: "6D6875"),
                "cyan": Color(hex: "B5838D"),
                "blue": Color(hex: "7209B7"),
                "indigo": Color(hex: "560BAD"),
                "purple": Color(hex: "480CA8"),
                "pink": Color(hex: "F72585"),
                "brown": Color(hex: "3A0CA3")
            ]
        ),
        .midnight: Theme(
            preset: .midnight,
            primaryColor: Color(hex: "4A90E2"),
            backgroundColor: Color(hex: "0F1419"),
            cardBackgroundColor: Color(hex: "1A1F2E"),
            secondaryBackgroundColor: Color(hex: "242B3A"),
            textColor: Color(hex: "E8E8E8"),
            secondaryTextColor: Color(hex: "8892B0"),
            accentColor: Color(hex: "64FFDA"),
            shadowColor: Color.black.opacity(0.5),
            isDark: true,
            cardColorPalette: [
                "red": Color(hex: "FF5252"),
                "orange": Color(hex: "FF6B35"),
                "yellow": Color(hex: "FFD93D"),
                "green": Color(hex: "6BCF7F"),
                "mint": Color(hex: "64FFDA"),
                "teal": Color(hex: "4DD0E1"),
                "cyan": Color(hex: "00BCD4"),
                "blue": Color(hex: "4A90E2"),
                "indigo": Color(hex: "5C6BC0"),
                "purple": Color(hex: "AB47BC"),
                "pink": Color(hex: "EC407A"),
                "brown": Color(hex: "8D6E63")
            ]
        ),
        .sakura: Theme(
            preset: .sakura,
            primaryColor: Color(hex: "FF69B4"),
            backgroundColor: Color(hex: "FFF0F5"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "FFE4E1"),
            textColor: Color(hex: "4A0E4E"),
            secondaryTextColor: Color(hex: "8B008B"),
            accentColor: Color(hex: "FFB6C1"),
            shadowColor: Color(hex: "FF69B4").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "DC143C"),
                "orange": Color(hex: "FF7F50"),
                "yellow": Color(hex: "FFB347"),
                "green": Color(hex: "98D8C8"),
                "mint": Color(hex: "F7DC6F"),
                "teal": Color(hex: "FFC0CB"),
                "cyan": Color(hex: "FFB6C1"),
                "blue": Color(hex: "DDA0DD"),
                "indigo": Color(hex: "EE82EE"),
                "purple": Color(hex: "DA70D6"),
                "pink": Color(hex: "FF1493"),
                "brown": Color(hex: "BC8F8F")
            ]
        ),
        .autumn: Theme(
            preset: .autumn,
            primaryColor: Color(hex: "D2691E"),
            backgroundColor: Color(hex: "FFF8DC"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "FAEBD7"),
            textColor: Color(hex: "8B4513"),
            secondaryTextColor: Color(hex: "A0522D"),
            accentColor: Color(hex: "FF8C00"),
            shadowColor: Color(hex: "D2691E").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "B22222"),
                "orange": Color(hex: "FF8C00"),
                "yellow": Color(hex: "FFD700"),
                "green": Color(hex: "228B22"),
                "mint": Color(hex: "8FBC8F"),
                "teal": Color(hex: "CD853F"),
                "cyan": Color(hex: "D2691E"),
                "blue": Color(hex: "6B8E23"),
                "indigo": Color(hex: "556B2F"),
                "purple": Color(hex: "8B4513"),
                "pink": Color(hex: "BC8F8F"),
                "brown": Color(hex: "A52A2A")
            ]
        ),
        .mint: Theme(
            preset: .mint,
            primaryColor: Color(hex: "00BFA5"),
            backgroundColor: Color(hex: "F0FFF4"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "E0F2E9"),
            textColor: Color(hex: "004D40"),
            secondaryTextColor: Color(hex: "00695C"),
            accentColor: Color(hex: "64FFDA"),
            shadowColor: Color(hex: "00BFA5").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "FF5252"),
                "orange": Color(hex: "FF9800"),
                "yellow": Color(hex: "FFEB3B"),
                "green": Color(hex: "4CAF50"),
                "mint": Color(hex: "00BFA5"),
                "teal": Color(hex: "009688"),
                "cyan": Color(hex: "00BCD4"),
                "blue": Color(hex: "03A9F4"),
                "indigo": Color(hex: "3F51B5"),
                "purple": Color(hex: "9C27B0"),
                "pink": Color(hex: "E91E63"),
                "brown": Color(hex: "795548")
            ]
        ),
        .coral: Theme(
            preset: .coral,
            primaryColor: Color(hex: "FF6F61"),
            backgroundColor: Color(hex: "FFF5F3"),
            cardBackgroundColor: Color(hex: "FFFFFF"),
            secondaryBackgroundColor: Color(hex: "FFE8E5"),
            textColor: Color(hex: "5D4037"),
            secondaryTextColor: Color(hex: "BF360C"),
            accentColor: Color(hex: "FF8A65"),
            shadowColor: Color(hex: "FF6F61").opacity(0.2),
            isDark: false,
            cardColorPalette: [
                "red": Color(hex: "E53935"),
                "orange": Color(hex: "FB8C00"),
                "yellow": Color(hex: "FDD835"),
                "green": Color(hex: "43A047"),
                "mint": Color(hex: "00ACC1"),
                "teal": Color(hex: "00897B"),
                "cyan": Color(hex: "0097A7"),
                "blue": Color(hex: "1E88E5"),
                "indigo": Color(hex: "3949AB"),
                "purple": Color(hex: "8E24AA"),
                "pink": Color(hex: "D81B60"),
                "brown": Color(hex: "6D4C41")
            ]
        ),
        .aurora: Theme(
            preset: .aurora,
            primaryColor: Color(hex: "00E5FF"),
            backgroundColor: Color(hex: "0A0E27"),
            cardBackgroundColor: Color(hex: "151A3A"),
            secondaryBackgroundColor: Color(hex: "1F2451"),
            textColor: Color(hex: "FFFFFF"),
            secondaryTextColor: Color(hex: "B8C5EC"),
            accentColor: Color(hex: "B388FF"),
            shadowColor: Color.black.opacity(0.6),
            isDark: true,
            cardColorPalette: [
                "red": Color(hex: "FF006E"),
                "orange": Color(hex: "FB5607"),
                "yellow": Color(hex: "FFBE0B"),
                "green": Color(hex: "8FE402"),
                "mint": Color(hex: "00F5FF"),
                "teal": Color(hex: "00E5FF"),
                "cyan": Color(hex: "00D9FF"),
                "blue": Color(hex: "3A86FF"),
                "indigo": Color(hex: "8338EC"),
                "purple": Color(hex: "C77DFF"),
                "pink": Color(hex: "FF006E"),
                "brown": Color(hex: "8B5A3C")
            ]
        )
    ]
}

// テーマ管理クラス
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme
    @Published var selectedPreset: ThemePreset {
        didSet {
            updateTheme()
            savePreference()
        }
    }
    
    @AppStorage("selectedThemePreset") private var savedPreset: String = ThemePreset.system.rawValue
    @AppStorage("selectedAccentColor") private var savedAccentColor: String = "orange"
    
    static let shared = ThemeManager()
    
    init() {
        // 一時変数でプリセットを決定
        let presetString = UserDefaults.standard.string(forKey: "selectedThemePreset") ?? ThemePreset.system.rawValue
        let preset = ThemePreset(rawValue: presetString) ?? .system
        
        // プロパティを初期化
        self.selectedPreset = preset
        
        // テーマを設定
        if preset == .system {
            let colorScheme = UITraitCollection.current.userInterfaceStyle
            self.currentTheme = Theme.themes[colorScheme == .dark ? .dark : .light]!
        } else {
            self.currentTheme = Theme.themes[preset] ?? Theme.themes[.light]!
        }
    }
    
    private func updateTheme() {
        if selectedPreset == .system {
            let colorScheme = UITraitCollection.current.userInterfaceStyle
            currentTheme = Theme.themes[colorScheme == .dark ? .dark : .light]!
        } else {
            currentTheme = Theme.themes[selectedPreset] ?? Theme.themes[.light]!
        }
    }
    
    private func savePreference() {
        savedPreset = selectedPreset.rawValue
    }
    
    func updateAccentColor(_ color: String) {
        savedAccentColor = color
        objectWillChange.send()
    }
    
    var accentColor: Color {
        return getCardColor(for: savedAccentColor) ?? currentTheme.accentColor
    }
    
    // テーマに応じたカードカラーを取得
    func getCardColor(for colorName: String) -> Color? {
        return currentTheme.cardColorPalette[colorName]
    }
    
    // 現在のテーマで利用可能なカラーキーを取得
    var availableCardColors: [String] {
        return Array(currentTheme.cardColorPalette.keys).sorted()
    }
}

// Color拡張（16進数カラー対応）
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 