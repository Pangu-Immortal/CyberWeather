//
//  RainyAnimation.swift
//  CyberWeather
//
//  雨天动画增强版
//  包含雨滴下落、涟漪效果、水花溅射、雾气层、闪电、风向影响
//  赛博朋克霓虹风格 - 多彩绚丽效果
//

import SwiftUI

// MARK: - 降雨强度
enum RainIntensity {
    case light      // 小雨
    case moderate   // 中雨
    case heavy      // 大雨

    var dropCount: Int {
        switch self {
        case .light: return 80
        case .moderate: return 160
        case .heavy: return 300
        }
    }

    var dropSpeed: ClosedRange<CGFloat> {
        switch self {
        case .light: return 350...550
        case .moderate: return 550...900
        case .heavy: return 900...1400
        }
    }

    var rippleCount: Int {
        switch self {
        case .light: return 12
        case .moderate: return 25
        case .heavy: return 45
        }
    }

    var splashCount: Int {
        switch self {
        case .light: return 15
        case .moderate: return 30
        case .heavy: return 60
        }
    }

    var mistOpacity: Double {
        switch self {
        case .light: return 0.12
        case .moderate: return 0.25
        case .heavy: return 0.4
        }
    }

    var windStrength: CGFloat {
        switch self {
        case .light: return 0.05
        case .moderate: return 0.12
        case .heavy: return 0.25
        }
    }

    var hasLightning: Bool {
        switch self {
        case .light: return false
        case .moderate: return true
        case .heavy: return true
        }
    }
}

// MARK: - 雨天动画
struct RainyAnimation: View {
    let intensity: RainIntensity                                // 降雨强度

    @State private var drops: [RainDrop] = []                   // 雨滴
    @State private var backgroundDrops: [RainDrop] = []         // 背景雨滴（远景）
    @State private var midgroundDrops: [RainDrop] = []          // 中景雨滴
    @State private var ripples: [Ripple] = []                   // 涟漪
    @State private var splashes: [Splash] = []                  // 水花
    @State private var lightningFlash: Double = 0               // 闪电闪烁
    @State private var windOffset: CGFloat = 0                  // 风向偏移

    init(intensity: RainIntensity = .moderate) {
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // 0. 闪电背景闪烁
                if intensity.hasLightning {
                    lightningBackground()
                }

                // 1. 流动雾气层
                flowingMistLayer(size: size)

                // 2. 霓虹光斑层
                neonLightSpots(size: size)

                // 3. 雨滴和效果
                rainCanvas(size: size)

                // 4. 电子雨效果（Matrix风格）
                if intensity == .heavy {
                    matrixRainEffect(size: size)
                }

                // 5. 顶部霓虹光晕
                topNeonGlow(size: size)

                // 6. 底部水面反光
                bottomReflection(size: size)

                // 7. 闪电光柱
                if intensity.hasLightning {
                    lightningBolts(size: size)
                }
            }
            .onAppear {
                generateDrops(in: size)
                generateBackgroundDrops(in: size)
                generateMidgroundDrops(in: size)
                generateRipples(in: size)
                generateSplashes(in: size)
                startAnimations()
            }
        }
        .drawingGroup()
    }

    // MARK: - 雨滴画布
    private func rainCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 1. 绘制远景雨滴
                for drop in backgroundDrops {
                    drawBackgroundDrop(context: context, drop: drop, time: time, canvasSize: canvasSize)
                }

                // 2. 绘制中景雨滴
                for drop in midgroundDrops {
                    drawMidgroundDrop(context: context, drop: drop, time: time, canvasSize: canvasSize)
                }

                // 3. 绘制涟漪
                for ripple in ripples {
                    drawRipple(context: context, ripple: ripple, time: time, canvasSize: canvasSize)
                }

                // 4. 绘制水花
                for splash in splashes {
                    drawSplash(context: context, splash: splash, time: time, canvasSize: canvasSize)
                }

                // 5. 绘制前景雨滴
                for drop in drops {
                    drawRainDrop(context: context, drop: drop, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 闪电背景
    private func lightningBackground() -> some View {
        Color.white
            .opacity(lightningFlash)
            .animation(.easeOut(duration: 0.1), value: lightningFlash)
    }

    // MARK: - 闪电光柱
    private func lightningBolts(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 随机触发闪电
                let shouldFlash = sin(time * 0.5) > 0.95 || sin(time * 0.3 + 1) > 0.97

                if shouldFlash {
                    // 闪电主干
                    let startX = canvasSize.width * CGFloat.random(in: 0.2...0.8)
                    var path = Path()
                    path.move(to: CGPoint(x: startX, y: 0))

                    var currentX = startX
                    var currentY: CGFloat = 0
                    let segments = Int.random(in: 5...10)

                    for _ in 0..<segments {
                        currentX += CGFloat.random(in: -40...40)
                        currentY += canvasSize.height / CGFloat(segments) * CGFloat.random(in: 0.8...1.2)
                        path.addLine(to: CGPoint(x: currentX, y: currentY))

                        // 分叉
                        if Bool.random() && currentY < canvasSize.height * 0.7 {
                            var branchPath = Path()
                            branchPath.move(to: CGPoint(x: currentX, y: currentY))
                            let branchX = currentX + CGFloat.random(in: -60...60)
                            let branchY = currentY + CGFloat.random(in: 50...100)
                            branchPath.addLine(to: CGPoint(x: branchX, y: branchY))

                            context.stroke(
                                branchPath,
                                with: .color(Color(hex: "00D4FF").opacity(0.6)),
                                lineWidth: 2
                            )
                        }
                    }

                    // 外发光
                    context.stroke(path, with: .color(Color(hex: "7B2FFF").opacity(0.4)), lineWidth: 12)
                    context.stroke(path, with: .color(Color(hex: "00D4FF").opacity(0.6)), lineWidth: 6)
                    context.stroke(path, with: .color(Color.white.opacity(0.9)), lineWidth: 2)

                    // 触发背景闪烁
                    DispatchQueue.main.async {
                        lightningFlash = 0.3
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            lightningFlash = 0
                        }
                    }
                }
            }
        }
    }

    // MARK: - 流动雾气层
    private func flowingMistLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 多层流动雾气
                for layer in 0..<4 {
                    let layerOffset = CGFloat(layer) * 0.25
                    let speed = 0.2 + Double(layer) * 0.15
                    let flowX = sin(time * speed + Double(layerOffset) * 3) * 100

                    let mistPath = Path { path in
                        path.move(to: CGPoint(x: -50 + flowX, y: canvasSize.height * (0.3 + layerOffset * 0.2)))
                        path.addQuadCurve(
                            to: CGPoint(x: canvasSize.width + 50 + flowX, y: canvasSize.height * (0.4 + layerOffset * 0.15)),
                            control: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * (0.2 + layerOffset * 0.3))
                        )
                        path.addLine(to: CGPoint(x: canvasSize.width + 50, y: canvasSize.height))
                        path.addLine(to: CGPoint(x: -50, y: canvasSize.height))
                        path.closeSubpath()
                    }

                    let colors: [Color] = [
                        Color(hex: "00D4FF"),
                        Color(hex: "7B2FFF"),
                        Color(hex: "FF00FF"),
                        Color(hex: "00E400")
                    ]

                    let opacity = intensity.mistOpacity * (0.4 - Double(layer) * 0.08)

                    context.fill(
                        mistPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                colors[layer % colors.count].opacity(opacity),
                                colors[(layer + 1) % colors.count].opacity(opacity * 0.5),
                                .clear
                            ]),
                            startPoint: CGPoint(x: canvasSize.width * 0.5, y: 0),
                            endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height)
                        )
                    )
                }
            }
        }
    }

    // MARK: - 霓虹光斑层
    private func neonLightSpots(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let spots: [(CGFloat, CGFloat, CGFloat, Color)] = [
                    (0.1, 0.3, 100, Color(hex: "00D4FF")),
                    (0.9, 0.2, 80, Color(hex: "FF00FF")),
                    (0.3, 0.7, 120, Color(hex: "7B2FFF")),
                    (0.7, 0.8, 90, Color(hex: "00E400")),
                    (0.5, 0.4, 70, Color(hex: "FFD700")),
                ]

                for (xRatio, yRatio, baseSize, color) in spots {
                    let pulse = sin(time * 0.5 + Double(xRatio + yRatio) * 5) * 0.3 + 0.7
                    let spotSize = baseSize * CGFloat(pulse)
                    let x = canvasSize.width * xRatio
                    let y = canvasSize.height * yRatio

                    let rect = CGRect(
                        x: x - spotSize,
                        y: y - spotSize,
                        width: spotSize * 2,
                        height: spotSize * 2
                    )

                    context.fill(
                        Circle().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                color.opacity(0.08 * pulse),
                                color.opacity(0.03 * pulse),
                                .clear
                            ]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: spotSize
                        )
                    )
                }
            }
        }
    }

    // MARK: - 电子雨效果 (Matrix风格)
    private func matrixRainEffect(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let columnCount = 15
                let columnWidth = canvasSize.width / CGFloat(columnCount)

                for col in 0..<columnCount {
                    let x = CGFloat(col) * columnWidth + columnWidth / 2
                    let speed = 150 + Double(col % 5) * 50
                    let offset = Double(col) * 0.5

                    let yOffset = (time * speed + offset * 100).truncatingRemainder(dividingBy: Double(canvasSize.height) + 200)

                    // 绘制数字/符号串
                    for i in 0..<8 {
                        let y = CGFloat(yOffset) - CGFloat(i) * 25
                        if y > -25 && y < canvasSize.height + 25 {
                            let fade = 1.0 - Double(i) * 0.12
                            let charRect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)

                            // 发光效果
                            context.fill(
                                RoundedRectangle(cornerRadius: 2).path(in: charRect.insetBy(dx: -3, dy: -3)),
                                with: .color(Color(hex: "00E400").opacity(0.15 * fade))
                            )

                            context.fill(
                                RoundedRectangle(cornerRadius: 1).path(in: charRect),
                                with: .color(Color(hex: "00E400").opacity(0.6 * fade))
                            )

                            // 头部更亮
                            if i == 0 {
                                context.fill(
                                    Circle().path(in: charRect),
                                    with: .color(Color.white.opacity(0.9))
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 顶部霓虹光晕
    private func topNeonGlow(size: CGSize) -> some View {
        LinearGradient(
            colors: [
                Color(hex: "7B2FFF").opacity(0.2),
                Color(hex: "00D4FF").opacity(0.1),
                Color(hex: "FF00FF").opacity(0.05),
                .clear
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.45)
        )
        .allowsHitTesting(false)
    }

    // MARK: - 底部水面反光
    private func bottomReflection(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 波纹状水面反光
                for wave in 0..<5 {
                    let waveY = canvasSize.height * (0.85 + CGFloat(wave) * 0.03)
                    let waveOffset = sin(time * 0.8 + Double(wave) * 0.5) * 20

                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: waveY))

                    for x in stride(from: 0, through: canvasSize.width, by: 5) {
                        let y = waveY + sin(Double(x) * 0.02 + time * 1.5 + Double(wave)) * 3
                        path.addLine(to: CGPoint(x: x + CGFloat(waveOffset), y: y))
                    }

                    let colors: [Color] = [
                        Color(hex: "00D4FF"),
                        Color(hex: "7B2FFF"),
                        Color(hex: "FF00FF"),
                        Color(hex: "00E400"),
                        Color(hex: "FFD700")
                    ]

                    let opacity = 0.15 - Double(wave) * 0.025

                    context.stroke(
                        path,
                        with: .color(colors[wave % colors.count].opacity(opacity)),
                        lineWidth: 2
                    )
                }
            }
        }
    }

    // MARK: - 启动动画
    private func startAnimations() {
        // 风向摆动
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            windOffset = intensity.windStrength * 50
        }
    }

    // MARK: - 生成前景雨滴
    private func generateDrops(in size: CGSize) {
        let colors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "7B2FFF"),
            Color(hex: "FF00FF"),
            Color.white
        ]

        drops = (0..<intensity.dropCount).map { index in
            RainDrop(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -size.height...0),
                length: CGFloat.random(in: 25...50),
                speed: CGFloat.random(in: intensity.dropSpeed),
                opacity: Double.random(in: 0.6...0.95),
                thickness: CGFloat.random(in: 1.5...3.0),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...2),
                color: colors.randomElement()!,
                windInfluence: CGFloat.random(in: 0.8...1.2)
            )
        }
    }

    // MARK: - 生成背景雨滴（远景）
    private func generateBackgroundDrops(in size: CGSize) {
        backgroundDrops = (0..<intensity.dropCount / 2).map { index in
            RainDrop(
                id: index + 10000,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -size.height...0),
                length: CGFloat.random(in: 8...18),
                speed: CGFloat.random(in: 180...350),
                opacity: Double.random(in: 0.1...0.3),
                thickness: CGFloat.random(in: 0.5...1.0),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...2),
                color: Color(hex: "00D4FF"),
                windInfluence: CGFloat.random(in: 0.5...0.8)
            )
        }
    }

    // MARK: - 生成中景雨滴
    private func generateMidgroundDrops(in size: CGSize) {
        midgroundDrops = (0..<intensity.dropCount / 3).map { index in
            RainDrop(
                id: index + 20000,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -size.height...0),
                length: CGFloat.random(in: 15...30),
                speed: CGFloat.random(in: 300...500),
                opacity: Double.random(in: 0.3...0.5),
                thickness: CGFloat.random(in: 1.0...1.5),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...2),
                color: [Color(hex: "00D4FF"), Color(hex: "7B2FFF")].randomElement()!,
                windInfluence: CGFloat.random(in: 0.6...1.0)
            )
        }
    }

    // MARK: - 生成涟漪
    private func generateRipples(in size: CGSize) {
        let colors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "7B2FFF"),
            Color(hex: "FF00FF"),
            Color(hex: "00E400")
        ]

        ripples = (0..<intensity.rippleCount).map { index in
            Ripple(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: size.height * CGFloat.random(in: 0.75...0.98),
                maxRadius: CGFloat.random(in: 30...60),
                duration: Double.random(in: 1.0...2.5),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...3),
                neonColor: colors.randomElement()!
            )
        }
    }

    // MARK: - 生成水花
    private func generateSplashes(in size: CGSize) {
        splashes = (0..<intensity.splashCount).map { index in
            Splash(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: size.height * CGFloat.random(in: 0.8...0.98),
                particleCount: Int.random(in: 4...8),
                maxHeight: CGFloat.random(in: 10...25),
                duration: Double.random(in: 0.3...0.7),
                interval: Double.random(in: 0.4...1.8),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...2),
                color: [Color(hex: "00D4FF"), Color(hex: "7B2FFF"), Color(hex: "FF00FF"), Color.white].randomElement()!
            )
        }
    }

    // MARK: - 绘制背景雨滴
    private func drawBackgroundDrop(context: GraphicsContext, drop: RainDrop, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - drop.startTime
        if elapsed < 0 { return }

        let cycleTime = Double(canvasSize.height + drop.length) / Double(drop.speed)
        let progress = elapsed.truncatingRemainder(dividingBy: cycleTime)
        let currentY = drop.startY + CGFloat(progress) * drop.speed
        let windX = sin(time * 0.5) * intensity.windStrength * 30 * drop.windInfluence

        if currentY > canvasSize.height + drop.length { return }

        let startPoint = CGPoint(x: drop.x + windX, y: currentY - drop.length)
        let endPoint = CGPoint(x: drop.x + windX * 0.8, y: currentY)

        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)

        context.stroke(
            path,
            with: .color(drop.color.opacity(drop.opacity)),
            lineWidth: drop.thickness
        )
    }

    // MARK: - 绘制中景雨滴
    private func drawMidgroundDrop(context: GraphicsContext, drop: RainDrop, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - drop.startTime
        if elapsed < 0 { return }

        let cycleTime = Double(canvasSize.height + drop.length) / Double(drop.speed)
        let progress = elapsed.truncatingRemainder(dividingBy: cycleTime)
        let currentY = drop.startY + CGFloat(progress) * drop.speed
        let windX = sin(time * 0.5) * intensity.windStrength * 40 * drop.windInfluence

        if currentY > canvasSize.height + drop.length { return }

        let startPoint = CGPoint(x: drop.x + windX, y: currentY - drop.length)
        let endPoint = CGPoint(x: drop.x + windX * 0.85, y: currentY)

        // 微弱发光
        var glowPath = Path()
        glowPath.move(to: startPoint)
        glowPath.addLine(to: endPoint)

        context.stroke(
            glowPath,
            with: .color(drop.color.opacity(drop.opacity * 0.3)),
            lineWidth: drop.thickness + 2
        )

        context.stroke(
            glowPath,
            with: .color(drop.color.opacity(drop.opacity)),
            lineWidth: drop.thickness
        )
    }

    // MARK: - 绘制前景雨滴
    private func drawRainDrop(context: GraphicsContext, drop: RainDrop, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - drop.startTime
        if elapsed < 0 { return }

        let cycleTime = Double(canvasSize.height + drop.length) / Double(drop.speed)
        let progress = elapsed.truncatingRemainder(dividingBy: cycleTime)
        let currentY = drop.startY + CGFloat(progress) * drop.speed
        let windX = sin(time * 0.5) * intensity.windStrength * 50 * drop.windInfluence

        if currentY > canvasSize.height + drop.length { return }

        let startPoint = CGPoint(x: drop.x + windX, y: currentY - drop.length)
        let endPoint = CGPoint(x: drop.x + windX * 0.9, y: currentY)

        // 雨滴外发光
        var glowPath = Path()
        glowPath.move(to: startPoint)
        glowPath.addLine(to: endPoint)

        context.stroke(
            glowPath,
            with: .color(drop.color.opacity(drop.opacity * 0.35)),
            lineWidth: drop.thickness + 5
        )

        // 雨滴主体渐变
        context.stroke(
            glowPath,
            with: .linearGradient(
                Gradient(colors: [
                    Color.white.opacity(0),
                    drop.color.opacity(drop.opacity * 0.7),
                    Color.white.opacity(drop.opacity)
                ]),
                startPoint: startPoint,
                endPoint: endPoint
            ),
            lineWidth: drop.thickness
        )

        // 雨滴头部亮点
        let headRect = CGRect(x: drop.x + windX * 0.9 - 2, y: currentY - 2, width: 4, height: 4)
        context.fill(
            Circle().path(in: headRect),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(drop.opacity),
                    drop.color.opacity(drop.opacity * 0.5),
                    .clear
                ]),
                center: CGPoint(x: drop.x + windX * 0.9, y: currentY),
                startRadius: 0,
                endRadius: 4
            )
        )
    }

    // MARK: - 绘制涟漪
    private func drawRipple(context: GraphicsContext, ripple: Ripple, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - ripple.startTime
        if elapsed < 0 { return }

        let cycleProgress = elapsed.truncatingRemainder(dividingBy: ripple.duration) / ripple.duration
        let currentRadius = ripple.maxRadius * CGFloat(cycleProgress)
        let opacity = (1.0 - cycleProgress) * 0.7

        // 涟漪椭圆（扁平化模拟透视）
        let rect = CGRect(
            x: ripple.x - currentRadius,
            y: ripple.y - currentRadius * 0.2,
            width: currentRadius * 2,
            height: currentRadius * 0.4
        )

        // 外发光
        context.stroke(
            Ellipse().path(in: rect.insetBy(dx: -3, dy: -1.5)),
            with: .color(ripple.neonColor.opacity(opacity * 0.35)),
            lineWidth: 4
        )

        // 主涟漪
        context.stroke(
            Ellipse().path(in: rect),
            with: .color(ripple.neonColor.opacity(opacity)),
            lineWidth: 2
        )

        // 内圈涟漪
        if cycleProgress < 0.6 {
            let innerProgress = cycleProgress * 1.5
            let innerRadius = ripple.maxRadius * CGFloat(innerProgress) * 0.5
            let innerRect = CGRect(
                x: ripple.x - innerRadius,
                y: ripple.y - innerRadius * 0.2,
                width: innerRadius * 2,
                height: innerRadius * 0.4
            )
            context.stroke(
                Ellipse().path(in: innerRect),
                with: .color(Color.white.opacity(opacity * 0.6)),
                lineWidth: 1.5
            )
        }
    }

    // MARK: - 绘制水花
    private func drawSplash(context: GraphicsContext, splash: Splash, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - splash.startTime
        if elapsed < 0 { return }

        let cycleTime = splash.duration + splash.interval
        let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleTime)

        guard cycleProgress < splash.duration else { return }

        let progress = cycleProgress / splash.duration

        // 绘制多个水花粒子
        for i in 0..<splash.particleCount {
            let angle = Double(i) / Double(splash.particleCount) * .pi - .pi / 2 + Double.random(in: -0.2...0.2)
            let spread = CGFloat(25 + i * 6)

            // 抛物线轨迹
            let t = progress
            let particleX = splash.x + cos(angle) * spread * CGFloat(t)
            let particleY = splash.y - splash.maxHeight * CGFloat(sin(.pi * t)) + 8 * CGFloat(t * t)

            let particleSize = CGFloat(3 - progress * 2)
            let particleOpacity = (1.0 - progress) * 0.85

            if particleSize > 0 {
                // 发光
                let glowRect = CGRect(
                    x: particleX - particleSize * 2,
                    y: particleY - particleSize * 2,
                    width: particleSize * 4,
                    height: particleSize * 4
                )
                context.fill(
                    Circle().path(in: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            splash.color.opacity(particleOpacity * 0.4),
                            .clear
                        ]),
                        center: CGPoint(x: particleX, y: particleY),
                        startRadius: 0,
                        endRadius: particleSize * 2
                    )
                )

                // 主体
                let rect = CGRect(
                    x: particleX - particleSize / 2,
                    y: particleY - particleSize / 2,
                    width: particleSize,
                    height: particleSize
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(splash.color.opacity(particleOpacity))
                )
            }
        }
    }
}

// MARK: - 雨滴数据
struct RainDrop: Identifiable {
    let id: Int
    let x: CGFloat
    let startY: CGFloat
    let length: CGFloat
    let speed: CGFloat
    let opacity: Double
    let thickness: CGFloat
    let startTime: TimeInterval
    let color: Color
    let windInfluence: CGFloat                                  // 风力影响系数
}

// MARK: - 涟漪数据
struct Ripple: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let maxRadius: CGFloat
    let duration: Double
    let startTime: TimeInterval
    let neonColor: Color
}

// MARK: - 水花数据
struct Splash: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let particleCount: Int
    let maxHeight: CGFloat
    let duration: Double
    let interval: Double
    let startTime: TimeInterval
    let color: Color                                            // 水花颜色
}

// MARK: - 预览
#Preview("小雨") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a2a4a"), Color(hex: "0d1a30")],
            startPoint: .top,
            endPoint: .bottom
        )
        RainyAnimation(intensity: .light)
    }
    .ignoresSafeArea()
}

#Preview("中雨") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a2a4a"), Color(hex: "0d1a30")],
            startPoint: .top,
            endPoint: .bottom
        )
        RainyAnimation(intensity: .moderate)
    }
    .ignoresSafeArea()
}

#Preview("大雨") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "14243a"), Color(hex: "0a1520")],
            startPoint: .top,
            endPoint: .bottom
        )
        RainyAnimation(intensity: .heavy)
    }
    .ignoresSafeArea()
}
