//
//  Color+Cyber.swift
//  SmartCleaner
//
//  Color 扩展 - 支持十六进制颜色初始化
//  为赛博朋克主题提供便捷的颜色创建方式
//

import SwiftUI

extension Color {
    /// 通过十六进制值初始化颜色
    /// - Parameter hex: 十六进制颜色值（如 0xFF00FF）
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0, // 提取红色分量
            green: Double((hex >> 8) & 0xFF) / 255.0, // 提取绿色分量
            blue: Double(hex & 0xFF) / 255.0 // 提取蓝色分量
        )
    }

    /// 通过十六进制字符串初始化颜色（便捷方法）
    /// - Parameter hex: 十六进制颜色字符串（支持 "#RRGGBB" 或 "RRGGBB" 格式）
    init(hex: String) {
        var cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines) // 去除空白
        cleanedHex = cleanedHex.replacingOccurrences(of: "#", with: "") // 去除 # 符号

        var rgb: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&rgb) // 解析十六进制

        self.init(hex: UInt(rgb))
    }

    /// 通过十六进制字符串初始化颜色
    /// - Parameter hexString: 十六进制颜色字符串（支持 "#RRGGBB" 或 "RRGGBB" 格式）
    init(hexString: String) {
        self.init(hex: hexString)
    }

    /// 调整颜色亮度
    /// - Parameter amount: 亮度调整量（正值变亮，负值变暗）
    func adjustBrightness(_ amount: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        // 转换为 UIColor 以获取 HSB 分量
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // 调整亮度并确保在有效范围内
        let newBrightness = max(0, min(1, brightness + CGFloat(amount)))

        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(newBrightness), opacity: Double(alpha))
    }

    /// 将颜色与另一颜色混合
    /// - Parameters:
    ///   - color: 要混合的颜色
    ///   - amount: 混合比例（0-1，0 为完全当前色，1 为完全目标色）
    func blend(with color: Color, amount: Double) -> Color {
        let uiColor1 = UIColor(self)
        let uiColor2 = UIColor(color)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) // 获取当前颜色 RGBA
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) // 获取目标颜色 RGBA

        let clampedAmount = CGFloat(max(0, min(1, amount))) // 确保混合比例在有效范围

        return Color(
            red: Double(r1 + (r2 - r1) * clampedAmount),
            green: Double(g1 + (g2 - g1) * clampedAmount),
            blue: Double(b1 + (b2 - b1) * clampedAmount),
            opacity: Double(a1 + (a2 - a1) * clampedAmount)
        )
    }
}

// MARK: - 便捷赛博朋克颜色访问
extension Color {
    /// 快捷访问赛博朋克主色调
    static var cyberBlue: Color { CyberTheme.neonBlue }
    static var cyberPink: Color { CyberTheme.neonPink }
    static var cyberPurple: Color { CyberTheme.neonPurple }
    static var cyberOrange: Color { CyberTheme.neonOrange }
    static var cyberGreen: Color { CyberTheme.neonGreen }
    static var cyberYellow: Color { CyberTheme.neonYellow }

    /// 快捷访问背景色
    static var cyberBackground: Color { CyberTheme.darkBackground }
    static var cyberDarkBlue: Color { CyberTheme.darkBlue }
}

// MARK: - 渐变颜色数组
extension Array where Element == Color {
    /// 赛博朋克标准渐变色组
    static var cyberGradient: [Color] {
        [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink]
    }

    /// 赛博朋克冷色渐变
    static var cyberCoolGradient: [Color] {
        [CyberTheme.neonBlue, CyberTheme.neonPurple]
    }

    /// 赛博朋克暖色渐变
    static var cyberWarmGradient: [Color] {
        [CyberTheme.neonPink, CyberTheme.neonOrange]
    }

    /// 彩虹霓虹渐变
    static var cyberRainbow: [Color] {
        [
            CyberTheme.neonBlue,
            CyberTheme.neonPurple,
            CyberTheme.neonPink,
            CyberTheme.neonOrange,
            CyberTheme.neonYellow,
            CyberTheme.neonGreen
        ]
    }
}
