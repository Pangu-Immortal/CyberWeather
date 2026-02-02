//
//  AnimatedGradient.swift
//  CyberWeather
//
//  动画渐变背景组件
//  提供流动、脉冲、极光等多种渐变动画效果
//  增强赛博朋克视觉体验
//

import SwiftUI

// MARK: - 动画渐变类型
enum AnimatedGradientType {
    case flowing         // 流动渐变
    case pulsing         // 脉冲渐变
    case aurora          // 极光效果
    case mesh            // 网格渐变
    case radialPulse     // 径向脉冲
}

// MARK: - 动画渐变视图
struct AnimatedGradient: View {
    let type: AnimatedGradientType                      // 渐变类型
    let colors: [Color]                                 // 渐变颜色
    let speed: Double                                   // 动画速度（1.0为正常）

    @State private var animationPhase: CGFloat = 0     // 动画相位
    @State private var rotationAngle: Double = 0       // 旋转角度
    @State private var scale: CGFloat = 1.0            // 缩放

    init(
        type: AnimatedGradientType = .flowing,
        colors: [Color] = [Color(hex: "00D4FF"), Color(hex: "7B2FFF"), Color(hex: "FF00FF")],
        speed: Double = 1.0
    ) {
        self.type = type
        self.colors = colors
        self.speed = speed
    }

    var body: some View {
        GeometryReader { geometry in
            switch type {
            case .flowing:
                flowingGradient(size: geometry.size)
            case .pulsing:
                pulsingGradient(size: geometry.size)
            case .aurora:
                auroraGradient(size: geometry.size)
            case .mesh:
                meshGradient(size: geometry.size)
            case .radialPulse:
                radialPulseGradient(size: geometry.size)
            }
        }
        .drawingGroup()
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - 流动渐变
    private func flowingGradient(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let centerX = canvasSize.width / 2 + cos(animationPhase * 2) * 100
            let centerY = canvasSize.height / 2 + sin(animationPhase * 3) * 50

            // 多层渐变叠加
            for i in 0..<3 {
                let offset = CGFloat(i) * 0.3
                let gradient = Gradient(colors: colors.map { $0.opacity(0.4 - Double(i) * 0.1) })
                let startPoint = CGPoint(
                    x: centerX + cos(animationPhase + offset) * 150,
                    y: centerY + sin(animationPhase + offset) * 100
                )
                let endPoint = CGPoint(
                    x: centerX + cos(animationPhase + .pi + offset) * 150,
                    y: centerY + sin(animationPhase + .pi + offset) * 100
                )

                context.fill(
                    Path(CGRect(origin: .zero, size: canvasSize)),
                    with: .linearGradient(
                        gradient,
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
            }
        }
    }

    // MARK: - 脉冲渐变
    private func pulsingGradient(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colors[i % colors.count].opacity(0.6),
                                colors[i % colors.count].opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.6
                        )
                    )
                    .scaleEffect(scale + CGFloat(i) * 0.2)
                    .offset(
                        x: cos(animationPhase + Double(i) * .pi / 1.5) * 50,
                        y: sin(animationPhase + Double(i) * .pi / 1.5) * 30
                    )
            }
        }
    }

    // MARK: - 极光效果
    private func auroraGradient(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let waveCount = 5
            let waveHeight = canvasSize.height * 0.3

            for wave in 0..<waveCount {
                let waveOffset = CGFloat(wave) / CGFloat(waveCount)
                let colorIndex = wave % colors.count
                var path = Path()

                path.move(to: CGPoint(x: 0, y: canvasSize.height))

                // 创建波浪形状
                for x in stride(from: 0, through: canvasSize.width, by: 5) {
                    let progress = x / canvasSize.width
                    let baseY = canvasSize.height * (0.4 + waveOffset * 0.15)
                    let wave1 = sin((progress + animationPhase + waveOffset) * .pi * 2) * waveHeight * 0.3
                    let wave2 = sin((progress + animationPhase * 1.5 + waveOffset) * .pi * 3) * waveHeight * 0.2
                    let wave3 = sin((progress + animationPhase * 0.7 + waveOffset) * .pi * 4) * waveHeight * 0.1
                    let y = baseY + wave1 + wave2 + wave3

                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
                path.closeSubpath()

                // 渐变填充
                let gradient = Gradient(colors: [
                    colors[colorIndex].opacity(0.4 - Double(wave) * 0.06),
                    colors[colorIndex].opacity(0.1)
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: canvasSize.width / 2, y: 0),
                        endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height)
                    )
                )
            }
        }
    }

    // MARK: - 网格渐变
    private func meshGradient(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let gridSize: CGFloat = 60
            let cols = Int(canvasSize.width / gridSize) + 2
            let rows = Int(canvasSize.height / gridSize) + 2

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * gridSize + sin(animationPhase + Double(row) * 0.3) * 10
                    let y = CGFloat(row) * gridSize + cos(animationPhase + Double(col) * 0.3) * 10

                    let colorIndex = (row + col) % colors.count
                    let pulse = sin(animationPhase * 2 + Double(row + col) * 0.5) * 0.3 + 0.5

                    // 绘制发光点
                    let gradient = Gradient(colors: [
                        colors[colorIndex].opacity(pulse * 0.8),
                        colors[colorIndex].opacity(0)
                    ])

                    let center = CGPoint(x: x, y: y)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: x - 20,
                            y: y - 20,
                            width: 40,
                            height: 40
                        )),
                        with: .radialGradient(
                            gradient,
                            center: center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                }
            }
        }
    }

    // MARK: - 径向脉冲
    private func radialPulseGradient(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let maxRadius = sqrt(pow(canvasSize.width, 2) + pow(canvasSize.height, 2)) / 2

            // 多个同心圆脉冲
            for ring in 0..<5 {
                let baseRadius = maxRadius * (CGFloat(ring) + animationPhase.truncatingRemainder(dividingBy: 1)) / 5
                let colorIndex = ring % colors.count

                let innerRadius = max(0, baseRadius - 30)
                let outerRadius = baseRadius + 30

                let gradient = Gradient(colors: [
                    colors[colorIndex].opacity(0),
                    colors[colorIndex].opacity(0.4),
                    colors[colorIndex].opacity(0)
                ])

                var path = Path()
                path.addArc(center: center, radius: outerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                path.addArc(center: center, radius: innerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
                path.closeSubpath()

                context.fill(
                    path,
                    with: .radialGradient(
                        gradient,
                        center: center,
                        startRadius: innerRadius,
                        endRadius: outerRadius
                    )
                )
            }
        }
    }

    // MARK: - 启动动画
    private func startAnimations() {
        let duration = 4.0 / speed

        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }

        withAnimation(.easeInOut(duration: 2.0 / speed).repeatForever(autoreverses: true)) {
            scale = 1.3
        }

        withAnimation(.linear(duration: 20.0 / speed).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// MARK: - 预设渐变
extension AnimatedGradient {
    /// 赛博朋克霓虹渐变
    static var cyberNeon: AnimatedGradient {
        AnimatedGradient(
            type: .flowing,
            colors: [Color(hex: "00D4FF"), Color(hex: "7B2FFF"), Color(hex: "FF00FF")],
            speed: 1.0
        )
    }

    /// 日出渐变
    static var sunrise: AnimatedGradient {
        AnimatedGradient(
            type: .aurora,
            colors: [Color(hex: "FF6B00"), Color(hex: "FFD700"), Color(hex: "FF00FF")],
            speed: 0.8
        )
    }

    /// 深海渐变
    static var deepSea: AnimatedGradient {
        AnimatedGradient(
            type: .pulsing,
            colors: [Color(hex: "0066FF"), Color(hex: "00D4FF"), Color(hex: "00E400")],
            speed: 0.6
        )
    }

    /// 数字矩阵渐变
    static var matrix: AnimatedGradient {
        AnimatedGradient(
            type: .mesh,
            colors: [Color(hex: "00E400"), Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
            speed: 1.2
        )
    }
}

// MARK: - 预览
#Preview("Flowing") {
    AnimatedGradient(type: .flowing)
        .ignoresSafeArea()
}

#Preview("Aurora") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        AnimatedGradient(type: .aurora)
    }
}

#Preview("Mesh") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        AnimatedGradient(type: .mesh)
    }
}

#Preview("Radial Pulse") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        AnimatedGradient(type: .radialPulse)
    }
}
