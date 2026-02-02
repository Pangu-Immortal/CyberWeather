//
//  SnowyAnimation.swift
//  SmartCleaner
//
//  雪天动画 - 赛博朋克增强版
//  包含：雪花飘落、冰晶粒子、暴风雪漩涡、钻石尘埃、
//       极光反射、冰棱折射、六边形冰晶、霜雾层
//  支持不同雪量强度，丰富的霓虹色彩
//

import SwiftUI

// MARK: - 降雪强度
enum SnowIntensity {
    case light      // 小雪
    case moderate   // 中雪
    case heavy      // 大雪/暴风雪

    var flakeCount: Int {
        switch self {
        case .light: return 120
        case .moderate: return 250
        case .heavy: return 500
        }
    }

    var flakeSpeed: ClosedRange<CGFloat> {
        switch self {
        case .light: return 50...100
        case .moderate: return 80...150
        case .heavy: return 120...250
        }
    }

    var flakeSize: ClosedRange<CGFloat> {
        switch self {
        case .light: return 3...6
        case .moderate: return 4...10
        case .heavy: return 5...14
        }
    }

    var frostParticleCount: Int {
        switch self {
        case .light: return 20
        case .moderate: return 35
        case .heavy: return 60
        }
    }

    var mistOpacity: Double {
        switch self {
        case .light: return 0.12
        case .moderate: return 0.22
        case .heavy: return 0.4
        }
    }

    var windStrength: CGFloat {
        switch self {
        case .light: return 0.1
        case .moderate: return 0.2
        case .heavy: return 0.5  // 暴风雪强风
        }
    }

    var hasBlizzard: Bool {
        self == .heavy
    }

    var diamondDustCount: Int {
        switch self {
        case .light: return 30
        case .moderate: return 50
        case .heavy: return 80
        }
    }
}

// MARK: - 雪天动画
struct SnowyAnimation: View {
    let intensity: SnowIntensity

    @State private var snowflakes: [Snowflake] = []
    @State private var backgroundFlakes: [Snowflake] = []
    @State private var midgroundFlakes: [Snowflake] = []        // 中景雪花增加深度
    @State private var frostParticles: [FrostParticle] = []
    @State private var windOffset: CGFloat = 0
    @State private var groundSparkles: [GroundSparkle] = []
    @State private var diamondDust: [DiamondDust] = []          // 钻石尘埃
    @State private var iceShards: [IceShard] = []               // 冰碎片
    @State private var blizzardPhase: Double = 0                // 暴风雪相位

    init(intensity: SnowIntensity = .moderate) {
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // 1. 极光反射层（底层）
                auroraReflectionLayer(size: size)

                // 2. 霜雾层
                frostMistLayer(size: size)

                // 3. 冰棱折射效果
                icePrismLayer(size: size)

                // 4. 暴风雪漩涡（仅大雪）
                if intensity.hasBlizzard {
                    blizzardVortexLayer(size: size)
                }

                // 5. 雪花画布
                snowCanvas(size: size)

                // 6. 钻石尘埃层
                diamondDustCanvas(size: size)

                // 7. 顶部霓虹冷光
                topColdGlow(size: size)

                // 8. 底部积雪反光
                bottomSnowReflection(size: size)

                // 9. 边缘霜冻效果
                edgeFrostEffect(size: size)
            }
            .onAppear {
                generateSnowflakes(in: size)
                generateBackgroundFlakes(in: size)
                generateMidgroundFlakes(in: size)
                generateFrostParticles(in: size)
                generateGroundSparkles(in: size)
                generateDiamondDust(in: size)
                generateIceShards(in: size)
                startWindAnimation()
            }
        }
        .drawingGroup()
    }

    // MARK: - 雪花画布
    private func snowCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 背景雪花（远景、小、慢、模糊）
                for flake in backgroundFlakes {
                    drawBackgroundSnowflake(
                        context: context,
                        flake: flake,
                        time: time,
                        canvasSize: canvasSize
                    )
                }

                // 中景雪花
                for flake in midgroundFlakes {
                    drawMidgroundSnowflake(
                        context: context,
                        flake: flake,
                        time: time,
                        canvasSize: canvasSize
                    )
                }

                // 霜晶粒子
                for particle in frostParticles {
                    drawFrostParticle(
                        context: context,
                        particle: particle,
                        time: time,
                        canvasSize: canvasSize
                    )
                }

                // 冰碎片
                for shard in iceShards {
                    drawIceShard(
                        context: context,
                        shard: shard,
                        time: time,
                        canvasSize: canvasSize
                    )
                }

                // 前景雪花
                for flake in snowflakes {
                    drawSnowflake(
                        context: context,
                        flake: flake,
                        time: time,
                        canvasSize: canvasSize
                    )
                }

                // 地面积雪和闪光
                drawEnhancedSnowGround(context: context, canvasSize: canvasSize, time: time)
            }
        }
    }

    // MARK: - 钻石尘埃画布
    private func diamondDustCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for dust in diamondDust {
                    drawDiamondDust(
                        context: context,
                        dust: dust,
                        time: time,
                        canvasSize: canvasSize
                    )
                }
            }
        }
    }

    // MARK: - 极光反射层
    private func auroraReflectionLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 多条极光反射带
                let auroraColors: [(Color, Color)] = [
                    (Color(hex: "00D4FF"), Color(hex: "00FF88")),
                    (Color(hex: "FF00FF"), Color(hex: "7B2FFF")),
                    (Color(hex: "FFD700"), Color(hex: "FF6B00"))
                ]

                for (index, colors) in auroraColors.enumerated() {
                    let baseY = canvasSize.height * 0.15 + CGFloat(index) * 80
                    let wave = sin(time * 0.3 + Double(index) * 1.5) * 30
                    let opacity = 0.06 + sin(time * 0.5 + Double(index)) * 0.03

                    let rect = CGRect(
                        x: -50,
                        y: baseY + CGFloat(wave) - 60,
                        width: canvasSize.width + 100,
                        height: 120
                    )

                    context.fill(
                        Ellipse().path(in: rect),
                        with: .linearGradient(
                            Gradient(colors: [
                                .clear,
                                colors.0.opacity(opacity),
                                colors.1.opacity(opacity * 0.7),
                                .clear
                            ]),
                            startPoint: CGPoint(x: 0, y: baseY),
                            endPoint: CGPoint(x: canvasSize.width, y: baseY)
                        )
                    )
                }
            }
        }
    }

    // MARK: - 霜雾层
    private func frostMistLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let colors: [Color] = [
                    Color(hex: "00D4FF"),
                    Color(hex: "7B2FFF"),
                    Color(hex: "FF00FF"),
                    Color.white
                ]

                // 多层霜雾
                for layer in 0..<4 {
                    let layerOffset = CGFloat(layer) * 0.25
                    let speed = 0.15 + Double(layer) * 0.08
                    let pulse = sin(time * speed + Double(layerOffset) * 2) * 0.3 + 0.7

                    for i in 0..<6 {
                        let xBase = canvasSize.width * CGFloat(i + 1) / 7
                        let yBase = canvasSize.height * (0.25 + CGFloat(layer) * 0.18)

                        let x = xBase + sin(time * 0.25 + Double(i) + Double(layer)) * 60
                        let y = yBase + cos(time * 0.18 + Double(i) + Double(layer)) * 35

                        let mistSize: CGFloat = 120 + CGFloat(layer) * 40

                        let rect = CGRect(
                            x: x - mistSize,
                            y: y - mistSize / 2,
                            width: mistSize * 2,
                            height: mistSize
                        )

                        context.fill(
                            Ellipse().path(in: rect),
                            with: .radialGradient(
                                Gradient(colors: [
                                    colors[layer].opacity(intensity.mistOpacity * 0.25 * pulse),
                                    colors[layer].opacity(intensity.mistOpacity * 0.08 * pulse),
                                    .clear
                                ]),
                                center: CGPoint(x: x, y: y),
                                startRadius: 0,
                                endRadius: mistSize
                            )
                        )
                    }
                }
            }
        }
    }

    // MARK: - 冰棱折射效果
    private func icePrismLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 彩虹棱镜光带
                let prismCount = 8
                for i in 0..<prismCount {
                    let phase = Double(i) * 0.8 + time * 0.2
                    let x = canvasSize.width * CGFloat(i + 1) / CGFloat(prismCount + 1)
                    let shimmer = sin(time * 2 + Double(i)) * 0.5 + 0.5

                    if shimmer > 0.3 {
                        // 彩虹渐变
                        let rainbowColors: [Color] = [
                            Color(hex: "FF0000").opacity(0.15 * shimmer),
                            Color(hex: "FF7F00").opacity(0.12 * shimmer),
                            Color(hex: "FFFF00").opacity(0.1 * shimmer),
                            Color(hex: "00FF00").opacity(0.12 * shimmer),
                            Color(hex: "00D4FF").opacity(0.15 * shimmer),
                            Color(hex: "7B2FFF").opacity(0.12 * shimmer),
                            .clear
                        ]

                        let startY = canvasSize.height * 0.1 + sin(phase) * 50
                        let endY = canvasSize.height * 0.6 + cos(phase) * 80

                        var path = Path()
                        path.move(to: CGPoint(x: x - 15, y: startY))
                        path.addLine(to: CGPoint(x: x + 15, y: startY))
                        path.addLine(to: CGPoint(x: x + 25, y: endY))
                        path.addLine(to: CGPoint(x: x - 25, y: endY))
                        path.closeSubpath()

                        context.fill(
                            path,
                            with: .linearGradient(
                                Gradient(colors: rainbowColors),
                                startPoint: CGPoint(x: x, y: startY),
                                endPoint: CGPoint(x: x, y: endY)
                            )
                        )
                    }
                }
            }
        }
    }

    // MARK: - 暴风雪漩涡层
    private func blizzardVortexLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let centerX = canvasSize.width / 2
                let centerY = canvasSize.height * 0.4

                // 漩涡线条
                for i in 0..<15 {
                    let baseAngle = Double(i) * 24.0 * .pi / 180.0 + time * 0.8
                    let spiralTurns = 3.0
                    let maxRadius = min(canvasSize.width, canvasSize.height) * 0.5

                    var path = Path()
                    var firstPoint = true

                    for t in stride(from: 0.0, through: spiralTurns * 2 * .pi, by: 0.1) {
                        let r = maxRadius * t / (spiralTurns * 2 * .pi)
                        let angle = baseAngle + t
                        let x = centerX + cos(angle) * r
                        let y = centerY + sin(angle) * r * 0.6

                        if firstPoint {
                            path.move(to: CGPoint(x: x, y: y))
                            firstPoint = false
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    let opacity = 0.08 * (1 - Double(i) / 15)
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(opacity)),
                        lineWidth: 1.5
                    )
                }

                // 漩涡中心发光
                let glowRect = CGRect(
                    x: centerX - 100,
                    y: centerY - 60,
                    width: 200,
                    height: 120
                )
                let pulse = sin(time * 2) * 0.3 + 0.7
                context.fill(
                    Ellipse().path(in: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(hex: "00D4FF").opacity(0.15 * pulse),
                            Color(hex: "7B2FFF").opacity(0.08 * pulse),
                            .clear
                        ]),
                        center: CGPoint(x: centerX, y: centerY),
                        startRadius: 0,
                        endRadius: 100
                    )
                )
            }
        }
    }

    // MARK: - 顶部冷光
    private func topColdGlow(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/10)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = sin(time * 0.5) * 0.04 + 0.96

            LinearGradient(
                colors: [
                    Color(hex: "00D4FF").opacity(0.15 * pulse),
                    Color(hex: "7B2FFF").opacity(0.08 * pulse),
                    Color(hex: "FF00FF").opacity(0.04 * pulse),
                    .clear
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.4)
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - 底部积雪反光
    private func bottomSnowReflection(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/10)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let shimmer = sin(time * 1.5) * 0.15 + 0.85
            let colorShift = sin(time * 0.8)

            LinearGradient(
                colors: [
                    .clear,
                    Color.white.opacity(0.1 * shimmer),
                    Color(hex: colorShift > 0 ? "00D4FF" : "FF00FF").opacity(0.12 * shimmer),
                    Color(hex: "7B2FFF").opacity(0.08 * shimmer),
                    Color.white.opacity(0.2 * shimmer)
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.75),
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - 边缘霜冻效果
    private func edgeFrostEffect(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 四边霜冻边缘
                let edgeWidth: CGFloat = 60

                // 顶部霜冻
                let topRect = CGRect(x: 0, y: 0, width: canvasSize.width, height: edgeWidth)
                context.fill(
                    Rectangle().path(in: topRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color(hex: "00D4FF").opacity(0.08),
                            .clear
                        ]),
                        startPoint: CGPoint(x: canvasSize.width/2, y: 0),
                        endPoint: CGPoint(x: canvasSize.width/2, y: edgeWidth)
                    )
                )

                // 霜晶纹理
                for i in 0..<20 {
                    let x = CGFloat(i) * canvasSize.width / 20
                    let length = CGFloat.random(in: 20...50)
                    let shimmer = sin(time * 2 + Double(i) * 0.5) * 0.5 + 0.5

                    if shimmer > 0.4 {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + 10, y: length))
                        path.addLine(to: CGPoint(x: x - 5, y: length * 0.6))
                        path.closeSubpath()

                        context.fill(
                            path,
                            with: .color(Color.white.opacity(0.2 * shimmer))
                        )
                    }
                }
            }
        }
    }

    // MARK: - 启动风力动画
    private func startWindAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            let time = Date.timeIntervalSinceReferenceDate
            let baseWind = sin(time * 0.5) * 30 + sin(time * 1.3) * 15

            if intensity.hasBlizzard {
                // 暴风雪：更强的风力变化
                let gustWind = sin(time * 3) * 40
                windOffset = baseWind + gustWind
                blizzardPhase = time
            } else {
                windOffset = baseWind
            }
        }
    }

    // MARK: - 生成前景雪花
    private func generateSnowflakes(in size: CGSize) {
        let colors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "7B2FFF"),
            Color(hex: "FF00FF"),
            Color(hex: "FFD700"),
            Color(hex: "00FF88"),
            Color.white
        ]

        snowflakes = (0..<intensity.flakeCount).map { index in
            Snowflake(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -size.height...0),
                size: CGFloat.random(in: intensity.flakeSize),
                speed: CGFloat.random(in: intensity.flakeSpeed),
                wobbleAmplitude: CGFloat.random(in: 20...60),
                wobbleFrequency: Double.random(in: 0.5...2.0),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 30...120),
                opacity: Double.random(in: 0.6...1.0),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...3),
                type: SnowflakeType.allCases.randomElement()!,
                glowColor: colors.randomElement()!,
                windInfluence: CGFloat.random(in: 0.7...1.3)
            )
        }
    }

    // MARK: - 生成背景雪花
    private func generateBackgroundFlakes(in size: CGSize) {
        backgroundFlakes = (0..<intensity.flakeCount / 2).map { index in
            Snowflake(
                id: index + 10000,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -size.height...0),
                size: CGFloat.random(in: 2...4),
                speed: CGFloat.random(in: 25...50),
                wobbleAmplitude: CGFloat.random(in: 8...20),
                wobbleFrequency: Double.random(in: 0.2...0.8),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 10...30),
                opacity: Double.random(in: 0.15...0.35),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...3),
                type: .dot,
                glowColor: Color(hex: "00D4FF"),
                windInfluence: CGFloat.random(in: 0.2...0.4)
            )
        }
    }

    // MARK: - 生成中景雪花
    private func generateMidgroundFlakes(in size: CGSize) {
        let colors: [Color] = [Color(hex: "00D4FF"), Color(hex: "7B2FFF"), Color.white]

        midgroundFlakes = (0..<intensity.flakeCount / 3).map { index in
            Snowflake(
                id: index + 20000,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -size.height...0),
                size: CGFloat.random(in: 4...7),
                speed: CGFloat.random(in: 50...90),
                wobbleAmplitude: CGFloat.random(in: 15...35),
                wobbleFrequency: Double.random(in: 0.4...1.2),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 20...60),
                opacity: Double.random(in: 0.4...0.7),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...3),
                type: SnowflakeType.allCases.randomElement()!,
                glowColor: colors.randomElement()!,
                windInfluence: CGFloat.random(in: 0.5...0.8)
            )
        }
    }

    // MARK: - 生成霜晶粒子
    private func generateFrostParticles(in size: CGSize) {
        let colors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "7B2FFF"),
            Color(hex: "FF00FF"),
            Color(hex: "FFD700"),
            Color.white
        ]

        frostParticles = (0..<intensity.frostParticleCount).map { index in
            FrostParticle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.2...size.height * 0.85),
                size: CGFloat.random(in: 2...6),
                driftSpeed: Double.random(in: 0.2...0.6),
                twinkleSpeed: Double.random(in: 2...6),
                phase: Double.random(in: 0...(.pi * 2)),
                color: colors.randomElement()!
            )
        }
    }

    // MARK: - 生成地面闪光
    private func generateGroundSparkles(in size: CGSize) {
        let colors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "FF00FF"),
            Color(hex: "FFD700"),
            Color.white
        ]

        groundSparkles = (0..<40).map { index in
            GroundSparkle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: size.height - CGFloat.random(in: 10...60),
                twinkleSpeed: Double.random(in: 1...5),
                phase: Double.random(in: 0...(.pi * 2)),
                color: colors.randomElement()!
            )
        }
    }

    // MARK: - 生成钻石尘埃
    private func generateDiamondDust(in size: CGSize) {
        diamondDust = (0..<intensity.diamondDustCount).map { index in
            DiamondDust(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height * 0.8),
                size: CGFloat.random(in: 1...3),
                driftSpeed: Double.random(in: 0.1...0.3),
                shimmerSpeed: Double.random(in: 3...8),
                phase: Double.random(in: 0...(.pi * 2)),
                colorPhase: Double.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - 生成冰碎片
    private func generateIceShards(in size: CGSize) {
        iceShards = (0..<15).map { index in
            IceShard(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -size.height * 0.5...0),
                size: CGFloat.random(in: 8...20),
                speed: CGFloat.random(in: 40...80),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 60...180),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...5)
            )
        }
    }

    // MARK: - 绘制背景雪花
    private func drawBackgroundSnowflake(context: GraphicsContext, flake: Snowflake, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - flake.startTime
        if elapsed < 0 { return }

        let cycleTime = Double(canvasSize.height + flake.size * 2) / Double(flake.speed)
        let progress = elapsed.truncatingRemainder(dividingBy: cycleTime)
        let currentY = flake.startY + CGFloat(progress) * flake.speed
        let wobbleOffset = sin(elapsed * flake.wobbleFrequency * .pi * 2) * flake.wobbleAmplitude
        let currentX = flake.x + CGFloat(wobbleOffset) + windOffset * flake.windInfluence

        if currentY > canvasSize.height + flake.size { return }

        let rect = CGRect(
            x: currentX - flake.size / 2,
            y: currentY - flake.size / 2,
            width: flake.size,
            height: flake.size
        )

        context.fill(
            Circle().path(in: rect),
            with: .color(Color.white.opacity(flake.opacity))
        )
    }

    // MARK: - 绘制中景雪花
    private func drawMidgroundSnowflake(context: GraphicsContext, flake: Snowflake, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - flake.startTime
        if elapsed < 0 { return }

        let cycleTime = Double(canvasSize.height + flake.size * 2) / Double(flake.speed)
        let progress = elapsed.truncatingRemainder(dividingBy: cycleTime)
        let currentY = flake.startY + CGFloat(progress) * flake.speed
        let wobbleOffset = sin(elapsed * flake.wobbleFrequency * .pi * 2) * flake.wobbleAmplitude
        let currentX = flake.x + CGFloat(wobbleOffset) + windOffset * flake.windInfluence

        if currentY > canvasSize.height + flake.size { return }

        let currentRotation = flake.rotation + elapsed * flake.rotationSpeed

        var localContext = context
        localContext.translateBy(x: currentX, y: currentY)
        localContext.rotate(by: .degrees(currentRotation))

        // 中景雪花带轻微模糊感
        let rect = CGRect(x: -flake.size/2, y: -flake.size/2, width: flake.size, height: flake.size)
        let glowRect = rect.insetBy(dx: -flake.size * 0.3, dy: -flake.size * 0.3)

        localContext.fill(
            Circle().path(in: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    flake.glowColor.opacity(flake.opacity * 0.3),
                    .clear
                ]),
                center: .zero,
                startRadius: 0,
                endRadius: flake.size
            )
        )

        localContext.fill(
            Circle().path(in: rect),
            with: .color(Color.white.opacity(flake.opacity * 0.8))
        )
    }

    // MARK: - 绘制前景雪花
    private func drawSnowflake(context: GraphicsContext, flake: Snowflake, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - flake.startTime
        if elapsed < 0 { return }

        let cycleTime = Double(canvasSize.height + flake.size * 2) / Double(flake.speed)
        let progress = elapsed.truncatingRemainder(dividingBy: cycleTime)
        let currentY = flake.startY + CGFloat(progress) * flake.speed
        let wobbleOffset = sin(elapsed * flake.wobbleFrequency * .pi * 2) * flake.wobbleAmplitude
        var currentX = flake.x + CGFloat(wobbleOffset) + windOffset * flake.windInfluence

        // 暴风雪额外漩涡影响
        if intensity.hasBlizzard {
            let vortexInfluence = sin(elapsed * 2 + Double(flake.id) * 0.1) * 20
            currentX += CGFloat(vortexInfluence)
        }

        if currentY > canvasSize.height + flake.size { return }

        let currentRotation = flake.rotation + elapsed * flake.rotationSpeed

        var localContext = context
        localContext.translateBy(x: currentX, y: currentY)
        localContext.rotate(by: .degrees(currentRotation))

        switch flake.type {
        case .crystal:
            drawCrystalSnowflake(context: &localContext, size: flake.size, opacity: flake.opacity, glowColor: flake.glowColor)
        case .dot:
            drawDotSnowflake(context: &localContext, size: flake.size, opacity: flake.opacity, glowColor: flake.glowColor)
        case .star:
            drawStarSnowflake(context: &localContext, size: flake.size, opacity: flake.opacity, glowColor: flake.glowColor)
        case .hexagon:
            drawHexagonSnowflake(context: &localContext, size: flake.size, opacity: flake.opacity, glowColor: flake.glowColor)
        case .dendrite:
            drawDendriteSnowflake(context: &localContext, size: flake.size, opacity: flake.opacity, glowColor: flake.glowColor)
        }
    }

    // MARK: - 绘制霜晶粒子
    private func drawFrostParticle(context: GraphicsContext, particle: FrostParticle, time: TimeInterval, canvasSize: CGSize) {
        let driftX = sin(time * particle.driftSpeed + particle.phase) * 50
        let driftY = cos(time * particle.driftSpeed * 0.7 + particle.phase) * 25
        let twinkle = sin(time * particle.twinkleSpeed + particle.phase) * 0.5 + 0.5

        let x = particle.x + CGFloat(driftX) + windOffset * 0.4
        let y = particle.y + CGFloat(driftY)

        // 多层发光
        let glowRect = CGRect(
            x: x - particle.size * 4,
            y: y - particle.size * 4,
            width: particle.size * 8,
            height: particle.size * 8
        )
        context.fill(
            Circle().path(in: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    particle.color.opacity(0.5 * twinkle),
                    particle.color.opacity(0.2 * twinkle),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: particle.size * 4
            )
        )

        // 主体
        let rect = CGRect(
            x: x - particle.size / 2,
            y: y - particle.size / 2,
            width: particle.size,
            height: particle.size
        )
        context.fill(
            Circle().path(in: rect),
            with: .color(Color.white.opacity(0.9 * twinkle))
        )
    }

    // MARK: - 绘制冰碎片
    private func drawIceShard(context: GraphicsContext, shard: IceShard, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - shard.startTime
        if elapsed < 0 { return }

        let cycleTime = Double(canvasSize.height + shard.size * 2) / Double(shard.speed)
        let progress = elapsed.truncatingRemainder(dividingBy: cycleTime)
        let currentY = shard.startY + CGFloat(progress) * shard.speed

        if currentY > canvasSize.height + shard.size { return }

        let currentX = shard.x + windOffset * 0.6
        let currentRotation = shard.rotation + elapsed * shard.rotationSpeed

        var localContext = context
        localContext.translateBy(x: currentX, y: currentY)
        localContext.rotate(by: .degrees(currentRotation))

        // 菱形冰碎片
        var path = Path()
        path.move(to: CGPoint(x: 0, y: -shard.size/2))
        path.addLine(to: CGPoint(x: shard.size/3, y: 0))
        path.addLine(to: CGPoint(x: 0, y: shard.size/2))
        path.addLine(to: CGPoint(x: -shard.size/3, y: 0))
        path.closeSubpath()

        // 发光边缘
        localContext.stroke(path, with: .color(Color(hex: "00D4FF").opacity(0.6)), lineWidth: 2)

        // 填充
        localContext.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color.white.opacity(0.8),
                    Color(hex: "00D4FF").opacity(0.4),
                    Color.white.opacity(0.6)
                ]),
                startPoint: CGPoint(x: -shard.size/3, y: 0),
                endPoint: CGPoint(x: shard.size/3, y: 0)
            )
        )
    }

    // MARK: - 绘制钻石尘埃
    private func drawDiamondDust(context: GraphicsContext, dust: DiamondDust, time: TimeInterval, canvasSize: CGSize) {
        let driftX = sin(time * dust.driftSpeed + dust.phase) * 30
        let driftY = sin(time * dust.driftSpeed * 0.5 + dust.phase + 1) * 20
        let shimmer = sin(time * dust.shimmerSpeed + dust.phase)

        if shimmer < 0.2 { return }  // 大部分时间不可见

        let x = dust.x + CGFloat(driftX) + windOffset * 0.2
        let y = dust.y + CGFloat(driftY)
        let brightness = (shimmer - 0.2) / 0.8

        // 彩虹色相变化
        let hue = (time * 0.5 + dust.colorPhase).truncatingRemainder(dividingBy: 1.0)
        let rainbowColor = Color(hue: hue, saturation: 0.7, brightness: 1.0)

        // 闪烁光芒
        let size = dust.size * CGFloat(1 + brightness)

        // 十字光芒
        let rayLength = size * 4 * CGFloat(brightness)

        var hPath = Path()
        hPath.move(to: CGPoint(x: x - rayLength, y: y))
        hPath.addLine(to: CGPoint(x: x + rayLength, y: y))

        var vPath = Path()
        vPath.move(to: CGPoint(x: x, y: y - rayLength))
        vPath.addLine(to: CGPoint(x: x, y: y + rayLength))

        context.stroke(hPath, with: .color(rainbowColor.opacity(brightness * 0.6)), lineWidth: 1)
        context.stroke(vPath, with: .color(rainbowColor.opacity(brightness * 0.6)), lineWidth: 1)

        // 中心亮点
        let rect = CGRect(x: x - size/2, y: y - size/2, width: size, height: size)
        context.fill(Circle().path(in: rect), with: .color(Color.white.opacity(brightness)))
    }

    // MARK: - 绘制晶状雪花
    private func drawCrystalSnowflake(context: inout GraphicsContext, size: CGFloat, opacity: Double, glowColor: Color) {
        let halfSize = size / 2

        for i in 0..<6 {
            let angle = Double(i) * 60.0 * .pi / 180.0
            let endX = cos(angle) * Double(halfSize)
            let endY = sin(angle) * Double(halfSize)

            var path = Path()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: endX, y: endY))

            // 霓虹发光
            context.stroke(path, with: .color(glowColor.opacity(opacity * 0.5)), lineWidth: 4)
            context.stroke(path, with: .color(Color.white.opacity(opacity)), lineWidth: 1.5)

            // 分支
            let branchLength = halfSize * 0.45
            let branchAngle1 = angle + .pi / 6
            let branchAngle2 = angle - .pi / 6
            let branchStart = CGPoint(x: cos(angle) * Double(halfSize * 0.55), y: sin(angle) * Double(halfSize * 0.55))

            var branch1 = Path()
            branch1.move(to: branchStart)
            branch1.addLine(to: CGPoint(
                x: branchStart.x + cos(branchAngle1) * Double(branchLength),
                y: branchStart.y + sin(branchAngle1) * Double(branchLength)
            ))

            var branch2 = Path()
            branch2.move(to: branchStart)
            branch2.addLine(to: CGPoint(
                x: branchStart.x + cos(branchAngle2) * Double(branchLength),
                y: branchStart.y + sin(branchAngle2) * Double(branchLength)
            ))

            context.stroke(branch1, with: .color(Color.white.opacity(opacity * 0.8)), lineWidth: 0.8)
            context.stroke(branch2, with: .color(Color.white.opacity(opacity * 0.8)), lineWidth: 0.8)
        }

        // 中心发光点
        let centerRect = CGRect(x: -3, y: -3, width: 6, height: 6)
        context.fill(
            Circle().path(in: centerRect),
            with: .radialGradient(
                Gradient(colors: [glowColor, glowColor.opacity(0.5)]),
                center: .zero,
                startRadius: 0,
                endRadius: 3
            )
        )
    }

    // MARK: - 绘制圆点雪花
    private func drawDotSnowflake(context: inout GraphicsContext, size: CGFloat, opacity: Double, glowColor: Color) {
        let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)

        // 外发光
        let glowRect = rect.insetBy(dx: -size/2, dy: -size/2)
        context.fill(
            Circle().path(in: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    glowColor.opacity(opacity * 0.5),
                    glowColor.opacity(opacity * 0.2),
                    .clear
                ]),
                center: .zero,
                startRadius: 0,
                endRadius: size
            )
        )

        // 主体
        context.fill(
            Circle().path(in: rect),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(opacity),
                    Color.white.opacity(opacity * 0.7)
                ]),
                center: .zero,
                startRadius: 0,
                endRadius: size/2
            )
        )
    }

    // MARK: - 绘制星形雪花
    private func drawStarSnowflake(context: inout GraphicsContext, size: CGFloat, opacity: Double, glowColor: Color) {
        var path = Path()
        let points = 6
        let innerRadius = size * 0.3
        let outerRadius = size * 0.5

        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let point = CGPoint(x: cos(angle) * Double(radius), y: sin(angle) * Double(radius))

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        // 外发光
        context.fill(path, with: .color(glowColor.opacity(opacity * 0.5)))

        // 主体
        context.fill(path, with: .color(Color.white.opacity(opacity)))
    }

    // MARK: - 绘制六边形雪花
    private func drawHexagonSnowflake(context: inout GraphicsContext, size: CGFloat, opacity: Double, glowColor: Color) {
        var path = Path()
        let radius = size / 2

        for i in 0..<6 {
            let angle = Double(i) * 60.0 * .pi / 180.0 - .pi / 2
            let point = CGPoint(x: cos(angle) * Double(radius), y: sin(angle) * Double(radius))

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        // 外发光描边
        context.stroke(path, with: .color(glowColor.opacity(opacity * 0.6)), lineWidth: 3)

        // 填充
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color.white.opacity(opacity * 0.9),
                    glowColor.opacity(opacity * 0.4)
                ]),
                startPoint: CGPoint(x: 0, y: -radius),
                endPoint: CGPoint(x: 0, y: radius)
            )
        )

        // 中心点
        let centerRect = CGRect(x: -2, y: -2, width: 4, height: 4)
        context.fill(Circle().path(in: centerRect), with: .color(Color.white.opacity(opacity)))
    }

    // MARK: - 绘制树枝状雪花
    private func drawDendriteSnowflake(context: inout GraphicsContext, size: CGFloat, opacity: Double, glowColor: Color) {
        let halfSize = size / 2

        for i in 0..<6 {
            let angle = Double(i) * 60.0 * .pi / 180.0
            let endX = cos(angle) * Double(halfSize)
            let endY = sin(angle) * Double(halfSize)

            // 主干
            var mainPath = Path()
            mainPath.move(to: .zero)
            mainPath.addLine(to: CGPoint(x: endX, y: endY))

            context.stroke(mainPath, with: .color(glowColor.opacity(opacity * 0.4)), lineWidth: 3)
            context.stroke(mainPath, with: .color(Color.white.opacity(opacity)), lineWidth: 1)

            // 多级分支
            for j in 1...3 {
                let branchPos = CGFloat(j) / 4.0
                let branchStart = CGPoint(
                    x: cos(angle) * Double(halfSize * branchPos),
                    y: sin(angle) * Double(halfSize * branchPos)
                )
                let branchLength = halfSize * (0.5 - CGFloat(j) * 0.1)

                for sign in [-1.0, 1.0] {
                    let branchAngle = angle + sign * .pi / 4

                    var branchPath = Path()
                    branchPath.move(to: branchStart)
                    branchPath.addLine(to: CGPoint(
                        x: branchStart.x + cos(branchAngle) * Double(branchLength),
                        y: branchStart.y + sin(branchAngle) * Double(branchLength)
                    ))

                    context.stroke(branchPath, with: .color(Color.white.opacity(opacity * 0.7)), lineWidth: 0.5)
                }
            }
        }

        // 中心
        let centerRect = CGRect(x: -2, y: -2, width: 4, height: 4)
        context.fill(Circle().path(in: centerRect), with: .color(glowColor.opacity(opacity)))
    }

    // MARK: - 绘制增强地面积雪
    private func drawEnhancedSnowGround(context: GraphicsContext, canvasSize: CGSize, time: TimeInterval) {
        let groundHeight: CGFloat = 50
        let y = canvasSize.height - groundHeight

        // 积雪渐变
        let rect = CGRect(x: 0, y: y, width: canvasSize.width, height: groundHeight)
        context.fill(
            Rectangle().path(in: rect),
            with: .linearGradient(
                Gradient(colors: [
                    Color.white.opacity(0.4),
                    Color(hex: "00D4FF").opacity(0.2),
                    Color(hex: "7B2FFF").opacity(0.1),
                    Color.white.opacity(0.15),
                    .clear
                ]),
                startPoint: CGPoint(x: canvasSize.width/2, y: y),
                endPoint: CGPoint(x: canvasSize.width/2, y: canvasSize.height)
            )
        )

        // 积雪起伏
        var snowPath = Path()
        snowPath.move(to: CGPoint(x: 0, y: y + 6))

        for x in stride(from: CGFloat(0), through: canvasSize.width, by: 12) {
            let wave1 = sin(x * 0.025 + time * 0.1) * 8
            let wave2 = sin(x * 0.06 + 1.5) * 4
            let wave3 = sin(x * 0.1 + time * 0.05) * 2
            let waveY = y + 4 + CGFloat(wave1 + wave2 + wave3)
            snowPath.addLine(to: CGPoint(x: x, y: waveY))
        }

        snowPath.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
        snowPath.addLine(to: CGPoint(x: 0, y: canvasSize.height))
        snowPath.closeSubpath()

        context.fill(snowPath, with: .color(Color.white.opacity(0.22)))

        // 地面闪光点
        for sparkle in groundSparkles {
            let twinkle = sin(time * sparkle.twinkleSpeed + sparkle.phase)
            if twinkle > 0.25 {
                let sparkleOpacity = (twinkle - 0.25) / 0.75 * 0.9
                let sparkleSize: CGFloat = 2 + CGFloat(twinkle) * 3

                let sparkleRect = CGRect(
                    x: sparkle.x - sparkleSize/2,
                    y: sparkle.y - sparkleSize/2,
                    width: sparkleSize,
                    height: sparkleSize
                )

                // 发光
                let glowRect = sparkleRect.insetBy(dx: -sparkleSize, dy: -sparkleSize)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            sparkle.color.opacity(sparkleOpacity * 0.5),
                            .clear
                        ]),
                        center: CGPoint(x: sparkle.x, y: sparkle.y),
                        startRadius: 0,
                        endRadius: sparkleSize * 2
                    )
                )

                context.fill(
                    Circle().path(in: sparkleRect),
                    with: .color(Color.white.opacity(sparkleOpacity))
                )

                // 十字闪光
                if twinkle > 0.65 {
                    let rayLength = sparkleSize * 2.5
                    var hPath = Path()
                    hPath.move(to: CGPoint(x: sparkle.x - rayLength, y: sparkle.y))
                    hPath.addLine(to: CGPoint(x: sparkle.x + rayLength, y: sparkle.y))

                    var vPath = Path()
                    vPath.move(to: CGPoint(x: sparkle.x, y: sparkle.y - rayLength))
                    vPath.addLine(to: CGPoint(x: sparkle.x, y: sparkle.y + rayLength))

                    context.stroke(hPath, with: .color(sparkle.color.opacity(sparkleOpacity * 0.6)), lineWidth: 0.8)
                    context.stroke(vPath, with: .color(sparkle.color.opacity(sparkleOpacity * 0.6)), lineWidth: 0.8)
                }
            }
        }
    }
}

// MARK: - 雪花类型
enum SnowflakeType: CaseIterable {
    case crystal    // 晶状
    case dot        // 圆点
    case star       // 星形
    case hexagon    // 六边形
    case dendrite   // 树枝状
}

// MARK: - 雪花数据
struct Snowflake: Identifiable {
    let id: Int
    let x: CGFloat
    let startY: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let wobbleAmplitude: CGFloat
    let wobbleFrequency: Double
    let rotation: Double
    let rotationSpeed: Double
    let opacity: Double
    let startTime: TimeInterval
    let type: SnowflakeType
    let glowColor: Color
    let windInfluence: CGFloat
}

// MARK: - 霜晶粒子数据
struct FrostParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let driftSpeed: Double
    let twinkleSpeed: Double
    let phase: Double
    let color: Color
}

// MARK: - 地面闪光数据
struct GroundSparkle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let twinkleSpeed: Double
    let phase: Double
    let color: Color
}

// MARK: - 钻石尘埃数据
struct DiamondDust: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let driftSpeed: Double
    let shimmerSpeed: Double
    let phase: Double
    let colorPhase: Double
}

// MARK: - 冰碎片数据
struct IceShard: Identifiable {
    let id: Int
    let x: CGFloat
    let startY: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let startTime: TimeInterval
}

// MARK: - 预览
#Preview("小雪") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "2a3a5a"), Color(hex: "1a2a40"), Color(hex: "0d1a2a")],
            startPoint: .top,
            endPoint: .bottom
        )
        SnowyAnimation(intensity: .light)
    }
    .ignoresSafeArea()
}

#Preview("中雪") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "2a3a5a"), Color(hex: "1a2a40"), Color(hex: "0d1a2a")],
            startPoint: .top,
            endPoint: .bottom
        )
        SnowyAnimation(intensity: .moderate)
    }
    .ignoresSafeArea()
}

#Preview("暴风雪") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a2535"), Color(hex: "101820"), Color(hex: "080c12")],
            startPoint: .top,
            endPoint: .bottom
        )
        SnowyAnimation(intensity: .heavy)
    }
    .ignoresSafeArea()
}
