//
//  View+Glow.swift
//  CyberWeather
//
//  View 扩展 - 霓虹发光效果
//  为任意视图添加赛博朋克风格的发光效果
//

import SwiftUI

extension View {

    // MARK: - 霓虹发光效果

    /// 添加霓虹发光效果（多层阴影叠加实现）
    /// - Parameters:
    ///   - color: 发光颜色
    ///   - radius: 发光半径（默认 20）
    /// - Returns: 带发光效果的视图
    func neonGlow(color: Color = CyberTheme.neonBlue, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.8), radius: radius / 3) // 内层强光
            .shadow(color: color.opacity(0.6), radius: radius / 2) // 中层光晕
            .shadow(color: color.opacity(0.4), radius: radius) // 外层柔光
    }

    /// 使用预设配置的发光效果
    /// - Parameter glow: 发光配置
    /// - Returns: 带发光效果的视图
    func neonGlow(_ glow: CyberTheme.Glow) -> some View {
        self
            .shadow(color: glow.color.opacity(glow.intensity), radius: glow.radius / 3)
            .shadow(color: glow.color.opacity(glow.intensity * 0.75), radius: glow.radius / 2)
            .shadow(color: glow.color.opacity(glow.intensity * 0.5), radius: glow.radius)
    }

    /// 呼吸发光效果（动画）
    /// - Parameters:
    ///   - color: 发光颜色
    ///   - minRadius: 最小发光半径
    ///   - maxRadius: 最大发光半径
    ///   - isAnimating: 是否启用动画
    /// - Returns: 带呼吸发光效果的视图
    func breathingGlow(
        color: Color = CyberTheme.neonBlue,
        minRadius: CGFloat = 10,
        maxRadius: CGFloat = 25,
        isAnimating: Bool = true
    ) -> some View {
        modifier(BreathingGlowModifier(
            color: color,
            minRadius: minRadius,
            maxRadius: maxRadius,
            isAnimating: isAnimating
        ))
    }

    // MARK: - 玻璃拟态效果

    /// 添加玻璃拟态背景
    /// - Parameters:
    ///   - cornerRadius: 圆角半径
    ///   - borderWidth: 边框宽度
    /// - Returns: 带玻璃拟态效果的视图
    func glassBackground(
        cornerRadius: CGFloat = CyberTheme.CornerRadius.large,
        borderWidth: CGFloat = 1
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial) // 毛玻璃材质
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(CyberTheme.cardBorderGradient, lineWidth: borderWidth) // 渐变边框
                    )
            )
    }

    /// 添加赛博朋克风格卡片背景
    /// - Parameter cornerRadius: 圆角半径
    /// - Returns: 带卡片背景的视图
    func cyberCard(cornerRadius: CGFloat = CyberTheme.CornerRadius.large) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(CyberTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(CyberTheme.cardBorderGradient, lineWidth: 1)
                    )
            )
    }

    // MARK: - 动画效果

    /// 添加进入动画
    /// - Parameters:
    ///   - delay: 延迟时间
    ///   - isVisible: 是否可见
    /// - Returns: 带进入动画的视图
    func slideInFromBottom(delay: Double = 0, isVisible: Bool = true) -> some View {
        modifier(SlideInModifier(delay: delay, isVisible: isVisible))
    }

    /// 添加脉冲动画
    /// - Parameter isAnimating: 是否启用动画
    /// - Returns: 带脉冲动画的视图
    func pulseAnimation(isAnimating: Bool = true) -> some View {
        modifier(PulseModifier(isAnimating: isAnimating))
    }

    /// 添加缓慢旋转动画
    /// - Parameter duration: 旋转一周的时间
    /// - Returns: 带旋转动画的视图
    func slowRotation(duration: Double = 10) -> some View {
        modifier(SlowRotationModifier(duration: duration))
    }
}

// MARK: - 呼吸发光修饰器
/// 实现呼吸发光效果的 ViewModifier
struct BreathingGlowModifier: ViewModifier {
    let color: Color
    let minRadius: CGFloat
    let maxRadius: CGFloat
    let isAnimating: Bool

    @State private var currentRadius: CGFloat = 10 // 当前发光半径

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: currentRadius / 3)
            .shadow(color: color.opacity(0.6), radius: currentRadius / 2)
            .shadow(color: color.opacity(0.4), radius: currentRadius)
            .onAppear {
                if isAnimating {
                    withAnimation(
                        .easeInOut(duration: CyberTheme.Animation.breathing)
                        .repeatForever(autoreverses: true)
                    ) {
                        currentRadius = maxRadius
                    }
                }
            }
    }
}

// MARK: - 滑入动画修饰器
/// 从底部滑入的动画效果
struct SlideInModifier: ViewModifier {
    let delay: Double
    let isVisible: Bool

    @State private var offsetY: CGFloat = 50 // 初始偏移
    @State private var opacity: Double = 0 // 初始透明度

    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(delay)
                ) {
                    offsetY = 0
                    opacity = 1
                }
            }
            .onChange(of: isVisible) { _, newValue in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    offsetY = newValue ? 0 : 50
                    opacity = newValue ? 1 : 0
                }
            }
    }
}

// MARK: - 脉冲动画修饰器
/// 放大缩小的脉冲效果
struct PulseModifier: ViewModifier {
    let isAnimating: Bool

    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                if isAnimating {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        scale = 1.1
                    }
                }
            }
    }
}

// MARK: - 缓慢旋转修饰器
/// 持续缓慢旋转效果
struct SlowRotationModifier: ViewModifier {
    let duration: Double

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}
