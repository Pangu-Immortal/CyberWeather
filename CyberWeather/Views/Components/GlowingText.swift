//
//  GlowingText.swift
//  CyberWeather
//
//  霓虹发光文字组件
//  实现赛博朋克风格的发光文字效果
//

import SwiftUI

// MARK: - 霓虹发光文字
/// 带霓虹发光效果的文字组件
struct GlowingText: View {

    // MARK: - 属性
    let text: String // 文字内容
    let font: Font // 字体
    let color: Color // 文字颜色
    let glowColor: Color // 发光颜色
    let glowRadius: CGFloat // 发光半径
    let isAnimated: Bool // 是否启用呼吸动画

    @State private var currentGlowRadius: CGFloat = 10 // 当前发光半径（动画用）

    // MARK: - 初始化
    init(
        _ text: String,
        font: Font = .title,
        color: Color = .white,
        glowColor: Color = CyberTheme.neonBlue,
        glowRadius: CGFloat = 15,
        animated: Bool = false
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.isAnimated = animated
    }

    // MARK: - 视图
    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .shadow(color: glowColor.opacity(0.9), radius: isAnimated ? currentGlowRadius / 3 : glowRadius / 3)
            .shadow(color: glowColor.opacity(0.7), radius: isAnimated ? currentGlowRadius / 2 : glowRadius / 2)
            .shadow(color: glowColor.opacity(0.5), radius: isAnimated ? currentGlowRadius : glowRadius)
            .onAppear {
                if isAnimated {
                    startBreathingAnimation() // 启动呼吸动画
                }
            }
    }

    // MARK: - 私有方法
    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: CyberTheme.Animation.breathing)
            .repeatForever(autoreverses: true)
        ) {
            currentGlowRadius = glowRadius * 1.5
        }
    }
}

// MARK: - 大温度显示组件
/// 专门用于显示温度的大字组件
struct LargeTemperatureText: View {

    let temperature: String // 温度值
    let unit: String // 单位（默认 °）
    let color: Color // 颜色
    let animated: Bool // 是否动画

    @State private var glowIntensity: Double = 1.0

    init(
        _ temperature: String,
        unit: String = "°",
        color: Color = .white,
        animated: Bool = true
    ) {
        self.temperature = temperature
        self.unit = unit
        self.color = color
        self.animated = animated
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 温度数字
            Text(temperature)
                .font(.system(size: 120, weight: .thin, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: CyberTheme.neonBlue.opacity(0.8 * glowIntensity), radius: 10)
                .shadow(color: CyberTheme.neonBlue.opacity(0.6 * glowIntensity), radius: 20)
                .shadow(color: CyberTheme.neonPurple.opacity(0.4 * glowIntensity), radius: 30)

            // 度数符号
            Text(unit)
                .font(.system(size: 50, weight: .thin))
                .foregroundStyle(color.opacity(0.8))
                .offset(y: 10)
        }
        .onAppear {
            if animated {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    glowIntensity = 1.3
                }
            }
        }
    }
}

// MARK: - 渐变文字组件
/// 带渐变颜色的文字
struct GradientText: View {

    let text: String
    let gradient: LinearGradient
    let font: Font

    init(
        _ text: String,
        gradient: LinearGradient = CyberTheme.primaryGradient,
        font: Font = .headline
    ) {
        self.text = text
        self.gradient = gradient
        self.font = font
    }

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(.semibold)
            .foregroundStyle(gradient)
    }
}

// MARK: - 预览
#Preview("GlowingText") {
    ZStack {
        CyberTheme.darkBackground.ignoresSafeArea()

        VStack(spacing: 30) {
            GlowingText("霓虹蓝", glowColor: CyberTheme.neonBlue)
            GlowingText("霓虹粉", glowColor: CyberTheme.neonPink)
            GlowingText("霓虹紫", glowColor: CyberTheme.neonPurple, animated: true)

            LargeTemperatureText("25")

            GradientText("渐变文字效果", font: .title2)
        }
    }
}
