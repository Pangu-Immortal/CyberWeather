//
//  FoggyAnimation.swift
//  SmartCleaner
//
//  雾天动画 - 增强版
//  包含多层雾气流动、神秘光源、雾气卷须
//  极光反射、地面薄雾、赛博朋克光效
//

import SwiftUI

// MARK: - 雾气浓度
enum FogDensity {
    case light      // 薄雾
    case moderate   // 中等
    case heavy      // 浓雾

    var layerCount: Int {
        switch self {
        case .light: return 4
        case .moderate: return 6
        case .heavy: return 10
        }
    }

    var opacity: Double {
        switch self {
        case .light: return 0.35
        case .moderate: return 0.55
        case .heavy: return 0.75
        }
    }

    // 雾气卷须数量
    var tendrilCount: Int {
        switch self {
        case .light: return 5
        case .moderate: return 10
        case .heavy: return 18
        }
    }

    // 神秘光源数量
    var mysteryLightCount: Int {
        switch self {
        case .light: return 3
        case .moderate: return 5
        case .heavy: return 8
        }
    }

    // 地面雾气厚度
    var groundFogHeight: CGFloat {
        switch self {
        case .light: return 0.2
        case .moderate: return 0.35
        case .heavy: return 0.5
        }
    }

    // 漂浮颗粒数量
    var floatingParticleCount: Int {
        switch self {
        case .light: return 20
        case .moderate: return 40
        case .heavy: return 70
        }
    }
}

// MARK: - 雾气层数据
struct FogLayer: Identifiable {
    let id: Int
    let y: CGFloat
    let height: CGFloat
    let speed: CGFloat
    let waveAmplitude: CGFloat
    let waveFrequency: Double
    let opacity: Double
    let depth: CGFloat
    let color: Color
    let neonTint: Color         // 霓虹色调
    let startTime: TimeInterval
    let turbulence: Double      // 湍流强度
    let phase: Double           // 相位偏移
}

// MARK: - 雾气卷须数据
struct FogTendril: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let length: CGFloat
    let thickness: CGFloat
    let speed: Double
    let color: Color
    let curvature: Double       // 弯曲度
    let startTime: TimeInterval
}

// MARK: - 神秘光源数据
struct MysteryLight: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let color: Color
    let pulseSpeed: Double
    let driftSpeed: CGFloat
    let startTime: TimeInterval
}

// MARK: - 漂浮颗粒数据
struct FloatingParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let drift: CGFloat          // 横向漂移
    let color: Color
    let opacity: Double
    let startTime: TimeInterval
}

// MARK: - 光柱数据
struct LightBeam: Identifiable {
    let id: Int
    let x: CGFloat
    let width: CGFloat
    let color: Color
    let opacity: Double
    let swaySpeed: Double
    let startTime: TimeInterval
}

// MARK: - 雾天动画
struct FoggyAnimation: View {
    let density: FogDensity

    @State private var fogLayers: [FogLayer] = []
    @State private var tendrils: [FogTendril] = []
    @State private var mysteryLights: [MysteryLight] = []
    @State private var floatingParticles: [FloatingParticle] = []
    @State private var lightBeams: [LightBeam] = []

    // 赛博朋克色彩
    private let neonColors: [Color] = [
        Color(hex: "00D4FF"),   // 霓虹青
        Color(hex: "7B2FFF"),   // 霓虹紫
        Color(hex: "FF00FF"),   // 霓虹粉
        Color(hex: "00FF88"),   // 霓虹绿
        Color(hex: "FFD700"),   // 金色
        Color(hex: "FF6B00")    // 橙色
    ]

    init(density: FogDensity = .moderate) {
        self.density = density
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // 层1: 深空背景渐变
                deepSpaceBackground(size: size)

                // 层2: 极光反射层
                auroraReflectionLayer(size: size)

                // 层3: 远景光柱
                lightBeamCanvas(size: size)

                // 层4: 主雾气画布
                mainFogCanvas(size: size)

                // 层5: 雾气卷须画布
                tendrilCanvas(size: size)

                // 层6: 神秘光源画布
                mysteryLightCanvas(size: size)

                // 层7: 漂浮颗粒画布
                floatingParticleCanvas(size: size)

                // 层8: 地面雾气层
                groundFogLayer(size: size)

                // 层9: 顶部冷光层
                topColdGlowLayer(size: size)

                // 层10: 扫描线效果
                scanLineEffect(size: size)
            }
            .onAppear {
                initializeAllData(size: size)
            }
        }
        .drawingGroup()
    }

    // MARK: - 初始化所有数据
    private func initializeAllData(size: CGSize) {
        generateFogLayers(in: size)
        generateTendrils(in: size)
        generateMysteryLights(in: size)
        generateFloatingParticles(in: size)
        generateLightBeams(in: size)
    }

    // MARK: - 深空背景渐变
    private func deepSpaceBackground(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 动态背景色调
                let hueShift = sin(time * 0.1) * 0.05

                // 主渐变
                let bgGradient = Gradient(colors: [
                    Color(hue: 0.7 + hueShift, saturation: 0.3, brightness: 0.12),
                    Color(hue: 0.75 + hueShift, saturation: 0.25, brightness: 0.08),
                    Color(hue: 0.8 + hueShift, saturation: 0.2, brightness: 0.05)
                ])

                context.fill(
                    Rectangle().path(in: CGRect(origin: .zero, size: canvasSize)),
                    with: .linearGradient(
                        bgGradient,
                        startPoint: CGPoint(x: canvasSize.width / 2, y: 0),
                        endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height)
                    )
                )

                // 添加暗角效果
                let vignetteGradient = Gradient(colors: [
                    .clear,
                    Color.black.opacity(0.4)
                ])

                context.fill(
                    Rectangle().path(in: CGRect(origin: .zero, size: canvasSize)),
                    with: .radialGradient(
                        vignetteGradient,
                        center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
                        startRadius: canvasSize.width * 0.3,
                        endRadius: canvasSize.width * 0.9
                    )
                )
            }
        }
    }

    // MARK: - 极光反射层
    private func auroraReflectionLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 极光波浪
                for i in 0..<3 {
                    let waveOffset = Double(i) * 0.3
                    let yBase = canvasSize.height * CGFloat(0.15 + Double(i) * 0.1)

                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: yBase))

                    for x in stride(from: 0, through: canvasSize.width, by: 4) {
                        let wave1 = sin((Double(x) / 80) + time * 0.5 + waveOffset) * 30
                        let wave2 = sin((Double(x) / 120) + time * 0.3 + waveOffset) * 20
                        let y = yBase + CGFloat(wave1 + wave2)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: canvasSize.width, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.closeSubpath()

                    let auroraColor = neonColors[i % neonColors.count]
                    let opacity = 0.08 + sin(time * 0.4 + waveOffset) * 0.03

                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                auroraColor.opacity(opacity),
                                auroraColor.opacity(opacity * 0.3),
                                .clear
                            ]),
                            startPoint: CGPoint(x: canvasSize.width / 2, y: 0),
                            endPoint: CGPoint(x: canvasSize.width / 2, y: yBase + 50)
                        )
                    )
                }
            }
        }
    }

    // MARK: - 光柱画布
    private func lightBeamCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for beam in lightBeams {
                    drawLightBeam(context: context, beam: beam, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制光柱
    private func drawLightBeam(context: GraphicsContext, beam: LightBeam, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - beam.startTime
        let sway = sin(elapsed * beam.swaySpeed) * 30

        let x = beam.x + CGFloat(sway)
        let topWidth = beam.width * 0.3
        let bottomWidth = beam.width * 1.5

        var path = Path()
        path.move(to: CGPoint(x: x - topWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: x + topWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: x + bottomWidth / 2, y: canvasSize.height))
        path.addLine(to: CGPoint(x: x - bottomWidth / 2, y: canvasSize.height))
        path.closeSubpath()

        let pulseOpacity = beam.opacity * (0.7 + sin(elapsed * 2) * 0.3)

        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    beam.color.opacity(pulseOpacity * 0.8),
                    beam.color.opacity(pulseOpacity * 0.4),
                    beam.color.opacity(pulseOpacity * 0.1),
                    .clear
                ]),
                startPoint: CGPoint(x: x, y: 0),
                endPoint: CGPoint(x: x, y: canvasSize.height)
            )
        )
    }

    // MARK: - 主雾气画布
    private func mainFogCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 从远到近绘制雾气层
                for layer in fogLayers.sorted(by: { $0.depth < $1.depth }) {
                    drawEnhancedFogLayer(
                        context: context,
                        layer: layer,
                        time: time,
                        canvasSize: canvasSize
                    )
                }
            }
        }
    }

    // MARK: - 绘制增强雾气层
    private func drawEnhancedFogLayer(context: GraphicsContext, layer: FogLayer, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - layer.startTime

        // 水平移动 + 湍流
        let baseXOffset = (elapsed * Double(layer.speed)).truncatingRemainder(dividingBy: Double(canvasSize.width * 2))
        let turbulenceX = sin(elapsed * layer.turbulence + layer.phase) * 15
        let xOffset = baseXOffset + turbulenceX

        // 垂直波动
        let waveOffset = sin(elapsed * layer.waveFrequency * .pi * 2 + layer.phase) * Double(layer.waveAmplitude)

        // 创建多个重叠的雾气椭圆
        let cloudCount = 6
        let cloudWidth = canvasSize.width / 2.2

        for i in 0..<cloudCount {
            let baseX = CGFloat(i) * (canvasSize.width / CGFloat(cloudCount - 1)) - cloudWidth / 2
            let x = (baseX + CGFloat(xOffset)).truncatingRemainder(dividingBy: canvasSize.width + cloudWidth) - cloudWidth / 2

            // 多层波动
            let localWave1 = sin(Double(i) * 0.5 + elapsed * 0.3) * 25
            let localWave2 = sin(Double(i) * 0.8 + elapsed * 0.5) * 15
            let y = layer.y + CGFloat(waveOffset + localWave1 + localWave2)

            let heightVariation = 1.0 + sin(elapsed * 0.2 + Double(i)) * 0.15
            let currentHeight = layer.height * CGFloat(heightVariation)

            let rect = CGRect(
                x: x,
                y: y - currentHeight / 2,
                width: cloudWidth,
                height: currentHeight
            )

            // 主雾气渐变
            let fogGradient = Gradient(colors: [
                .clear,
                layer.color.opacity(layer.opacity * 0.4),
                layer.color.opacity(layer.opacity * 0.8),
                layer.color.opacity(layer.opacity * 0.4),
                .clear
            ])

            context.fill(
                Ellipse().path(in: rect),
                with: .linearGradient(
                    fogGradient,
                    startPoint: CGPoint(x: rect.minX, y: rect.midY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.midY)
                )
            )

            // 霓虹边缘发光（深层雾气）
            if layer.depth > 0.4 {
                let glowRect = rect.insetBy(dx: -15, dy: -8)
                let glowOpacity = layer.opacity * 0.15 * (0.7 + sin(elapsed * 1.5 + Double(i)) * 0.3)

                context.stroke(
                    Ellipse().path(in: glowRect),
                    with: .color(layer.neonTint.opacity(glowOpacity)),
                    lineWidth: 3
                )
            }

            // 内部霓虹核心（最深层）
            if layer.depth > 0.7 {
                let coreRect = rect.insetBy(dx: rect.width * 0.3, dy: rect.height * 0.35)
                let coreOpacity = 0.1 * (0.5 + sin(elapsed * 2 + Double(i) * 0.5) * 0.5)

                context.fill(
                    Ellipse().path(in: coreRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            layer.neonTint.opacity(coreOpacity),
                            .clear
                        ]),
                        center: CGPoint(x: coreRect.midX, y: coreRect.midY),
                        startRadius: 0,
                        endRadius: coreRect.width / 2
                    )
                )
            }
        }
    }

    // MARK: - 雾气卷须画布
    private func tendrilCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for tendril in tendrils {
                    drawTendril(context: context, tendril: tendril, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制雾气卷须
    private func drawTendril(context: GraphicsContext, tendril: FogTendril, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - tendril.startTime

        var path = Path()
        let segments = 20

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let baseX = tendril.startX + (cos(elapsed * tendril.speed) * 50 + tendril.length * 0.3) * t
            let baseY = tendril.startY + tendril.length * t

            // 蛇形弯曲
            let curve1 = sin(t * .pi * 3 + elapsed * tendril.speed) * CGFloat(tendril.curvature) * 40
            let curve2 = sin(t * .pi * 5 + elapsed * tendril.speed * 1.5) * CGFloat(tendril.curvature) * 20

            let x = baseX + curve1 + curve2
            let y = baseY

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        // 渐变线宽效果（通过多次绘制）
        let maxWidth = tendril.thickness
        for w in stride(from: maxWidth, through: 1, by: -2) {
            let widthRatio = w / maxWidth
            let opacity = 0.3 * widthRatio

            context.stroke(
                path,
                with: .color(tendril.color.opacity(opacity)),
                lineWidth: w
            )
        }

        // 卷须尖端发光
        if let lastPoint = path.currentPoint {
            let glowRadius: CGFloat = 15
            context.fill(
                Circle().path(in: CGRect(
                    x: lastPoint.x - glowRadius,
                    y: lastPoint.y - glowRadius,
                    width: glowRadius * 2,
                    height: glowRadius * 2
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        tendril.color.opacity(0.4),
                        tendril.color.opacity(0.1),
                        .clear
                    ]),
                    center: lastPoint,
                    startRadius: 0,
                    endRadius: glowRadius
                )
            )
        }
    }

    // MARK: - 神秘光源画布
    private func mysteryLightCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for light in mysteryLights {
                    drawMysteryLight(context: context, light: light, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制神秘光源
    private func drawMysteryLight(context: GraphicsContext, light: MysteryLight, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - light.startTime

        // 缓慢漂移
        let driftX = sin(elapsed * Double(light.driftSpeed)) * 30
        let driftY = cos(elapsed * Double(light.driftSpeed) * 0.7) * 20

        let x = light.x + CGFloat(driftX)
        let y = light.y + CGFloat(driftY)

        // 脉动半径
        let pulseScale = 1.0 + sin(elapsed * light.pulseSpeed) * 0.3
        let radius = light.radius * CGFloat(pulseScale)

        // 外发光
        let outerRadius = radius * 2.5
        context.fill(
            Circle().path(in: CGRect(
                x: x - outerRadius,
                y: y - outerRadius,
                width: outerRadius * 2,
                height: outerRadius * 2
            )),
            with: .radialGradient(
                Gradient(colors: [
                    light.color.opacity(0.15),
                    light.color.opacity(0.05),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: outerRadius
            )
        )

        // 中发光
        context.fill(
            Circle().path(in: CGRect(
                x: x - radius * 1.5,
                y: y - radius * 1.5,
                width: radius * 3,
                height: radius * 3
            )),
            with: .radialGradient(
                Gradient(colors: [
                    light.color.opacity(0.3),
                    light.color.opacity(0.1),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: radius * 1.5
            )
        )

        // 核心
        context.fill(
            Circle().path(in: CGRect(
                x: x - radius * 0.5,
                y: y - radius * 0.5,
                width: radius,
                height: radius
            )),
            with: .radialGradient(
                Gradient(colors: [
                    .white.opacity(0.8),
                    light.color.opacity(0.5),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: radius * 0.5
            )
        )

        // 光芒射线
        let rayCount = 6
        for i in 0..<rayCount {
            let angle = (Double(i) / Double(rayCount)) * .pi * 2 + elapsed * 0.2
            let rayLength = radius * 1.2
            let rayWidth: CGFloat = 2

            let startX = x + cos(angle) * radius * 0.3
            let startY = y + sin(angle) * radius * 0.3
            let endX = x + cos(angle) * rayLength
            let endY = y + sin(angle) * rayLength

            var rayPath = Path()
            rayPath.move(to: CGPoint(x: startX, y: startY))
            rayPath.addLine(to: CGPoint(x: endX, y: endY))

            context.stroke(
                rayPath,
                with: .color(light.color.opacity(0.4)),
                lineWidth: rayWidth
            )
        }
    }

    // MARK: - 漂浮颗粒画布
    private func floatingParticleCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in floatingParticles {
                    drawFloatingParticle(context: context, particle: particle, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制漂浮颗粒
    private func drawFloatingParticle(context: GraphicsContext, particle: FloatingParticle, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - particle.startTime

        // 缓慢上升 + 横向漂移
        let yMove = elapsed * Double(particle.speed)
        let xMove = sin(elapsed * 0.5 + Double(particle.id)) * Double(particle.drift)

        var y = particle.y - CGFloat(yMove.truncatingRemainder(dividingBy: Double(canvasSize.height + 50)))
        if y < -20 {
            y += canvasSize.height + 50
        }

        let x = particle.x + CGFloat(xMove)

        // 闪烁
        let twinkle = 0.5 + sin(elapsed * 3 + Double(particle.id) * 0.5) * 0.5
        let opacity = particle.opacity * twinkle

        // 颗粒本体
        context.fill(
            Circle().path(in: CGRect(
                x: x - particle.size / 2,
                y: y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )),
            with: .color(particle.color.opacity(opacity))
        )

        // 发光
        let glowSize = particle.size * 3
        context.fill(
            Circle().path(in: CGRect(
                x: x - glowSize / 2,
                y: y - glowSize / 2,
                width: glowSize,
                height: glowSize
            )),
            with: .radialGradient(
                Gradient(colors: [
                    particle.color.opacity(opacity * 0.3),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: glowSize / 2
            )
        )
    }

    // MARK: - 地面雾气层
    private func groundFogLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                let fogHeight = canvasSize.height * density.groundFogHeight
                let fogY = canvasSize.height - fogHeight

                // 波动的雾气顶部
                var topPath = Path()
                topPath.move(to: CGPoint(x: 0, y: canvasSize.height))

                for x in stride(from: 0, through: canvasSize.width, by: 3) {
                    let wave1 = sin((Double(x) / 60) + time * 0.4) * 25
                    let wave2 = sin((Double(x) / 100) + time * 0.6) * 15
                    let wave3 = sin((Double(x) / 40) + time * 0.8) * 10
                    let y = fogY + CGFloat(wave1 + wave2 + wave3)
                    topPath.addLine(to: CGPoint(x: x, y: y))
                }

                topPath.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
                topPath.closeSubpath()

                // 主雾气渐变
                context.fill(
                    topPath,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: "3a3a5a").opacity(density.opacity * 0.2),
                            Color(hex: "4a4a6a").opacity(density.opacity * 0.5),
                            Color(hex: "5a5a7a").opacity(density.opacity * 0.7),
                            Color(hex: "5a5a7a").opacity(density.opacity * 0.8)
                        ]),
                        startPoint: CGPoint(x: canvasSize.width / 2, y: fogY),
                        endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height)
                    )
                )

                // 霓虹底光
                let glowHeight: CGFloat = 60
                context.fill(
                    Rectangle().path(in: CGRect(
                        x: 0,
                        y: canvasSize.height - glowHeight,
                        width: canvasSize.width,
                        height: glowHeight
                    )),
                    with: .linearGradient(
                        Gradient(colors: [
                            .clear,
                            Color(hex: "00D4FF").opacity(0.1),
                            Color(hex: "7B2FFF").opacity(0.15)
                        ]),
                        startPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height - glowHeight),
                        endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height)
                    )
                )
            }
        }
    }

    // MARK: - 顶部冷光层
    private func topColdGlowLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 动态冷光
                let pulseOpacity = 0.08 + sin(time * 0.5) * 0.03

                context.fill(
                    Rectangle().path(in: CGRect(
                        x: 0,
                        y: 0,
                        width: canvasSize.width,
                        height: canvasSize.height * 0.35
                    )),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: "00D4FF").opacity(pulseOpacity),
                            Color(hex: "7B2FFF").opacity(pulseOpacity * 0.5),
                            .clear
                        ]),
                        startPoint: CGPoint(x: canvasSize.width / 2, y: 0),
                        endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.35)
                    )
                )
            }
        }
    }

    // MARK: - 扫描线效果
    private func scanLineEffect(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 横向扫描线
                let scanY = (CGFloat(time * 30).truncatingRemainder(dividingBy: canvasSize.height + 100)) - 50

                context.fill(
                    Rectangle().path(in: CGRect(
                        x: 0,
                        y: scanY,
                        width: canvasSize.width,
                        height: 2
                    )),
                    with: .linearGradient(
                        Gradient(colors: [
                            .clear,
                            Color(hex: "00D4FF").opacity(0.15),
                            Color(hex: "00D4FF").opacity(0.3),
                            Color(hex: "00D4FF").opacity(0.15),
                            .clear
                        ]),
                        startPoint: CGPoint(x: 0, y: scanY),
                        endPoint: CGPoint(x: canvasSize.width, y: scanY)
                    )
                )

                // 扫描线拖尾
                context.fill(
                    Rectangle().path(in: CGRect(
                        x: 0,
                        y: scanY,
                        width: canvasSize.width,
                        height: 30
                    )),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: "00D4FF").opacity(0.1),
                            .clear
                        ]),
                        startPoint: CGPoint(x: canvasSize.width / 2, y: scanY),
                        endPoint: CGPoint(x: canvasSize.width / 2, y: scanY + 30)
                    )
                )
            }
        }
    }

    // MARK: - 生成雾气层数据
    private func generateFogLayers(in size: CGSize) {
        fogLayers = (0..<density.layerCount).map { index in
            let depth = CGFloat(index) / CGFloat(density.layerCount)
            let baseOpacity = density.opacity * (0.25 + depth * 0.75)

            let fogColors: [Color] = [
                Color(hex: "2a2a4a"),
                Color(hex: "3a3a5a"),
                Color(hex: "4a4a6a"),
                Color(hex: "3a4a5a"),
                Color(hex: "4a5a6a")
            ]

            return FogLayer(
                id: index,
                y: size.height * CGFloat.random(in: 0.15...0.85),
                height: CGFloat.random(in: 100...250) * (1.0 + depth * 0.6),
                speed: CGFloat.random(in: 8...25) * (0.4 + depth * 0.6),
                waveAmplitude: CGFloat.random(in: 25...60),
                waveFrequency: Double.random(in: 0.2...0.6),
                opacity: baseOpacity,
                depth: depth,
                color: fogColors.randomElement()!,
                neonTint: neonColors.randomElement()!,
                startTime: Date.timeIntervalSinceReferenceDate,
                turbulence: Double.random(in: 0.3...1.0),
                phase: Double.random(in: 0...Double.pi * 2)
            )
        }
    }

    // MARK: - 生成雾气卷须
    private func generateTendrils(in size: CGSize) {
        tendrils = (0..<density.tendrilCount).map { index in
            FogTendril(
                id: index,
                startX: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -50...size.height * 0.3),
                length: CGFloat.random(in: 150...400),
                thickness: CGFloat.random(in: 8...20),
                speed: Double.random(in: 0.3...0.8),
                color: neonColors.randomElement()!.opacity(0.3),
                curvature: Double.random(in: 0.3...1.0),
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }

    // MARK: - 生成神秘光源
    private func generateMysteryLights(in size: CGSize) {
        mysteryLights = (0..<density.mysteryLightCount).map { index in
            MysteryLight(
                id: index,
                x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                y: CGFloat.random(in: size.height * 0.2...size.height * 0.8),
                radius: CGFloat.random(in: 20...50),
                color: neonColors.randomElement()!,
                pulseSpeed: Double.random(in: 1.5...3.0),
                driftSpeed: CGFloat.random(in: 0.1...0.3),
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }

    // MARK: - 生成漂浮颗粒
    private func generateFloatingParticles(in size: CGSize) {
        floatingParticles = (0..<density.floatingParticleCount).map { index in
            FloatingParticle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                speed: CGFloat.random(in: 5...20),
                drift: CGFloat.random(in: 20...60),
                color: neonColors.randomElement()!,
                opacity: Double.random(in: 0.3...0.8),
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }

    // MARK: - 生成光柱
    private func generateLightBeams(in size: CGSize) {
        let beamCount = density == .heavy ? 5 : (density == .moderate ? 3 : 2)

        lightBeams = (0..<beamCount).map { index in
            LightBeam(
                id: index,
                x: size.width * CGFloat(index + 1) / CGFloat(beamCount + 1),
                width: CGFloat.random(in: 40...80),
                color: neonColors.randomElement()!,
                opacity: Double.random(in: 0.05...0.12),
                swaySpeed: Double.random(in: 0.2...0.5),
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }
}

// MARK: - 预览
#Preview {
    ZStack {
        Color.black
        FoggyAnimation(density: .heavy)
    }
    .ignoresSafeArea()
}
