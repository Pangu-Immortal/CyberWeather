//
//  SunnyAnimation.swift
//  CyberWeather
//
//  晴天动画增强版
//  包含太阳、光芒旋转、漂浮光斑、热浪效果、镜头光晕
//  霓虹发光风格 + 赛博朋克美学 + 多彩绚丽效果
//

import SwiftUI

// MARK: - 漂浮光斑数据
struct FloatingLightSpot: Identifiable {
    let id: Int
    let baseX: CGFloat                  // 基础X位置
    let baseY: CGFloat                  // 基础Y位置
    let size: CGFloat                   // 大小
    let color: Color                    // 颜色
    let floatSpeed: Double              // 漂浮速度
    let floatAmplitudeX: CGFloat        // X轴漂浮幅度
    let floatAmplitudeY: CGFloat        // Y轴漂浮幅度
    let phase: Double                   // 相位偏移
    let pulseSpeed: Double              // 脉冲速度
}

// MARK: - 晴天动画
struct SunnyAnimation: View {
    @State private var sunRotation: Double = 0      // 太阳旋转角度
    @State private var glowScale: CGFloat = 1.0     // 发光缩放
    @State private var rayOpacity: Double = 0.6     // 光芒透明度
    @State private var flareOffset: CGFloat = 0     // 光晕偏移
    @State private var ringPulse: CGFloat = 1.0     // 光环脉冲
    @State private var lightSpots: [FloatingLightSpot] = []  // 漂浮光斑
    @State private var heatWavePhase: Double = 0    // 热浪相位

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let sunSize = min(size.width, size.height) * 0.35  // 增大太阳尺寸
            let centerX = size.width * 0.65  // 稍微左移，更居中
            let centerY = size.height * 0.22  // 稍微上移

            ZStack {
                // 全屏背景光晕（确保可见）
                fullScreenGlow(size: size, centerX: centerX, centerY: centerY)

                // 热浪效果层（底部）
                heatWaveLayer(size: size)

                // 背景光晕层
                backgroundGlow(size: size, sunSize: sunSize, centerX: centerX, centerY: centerY)

                // 漂浮光斑层（背景）
                floatingLightSpotsLayer(size: size, sunSize: sunSize, centerX: centerX, centerY: centerY)

                // 镜头光晕效果
                lensFlare(size: size, sunSize: sunSize, centerX: centerX, centerY: centerY)

                // 彩虹光晕效果
                rainbowFlare(size: size, centerX: centerX, centerY: centerY)

                // 外层脉冲光环
                pulsingRings(sunSize: sunSize, centerX: centerX, centerY: centerY)

                // 外层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FFD700").opacity(0.5),   // 增强中心
                                Color(hex: "FF8C00").opacity(0.25),  // 增强橙色
                                Color(hex: "FF00FF").opacity(0.1),   // 霓虹粉
                                Color(hex: "7B2FFF").opacity(0.05),  // 霓虹紫
                                .clear
                            ],
                            center: .center,
                            startRadius: sunSize * 0.3,
                            endRadius: sunSize * 2.0
                        )
                    )
                    .frame(width: sunSize * 4, height: sunSize * 4)
                    .scaleEffect(glowScale)
                    .position(x: centerX, y: centerY)

                // 光芒射线 - 主层
                ForEach(0..<12, id: \.self) { index in
                    SunRay(length: sunSize * 0.9)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFD700").opacity(rayOpacity),
                                    Color(hex: "FF6B00").opacity(0.2),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .frame(width: sunSize * 0.1, height: sunSize * 0.9)
                        .rotationEffect(.degrees(Double(index) * 30 + sunRotation))
                        .position(x: centerX, y: centerY)
                }

                // 光芒射线 - 次层（更细更长）
                ForEach(0..<24, id: \.self) { index in
                    SunRay(length: sunSize * 1.2)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFFFFF").opacity(rayOpacity * 0.3),
                                    Color(hex: "FFD700").opacity(0.1),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .frame(width: sunSize * 0.05, height: sunSize * 1.2)
                        .rotationEffect(.degrees(Double(index) * 15 + sunRotation * 0.5))
                        .position(x: centerX, y: centerY)
                }

                // 霓虹光环
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: "00D4FF"),
                                Color(hex: "FF00FF"),
                                Color(hex: "FFD700"),
                                Color(hex: "00E400"),
                                Color(hex: "00D4FF")
                            ],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: sunSize * 1.2, height: sunSize * 1.2)
                    .blur(radius: 5)
                    .rotationEffect(.degrees(-sunRotation * 2))
                    .position(x: centerX, y: centerY)

                // 内层霓虹环
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: "FFFFFF").opacity(0.8),
                                Color(hex: "00D4FF").opacity(0.6),
                                Color(hex: "FFFFFF").opacity(0.8)
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: sunSize * 0.95, height: sunSize * 0.95)
                    .rotationEffect(.degrees(sunRotation * 3))
                    .position(x: centerX, y: centerY)

                // 太阳核心
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FFFFFF"),
                                Color(hex: "FFF8DC"),
                                Color(hex: "FFD700"),
                                Color(hex: "FF8C00")
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: sunSize * 0.5
                        )
                    )
                    .frame(width: sunSize, height: sunSize)
                    .shadow(color: Color(hex: "FFFFFF").opacity(0.9), radius: 20)  // 白色内发光
                    .shadow(color: Color(hex: "FFD700").opacity(0.95), radius: 40)  // 金色光晕
                    .shadow(color: Color(hex: "FF8C00").opacity(0.8), radius: 60)   // 橙色扩散
                    .shadow(color: Color(hex: "FF6B00").opacity(0.6), radius: 80)   // 深橙色外圈
                    .shadow(color: Color(hex: "FF00FF").opacity(0.3), radius: 100)  // 霓虹粉边缘
                    .position(x: centerX, y: centerY)

                // 核心高光
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0)
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: sunSize * 0.3
                        )
                    )
                    .frame(width: sunSize * 0.8, height: sunSize * 0.8)
                    .position(x: centerX, y: centerY)

                // 漂浮粒子 - 主层
                SunParticles(
                    centerX: centerX,
                    centerY: centerY,
                    radius: sunSize * 1.5,
                    particleCount: 25
                )

                // 漂浮粒子 - 远景层
                SunParticles(
                    centerX: centerX,
                    centerY: centerY,
                    radius: sunSize * 2.5,
                    particleCount: 15
                )
                .opacity(0.5)

                // 闪烁星星
                sparklingStars(size: size)

                // 多彩漂浮光斑（前景）
                floatingLightSpotsForeground(size: size)
            }
            .onAppear {
                // 生成漂浮光斑
                generateLightSpots(in: size, sunX: centerX, sunY: centerY)

                // 太阳缓慢旋转
                withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                    sunRotation = 360
                }
                // 发光呼吸效果
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    glowScale = 1.2
                }
                // 光芒闪烁
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    rayOpacity = 0.95
                }
                // 光晕移动
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    flareOffset = 30
                }
                // 光环脉冲
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    ringPulse = 1.15
                }
                // 热浪动画
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    heatWavePhase = .pi * 2
                }
            }
            .drawingGroup() // 性能优化
        }
    }

    // MARK: - 全屏背景光晕（确保动画可见）
    private func fullScreenGlow(size: CGSize, centerX: CGFloat, centerY: CGFloat) -> some View {
        ZStack {
            // 大范围暖色光晕覆盖整个屏幕
            RadialGradient(
                colors: [
                    Color(hex: "FFD700").opacity(0.25),  // 金色中心
                    Color(hex: "FF8C00").opacity(0.15),  // 橙色过渡
                    Color(hex: "FF6B00").opacity(0.08),  // 深橙色
                    Color(hex: "7B2FFF").opacity(0.05),  // 紫色边缘
                    .clear
                ],
                center: UnitPoint(x: centerX / size.width, y: centerY / size.height),
                startRadius: 50,
                endRadius: max(size.width, size.height) * 0.9
            )

            // 次级光晕 - 增加层次感
            RadialGradient(
                colors: [
                    Color(hex: "FFFFFF").opacity(0.12),
                    Color(hex: "FFD700").opacity(0.08),
                    .clear
                ],
                center: UnitPoint(x: centerX / size.width, y: centerY / size.height),
                startRadius: 30,
                endRadius: size.width * 0.5
            )

            // 底部暖色渐变（地面反光效果）
            LinearGradient(
                colors: [
                    .clear,
                    Color(hex: "FF8C00").opacity(0.06),
                    Color(hex: "FFD700").opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .mask(
                LinearGradient(
                    colors: [.clear, .white],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
        }
    }

    // MARK: - 热浪效果层
    private func heatWaveLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 热浪区域（底部1/3）
                let startY = canvasSize.height * 0.65

                // 绘制多层热浪波纹
                for layer in 0..<5 {
                    let layerOffset = CGFloat(layer) * 0.15
                    let speed = 0.8 + Double(layer) * 0.2
                    let amplitude = 8.0 - Double(layer) * 1.0

                    var path = Path()
                    let y = startY + CGFloat(layer) * 25

                    for x in stride(from: CGFloat(0), through: canvasSize.width, by: 4) {
                        let wave1 = sin((Double(x) / 80 + time * speed + Double(layerOffset) * 3)) * amplitude
                        let wave2 = sin((Double(x) / 50 + time * speed * 1.3 + Double(layerOffset) * 2)) * amplitude * 0.5
                        let waveY = y + CGFloat(wave1 + wave2)

                        if x == 0 {
                            path.move(to: CGPoint(x: x, y: waveY))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: waveY))
                        }
                    }

                    path.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
                    path.addLine(to: CGPoint(x: 0, y: canvasSize.height))
                    path.closeSubpath()

                    // 热浪渐变（暖色调）
                    let opacity = 0.08 - Double(layer) * 0.012
                    let colors: [Color] = [
                        Color(hex: "FF8C00").opacity(opacity),
                        Color(hex: "FFD700").opacity(opacity * 0.7),
                        Color(hex: "FF6B00").opacity(opacity * 0.5),
                        .clear
                    ]

                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: colors),
                            startPoint: CGPoint(x: canvasSize.width / 2, y: y),
                            endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height)
                        )
                    )
                }

                // 热浪扭曲线条
                for i in 0..<8 {
                    let baseY = startY + CGFloat(i) * 20 + 10
                    var linePath = Path()

                    for x in stride(from: CGFloat(0), through: canvasSize.width, by: 3) {
                        let wave = sin((Double(x) / 60 + time * 1.2 + Double(i) * 0.5)) * 6
                        let y = baseY + CGFloat(wave)

                        if x == 0 {
                            linePath.move(to: CGPoint(x: x, y: y))
                        } else {
                            linePath.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    let lineOpacity = 0.15 - Double(i) * 0.015
                    context.stroke(
                        linePath,
                        with: .color(Color(hex: "FFD700").opacity(lineOpacity)),
                        lineWidth: 1
                    )
                }
            }
        }
    }

    // MARK: - 生成漂浮光斑
    private func generateLightSpots(in size: CGSize, sunX: CGFloat, sunY: CGFloat) {
        let colors: [Color] = [
            Color(hex: "FFD700"),   // 金色
            Color(hex: "FF8C00"),   // 橙色
            Color(hex: "00D4FF"),   // 霓虹蓝
            Color(hex: "FF00FF"),   // 霓虹粉
            Color(hex: "7B2FFF"),   // 霓虹紫
            Color(hex: "00E400"),   // 霓虹绿
            Color.white             // 白色
        ]

        lightSpots = (0..<35).map { index in
            // 分布在太阳周围和整个画面
            let isSunArea = index < 15
            let baseX: CGFloat
            let baseY: CGFloat

            if isSunArea {
                // 太阳周围区域
                let angle = Double.random(in: 0...(.pi * 2))
                let distance = CGFloat.random(in: 50...200)
                baseX = sunX + cos(angle) * distance
                baseY = sunY + sin(angle) * distance
            } else {
                // 整个画面随机分布
                baseX = CGFloat.random(in: 0...size.width)
                baseY = CGFloat.random(in: 0...size.height * 0.7)
            }

            return FloatingLightSpot(
                id: index,
                baseX: baseX,
                baseY: baseY,
                size: CGFloat.random(in: 4...15),
                color: colors.randomElement()!,
                floatSpeed: Double.random(in: 0.3...1.2),
                floatAmplitudeX: CGFloat.random(in: 20...60),
                floatAmplitudeY: CGFloat.random(in: 15...40),
                phase: Double.random(in: 0...(.pi * 2)),
                pulseSpeed: Double.random(in: 1.5...4.0)
            )
        }
    }

    // MARK: - 漂浮光斑层（背景）
    private func floatingLightSpotsLayer(size: CGSize, sunSize: CGFloat, centerX: CGFloat, centerY: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                for spot in lightSpots.prefix(20) {
                    drawFloatingSpot(context: context, spot: spot, time: time, canvasSize: canvasSize, isForeground: false)
                }
            }
        }
    }

    // MARK: - 漂浮光斑前景层
    private func floatingLightSpotsForeground(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                for spot in lightSpots.suffix(15) {
                    drawFloatingSpot(context: context, spot: spot, time: time, canvasSize: canvasSize, isForeground: true)
                }
            }
        }
    }

    // MARK: - 绘制单个漂浮光斑
    private func drawFloatingSpot(context: GraphicsContext, spot: FloatingLightSpot, time: TimeInterval, canvasSize: CGSize, isForeground: Bool) {
        // 计算当前位置（漂浮效果）
        let floatX = sin(time * spot.floatSpeed + spot.phase) * spot.floatAmplitudeX
        let floatY = cos(time * spot.floatSpeed * 0.8 + spot.phase) * spot.floatAmplitudeY

        let currentX = spot.baseX + floatX
        let currentY = spot.baseY + floatY

        // 确保在画布内
        guard currentX > -spot.size && currentX < canvasSize.width + spot.size &&
              currentY > -spot.size && currentY < canvasSize.height + spot.size else {
            return
        }

        // 脉冲效果
        let pulse = sin(time * spot.pulseSpeed + spot.phase) * 0.3 + 0.7
        let currentSize = spot.size * CGFloat(pulse) * 1.3  // 增大光斑尺寸
        let opacity = isForeground ? 0.85 * pulse : 0.55 * pulse  // 提高透明度

        // 外发光
        let glowSize = currentSize * 5  // 增大发光范围
        let glowRect = CGRect(
            x: currentX - glowSize / 2,
            y: currentY - glowSize / 2,
            width: glowSize,
            height: glowSize
        )

        context.fill(
            Circle().path(in: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    spot.color.opacity(opacity * 0.6),
                    spot.color.opacity(opacity * 0.3),
                    spot.color.opacity(opacity * 0.1),
                    .clear
                ]),
                center: CGPoint(x: currentX, y: currentY),
                startRadius: 0,
                endRadius: glowSize / 2
            )
        )

        // 主体光斑
        let mainRect = CGRect(
            x: currentX - currentSize / 2,
            y: currentY - currentSize / 2,
            width: currentSize,
            height: currentSize
        )

        context.fill(
            Circle().path(in: mainRect),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(opacity),
                    spot.color.opacity(opacity * 0.9),
                    spot.color.opacity(opacity * 0.5)
                ]),
                center: CGPoint(x: currentX, y: currentY),
                startRadius: 0,
                endRadius: currentSize / 2
            )
        )

        // 十字光芒（较大的光斑）
        if currentSize > 8 && isForeground {
            let rayLength = currentSize * 2.5  // 增长光芒
            var hPath = Path()
            hPath.move(to: CGPoint(x: currentX - rayLength, y: currentY))
            hPath.addLine(to: CGPoint(x: currentX + rayLength, y: currentY))

            var vPath = Path()
            vPath.move(to: CGPoint(x: currentX, y: currentY - rayLength))
            vPath.addLine(to: CGPoint(x: currentX, y: currentY + rayLength))

            context.stroke(hPath, with: .color(spot.color.opacity(opacity * 0.5)), lineWidth: 1.5)
            context.stroke(vPath, with: .color(spot.color.opacity(opacity * 0.5)), lineWidth: 1.5)
        }
    }

    // MARK: - 彩虹光晕效果
    private func rainbowFlare(size: CGSize, centerX: CGFloat, centerY: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 彩虹光环（围绕太阳）
                let rainbowColors: [Color] = [
                    Color(hex: "FF0000").opacity(0.15),  // 红
                    Color(hex: "FF8C00").opacity(0.12),  // 橙
                    Color(hex: "FFD700").opacity(0.12),  // 黄
                    Color(hex: "00E400").opacity(0.10),  // 绿
                    Color(hex: "00D4FF").opacity(0.10),  // 青
                    Color(hex: "7B2FFF").opacity(0.10),  // 紫
                ]

                let baseRadius: CGFloat = 180
                let shimmer = sin(time * 0.5) * 0.2 + 0.8

                for (index, color) in rainbowColors.enumerated() {
                    let radius = baseRadius + CGFloat(index) * 12
                    let arcStart = Angle.degrees(time * 20 + Double(index) * 15)
                    let arcEnd = arcStart + .degrees(90 + Double(index) * 10)

                    var path = Path()
                    path.addArc(
                        center: CGPoint(x: centerX, y: centerY),
                        radius: radius,
                        startAngle: arcStart,
                        endAngle: arcEnd,
                        clockwise: false
                    )

                    context.stroke(
                        path,
                        with: .color(color.opacity(Double(shimmer))),
                        lineWidth: 8
                    )
                }
            }
        }
    }

    // MARK: - 背景光晕层
    private func backgroundGlow(size: CGSize, sunSize: CGFloat, centerX: CGFloat, centerY: CGFloat) -> some View {
        ZStack {
            // 大范围柔和光晕
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(0.3),   // 增强金色
                            Color(hex: "FF8C00").opacity(0.18),  // 增强橙色
                            Color(hex: "FF6B00").opacity(0.08),  // 深橙边缘
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.7
                    )
                )
                .frame(width: size.width * 1.2, height: size.height * 0.9)
                .position(x: centerX, y: centerY)

            // 额外的光芒扩散层
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFFFFF").opacity(0.15),
                            Color(hex: "FFD700").opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: sunSize * 2
                    )
                )
                .frame(width: sunSize * 4, height: sunSize * 3)
                .position(x: centerX, y: centerY)
        }
    }

    // MARK: - 镜头光晕
    private func lensFlare(size: CGSize, sunSize: CGFloat, centerX: CGFloat, centerY: CGFloat) -> some View {
        let flareDirection = CGPoint(
            x: size.width / 2 - centerX,
            y: size.height / 2 - centerY
        )

        return ZStack {
            ForEach(0..<5, id: \.self) { i in
                let offset = CGFloat(i + 1) * 0.2
                let flareSize = sunSize * (0.15 - CGFloat(i) * 0.02)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                [Color(hex: "00D4FF"), Color(hex: "FF00FF"), Color(hex: "FFD700"), Color(hex: "00E400"), Color(hex: "7B2FFF")][i].opacity(0.4),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: flareSize
                        )
                    )
                    .frame(width: flareSize * 2, height: flareSize * 2)
                    .position(
                        x: centerX + flareDirection.x * offset + flareOffset * offset,
                        y: centerY + flareDirection.y * offset + flareOffset * offset * 0.5
                    )
            }
        }
    }

    // MARK: - 脉冲光环
    private func pulsingRings(sunSize: CGFloat, centerX: CGFloat, centerY: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        Color(hex: "FFD700").opacity(0.3 - Double(i) * 0.08),
                        lineWidth: 2 - CGFloat(i) * 0.5
                    )
                    .frame(
                        width: sunSize * (1.4 + CGFloat(i) * 0.3) * ringPulse,
                        height: sunSize * (1.4 + CGFloat(i) * 0.3) * ringPulse
                    )
                    .position(x: centerX, y: centerY)
            }
        }
    }

    // MARK: - 闪烁星星
    private func sparklingStars(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 在画面中随机位置绘制闪烁的小星星
                for i in 0..<25 {  // 增加星星数量
                    let seed = Double(i) * 1234.5678
                    let x = (sin(seed) + 1) / 2 * canvasSize.width
                    let y = (cos(seed * 0.7) + 1) / 2 * canvasSize.height * 0.7

                    // 闪烁效果
                    let twinkle = sin(time * (2.0 + Double(i) * 0.3) + seed) * 0.5 + 0.5
                    let starSize = CGFloat(3 + twinkle * 5)  // 增大星星尺寸

                    // 星星颜色（混合多种颜色）
                    let colors: [Color] = [.white, Color(hex: "FFD700"), Color(hex: "00D4FF"), Color(hex: "FF00FF")]
                    let starColor = colors[i % colors.count]

                    // 绘制星星发光
                    let glowRect = CGRect(x: x - starSize * 2, y: y - starSize * 2, width: starSize * 4, height: starSize * 4)
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .radialGradient(
                            Gradient(colors: [
                                starColor.opacity(twinkle * 0.4),
                                .clear
                            ]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: starSize * 2
                        )
                    )

                    // 绘制星星（十字形）
                    var path = Path()
                    path.move(to: CGPoint(x: x - starSize, y: y))
                    path.addLine(to: CGPoint(x: x + starSize, y: y))
                    path.move(to: CGPoint(x: x, y: y - starSize))
                    path.addLine(to: CGPoint(x: x, y: y + starSize))

                    context.stroke(
                        path,
                        with: .color(starColor.opacity(twinkle * 0.8)),
                        lineWidth: 1.5
                    )

                    // 中心发光点
                    let rect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color.white.opacity(twinkle * 0.9))
                    )
                }
            }
        }
    }
}

// MARK: - 太阳光芒形状
struct SunRay: Shape {
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let centerY = rect.midY

        path.move(to: CGPoint(x: centerX, y: centerY - length * 0.5))
        path.addLine(to: CGPoint(x: centerX, y: centerY - length))

        return path
    }
}

// MARK: - 太阳粒子效果
struct SunParticles: View {
    let centerX: CGFloat
    let centerY: CGFloat
    let radius: CGFloat
    var particleCount: Int = 20                                 // 粒子数量

    @State private var particles: [SunParticle] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let progress = (time - particle.startTime).truncatingRemainder(dividingBy: particle.duration) / particle.duration
                    let currentRadius = radius * (0.5 + progress * 0.5)
                    let angle = particle.angle + progress * 0.5

                    let x = centerX + cos(angle) * currentRadius
                    let y = centerY + sin(angle) * currentRadius
                    let alpha = 1.0 - progress
                    let particleSize = particle.size * (1.0 - progress * 0.5)

                    let rect = CGRect(
                        x: x - particleSize / 2,
                        y: y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )

                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color.opacity(alpha * 0.6))
                    )
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            SunParticle(
                angle: Double.random(in: 0...Double.pi * 2),
                size: CGFloat.random(in: 3...8),
                color: [Color(hex: "FFD700"), Color(hex: "FF8C00"), Color(hex: "00D4FF")].randomElement()!,
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...3),
                duration: Double.random(in: 3...6)
            )
        }
    }
}

struct SunParticle {
    let angle: Double
    let size: CGFloat
    let color: Color
    let startTime: TimeInterval
    let duration: Double
}

// MARK: - 预览
#Preview {
    ZStack {
        Color(hex: "0a0a1a")
        SunnyAnimation()
    }
    .ignoresSafeArea()
}
