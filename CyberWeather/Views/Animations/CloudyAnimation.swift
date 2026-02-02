//
//  CloudyAnimation.swift
//  CyberWeather
//
//  多云/阴天动画 - 赛博朋克增强版
//  包含：多层云朵视差、云朵形变、霓虹边缘光、体积光、
//       闪电分支、云内闪烁、风力影响、赛博雾气
//  支持不同云量密度，丰富的霓虹色彩效果
//

import SwiftUI

// MARK: - 云量密度
enum CloudDensity {
    case light      // 少云
    case medium     // 多云
    case heavy      // 阴天

    var cloudCount: Int {
        switch self {
        case .light: return 6
        case .medium: return 12
        case .heavy: return 20
        }
    }

    var opacity: Double {
        switch self {
        case .light: return 0.55
        case .medium: return 0.75
        case .heavy: return 0.92
        }
    }

    var hasLightning: Bool {
        self == .heavy
    }

    var fogDensity: Int {
        switch self {
        case .light: return 10
        case .medium: return 18
        case .heavy: return 30
        }
    }

    var windStrength: CGFloat {
        switch self {
        case .light: return 0.8
        case .medium: return 1.0
        case .heavy: return 1.5
        }
    }
}

// MARK: - 多云动画
struct CloudyAnimation: View {
    let cloudDensity: CloudDensity

    @State private var clouds: [CloudData] = []
    @State private var lightRays: [LightRay] = []
    @State private var lightningFlash: Double = 0
    @State private var fogParticles: [CyberFogParticle] = []
    @State private var lightningBolts: [LightningBolt] = []
    @State private var cloudSparkles: [CloudSparkle] = []
    @State private var windPhase: Double = 0

    init(cloudDensity: CloudDensity = .medium) {
        self.cloudDensity = cloudDensity
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // 1. 极光背景层
                auroraBackgroundLayer(size: size)

                // 2. 体积光层（光线穿透云层）
                if cloudDensity == .light {
                    volumetricLight(size: size)
                }

                // 3. 远景雾气层
                distantFogLayer(size: size)

                // 4. 云朵层
                cloudCanvas(size: size)

                // 5. 云内闪烁
                cloudSparkleCanvas(size: size)

                // 6. 闪电分支（阴天时）
                if cloudDensity.hasLightning {
                    lightningCanvas(size: size)
                    lightningOverlay
                }

                // 7. 近景赛博雾气
                cyberFogLayer(size: size)

                // 8. 霓虹光晕层
                neonGlowLayer(size: size)

                // 9. 扫描线效果
                scanLineEffect(size: size)
            }
            .onAppear {
                generateClouds(in: size)
                generateLightRays(in: size)
                generateFogParticles(in: size)
                generateCloudSparkles(in: size)
                if cloudDensity.hasLightning {
                    generateLightningBolts(in: size)
                    startLightningTimer()
                }
                startWindAnimation()
            }
        }
        .drawingGroup()
    }

    // MARK: - 极光背景层
    private func auroraBackgroundLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 多条流动极光带
                let auroraColors: [Color] = [
                    Color(hex: "00D4FF"),
                    Color(hex: "7B2FFF"),
                    Color(hex: "FF00FF"),
                    Color(hex: "00FF88")
                ]

                for (index, color) in auroraColors.enumerated() {
                    let baseY = CGFloat(index) * canvasSize.height * 0.15 + 50
                    let wave1 = sin(time * 0.2 + Double(index) * 1.2) * 40
                    let wave2 = cos(time * 0.15 + Double(index) * 0.8) * 25
                    let opacity = 0.04 + sin(time * 0.3 + Double(index)) * 0.02

                    let y = baseY + CGFloat(wave1 + wave2)

                    let rect = CGRect(
                        x: -50,
                        y: y - 40,
                        width: canvasSize.width + 100,
                        height: 80
                    )

                    context.fill(
                        Ellipse().path(in: rect),
                        with: .linearGradient(
                            Gradient(colors: [
                                .clear,
                                color.opacity(opacity),
                                color.opacity(opacity * 1.5),
                                color.opacity(opacity),
                                .clear
                            ]),
                            startPoint: CGPoint(x: 0, y: y),
                            endPoint: CGPoint(x: canvasSize.width, y: y)
                        )
                    )
                }
            }
        }
    }

    // MARK: - 云朵画布
    private func cloudCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 按层级排序绘制
                for cloud in clouds.sorted(by: { $0.layer < $1.layer }) {
                    drawCloud(
                        context: context,
                        cloud: cloud,
                        time: time,
                        canvasSize: canvasSize
                    )
                }
            }
        }
    }

    // MARK: - 云内闪烁画布
    private func cloudSparkleCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for sparkle in cloudSparkles {
                    let pulse = sin(time * sparkle.pulseSpeed + sparkle.phase)
                    if pulse > 0.3 {
                        let opacity = (pulse - 0.3) / 0.7 * sparkle.maxOpacity
                        let currentSize = sparkle.size * CGFloat(0.5 + pulse * 0.5)

                        // 发光核心
                        let glowRect = CGRect(
                            x: sparkle.x - currentSize * 2,
                            y: sparkle.y - currentSize * 2,
                            width: currentSize * 4,
                            height: currentSize * 4
                        )
                        context.fill(
                            Circle().path(in: glowRect),
                            with: .radialGradient(
                                Gradient(colors: [
                                    sparkle.color.opacity(opacity * 0.6),
                                    sparkle.color.opacity(opacity * 0.2),
                                    .clear
                                ]),
                                center: CGPoint(x: sparkle.x, y: sparkle.y),
                                startRadius: 0,
                                endRadius: currentSize * 2
                            )
                        )

                        // 中心亮点
                        let coreRect = CGRect(
                            x: sparkle.x - currentSize / 2,
                            y: sparkle.y - currentSize / 2,
                            width: currentSize,
                            height: currentSize
                        )
                        context.fill(
                            Circle().path(in: coreRect),
                            with: .color(Color.white.opacity(opacity))
                        )
                    }
                }
            }
        }
    }

    // MARK: - 闪电画布
    private func lightningCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for bolt in lightningBolts {
                    // 闪电只在特定时间闪烁
                    let cycleDuration = bolt.interval
                    let cycleTime = time.truncatingRemainder(dividingBy: cycleDuration)

                    if cycleTime < 0.3 {
                        let flashIntensity = cycleTime < 0.1 ? 1.0 : (0.3 - cycleTime) / 0.2
                        drawLightningBolt(
                            context: context,
                            bolt: bolt,
                            intensity: flashIntensity,
                            time: time
                        )
                    }
                }
            }
        }
    }

    // MARK: - 绘制闪电分支
    private func drawLightningBolt(context: GraphicsContext, bolt: LightningBolt, intensity: Double, time: TimeInterval) {
        // 主干
        var mainPath = Path()
        mainPath.move(to: bolt.startPoint)

        var currentPoint = bolt.startPoint
        let segments = 8
        let segmentLength = (bolt.endPoint.y - bolt.startPoint.y) / CGFloat(segments)

        for i in 1...segments {
            let jitter = CGFloat.random(in: -30...30)
            let nextX = bolt.startPoint.x + (bolt.endPoint.x - bolt.startPoint.x) * CGFloat(i) / CGFloat(segments) + jitter
            let nextY = bolt.startPoint.y + segmentLength * CGFloat(i)
            let nextPoint = CGPoint(x: nextX, y: nextY)
            mainPath.addLine(to: nextPoint)

            // 分支
            if i > 2 && i < segments - 1 && Bool.random() {
                var branchPath = Path()
                branchPath.move(to: nextPoint)
                let branchDirection: CGFloat = Bool.random() ? 1 : -1
                let branchEnd = CGPoint(
                    x: nextPoint.x + branchDirection * CGFloat.random(in: 30...60),
                    y: nextPoint.y + CGFloat.random(in: 20...40)
                )
                branchPath.addLine(to: branchEnd)

                // 分支发光
                context.stroke(branchPath, with: .color(bolt.color.opacity(intensity * 0.4)), lineWidth: 4)
                context.stroke(branchPath, with: .color(Color.white.opacity(intensity * 0.6)), lineWidth: 1)
            }

            currentPoint = nextPoint
        }

        // 主干发光（多层）
        context.stroke(mainPath, with: .color(bolt.color.opacity(intensity * 0.3)), lineWidth: 12)
        context.stroke(mainPath, with: .color(bolt.color.opacity(intensity * 0.5)), lineWidth: 6)
        context.stroke(mainPath, with: .color(Color.white.opacity(intensity * 0.8)), lineWidth: 2)
    }

    // MARK: - 体积光（光线穿透云层）
    private func volumetricLight(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for ray in lightRays {
                    let shimmer = sin(time * ray.shimmerSpeed + ray.phase) * 0.3 + 0.7
                    let rayWidth = ray.width * CGFloat(shimmer)
                    let sway = sin(time * 0.3 + ray.phase) * 20

                    var path = Path()
                    path.move(to: CGPoint(x: ray.x - rayWidth/2 + sway, y: 0))
                    path.addLine(to: CGPoint(x: ray.x + rayWidth/2 + sway, y: 0))
                    path.addLine(to: CGPoint(x: ray.x + rayWidth * 2.5 + sway, y: canvasSize.height))
                    path.addLine(to: CGPoint(x: ray.x - rayWidth * 2.5 + sway, y: canvasSize.height))
                    path.closeSubpath()

                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                ray.color.opacity(ray.opacity * shimmer * 0.35),
                                ray.color.opacity(ray.opacity * shimmer * 0.15),
                                ray.color.opacity(ray.opacity * shimmer * 0.05),
                                .clear
                            ]),
                            startPoint: CGPoint(x: ray.x + sway, y: 0),
                            endPoint: CGPoint(x: ray.x + sway, y: canvasSize.height)
                        )
                    )
                }
            }
        }
    }

    // MARK: - 远景雾气层
    private func distantFogLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 大范围雾气团
                for i in 0..<5 {
                    let baseX = canvasSize.width * CGFloat(i) / 4
                    let x = baseX + sin(time * 0.1 + Double(i) * 1.5) * 100
                    let y = canvasSize.height * 0.3 + cos(time * 0.08 + Double(i)) * 50
                    let fogSize = canvasSize.width * 0.4

                    let pulse = sin(time * 0.2 + Double(i) * 0.8) * 0.2 + 0.8

                    let rect = CGRect(
                        x: x - fogSize / 2,
                        y: y - fogSize / 3,
                        width: fogSize,
                        height: fogSize * 0.6
                    )

                    context.fill(
                        Ellipse().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color(hex: "7B2FFF").opacity(0.08 * pulse),
                                Color(hex: "00D4FF").opacity(0.04 * pulse),
                                .clear
                            ]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: fogSize / 2
                        )
                    )
                }
            }
        }
    }

    // MARK: - 赛博雾气层
    private func cyberFogLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in fogParticles {
                    let windEffect = sin(windPhase + particle.phase) * 30 * cloudDensity.windStrength
                    let progress = (time * particle.speed).truncatingRemainder(dividingBy: Double(canvasSize.width + particle.size * 2))
                    let currentX = (particle.x + CGFloat(progress) + CGFloat(windEffect)).truncatingRemainder(dividingBy: canvasSize.width + particle.size) - particle.size / 2
                    let floatY = particle.y + sin(time * 0.4 + particle.phase) * 25

                    let pulse = sin(time * particle.pulseSpeed + particle.phase) * 0.3 + 0.7

                    let rect = CGRect(
                        x: currentX - particle.size / 2,
                        y: floatY - particle.size / 3,
                        width: particle.size,
                        height: particle.size * 0.6
                    )

                    context.fill(
                        Ellipse().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                particle.color.opacity(particle.opacity * 0.4 * pulse),
                                particle.color.opacity(particle.opacity * 0.15 * pulse),
                                .clear
                            ]),
                            center: CGPoint(x: currentX, y: floatY),
                            startRadius: 0,
                            endRadius: particle.size / 2
                        )
                    )
                }
            }
        }
    }

    // MARK: - 闪电覆盖层
    private var lightningOverlay: some View {
        Rectangle()
            .fill(Color.white.opacity(lightningFlash))
            .allowsHitTesting(false)
    }

    // MARK: - 霓虹光晕层
    private func neonGlowLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 顶部霓虹光晕
                let pulseTop = sin(time * 0.5) * 0.2 + 0.8
                let colorShiftTop = sin(time * 0.3)

                context.fill(
                    Path(CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height * 0.35)),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: colorShiftTop > 0 ? "7B2FFF" : "00D4FF").opacity(0.18 * pulseTop),
                            Color(hex: "00D4FF").opacity(0.1 * pulseTop),
                            Color(hex: "FF00FF").opacity(0.04 * pulseTop),
                            .clear
                        ]),
                        startPoint: CGPoint(x: canvasSize.width/2, y: 0),
                        endPoint: CGPoint(x: canvasSize.width/2, y: canvasSize.height * 0.35)
                    )
                )

                // 底部霓虹反光
                let pulseBottom = sin(time * 0.7 + 1) * 0.2 + 0.8
                let colorShiftBottom = cos(time * 0.4)

                context.fill(
                    Path(CGRect(x: 0, y: canvasSize.height * 0.65, width: canvasSize.width, height: canvasSize.height * 0.35)),
                    with: .linearGradient(
                        Gradient(colors: [
                            .clear,
                            Color(hex: "FF00FF").opacity(0.06 * pulseBottom),
                            Color(hex: colorShiftBottom > 0 ? "00D4FF" : "7B2FFF").opacity(0.12 * pulseBottom)
                        ]),
                        startPoint: CGPoint(x: canvasSize.width/2, y: canvasSize.height * 0.65),
                        endPoint: CGPoint(x: canvasSize.width/2, y: canvasSize.height)
                    )
                )
            }
        }
    }

    // MARK: - 扫描线效果
    private func scanLineEffect(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                // 缓慢移动的扫描线
                let scanY = (CGFloat(time * 30).truncatingRemainder(dividingBy: canvasSize.height + 100)) - 50

                let scanRect = CGRect(x: 0, y: scanY - 30, width: canvasSize.width, height: 60)
                context.fill(
                    Rectangle().path(in: scanRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            .clear,
                            Color(hex: "00D4FF").opacity(0.03),
                            Color.white.opacity(0.05),
                            Color(hex: "00D4FF").opacity(0.03),
                            .clear
                        ]),
                        startPoint: CGPoint(x: canvasSize.width/2, y: scanY - 30),
                        endPoint: CGPoint(x: canvasSize.width/2, y: scanY + 30)
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 风力动画
    private func startWindAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            let time = Date.timeIntervalSinceReferenceDate
            windPhase = time * 0.5
        }
    }

    // MARK: - 生成云朵数据
    private func generateClouds(in size: CGSize) {
        let neonColors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "7B2FFF"),
            Color(hex: "FF00FF"),
            Color(hex: "00FF88"),
            Color(hex: "FFD700")
        ]

        clouds = (0..<cloudDensity.cloudCount).map { index in
            let layer = index % 4  // 0=最远, 1=远, 2=中, 3=近
            let scale: CGFloat = [0.5, 0.7, 0.85, 1.0][layer]
            let speed: CGFloat = [0.2, 0.35, 0.55, 0.8][layer]
            let opacity = cloudDensity.opacity * [0.35, 0.5, 0.7, 0.9][layer]

            return CloudData(
                id: index,
                x: CGFloat.random(in: -0.3...1.3) * size.width,
                y: CGFloat.random(in: 0.03...0.55) * size.height,
                width: CGFloat.random(in: 140...320) * scale,
                height: CGFloat.random(in: 55...130) * scale,
                speed: CGFloat.random(in: 12...28) * speed,
                opacity: opacity,
                layer: layer,
                neonColor: neonColors.randomElement()!,
                morphPhase: Double.random(in: 0...(.pi * 2)),
                morphSpeed: Double.random(in: 0.3...0.8)
            )
        }
    }

    // MARK: - 生成光线数据
    private func generateLightRays(in size: CGSize) {
        let rayColors: [Color] = [
            Color(hex: "FFD700"),
            Color(hex: "00D4FF"),
            Color(hex: "FF00FF")
        ]

        lightRays = (0..<6).map { index in
            LightRay(
                id: index,
                x: size.width * CGFloat.random(in: 0.15...0.85),
                width: CGFloat.random(in: 25...55),
                opacity: Double.random(in: 0.25...0.55),
                shimmerSpeed: Double.random(in: 0.4...1.2),
                phase: Double.random(in: 0...(.pi * 2)),
                color: rayColors.randomElement()!
            )
        }
    }

    // MARK: - 生成雾气粒子
    private func generateFogParticles(in size: CGSize) {
        let fogColors: [Color] = [
            Color(hex: "7B2FFF"),
            Color(hex: "00D4FF"),
            Color(hex: "FF00FF"),
            Color(hex: "00FF88")
        ]

        fogParticles = (0..<cloudDensity.fogDensity).map { index in
            CyberFogParticle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: size.height * CGFloat.random(in: 0.45...0.92),
                size: CGFloat.random(in: 80...220),
                speed: Double.random(in: 8...22),
                opacity: Double.random(in: 0.25...0.55),
                phase: Double.random(in: 0...(.pi * 2)),
                color: fogColors.randomElement()!,
                pulseSpeed: Double.random(in: 0.5...1.5)
            )
        }
    }

    // MARK: - 生成云内闪烁
    private func generateCloudSparkles(in size: CGSize) {
        let sparkleColors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "FF00FF"),
            Color(hex: "FFD700"),
            Color.white
        ]

        cloudSparkles = (0..<25).map { index in
            CloudSparkle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.5),
                size: CGFloat.random(in: 3...8),
                pulseSpeed: Double.random(in: 2...6),
                phase: Double.random(in: 0...(.pi * 2)),
                maxOpacity: Double.random(in: 0.4...0.8),
                color: sparkleColors.randomElement()!
            )
        }
    }

    // MARK: - 生成闪电
    private func generateLightningBolts(in size: CGSize) {
        let boltColors: [Color] = [
            Color(hex: "00D4FF"),
            Color(hex: "7B2FFF"),
            Color(hex: "FFD700")
        ]

        lightningBolts = (0..<4).map { index in
            let startX = size.width * CGFloat.random(in: 0.2...0.8)
            return LightningBolt(
                id: index,
                startPoint: CGPoint(x: startX, y: size.height * 0.1),
                endPoint: CGPoint(x: startX + CGFloat.random(in: -50...50), y: size.height * 0.55),
                color: boltColors.randomElement()!,
                interval: Double.random(in: 4...12)
            )
        }
    }

    // MARK: - 闪电计时器
    private func startLightningTimer() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: true) { timer in
            // 闪电闪烁序列
            withAnimation(.easeIn(duration: 0.05)) {
                lightningFlash = Double.random(in: 0.25...0.5)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    lightningFlash = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if Bool.random() {
                    withAnimation(.easeIn(duration: 0.05)) {
                        lightningFlash = Double.random(in: 0.15...0.35)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            lightningFlash = 0
                        }
                    }
                }
            }
            timer.fireDate = Date().addingTimeInterval(Double.random(in: 3...10))
        }
    }

    // MARK: - 绘制单个云朵
    private func drawCloud(context: GraphicsContext, cloud: CloudData, time: TimeInterval, canvasSize: CGSize) {
        // 计算当前位置（循环移动 + 风力影响）
        let windEffect = sin(windPhase + cloud.morphPhase) * 15 * cloudDensity.windStrength
        let progress = (time * Double(cloud.speed)).truncatingRemainder(dividingBy: Double(canvasSize.width + cloud.width * 2))
        let currentX = (cloud.x + CGFloat(progress) + CGFloat(windEffect)).truncatingRemainder(dividingBy: canvasSize.width + cloud.width) - cloud.width / 2

        // 形变动画
        let morphFactor = sin(time * cloud.morphSpeed + cloud.morphPhase) * 0.1 + 1.0
        let centerY = cloud.y + sin(time * 0.3 + cloud.morphPhase) * 8
        let baseWidth = cloud.width * CGFloat(morphFactor)
        let baseHeight = cloud.height * CGFloat(2 - morphFactor)

        // 云朵形状（更丰富的组成）
        let cloudParts: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0, 0, baseWidth * 0.55, baseHeight * 0.85),
            (-baseWidth * 0.28, baseHeight * 0.08, baseWidth * 0.42, baseHeight * 0.65),
            (baseWidth * 0.28, baseHeight * 0.08, baseWidth * 0.42, baseHeight * 0.65),
            (-baseWidth * 0.18, -baseHeight * 0.22, baseWidth * 0.38, baseHeight * 0.55),
            (baseWidth * 0.18, -baseHeight * 0.22, baseWidth * 0.38, baseHeight * 0.55),
            (-baseWidth * 0.38, baseHeight * 0.03, baseWidth * 0.32, baseHeight * 0.45),
            (baseWidth * 0.38, baseHeight * 0.03, baseWidth * 0.32, baseHeight * 0.45),
            (0, -baseHeight * 0.35, baseWidth * 0.3, baseHeight * 0.4),
        ]

        // 1. 绘制云朵外发光（霓虹效果）
        for (offsetX, offsetY, width, height) in cloudParts {
            let glowRect = CGRect(
                x: currentX + offsetX - width / 2 - 12,
                y: centerY + offsetY - height / 2 - 12,
                width: width + 24,
                height: height + 24
            )
            context.fill(
                Ellipse().path(in: glowRect),
                with: .color(cloud.neonColor.opacity(cloud.opacity * 0.12))
            )
        }

        // 2. 绘制云朵阴影
        for (offsetX, offsetY, width, height) in cloudParts {
            let shadowRect = CGRect(
                x: currentX + offsetX - width / 2,
                y: centerY + offsetY - height / 2 + 10,
                width: width,
                height: height
            )
            context.fill(
                Ellipse().path(in: shadowRect),
                with: .color(Color.black.opacity(cloud.opacity * 0.35))
            )
        }

        // 3. 绘制云朵主体（渐变填充）
        for (offsetX, offsetY, width, height) in cloudParts {
            let rect = CGRect(
                x: currentX + offsetX - width / 2,
                y: centerY + offsetY - height / 2,
                width: width,
                height: height
            )

            let gradient = Gradient(colors: [
                Color(hex: "3d3d60").opacity(cloud.opacity),
                Color(hex: "2d2d50").opacity(cloud.opacity * 0.9),
                Color(hex: "1d1d35").opacity(cloud.opacity * 0.8)
            ])

            context.fill(
                Ellipse().path(in: rect),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: rect.midX, y: rect.minY),
                    endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                )
            )
        }

        // 4. 云朵顶部高光
        let highlightRect = CGRect(
            x: currentX - baseWidth * 0.22,
            y: centerY - baseHeight * 0.45,
            width: baseWidth * 0.38,
            height: baseHeight * 0.22
        )
        context.fill(
            Ellipse().path(in: highlightRect),
            with: .linearGradient(
                Gradient(colors: [
                    Color.white.opacity(cloud.opacity * 0.25),
                    Color.white.opacity(cloud.opacity * 0.08)
                ]),
                startPoint: CGPoint(x: highlightRect.midX, y: highlightRect.minY),
                endPoint: CGPoint(x: highlightRect.midX, y: highlightRect.maxY)
            )
        )

        // 5. 云朵内部纹理
        let textureCount = cloud.layer >= 2 ? 5 : 3
        for i in 0..<textureCount {
            let tx = currentX + CGFloat.random(in: -baseWidth * 0.3...baseWidth * 0.3)
            let ty = centerY + CGFloat.random(in: -baseHeight * 0.2...baseHeight * 0.2)
            let tSize = CGFloat.random(in: 15...35)

            let textureRect = CGRect(x: tx - tSize/2, y: ty - tSize/2, width: tSize, height: tSize)
            context.fill(
                Ellipse().path(in: textureRect),
                with: .color(Color.white.opacity(cloud.opacity * 0.08))
            )
        }

        // 6. 云朵边缘霓虹描边（近景云朵）
        if cloud.layer >= 2 {
            let edgeRect = CGRect(
                x: currentX - baseWidth * 0.28,
                y: centerY - baseHeight * 0.45,
                width: baseWidth * 0.56,
                height: baseHeight * 0.9
            )
            context.stroke(
                Ellipse().path(in: edgeRect),
                with: .color(cloud.neonColor.opacity(cloud.opacity * 0.35)),
                lineWidth: 2.5
            )
        }
    }
}

// MARK: - 云朵数据
struct CloudData: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let speed: CGFloat
    let opacity: Double
    let layer: Int
    let neonColor: Color
    let morphPhase: Double
    let morphSpeed: Double
}

// MARK: - 光线数据
struct LightRay: Identifiable {
    let id: Int
    let x: CGFloat
    let width: CGFloat
    let opacity: Double
    let shimmerSpeed: Double
    let phase: Double
    let color: Color
}

// MARK: - 赛博雾气粒子数据
struct CyberFogParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let speed: Double
    let opacity: Double
    let phase: Double
    let color: Color
    let pulseSpeed: Double
}

// MARK: - 云内闪烁数据
struct CloudSparkle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let pulseSpeed: Double
    let phase: Double
    let maxOpacity: Double
    let color: Color
}

// MARK: - 闪电数据
struct LightningBolt: Identifiable {
    let id: Int
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: Color
    let interval: Double
}

// MARK: - 预览
#Preview("少云") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a3e"), Color(hex: "0a0a1a")],
            startPoint: .top,
            endPoint: .bottom
        )
        CloudyAnimation(cloudDensity: .light)
    }
    .ignoresSafeArea()
}

#Preview("多云") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a3e"), Color(hex: "0a0a1a")],
            startPoint: .top,
            endPoint: .bottom
        )
        CloudyAnimation(cloudDensity: .medium)
    }
    .ignoresSafeArea()
}

#Preview("阴天+闪电") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "14142e"), Color(hex: "0a0a1a")],
            startPoint: .top,
            endPoint: .bottom
        )
        CloudyAnimation(cloudDensity: .heavy)
    }
    .ignoresSafeArea()
}
