//
//  ThunderAnimation.swift
//  SmartCleaner
//
//  雷暴动画 - 增强版
//  包含复杂分叉闪电、风暴云层、雨滴
//  球形闪电、地面照明、电弧效果
//  赛博朋克霓虹风格
//

import SwiftUI

// MARK: - 雷暴强度
enum ThunderIntensity {
    case mild       // 轻微
    case moderate   // 中等
    case severe     // 强烈

    var lightningCount: Int {
        switch self {
        case .mild: return 3
        case .moderate: return 6
        case .severe: return 10
        }
    }

    var rainDropCount: Int {
        switch self {
        case .mild: return 100
        case .moderate: return 200
        case .severe: return 350
        }
    }

    var cloudCount: Int {
        switch self {
        case .mild: return 4
        case .moderate: return 6
        case .severe: return 9
        }
    }

    var ballLightningCount: Int {
        switch self {
        case .mild: return 0
        case .moderate: return 1
        case .severe: return 3
        }
    }

    var electricArcCount: Int {
        switch self {
        case .mild: return 2
        case .moderate: return 5
        case .severe: return 10
        }
    }
}

// MARK: - 闪电数据
struct Lightning: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let segments: [LightningSegment]
    let duration: Double
    let interval: Double
    let startTime: TimeInterval
    let color: Color               // 闪电颜色
    let isDistant: Bool            // 是否远景闪电
}

// MARK: - 闪电线段
struct LightningSegment {
    let start: CGPoint
    let end: CGPoint
    let width: CGFloat
    let isBranch: Bool
    let branchLevel: Int           // 分支层级
}

// MARK: - 风暴云数据
struct StormCloud: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let speed: CGFloat
    let opacity: Double
    let layer: Int                 // 云层深度
    let internalGlow: Color        // 内部发光颜色
    let startTime: TimeInterval
}

// MARK: - 雨滴数据
struct ThunderRainDrop: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let length: CGFloat
    let speed: CGFloat
    let windOffset: CGFloat
    let opacity: Double
    let startTime: TimeInterval
}

// MARK: - 球形闪电数据
struct BallLightning: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let radius: CGFloat
    let color: Color
    let pulseSpeed: Double
    let driftSpeedX: CGFloat
    let driftSpeedY: CGFloat
    let lifespan: Double           // 生命周期
    let startTime: TimeInterval
}

// MARK: - 电弧数据
struct ElectricArc: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let color: Color
    let speed: Double
    let startTime: TimeInterval
}

// MARK: - 雷暴动画
struct ThunderAnimation: View {
    let intensity: ThunderIntensity

    @State private var lightnings: [Lightning] = []
    @State private var stormClouds: [StormCloud] = []
    @State private var rainDrops: [ThunderRainDrop] = []
    @State private var ballLightnings: [BallLightning] = []
    @State private var electricArcs: [ElectricArc] = []
    @State private var skyFlashOpacity: Double = 0
    @State private var skyFlashColor: Color = .white
    @State private var groundIllumination: Double = 0
    @State private var flashTimer: Timer?
    @State private var windStrength: CGFloat = 0

    // 赛博朋克色彩
    private let neonColors: [Color] = [
        Color(hex: "00D4FF"),   // 霓虹青
        Color(hex: "7B2FFF"),   // 霓虹紫
        Color(hex: "FF00FF"),   // 霓虹粉
        Color(hex: "FFD700"),   // 金色
        Color(hex: "00FF88"),   // 霓虹绿
        .white                  // 纯白
    ]

    init(intensity: ThunderIntensity = .moderate) {
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // 层1: 暴风雨天空背景
                stormSkyBackground(size: size)

                // 层2: 远景闪电（云层内）
                distantLightningCanvas(size: size)

                // 层3: 风暴云层
                stormCloudCanvas(size: size)

                // 层4: 天空闪光效果
                Rectangle()
                    .fill(skyFlashColor.opacity(skyFlashOpacity))
                    .ignoresSafeArea()

                // 层5: 主闪电
                mainLightningCanvas(size: size)

                // 层6: 球形闪电
                ballLightningCanvas(size: size)

                // 层7: 电弧效果
                electricArcCanvas(size: size)

                // 层8: 雨滴
                rainCanvas(size: size)

                // 层9: 地面照明反射
                groundIlluminationLayer(size: size)

                // 层10: 闪电余晖
                lightningAfterglowLayer(size: size)

                // 层11: 扫描线效果
                scanLineEffect(size: size)
            }
            .onAppear {
                initializeAllData(size: size)
                startFlashTimer()
                startWindAnimation()
            }
            .onDisappear {
                flashTimer?.invalidate()
            }
        }
        .drawingGroup()
    }

    // MARK: - 初始化所有数据
    private func initializeAllData(size: CGSize) {
        generateLightnings(in: size)
        generateStormClouds(in: size)
        generateRainDrops(in: size)
        generateBallLightnings(in: size)
        generateElectricArcs(in: size)
    }

    // MARK: - 暴风雨天空背景
    private func stormSkyBackground(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 动态色调变化
                let hueShift = sin(time * 0.15) * 0.03

                // 主渐变 - 深紫到黑
                let bgGradient = Gradient(colors: [
                    Color(hue: 0.75 + hueShift, saturation: 0.5, brightness: 0.15),
                    Color(hue: 0.8 + hueShift, saturation: 0.4, brightness: 0.08),
                    Color(hue: 0.85 + hueShift, saturation: 0.3, brightness: 0.04)
                ])

                context.fill(
                    Rectangle().path(in: CGRect(origin: .zero, size: canvasSize)),
                    with: .linearGradient(
                        bgGradient,
                        startPoint: CGPoint(x: canvasSize.width / 2, y: 0),
                        endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height)
                    )
                )

                // 添加暗涌效果
                for i in 0..<5 {
                    let yBase = canvasSize.height * CGFloat(i) / 5
                    let wave = sin(time * 0.3 + Double(i) * 0.5) * 30
                    let opacity = 0.03 + sin(time * 0.5 + Double(i)) * 0.02

                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: 0,
                            y: yBase + CGFloat(wave),
                            width: canvasSize.width,
                            height: canvasSize.height / 5
                        )),
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(hex: "2a1a3a").opacity(opacity),
                                .clear
                            ]),
                            startPoint: CGPoint(x: canvasSize.width / 2, y: yBase),
                            endPoint: CGPoint(x: canvasSize.width / 2, y: yBase + canvasSize.height / 5)
                        )
                    )
                }

                // 暗角
                context.fill(
                    Rectangle().path(in: CGRect(origin: .zero, size: canvasSize)),
                    with: .radialGradient(
                        Gradient(colors: [.clear, Color.black.opacity(0.5)]),
                        center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.3),
                        startRadius: canvasSize.width * 0.2,
                        endRadius: canvasSize.width
                    )
                )
            }
        }
    }

    // MARK: - 远景闪电画布
    private func distantLightningCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for lightning in lightnings.filter({ $0.isDistant }) {
                    drawDistantLightning(context: context, lightning: lightning, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制远景闪电
    private func drawDistantLightning(context: GraphicsContext, lightning: Lightning, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - lightning.startTime
        if elapsed < 0 { return }

        let cycleTime = lightning.duration + lightning.interval
        let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleTime)

        guard cycleProgress < lightning.duration else { return }

        // 闪烁效果
        let flashProgress = cycleProgress / lightning.duration
        let opacity = calculateFlashOpacity(progress: flashProgress) * 0.4 // 远景更淡

        // 简化的云内闪电发光
        for segment in lightning.segments.filter({ !$0.isBranch }) {
            let center = CGPoint(
                x: (segment.start.x + segment.end.x) / 2,
                y: (segment.start.y + segment.end.y) / 2
            )

            let glowRadius: CGFloat = 80

            context.fill(
                Circle().path(in: CGRect(
                    x: center.x - glowRadius,
                    y: center.y - glowRadius,
                    width: glowRadius * 2,
                    height: glowRadius * 2
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        lightning.color.opacity(opacity * 0.5),
                        lightning.color.opacity(opacity * 0.2),
                        .clear
                    ]),
                    center: center,
                    startRadius: 0,
                    endRadius: glowRadius
                )
            )
        }
    }

    // MARK: - 风暴云画布
    private func stormCloudCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 从远到近绘制云层
                for cloud in stormClouds.sorted(by: { $0.layer < $1.layer }) {
                    drawStormCloud(context: context, cloud: cloud, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制风暴云
    private func drawStormCloud(context: GraphicsContext, cloud: StormCloud, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - cloud.startTime

        // 云缓慢移动
        let xOffset = (elapsed * Double(cloud.speed)).truncatingRemainder(dividingBy: Double(canvasSize.width + cloud.width))
        let x = (cloud.x + CGFloat(xOffset)).truncatingRemainder(dividingBy: canvasSize.width + cloud.width) - cloud.width / 2

        // 云的形变
        let heightVariation = 1.0 + sin(elapsed * 0.2) * 0.1
        let currentHeight = cloud.height * CGFloat(heightVariation)

        // 云朵由多个椭圆组成
        let parts = 5
        for i in 0..<parts {
            let partX = x + cloud.width * CGFloat(i) / CGFloat(parts)
            let partY = cloud.y + sin(Double(i) + elapsed * 0.3) * 10
            let partWidth = cloud.width / CGFloat(parts) * 1.5
            let partHeight = currentHeight * (0.7 + CGFloat.random(in: 0...0.3))

            let rect = CGRect(
                x: partX - partWidth / 2,
                y: partY - partHeight / 2,
                width: partWidth,
                height: partHeight
            )

            // 云主体
            context.fill(
                Ellipse().path(in: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: "3a3a5a").opacity(cloud.opacity),
                        Color(hex: "2a2a4a").opacity(cloud.opacity * 0.8),
                        Color(hex: "1a1a3a").opacity(cloud.opacity * 0.5)
                    ]),
                    center: CGPoint(x: rect.midX, y: rect.midY - partHeight * 0.2),
                    startRadius: 0,
                    endRadius: partWidth / 2
                )
            )

            // 内部发光（闪电照亮）
            let glowPulse = sin(elapsed * 2 + Double(i)) * 0.5 + 0.5
            if glowPulse > 0.7 && cloud.layer > 1 {
                let glowRect = rect.insetBy(dx: rect.width * 0.2, dy: rect.height * 0.2)
                context.fill(
                    Ellipse().path(in: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            cloud.internalGlow.opacity(0.3 * glowPulse),
                            cloud.internalGlow.opacity(0.1),
                            .clear
                        ]),
                        center: CGPoint(x: glowRect.midX, y: glowRect.midY),
                        startRadius: 0,
                        endRadius: glowRect.width / 2
                    )
                )
            }
        }
    }

    // MARK: - 主闪电画布
    private func mainLightningCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for lightning in lightnings.filter({ !$0.isDistant }) {
                    drawMainLightning(context: context, lightning: lightning, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制主闪电
    private func drawMainLightning(context: GraphicsContext, lightning: Lightning, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - lightning.startTime
        if elapsed < 0 { return }

        let cycleTime = lightning.duration + lightning.interval
        let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleTime)

        guard cycleProgress < lightning.duration else { return }

        let opacity = calculateFlashOpacity(progress: cycleProgress / lightning.duration)

        // 触发天空闪光和地面照明
        if cycleProgress < 0.05 {
            DispatchQueue.main.async {
                skyFlashColor = lightning.color
                withAnimation(.easeIn(duration: 0.05)) {
                    skyFlashOpacity = 0.3
                    groundIllumination = 0.5
                }
            }
        } else if cycleProgress > lightning.duration * 0.9 {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.1)) {
                    skyFlashOpacity = 0
                    groundIllumination = 0
                }
            }
        }

        for segment in lightning.segments {
            var path = Path()
            path.move(to: segment.start)
            path.addLine(to: segment.end)

            // 根据分支层级调整宽度和透明度
            let branchFactor = 1.0 / (1.0 + CGFloat(segment.branchLevel) * 0.5)
            let segmentOpacity = opacity * Double(branchFactor)

            // 外发光（大范围霓虹）
            context.stroke(
                path,
                with: .color(lightning.color.opacity(segmentOpacity * 0.2)),
                lineWidth: segment.width * 10 * branchFactor
            )

            // 中发光
            context.stroke(
                path,
                with: .color(lightning.color.opacity(segmentOpacity * 0.4)),
                lineWidth: segment.width * 6 * branchFactor
            )

            // 内发光
            context.stroke(
                path,
                with: .color(lightning.color.opacity(segmentOpacity * 0.7)),
                lineWidth: segment.width * 3 * branchFactor
            )

            // 核心（白色）
            context.stroke(
                path,
                with: .color(Color.white.opacity(segmentOpacity)),
                lineWidth: segment.width * branchFactor
            )
        }
    }

    // MARK: - 计算闪烁透明度
    private func calculateFlashOpacity(progress: Double) -> Double {
        if progress < 0.1 {
            return progress / 0.1
        } else if progress < 0.2 {
            return 1.0
        } else if progress < 0.3 {
            return 0.3 + (0.3 - progress) / 0.1 * 0.7
        } else if progress < 0.4 {
            return 0.3
        } else if progress < 0.6 {
            return 0.3 + (progress - 0.4) / 0.2 * 0.7
        } else if progress < 0.8 {
            return 1.0
        } else {
            return 1.0 - (progress - 0.8) / 0.2
        }
    }

    // MARK: - 球形闪电画布
    private func ballLightningCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for ball in ballLightnings {
                    drawBallLightning(context: context, ball: ball, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制球形闪电
    private func drawBallLightning(context: GraphicsContext, ball: BallLightning, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - ball.startTime
        let lifeProgress = (elapsed.truncatingRemainder(dividingBy: ball.lifespan)) / ball.lifespan

        // 出现和消失的渐变
        let visibility: Double
        if lifeProgress < 0.1 {
            visibility = lifeProgress / 0.1
        } else if lifeProgress > 0.9 {
            visibility = (1.0 - lifeProgress) / 0.1
        } else {
            visibility = 1.0
        }

        // 漂移移动
        let x = ball.x + sin(elapsed * Double(ball.driftSpeedX)) * 50
        let y = ball.y + cos(elapsed * Double(ball.driftSpeedY)) * 30

        // 脉动
        let pulseScale = 1.0 + sin(elapsed * ball.pulseSpeed) * 0.3
        let radius = ball.radius * CGFloat(pulseScale)

        // 外层光晕
        let outerRadius = radius * 4
        context.fill(
            Circle().path(in: CGRect(
                x: x - outerRadius,
                y: y - outerRadius,
                width: outerRadius * 2,
                height: outerRadius * 2
            )),
            with: .radialGradient(
                Gradient(colors: [
                    ball.color.opacity(0.2 * visibility),
                    ball.color.opacity(0.05 * visibility),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: outerRadius
            )
        )

        // 中层
        let midRadius = radius * 2
        context.fill(
            Circle().path(in: CGRect(
                x: x - midRadius,
                y: y - midRadius,
                width: midRadius * 2,
                height: midRadius * 2
            )),
            with: .radialGradient(
                Gradient(colors: [
                    ball.color.opacity(0.5 * visibility),
                    ball.color.opacity(0.2 * visibility),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: midRadius
            )
        )

        // 核心
        context.fill(
            Circle().path(in: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .radialGradient(
                Gradient(colors: [
                    .white.opacity(0.9 * visibility),
                    ball.color.opacity(0.7 * visibility),
                    ball.color.opacity(0.3 * visibility)
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: radius
            )
        )

        // 电弧射线
        let arcCount = 8
        for i in 0..<arcCount {
            let angle = (Double(i) / Double(arcCount)) * .pi * 2 + elapsed * 3
            let arcLength = radius * (1.5 + sin(elapsed * 5 + Double(i)) * 0.5)

            let startX = x + cos(angle) * radius * 0.5
            let startY = y + sin(angle) * radius * 0.5
            let endX = x + cos(angle) * arcLength
            let endY = y + sin(angle) * arcLength

            var arcPath = Path()
            arcPath.move(to: CGPoint(x: startX, y: startY))

            // 添加弯曲
            let midAngle = angle + sin(elapsed * 10 + Double(i)) * 0.3
            let midX = x + cos(midAngle) * arcLength * 0.7
            let midY = y + sin(midAngle) * arcLength * 0.7

            arcPath.addQuadCurve(
                to: CGPoint(x: endX, y: endY),
                control: CGPoint(x: midX, y: midY)
            )

            context.stroke(
                arcPath,
                with: .color(ball.color.opacity(0.6 * visibility)),
                lineWidth: 2
            )
        }
    }

    // MARK: - 电弧效果画布
    private func electricArcCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for arc in electricArcs {
                    drawElectricArc(context: context, arc: arc, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制电弧
    private func drawElectricArc(context: GraphicsContext, arc: ElectricArc, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - arc.startTime

        // 电弧闪烁
        let flicker = sin(elapsed * arc.speed * 20) * 0.5 + 0.5
        guard flicker > 0.3 else { return }

        // 生成锯齿形路径
        var path = Path()
        path.move(to: CGPoint(x: arc.startX, y: arc.startY))

        let segments = 10
        let dx = (arc.endX - arc.startX) / CGFloat(segments)
        let dy = (arc.endY - arc.startY) / CGFloat(segments)

        for i in 1..<segments {
            let baseX = arc.startX + dx * CGFloat(i)
            let baseY = arc.startY + dy * CGFloat(i)
            let jitter = sin(elapsed * 50 + Double(i) * 2) * 15

            path.addLine(to: CGPoint(x: baseX + CGFloat(jitter), y: baseY))
        }

        path.addLine(to: CGPoint(x: arc.endX, y: arc.endY))

        // 发光
        context.stroke(
            path,
            with: .color(arc.color.opacity(0.3 * flicker)),
            lineWidth: 8
        )

        context.stroke(
            path,
            with: .color(arc.color.opacity(0.6 * flicker)),
            lineWidth: 4
        )

        context.stroke(
            path,
            with: .color(.white.opacity(0.8 * flicker)),
            lineWidth: 1.5
        )
    }

    // MARK: - 雨滴画布
    private func rainCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for drop in rainDrops {
                    drawRainDrop(context: context, drop: drop, time: time, canvasSize: canvasSize)
                }
            }
        }
    }

    // MARK: - 绘制雨滴
    private func drawRainDrop(context: GraphicsContext, drop: ThunderRainDrop, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - drop.startTime

        // 雨滴下落 + 风影响
        let yMove = elapsed * Double(drop.speed)
        var y = drop.y + CGFloat(yMove.truncatingRemainder(dividingBy: Double(canvasSize.height + drop.length + 50)))
        if y > canvasSize.height + drop.length {
            y -= canvasSize.height + drop.length + 50
        }

        let windEffect = windStrength * drop.windOffset
        let x = drop.x + windEffect

        // 雨滴路径（斜线）
        var path = Path()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x - windEffect * 0.3, y: y + drop.length))

        // 雨滴发光
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: "88CCFF").opacity(drop.opacity * 0.3),
                    Color(hex: "88CCFF").opacity(drop.opacity),
                    Color(hex: "88CCFF").opacity(drop.opacity * 0.5)
                ]),
                startPoint: CGPoint(x: x, y: y),
                endPoint: CGPoint(x: x - windEffect * 0.3, y: y + drop.length)
            ),
            lineWidth: 1.5
        )
    }

    // MARK: - 地面照明层
    private func groundIlluminationLayer(size: CGSize) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color(hex: "00D4FF").opacity(groundIllumination * 0.3),
                        Color(hex: "7B2FFF").opacity(groundIllumination * 0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: size.height * 0.3)
            .position(x: size.width / 2, y: size.height - size.height * 0.15)
    }

    // MARK: - 闪电余晖层
    private func lightningAfterglowLayer(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 随机位置的余晖光斑
                for i in 0..<3 {
                    let pulse = sin(time * 2 + Double(i) * 1.5) * 0.5 + 0.5
                    guard pulse > 0.6 else { continue }

                    let x = canvasSize.width * (0.2 + CGFloat(i) * 0.3)
                    let y = canvasSize.height * 0.3
                    let radius: CGFloat = 100

                    context.fill(
                        Circle().path(in: CGRect(
                            x: x - radius,
                            y: y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )),
                        with: .radialGradient(
                            Gradient(colors: [
                                neonColors[i % neonColors.count].opacity(0.1 * pulse),
                                .clear
                            ]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                }
            }
        }
    }

    // MARK: - 扫描线效果
    private func scanLineEffect(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 快速扫描线
                let scanY = (CGFloat(time * 60).truncatingRemainder(dividingBy: canvasSize.height + 50)) - 25

                context.fill(
                    Rectangle().path(in: CGRect(
                        x: 0,
                        y: scanY,
                        width: canvasSize.width,
                        height: 1
                    )),
                    with: .color(Color(hex: "00D4FF").opacity(0.2))
                )

                // 静态噪点条纹
                for i in stride(from: 0, to: Int(canvasSize.height), by: 3) {
                    let noiseOpacity = sin(time * 10 + Double(i) * 0.1) * 0.02
                    if noiseOpacity > 0 {
                        context.fill(
                            Rectangle().path(in: CGRect(
                                x: 0,
                                y: CGFloat(i),
                                width: canvasSize.width,
                                height: 1
                            )),
                            with: .color(Color.white.opacity(noiseOpacity))
                        )
                    }
                }
            }
        }
    }

    // MARK: - 生成闪电数据
    private func generateLightnings(in size: CGSize) {
        lightnings = (0..<intensity.lightningCount).map { index in
            let isDistant = index < intensity.lightningCount / 3
            let startX = CGFloat.random(in: size.width * 0.1...size.width * 0.9)
            let endY = isDistant ?
                size.height * CGFloat.random(in: 0.2...0.4) :
                size.height * CGFloat.random(in: 0.5...0.85)

            return Lightning(
                id: index,
                startX: startX,
                startY: isDistant ? CGFloat.random(in: 0...size.height * 0.1) : 0,
                segments: generateLightningPath(
                    startX: startX,
                    startY: isDistant ? CGFloat.random(in: 0...size.height * 0.1) : 0,
                    endY: endY,
                    maxBranchLevel: isDistant ? 1 : 3
                ),
                duration: Double.random(in: 0.15...0.4),
                interval: Double.random(in: 2...6),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...4),
                color: neonColors.randomElement()!,
                isDistant: isDistant
            )
        }
    }

    // MARK: - 生成闪电路径
    private func generateLightningPath(startX: CGFloat, startY: CGFloat, endY: CGFloat, maxBranchLevel: Int) -> [LightningSegment] {
        var segments: [LightningSegment] = []
        generateBranch(
            segments: &segments,
            startX: startX,
            startY: startY,
            endY: endY,
            branchLevel: 0,
            maxBranchLevel: maxBranchLevel
        )
        return segments
    }

    private func generateBranch(segments: inout [LightningSegment], startX: CGFloat, startY: CGFloat, endY: CGFloat, branchLevel: Int, maxBranchLevel: Int) {
        var currentX = startX
        var currentY = startY

        let segmentCount = Int.random(in: 8...15)
        let segmentHeight = (endY - startY) / CGFloat(segmentCount)

        for i in 0..<segmentCount {
            let jitter = CGFloat.random(in: -35...35) * (1.0 - CGFloat(branchLevel) * 0.3)
            let nextX = currentX + jitter
            let nextY = currentY + segmentHeight

            let width = max(0.5, 4 - CGFloat(i) * 0.2 - CGFloat(branchLevel) * 1.5)

            segments.append(LightningSegment(
                start: CGPoint(x: currentX, y: currentY),
                end: CGPoint(x: nextX, y: nextY),
                width: width,
                isBranch: branchLevel > 0,
                branchLevel: branchLevel
            ))

            // 生成分支
            if branchLevel < maxBranchLevel && i > 2 && i < segmentCount - 2 && Int.random(in: 0...4) == 0 {
                let branchDirection: CGFloat = Bool.random() ? 1 : -1
                let branchEndX = nextX + branchDirection * CGFloat.random(in: 40...100)
                let branchEndY = nextY + CGFloat.random(in: 30...80)

                generateBranch(
                    segments: &segments,
                    startX: nextX,
                    startY: nextY,
                    endY: branchEndY,
                    branchLevel: branchLevel + 1,
                    maxBranchLevel: maxBranchLevel
                )
            }

            currentX = nextX
            currentY = nextY
        }
    }

    // MARK: - 生成风暴云
    private func generateStormClouds(in size: CGSize) {
        stormClouds = (0..<intensity.cloudCount).map { index in
            let layer = index % 3
            return StormCloud(
                id: index,
                x: CGFloat.random(in: -size.width * 0.2...size.width),
                y: size.height * CGFloat(0.05 + Double(layer) * 0.1) + CGFloat.random(in: -20...20),
                width: CGFloat.random(in: 200...400),
                height: CGFloat.random(in: 80...150),
                speed: CGFloat.random(in: 5...15) * (1.0 - CGFloat(layer) * 0.2),
                opacity: Double(0.4 + Double(layer) * 0.15),
                layer: layer,
                internalGlow: neonColors.randomElement()!,
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }

    // MARK: - 生成雨滴
    private func generateRainDrops(in size: CGSize) {
        rainDrops = (0..<intensity.rainDropCount).map { index in
            ThunderRainDrop(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -size.height...size.height),
                length: CGFloat.random(in: 15...40),
                speed: CGFloat.random(in: 400...700),
                windOffset: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.3...0.7),
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }

    // MARK: - 生成球形闪电
    private func generateBallLightnings(in size: CGSize) {
        ballLightnings = (0..<intensity.ballLightningCount).map { index in
            BallLightning(
                id: index,
                x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                y: CGFloat.random(in: size.height * 0.3...size.height * 0.7),
                radius: CGFloat.random(in: 15...35),
                color: neonColors.randomElement()!,
                pulseSpeed: Double.random(in: 3...6),
                driftSpeedX: CGFloat.random(in: 0.3...0.8),
                driftSpeedY: CGFloat.random(in: 0.2...0.5),
                lifespan: Double.random(in: 5...10),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...3)
            )
        }
    }

    // MARK: - 生成电弧
    private func generateElectricArcs(in size: CGSize) {
        electricArcs = (0..<intensity.electricArcCount).map { index in
            ElectricArc(
                id: index,
                startX: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: size.height * 0.6...size.height * 0.9),
                endX: CGFloat.random(in: 0...size.width),
                endY: CGFloat.random(in: size.height * 0.6...size.height * 0.9),
                color: neonColors.randomElement()!,
                speed: Double.random(in: 0.5...1.5),
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }

    // MARK: - 天空闪光定时器
    private func startFlashTimer() {
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // 随机触发额外的天空闪光
            if Int.random(in: 0...40) == 0 {
                let flashColor = neonColors.randomElement()!
                withAnimation(.easeIn(duration: 0.05)) {
                    skyFlashColor = flashColor
                    skyFlashOpacity = Double.random(in: 0.15...0.35)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        skyFlashOpacity = 0
                    }
                }

                // 二次闪光
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    if Bool.random() {
                        withAnimation(.easeIn(duration: 0.03)) {
                            skyFlashOpacity = Double.random(in: 0.08...0.2)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                            withAnimation(.easeOut(duration: 0.08)) {
                                skyFlashOpacity = 0
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 风动画
    private func startWindAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            let targetWind = CGFloat.random(in: 20...60)
            withAnimation(.easeInOut(duration: 2)) {
                windStrength = targetWind
            }
        }
    }
}

// MARK: - 预览
#Preview {
    ZStack {
        Color.black
        ThunderAnimation(intensity: .severe)
    }
    .ignoresSafeArea()
}
