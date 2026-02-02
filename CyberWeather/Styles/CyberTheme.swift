//
//  CyberTheme.swift
//  CyberWeather
//
//  赛博朋克主题配色定义
//  包含霓虹色彩、渐变配置、阴影参数等核心视觉元素
//

import SwiftUI

// MARK: - 赛博朋克主题命名空间
/// 统一管理所有赛博朋克风格的视觉元素
enum CyberTheme {

    // MARK: - 主色调
    /// 霓虹蓝 - 主色调，用于主要强调元素
    static let neonBlue = Color(hex: 0x00D4FF)
    /// 霓虹粉 - 强调色，用于次要强调和交互元素
    static let neonPink = Color(hex: 0xFF00FF)
    /// 霓虹紫 - 辅助色，用于背景渐变和装饰
    static let neonPurple = Color(hex: 0x7B2FFF)
    /// 霓虹橙 - 警告色，用于警告和高温显示
    static let neonOrange = Color(hex: 0xFF6B00)
    /// 霓虹绿 - 成功色，用于正常状态和低温显示
    static let neonGreen = Color(hex: 0x00FF88)
    /// 霓虹黄 - 中性色，用于中等状态
    static let neonYellow = Color(hex: 0xFFFF00)

    // MARK: - 背景色
    /// 深紫黑 - 主背景色
    static let darkBackground = Color(hex: 0x0A0A1A)
    /// 深蓝黑 - 次级背景色
    static let darkBlue = Color(hex: 0x0D1B2A)
    /// 卡片背景色（半透明深蓝）
    static let cardBackground = Color(hex: 0x141428).opacity(0.7)

    // MARK: - 文字颜色
    /// 主文字颜色（亮白）
    static let textPrimary = Color.white
    /// 次级文字颜色（灰白）
    static let textSecondary = Color.white.opacity(0.7)
    /// 第三级文字颜色（暗灰）
    static let textTertiary = Color.white.opacity(0.5)

    // MARK: - 渐变配置
    /// 主渐变（蓝到紫）
    static let primaryGradient = LinearGradient(
        colors: [neonBlue, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 粉紫渐变
    static let pinkPurpleGradient = LinearGradient(
        colors: [neonPink, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 背景渐变
    static let backgroundGradient = LinearGradient(
        colors: [darkBackground, darkBlue, Color(hex: 0x1B0A2E)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// 卡片边框渐变
    static let cardBorderGradient = LinearGradient(
        colors: [neonBlue.opacity(0.5), neonPurple.opacity(0.3), neonPink.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 温度渐变（冷到热）
    static func temperatureGradient(for temperature: Double) -> LinearGradient {
        let colors: [Color]
        switch temperature {
        case ..<0: colors = [neonBlue, Color(hex: 0x00FFFF)] // 极冷
        case 0..<10: colors = [neonBlue, neonPurple] // 冷
        case 10..<20: colors = [neonPurple, neonPink] // 凉爽
        case 20..<30: colors = [neonPink, neonOrange] // 温暖
        case 30..<40: colors = [neonOrange, neonYellow] // 热
        default: colors = [neonOrange, Color.red] // 极热
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - 发光参数
    /// 霓虹发光配置
    struct Glow {
        let color: Color // 发光颜色
        let radius: CGFloat // 发光半径
        let intensity: Double // 发光强度（透明度）

        /// 蓝色发光（默认）
        static let blue = Glow(color: neonBlue, radius: 20, intensity: 0.8)
        /// 粉色发光
        static let pink = Glow(color: neonPink, radius: 20, intensity: 0.8)
        /// 紫色发光
        static let purple = Glow(color: neonPurple, radius: 20, intensity: 0.8)
        /// 柔和发光
        static let soft = Glow(color: neonBlue, radius: 10, intensity: 0.5)
        /// 强烈发光
        static let intense = Glow(color: neonBlue, radius: 30, intensity: 1.0)
    }

    // MARK: - 动画时长
    struct Animation {
        /// 快速动画（0.2秒）
        static let fast: Double = 0.2
        /// 标准动画（0.35秒）
        static let standard: Double = 0.35
        /// 慢速动画（0.5秒）
        static let slow: Double = 0.5
        /// 呼吸动画周期（2秒）
        static let breathing: Double = 2.0
        /// 粒子漂浮周期（8秒）
        static let particle: Double = 8.0
        /// 渐变流动周期（3秒）
        static let gradientFlow: Double = 3.0
    }

    // MARK: - 圆角配置
    struct CornerRadius {
        /// 小圆角（8）
        static let small: CGFloat = 8
        /// 中圆角（16）
        static let medium: CGFloat = 16
        /// 大圆角（20）
        static let large: CGFloat = 20
        /// 超大圆角（28）
        static let extraLarge: CGFloat = 28
    }

    // MARK: - 间距配置
    struct Spacing {
        /// 极小间距（4）
        static let xs: CGFloat = 4
        /// 小间距（8）
        static let sm: CGFloat = 8
        /// 中间距（16）
        static let md: CGFloat = 16
        /// 大间距（24）
        static let lg: CGFloat = 24
        /// 超大间距（32）
        static let xl: CGFloat = 32
    }
}

// MARK: - 天气代码到图标映射
extension CyberTheme {
    /// 根据 WMO 天气代码返回对应的 SF Symbol 图标名
    static func weatherIcon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill" // 晴朗
        case 1, 2, 3: return "cloud.sun.fill" // 多云
        case 45, 48: return "cloud.fog.fill" // 雾
        case 51, 53, 55: return "cloud.drizzle.fill" // 毛毛雨
        case 56, 57: return "cloud.sleet.fill" // 冻毛毛雨
        case 61, 63, 65: return "cloud.rain.fill" // 雨
        case 66, 67: return "cloud.sleet.fill" // 冻雨
        case 71, 73, 75: return "cloud.snow.fill" // 雪
        case 77: return "snowflake" // 雪粒
        case 80, 81, 82: return "cloud.heavyrain.fill" // 阵雨
        case 85, 86: return "cloud.snow.fill" // 阵雪
        case 95: return "cloud.bolt.fill" // 雷暴
        case 96, 99: return "cloud.bolt.rain.fill" // 雷暴+冰雹
        default: return "questionmark.circle.fill"
        }
    }

    /// 根据 WMO 天气代码返回中文描述
    static func weatherDescription(for code: Int) -> String {
        switch code {
        case 0: return "晴朗"
        case 1: return "大部晴朗"
        case 2: return "局部多云"
        case 3: return "阴天"
        case 45: return "雾"
        case 48: return "沉积凝雾"
        case 51: return "轻微毛毛雨"
        case 53: return "中等毛毛雨"
        case 55: return "密集毛毛雨"
        case 56: return "轻微冻毛毛雨"
        case 57: return "密集冻毛毛雨"
        case 61: return "轻微小雨"
        case 63: return "中等降雨"
        case 65: return "大雨"
        case 66: return "轻微冻雨"
        case 67: return "大冻雨"
        case 71: return "轻微降雪"
        case 73: return "中等降雪"
        case 75: return "大雪"
        case 77: return "雪粒"
        case 80: return "轻微阵雨"
        case 81: return "中等阵雨"
        case 82: return "猛烈阵雨"
        case 85: return "轻微阵雪"
        case 86: return "大阵雪"
        case 95: return "雷暴"
        case 96: return "雷暴+小冰雹"
        case 99: return "雷暴+大冰雹"
        default: return "未知天气"
        }
    }

    /// 根据天气代码返回对应的霓虹颜色
    static func weatherColor(for code: Int) -> Color {
        switch code {
        case 0, 1: return neonYellow // 晴天 - 黄色
        case 2, 3: return neonPurple // 多云 - 紫色
        case 45, 48: return Color.gray // 雾 - 灰色
        case 51...67: return neonBlue // 雨 - 蓝色
        case 71...77, 85, 86: return Color.white // 雪 - 白色
        case 80...82: return neonBlue // 阵雨 - 蓝色
        case 95...99: return neonPink // 雷暴 - 粉色
        default: return neonBlue
        }
    }
}
