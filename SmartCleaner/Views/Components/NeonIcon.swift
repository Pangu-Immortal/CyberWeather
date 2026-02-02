//
//  NeonIcon.swift
//  SmartCleaner
//
//  霓虹图标组件
//  带发光效果的天气图标和通用图标组件
//

import SwiftUI

// MARK: - 霓虹图标
/// 带霓虹发光效果的 SF Symbol 图标
struct NeonIcon: View {

    // MARK: - 属性
    let systemName: String // SF Symbol 名称
    let size: CGFloat // 图标大小
    let color: Color // 图标颜色
    let glowRadius: CGFloat // 发光半径
    let isAnimated: Bool // 是否启用动画

    @State private var glowIntensity: Double = 1.0

    // MARK: - 初始化
    init(
        systemName: String,
        size: CGFloat = 24,
        color: Color = CyberTheme.neonBlue,
        glowRadius: CGFloat = 10,
        animated: Bool = false
    ) {
        self.systemName = systemName
        self.size = size
        self.color = color
        self.glowRadius = glowRadius
        self.isAnimated = animated
    }

    // MARK: - 视图
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.8 * glowIntensity), radius: glowRadius / 3)
            .shadow(color: color.opacity(0.6 * glowIntensity), radius: glowRadius / 2)
            .shadow(color: color.opacity(0.4 * glowIntensity), radius: glowRadius)
            .onAppear {
                if isAnimated {
                    withAnimation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        glowIntensity = 1.5
                    }
                }
            }
    }
}

// MARK: - 大天气图标
/// 用于主界面的大型天气图标
struct LargeWeatherIcon: View {

    let iconName: String // 图标名称
    let weatherCode: Int // 天气代码（用于确定颜色）
    let size: CGFloat // 图标大小
    let isAnimated: Bool // 是否动画

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    init(
        iconName: String,
        weatherCode: Int = 0,
        size: CGFloat = 80,
        animated: Bool = true
    ) {
        self.iconName = iconName
        self.weatherCode = weatherCode
        self.size = size
        self.isAnimated = animated
    }

    var body: some View {
        let iconColor = CyberTheme.weatherColor(for: weatherCode)

        Image(systemName: iconName)
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [iconColor, iconColor.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: iconColor.opacity(0.8), radius: 15)
            .shadow(color: iconColor.opacity(0.5), radius: 25)
            .shadow(color: iconColor.opacity(0.3), radius: 40)
            .scaleEffect(scale)
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .onAppear {
                if isAnimated {
                    // 缓慢 3D 旋转
                    withAnimation(
                        .linear(duration: 10)
                        .repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }

                    // 轻微脉冲
                    withAnimation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                    ) {
                        scale = 1.05
                    }
                }
            }
    }
}

// MARK: - 小天气图标
/// 用于列表项的小型天气图标
struct SmallWeatherIcon: View {

    let iconName: String
    let weatherCode: Int
    let size: CGFloat

    init(iconName: String, weatherCode: Int = 0, size: CGFloat = 24) {
        self.iconName = iconName
        self.weatherCode = weatherCode
        self.size = size
    }

    var body: some View {
        let iconColor = CyberTheme.weatherColor(for: weatherCode)

        Image(systemName: iconName)
            .font(.system(size: size))
            .foregroundStyle(iconColor)
            .shadow(color: iconColor.opacity(0.6), radius: 5)
    }
}

// MARK: - 位置图标
/// 带脉动动画的位置图标
struct LocationIcon: View {

    let isAnimated: Bool
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.8

    init(animated: Bool = true) {
        self.isAnimated = animated
    }

    var body: some View {
        ZStack {
            // 脉冲圆圈
            if isAnimated {
                Circle()
                    .fill(CyberTheme.neonBlue.opacity(pulseOpacity * 0.3))
                    .frame(width: 30 * pulseScale, height: 30 * pulseScale)

                Circle()
                    .stroke(CyberTheme.neonBlue.opacity(pulseOpacity), lineWidth: 1)
                    .frame(width: 30 * pulseScale, height: 30 * pulseScale)
            }

            // 定位图标
            Image(systemName: "location.fill")
                .font(.system(size: 14))
                .foregroundStyle(CyberTheme.neonBlue)
                .neonGlow(color: CyberTheme.neonBlue, radius: 8)
        }
        .onAppear {
            if isAnimated {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.3
                    pulseOpacity = 0.3
                }
            }
        }
    }
}

// MARK: - 刷新图标
/// 带旋转动画的刷新图标
struct RefreshIcon: View {

    let isRefreshing: Bool // 是否正在刷新
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(CyberTheme.neonBlue)
            .rotationEffect(.degrees(rotation))
            .neonGlow(color: CyberTheme.neonBlue, radius: 5)
            .onChange(of: isRefreshing) { _, newValue in
                if newValue {
                    withAnimation(
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rotation = 0
                    }
                }
            }
    }
}

// MARK: - 预览
#Preview("NeonIcon") {
    ZStack {
        CyberTheme.darkBackground.ignoresSafeArea()

        VStack(spacing: 40) {
            // 基础霓虹图标
            HStack(spacing: 30) {
                NeonIcon(systemName: "sun.max.fill", color: CyberTheme.neonYellow)
                NeonIcon(systemName: "cloud.rain.fill", color: CyberTheme.neonBlue)
                NeonIcon(systemName: "cloud.bolt.fill", color: CyberTheme.neonPink, animated: true)
            }

            // 大天气图标
            LargeWeatherIcon(iconName: "sun.max.fill", weatherCode: 0)

            // 小天气图标组
            HStack(spacing: 20) {
                SmallWeatherIcon(iconName: "cloud.fill", weatherCode: 3)
                SmallWeatherIcon(iconName: "cloud.rain.fill", weatherCode: 61)
                SmallWeatherIcon(iconName: "cloud.snow.fill", weatherCode: 71)
            }

            // 位置图标
            HStack(spacing: 8) {
                LocationIcon()
                Text("北京市")
                    .foregroundStyle(.white)
            }

            // 刷新图标
            RefreshIcon(isRefreshing: true)
        }
    }
}
