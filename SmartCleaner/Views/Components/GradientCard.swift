//
//  GradientCard.swift
//  SmartCleaner
//
//  渐变立体卡片组件
//  提供3D深度效果、动态边框、玻璃拟态
//  增强赛博朋克视觉层次
//

import SwiftUI

// MARK: - 卡片样式
enum GradientCardStyle {
    case neon           // 霓虹发光
    case glass          // 玻璃拟态
    case holographic    // 全息效果
    case depth3D        // 3D深度
}

// MARK: - 渐变立体卡片
struct GradientCard<Content: View>: View {
    let style: GradientCardStyle                        // 卡片样式
    let borderColors: [Color]                           // 边框渐变色
    let cornerRadius: CGFloat                           // 圆角半径
    let shadowRadius: CGFloat                           // 阴影半径
    @ViewBuilder let content: Content                   // 内容

    @State private var animationPhase: CGFloat = 0     // 动画相位
    @State private var isHovered: Bool = false         // 悬停状态

    init(
        style: GradientCardStyle = .neon,
        borderColors: [Color] = [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.borderColors = borderColors
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(cardBackground)
            .overlay(cardBorder)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: primaryColor.opacity(0.3), radius: shadowRadius, x: 0, y: 5)
            .shadow(color: primaryColor.opacity(0.1), radius: shadowRadius * 2, x: 0, y: 10)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animationPhase = 1
                }
            }
    }

    // 主色
    private var primaryColor: Color {
        borderColors.first ?? Color(hex: "00D4FF")
    }

    // MARK: - 卡片背景
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .neon:
            neonBackground
        case .glass:
            glassBackground
        case .holographic:
            holographicBackground
        case .depth3D:
            depth3DBackground
        }
    }

    // 霓虹背景
    private var neonBackground: some View {
        ZStack {
            // 深色基底
            Color(hex: "14142e").opacity(0.95)

            // 渐变光晕
            RadialGradient(
                colors: [
                    primaryColor.opacity(0.15),
                    Color.clear
                ],
                center: UnitPoint(
                    x: 0.3 + sin(animationPhase * .pi * 2) * 0.2,
                    y: 0.3 + cos(animationPhase * .pi * 2) * 0.2
                ),
                startRadius: 0,
                endRadius: 200
            )
        }
    }

    // 玻璃背景
    private var glassBackground: some View {
        ZStack {
            // 磨砂玻璃
            Color(hex: "1a1a3e").opacity(0.6)

            // 高光反射
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color.white.opacity(0.05)
                ],
                startPoint: UnitPoint(x: 0, y: animationPhase),
                endPoint: UnitPoint(x: 1, y: animationPhase + 0.5)
            )

            // 噪点纹理
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        }
    }

    // 全息背景
    private var holographicBackground: some View {
        ZStack {
            Color(hex: "14142e").opacity(0.9)

            // 彩虹渐变
            LinearGradient(
                colors: [
                    Color(hex: "FF00FF").opacity(0.2),
                    Color(hex: "00D4FF").opacity(0.2),
                    Color(hex: "00E400").opacity(0.2),
                    Color(hex: "FFD700").opacity(0.2),
                    Color(hex: "FF00FF").opacity(0.2)
                ],
                startPoint: UnitPoint(x: animationPhase - 0.5, y: 0),
                endPoint: UnitPoint(x: animationPhase + 0.5, y: 1)
            )

            // 扫描线
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 1)
                        .offset(y: CGFloat(i) * (geometry.size.height / 20))
                }
            }
        }
    }

    // 3D深度背景
    private var depth3DBackground: some View {
        ZStack {
            // 多层渐变模拟深度
            ForEach(0..<3, id: \.self) { layer in
                RoundedRectangle(cornerRadius: cornerRadius - CGFloat(layer) * 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1a1a3e").opacity(1 - Double(layer) * 0.2),
                                Color(hex: "0d0d2b").opacity(1 - Double(layer) * 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(CGFloat(layer) * 2)
            }

            // 内部光泽
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - 卡片边框
    @ViewBuilder
    private var cardBorder: some View {
        switch style {
        case .neon:
            neonBorder
        case .glass:
            glassBorder
        case .holographic:
            holographicBorder
        case .depth3D:
            depth3DBorder
        }
    }

    // 霓虹边框
    private var neonBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                AngularGradient(
                    colors: borderColors + [borderColors.first ?? .clear],
                    center: .center,
                    startAngle: .degrees(Double(animationPhase) * 360),
                    endAngle: .degrees(Double(animationPhase) * 360 + 360)
                ),
                lineWidth: 2
            )
            .shadow(color: primaryColor.opacity(0.5), radius: 5)
    }

    // 玻璃边框
    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // 全息边框
    private var holographicBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(hex: "FF00FF"),
                        Color(hex: "00D4FF"),
                        Color(hex: "00E400"),
                        Color(hex: "FFD700"),
                        Color(hex: "FF00FF")
                    ],
                    startPoint: UnitPoint(x: animationPhase * 2, y: 0),
                    endPoint: UnitPoint(x: animationPhase * 2 + 1, y: 1)
                ),
                lineWidth: 2
            )
    }

    // 3D边框
    private var depth3DBorder: some View {
        ZStack {
            // 外层阴影边框
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                .offset(x: 2, y: 2)

            // 主边框
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            borderColors.first?.opacity(0.6) ?? Color.clear,
                            borderColors.last?.opacity(0.3) ?? Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // 内层高光
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                .padding(1)
        }
    }
}

// MARK: - 便捷修饰器
extension View {
    /// 应用霓虹卡片样式
    func neonCard(
        borderColors: [Color] = [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
        cornerRadius: CGFloat = 16
    ) -> some View {
        GradientCard(style: .neon, borderColors: borderColors, cornerRadius: cornerRadius) {
            self
        }
    }

    /// 应用玻璃卡片样式
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        GradientCard(style: .glass, cornerRadius: cornerRadius) {
            self
        }
    }

    /// 应用全息卡片样式
    func holographicCard(cornerRadius: CGFloat = 16) -> some View {
        GradientCard(style: .holographic, cornerRadius: cornerRadius) {
            self
        }
    }

    /// 应用3D深度卡片样式
    func depth3DCard(
        borderColors: [Color] = [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
        cornerRadius: CGFloat = 16
    ) -> some View {
        GradientCard(style: .depth3D, borderColors: borderColors, cornerRadius: cornerRadius) {
            self
        }
    }
}

// MARK: - 预览
#Preview("Neon Card") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        GradientCard(style: .neon) {
            VStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "FFD700"))
                Text("25°C")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text("晴朗")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(30)
        }
    }
}

#Preview("Glass Card") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "7B2FFF"), Color(hex: "00D4FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GradientCard(style: .glass) {
            VStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "00D4FF"))
                Text("65%")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text("湿度")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(30)
        }
    }
}

#Preview("Holographic Card") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        GradientCard(style: .holographic) {
            VStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF00FF"), Color(hex: "00D4FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("全息效果")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .padding(30)
        }
    }
}

#Preview("3D Depth Card") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        GradientCard(style: .depth3D) {
            VStack {
                Image(systemName: "wind")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "00D4FF"))
                Text("12 km/h")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text("东南风")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(30)
        }
    }
}
