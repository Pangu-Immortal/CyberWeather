//
//  GlassCard.swift
//  CyberWeather
//
//  玻璃拟态卡片组件
//  实现赛博朋克风格的半透明毛玻璃卡片效果
//

import SwiftUI

// MARK: - 玻璃卡片组件
/// 带毛玻璃效果和霓虹边框的卡片
struct GlassCard<Content: View>: View {

    // MARK: - 属性
    let cornerRadius: CGFloat // 圆角半径
    let borderWidth: CGFloat // 边框宽度
    let borderGradient: LinearGradient // 边框渐变
    let padding: CGFloat // 内边距
    let content: () -> Content // 内容闭包

    // MARK: - 初始化
    init(
        cornerRadius: CGFloat = CyberTheme.CornerRadius.large,
        borderWidth: CGFloat = 1,
        borderGradient: LinearGradient = CyberTheme.cardBorderGradient,
        padding: CGFloat = CyberTheme.Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderGradient = borderGradient
        self.padding = padding
        self.content = content
    }

    // MARK: - 视图
    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial) // 毛玻璃效果
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderGradient, lineWidth: borderWidth) // 渐变边框
                    )
            )
    }
}

// MARK: - 发光玻璃卡片
/// 带霓虹发光效果的玻璃卡片
struct GlowingGlassCard<Content: View>: View {

    let glowColor: Color // 发光颜色
    let glowRadius: CGFloat // 发光半径
    let cornerRadius: CGFloat // 圆角
    let content: () -> Content // 内容

    init(
        glowColor: Color = CyberTheme.neonBlue,
        glowRadius: CGFloat = 10,
        cornerRadius: CGFloat = CyberTheme.CornerRadius.large,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        GlassCard(cornerRadius: cornerRadius, content: content)
            .shadow(color: glowColor.opacity(0.3), radius: glowRadius)
    }
}

// MARK: - 详情卡片项
/// 用于天气详情的单项卡片
struct DetailCardItem: View {

    let icon: String // SF Symbol 图标名
    let title: String // 标题
    let value: String // 值
    let unit: String // 单位
    let iconColor: Color // 图标颜色

    init(
        icon: String,
        title: String,
        value: String,
        unit: String = "",
        iconColor: Color = CyberTheme.neonBlue
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.unit = unit
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CyberTheme.Spacing.sm) {
            // 图标和标题行
            HStack(spacing: CyberTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
                    .neonGlow(color: iconColor, radius: 5)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(CyberTheme.textSecondary)
            }

            // 值和单位
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(CyberTheme.textPrimary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(CyberTheme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 信息行组件
/// 单行信息显示（图标 + 标签 + 值）
struct InfoRow: View {

    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    init(
        icon: String,
        label: String,
        value: String,
        iconColor: Color = CyberTheme.neonBlue
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.iconColor = iconColor
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(label)
                .foregroundStyle(CyberTheme.textSecondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(CyberTheme.textPrimary)
        }
        .font(.subheadline)
    }
}

// MARK: - 预览
#Preview("GlassCard") {
    ZStack {
        CyberTheme.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 20) {
            // 基础玻璃卡片
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("玻璃卡片")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("这是一个毛玻璃效果的卡片组件")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)

            // 发光玻璃卡片
            GlowingGlassCard(glowColor: CyberTheme.neonPink) {
                Text("发光卡片")
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)

            // 详情项
            GlassCard {
                HStack {
                    DetailCardItem(icon: "wind", title: "风速", value: "12", unit: "km/h")
                    DetailCardItem(icon: "humidity", title: "湿度", value: "65", unit: "%", iconColor: CyberTheme.neonPink)
                }
            }
            .padding(.horizontal)

            // 信息行
            GlassCard {
                VStack(spacing: 12) {
                    InfoRow(icon: "sunrise", label: "日出", value: "06:30")
                    InfoRow(icon: "sunset", label: "日落", value: "18:45", iconColor: CyberTheme.neonOrange)
                }
            }
            .padding(.horizontal)
        }
    }
}
