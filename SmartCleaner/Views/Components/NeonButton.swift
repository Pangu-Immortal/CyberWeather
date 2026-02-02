//
//  NeonButton.swift
//  SmartCleaner
//
//  霓虹发光按钮组件
//  支持多种样式：实心、边框、渐变、脉冲
//  赛博朋克风格，带动态发光效果
//

import SwiftUI

// MARK: - 按钮样式
enum NeonButtonStyle {
    case solid          // 实心填充
    case outline        // 边框轮廓
    case gradient       // 渐变填充
    case pulse          // 脉冲效果
}

// MARK: - 霓虹按钮
struct NeonButton: View {
    let title: String                                          // 按钮文字
    let icon: String?                                          // SF Symbol图标
    let style: NeonButtonStyle                                 // 按钮样式
    let primaryColor: Color                                    // 主色
    let secondaryColor: Color                                  // 辅助色
    let action: () -> Void                                     // 点击动作

    @State private var isPressed: Bool = false                // 按下状态
    @State private var glowPhase: CGFloat = 0                 // 发光相位
    @State private var pulseScale: CGFloat = 1                // 脉冲缩放

    init(
        _ title: String,
        icon: String? = nil,
        style: NeonButtonStyle = .solid,
        primaryColor: Color = Color(hex: "00D4FF"),
        secondaryColor: Color = Color(hex: "7B2FFF"),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            buttonContent
        }
        .buttonStyle(.plain)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - 按钮内容
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(buttonOverlay)
        .shadow(color: primaryColor.opacity(0.5), radius: isPressed ? 5 : 15)
        .shadow(color: primaryColor.opacity(0.3), radius: isPressed ? 10 : 25)
        .scaleEffect(isPressed ? 0.95 : (style == .pulse ? pulseScale : 1.0))
    }

    // MARK: - 文字颜色
    private var textColor: Color {
        switch style {
        case .solid, .gradient, .pulse:
            return .white
        case .outline:
            return primaryColor
        }
    }

    // MARK: - 按钮背景
    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .solid:
            solidBackground
        case .outline:
            outlineBackground
        case .gradient:
            gradientBackground
        case .pulse:
            pulseBackground
        }
    }

    // 实心背景
    private var solidBackground: some View {
        ZStack {
            // 基础颜色
            primaryColor

            // 顶部高光
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            // 底部阴影
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.2)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }

    // 边框背景
    private var outlineBackground: some View {
        Color.clear
    }

    // 渐变背景
    private var gradientBackground: some View {
        ZStack {
            // 流动渐变
            LinearGradient(
                colors: [primaryColor, secondaryColor, primaryColor],
                startPoint: UnitPoint(x: glowPhase - 0.5, y: 0),
                endPoint: UnitPoint(x: glowPhase + 0.5, y: 1)
            )

            // 顶部高光
            LinearGradient(
                colors: [
                    Color.white.opacity(0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    // 脉冲背景
    private var pulseBackground: some View {
        ZStack {
            // 基础渐变
            LinearGradient(
                colors: [primaryColor, secondaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 发光层
            RadialGradient(
                colors: [
                    Color.white.opacity(glowPhase * 0.3),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        }
    }

    // MARK: - 按钮叠加层
    @ViewBuilder
    private var buttonOverlay: some View {
        switch style {
        case .solid:
            solidOverlay
        case .outline:
            outlineOverlay
        case .gradient:
            gradientOverlay
        case .pulse:
            pulseOverlay
        }
    }

    // 实心叠加
    private var solidOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        primaryColor.opacity(0.5),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // 边框叠加
    private var outlineOverlay: some View {
        ZStack {
            // 外发光边框
            RoundedRectangle(cornerRadius: 12)
                .stroke(primaryColor.opacity(0.5), lineWidth: 4)
                .blur(radius: 4)

            // 主边框
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    AngularGradient(
                        colors: [primaryColor, secondaryColor, primaryColor],
                        center: .center,
                        startAngle: .degrees(Double(glowPhase) * 360),
                        endAngle: .degrees(Double(glowPhase) * 360 + 360)
                    ),
                    lineWidth: 2
                )
        }
    }

    // 渐变叠加
    private var gradientOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        Color.clear,
                        Color.white.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // 脉冲叠加
    private var pulseOverlay: some View {
        ZStack {
            // 脉冲光环
            RoundedRectangle(cornerRadius: 12)
                .stroke(primaryColor.opacity(0.5 * (1 - Double(pulseScale - 1) * 3)), lineWidth: 2)
                .scaleEffect(pulseScale)

            // 内边框
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - 启动动画
    private func startAnimations() {
        // 发光相位动画
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            glowPhase = 1
        }

        // 脉冲动画（仅pulse样式）
        if style == .pulse {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
}

// MARK: - 图标按钮变体
struct NeonIconButton: View {
    let icon: String                                           // SF Symbol图标
    let size: CGFloat                                          // 按钮尺寸
    let color: Color                                           // 主色
    let action: () -> Void                                     // 点击动作

    @State private var isPressed: Bool = false                // 按下状态
    @State private var rotationAngle: Double = 0              // 旋转角度

    init(
        icon: String,
        size: CGFloat = 44,
        color: Color = Color(hex: "00D4FF"),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                // 外发光
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: size + 10, height: size + 10)
                    .blur(radius: 8)

                // 背景
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "1a1a3e"),
                                Color(hex: "14142e")
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)

                // 边框
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [color, color.opacity(0.5), color],
                            center: .center,
                            startAngle: .degrees(rotationAngle),
                            endAngle: .degrees(rotationAngle + 360)
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)

                // 图标
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(color)
            }
            .shadow(color: color.opacity(0.5), radius: isPressed ? 5 : 10)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - 悬浮动作按钮
struct NeonFloatingButton: View {
    let icon: String                                           // SF Symbol图标
    let color: Color                                           // 主色
    let action: () -> Void                                     // 点击动作

    @State private var isPressed: Bool = false                // 按下状态
    @State private var breatheScale: CGFloat = 1              // 呼吸缩放
    @State private var glowOpacity: Double = 0.5              // 发光透明度

    init(
        icon: String,
        color: Color = Color(hex: "00D4FF"),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                // 外层呼吸光环
                Circle()
                    .fill(color.opacity(glowOpacity * 0.3))
                    .frame(width: 70, height: 70)
                    .scaleEffect(breatheScale)
                    .blur(radius: 10)

                // 中层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.4),
                                color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 60, height: 60)

                // 主按钮
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color,
                                color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                // 图标
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.6), radius: isPressed ? 5 : 15, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                breatheScale = 1.2
                glowOpacity = 0.8
            }
        }
    }
}

// MARK: - 预览
#Preview("Solid Button") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        VStack(spacing: 20) {
            NeonButton("刷新数据", icon: "arrow.clockwise", style: .solid) {
                print("Solid button tapped")
            }

            NeonButton("确认", style: .solid, primaryColor: Color(hex: "00E400")) {
                print("Green button tapped")
            }
        }
    }
}

#Preview("Outline Button") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        VStack(spacing: 20) {
            NeonButton("取消", icon: "xmark", style: .outline) {
                print("Outline button tapped")
            }

            NeonButton("设置", icon: "gearshape", style: .outline, primaryColor: Color(hex: "FF00FF")) {
                print("Settings tapped")
            }
        }
    }
}

#Preview("Gradient Button") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        NeonButton("开始体验", icon: "sparkles", style: .gradient) {
            print("Gradient button tapped")
        }
    }
}

#Preview("Pulse Button") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        NeonButton("定位", icon: "location.fill", style: .pulse, primaryColor: Color(hex: "FF6B00")) {
            print("Pulse button tapped")
        }
    }
}

#Preview("Icon Button") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        HStack(spacing: 20) {
            NeonIconButton(icon: "gearshape.fill") {
                print("Settings tapped")
            }

            NeonIconButton(icon: "location.fill", color: Color(hex: "FF00FF")) {
                print("Location tapped")
            }

            NeonIconButton(icon: "bell.fill", color: Color(hex: "FFD700")) {
                print("Bell tapped")
            }
        }
    }
}

#Preview("Floating Button") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                NeonFloatingButton(icon: "plus") {
                    print("Floating button tapped")
                }
                .padding(30)
            }
        }
    }
}
