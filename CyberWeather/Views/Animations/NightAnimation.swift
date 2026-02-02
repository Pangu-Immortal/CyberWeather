//
//  NightAnimation.swift
//  CyberWeather
//
//  夜晚动画增强版
//  包含月亮、星星、流星、极光、星云、萤火虫、银河效果
//  霓虹风格星空 + 赛博朋克美学 + 多彩绚丽效果
//

import SwiftUI

// MARK: - 月相
enum MoonPhase {
    case newMoon        // 新月
    case waxingCrescent // 蛾眉月
    case firstQuarter   // 上弦月
    case waxingGibbous  // 凸月
    case fullMoon       // 满月
    case waningGibbous  // 亏凸月
    case lastQuarter    // 下弦月
    case waningCrescent // 残月

    /// 根据日期计算月相
    static func current() -> MoonPhase {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        let phase = (day % 30) / 4
        return [.newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous,
                .fullMoon, .waningGibbous, .lastQuarter, .waningCrescent][phase]
    }
}

// MARK: - 夜晚动画
struct NightAnimation: View {
    let moonPhase: MoonPhase                                    // 月相

    @State private var stars: [Star] = []                       // 星星
    @State private var shootingStars: [ShootingStar] = []       // 流星
    @State private var moonGlow: CGFloat = 1.0                  // 月光呼吸
    @State private var auroraPhase: CGFloat = 0                 // 极光相位
    @State private var nebulaParticles: [NebulaParticle] = []   // 星云粒子
    @State private var fireflies: [Firefly] = []                // 萤火虫
    @State private var milkyWayStars: [MilkyWayStar] = []       // 银河星点

    init(moonPhase: MoonPhase = .current()) {
        self.moonPhase = moonPhase
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let moonSize = min(size.width, size.height) * 0.15
            let moonX = size.width * 0.75
            let moonY = size.height * 0.2

            ZStack {
                // 1. 银河层（最底层）
                milkyWayLayer(size: size)

                // 2. 星云层
                nebulaLayer(size: size)

                // 3. 极光层（增强版）
                enhancedAuroraLayer(size: size)

                // 4. 星星和流星层
                TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                    Canvas { context, canvasSize in
                        let time = timeline.date.timeIntervalSinceReferenceDate

                        // 绘制银河星点
                        for star in milkyWayStars {
                            drawMilkyWayStar(context: context, star: star, time: time)
                        }

                        // 绘制星云粒子
                        for particle in nebulaParticles {
                            drawNebulaParticle(context: context, particle: particle, time: time)
                        }

                        // 绘制星星
                        for star in stars {
                            drawStar(context: context, star: star, time: time)
                        }

                        // 绘制流星
                        for shootingStar in shootingStars {
                            drawShootingStar(context: context, star: shootingStar, time: time, canvasSize: canvasSize)
                        }

                        // 绘制萤火虫
                        for firefly in fireflies {
                            drawFirefly(context: context, firefly: firefly, time: time, canvasSize: canvasSize)
                        }
                    }
                }

                // 5. 月亮
                MoonView(
                    phase: moonPhase,
                    size: moonSize,
                    glowScale: moonGlow
                )
                .position(x: moonX, y: moonY)

                // 6. 星座连线装饰
                constellationDecoration(size: size)

                // 7. 多彩星云光斑
                colorfulNebulaSpots(size: size)

                // 8. 底部城市轮廓光晕
                cityGlow(size: size)
            }
            .onAppear {
                generateStars(in: size, moonX: moonX, moonY: moonY, moonSize: moonSize)
                generateShootingStars(in: size)
                generateNebulaParticles(in: size)
                generateFireflies(in: size)
                generateMilkyWay(in: size)

                // 月光呼吸效果
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    moonGlow = 1.25
                }

                // 极光动画
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    auroraPhase = .pi * 2
                }
            }
        }
        .drawingGroup()
    }

    // MARK: - 银河层
    private func milkyWayLayer(size: CGSize) -> some View {
        MilkyWayCanvas()
    }

    // MARK: - 生成银河星点
    private func generateMilkyWay(in size: CGSize) {
        milkyWayStars = (0..<150).map { index in
            // 沿银河带分布
            let xProgress = CGFloat.random(in: 0...1)
            let baseY = size.height * 0.15 + xProgress * size.height * 0.35
            let scatter = CGFloat.random(in: -40...40)

            return MilkyWayStar(
                id: index,
                x: xProgress * size.width + CGFloat.random(in: -20...20),
                y: baseY + scatter,
                size: CGFloat.random(in: 0.5...2.5),
                brightness: Double.random(in: 0.3...1.0),
                twinkleSpeed: Double.random(in: 1...4),
                phase: Double.random(in: 0...(.pi * 2)),
                color: [
                    Color.white,
                    Color(hex: "00D4FF"),
                    Color(hex: "7B2FFF"),
                    Color(hex: "FF00FF"),
                    Color(hex: "FFD700")
                ].randomElement()!
            )
        }
    }

    // MARK: - 绘制银河星点
    private func drawMilkyWayStar(context: GraphicsContext, star: MilkyWayStar, time: TimeInterval) {
        let twinkle = sin(time * star.twinkleSpeed + star.phase) * 0.4 + 0.6
        let opacity = star.brightness * twinkle

        let rect = CGRect(
            x: star.x - star.size / 2,
            y: star.y - star.size / 2,
            width: star.size,
            height: star.size
        )

        context.fill(
            Circle().path(in: rect),
            with: .color(star.color.opacity(opacity))
        )
    }

    // MARK: - 生成萤火虫
    private func generateFireflies(in size: CGSize) {
        fireflies = (0..<25).map { index in
            Firefly(
                id: index,
                baseX: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                baseY: CGFloat.random(in: size.height * 0.5...size.height * 0.85),
                size: CGFloat.random(in: 3...8),
                color: [
                    Color(hex: "00E400"),   // 绿色
                    Color(hex: "00D4FF"),   // 蓝色
                    Color(hex: "FFD700"),   // 金色
                    Color(hex: "FF00FF")    // 粉色
                ].randomElement()!,
                floatSpeedX: Double.random(in: 0.3...1.0),
                floatSpeedY: Double.random(in: 0.2...0.8),
                floatAmplitudeX: CGFloat.random(in: 30...80),
                floatAmplitudeY: CGFloat.random(in: 20...50),
                blinkSpeed: Double.random(in: 1.5...4.0),
                blinkPhase: Double.random(in: 0...(.pi * 2)),
                phase: Double.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - 绘制萤火虫
    private func drawFirefly(context: GraphicsContext, firefly: Firefly, time: TimeInterval, canvasSize: CGSize) {
        // 漂浮位置
        let floatX = sin(time * firefly.floatSpeedX + firefly.phase) * firefly.floatAmplitudeX
        let floatY = cos(time * firefly.floatSpeedY + firefly.phase) * firefly.floatAmplitudeY

        let x = firefly.baseX + floatX
        let y = firefly.baseY + floatY

        // 闪烁效果（模拟萤火虫发光）
        let blink = sin(time * firefly.blinkSpeed + firefly.blinkPhase)
        let isGlowing = blink > 0.3
        let glowIntensity = isGlowing ? (blink - 0.3) / 0.7 : 0

        if glowIntensity > 0 {
            // 外发光
            let glowSize = firefly.size * 6 * CGFloat(glowIntensity)
            let glowRect = CGRect(
                x: x - glowSize / 2,
                y: y - glowSize / 2,
                width: glowSize,
                height: glowSize
            )

            context.fill(
                Circle().path(in: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        firefly.color.opacity(0.6 * glowIntensity),
                        firefly.color.opacity(0.2 * glowIntensity),
                        .clear
                    ]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: glowSize / 2
                )
            )

            // 主体发光点
            let mainSize = firefly.size * CGFloat(0.5 + glowIntensity * 0.5)
            let mainRect = CGRect(
                x: x - mainSize / 2,
                y: y - mainSize / 2,
                width: mainSize,
                height: mainSize
            )

            context.fill(
                Circle().path(in: mainRect),
                with: .color(Color.white.opacity(0.9 * glowIntensity))
            )
        }

        // 萤火虫身体（始终可见但较暗）
        let bodyRect = CGRect(
            x: x - firefly.size * 0.3,
            y: y - firefly.size * 0.3,
            width: firefly.size * 0.6,
            height: firefly.size * 0.6
        )

        context.fill(
            Circle().path(in: bodyRect),
            with: .color(firefly.color.opacity(0.3 + glowIntensity * 0.4))
        )
    }

    // MARK: - 多彩星云光斑
    private func colorfulNebulaSpots(size: CGSize) -> some View {
        ColorfulNebulaSpotsCanvas()
    }

    // MARK: - 增强极光层
    private func enhancedAuroraLayer(size: CGSize) -> some View {
        EnhancedAuroraCanvas()
    }

    // MARK: - 星云层
    private func nebulaLayer(size: CGSize) -> some View {
        NebulaCanvas()
    }


    // MARK: - 星座连线装饰
    private func constellationDecoration(size: CGSize) -> some View {
        ConstellationCanvas(size: size)
    }

    // MARK: - 城市轮廓光晕
    private func cityGlow(size: CGSize) -> some View {
        LinearGradient(
            colors: [
                .clear,
                Color(hex: "FF00FF").opacity(0.03),
                Color(hex: "7B2FFF").opacity(0.06),
                Color(hex: "00D4FF").opacity(0.08)
            ],
            startPoint: UnitPoint(x: 0.5, y: 0.85),
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    // MARK: - 生成星星
    private func generateStars(in size: CGSize, moonX: CGFloat, moonY: CGFloat, moonSize: CGFloat) {
        stars = (0..<120).compactMap { index in
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height * 0.75)

            // 避免在月亮区域生成星星
            let distanceToMoon = sqrt(pow(x - moonX, 2) + pow(y - moonY, 2))
            if distanceToMoon < moonSize * 1.5 {
                return nil
            }

            return Star(
                id: index,
                x: x,
                y: y,
                size: CGFloat.random(in: 1...5),
                baseOpacity: Double.random(in: 0.3...1.0),
                twinkleSpeed: Double.random(in: 1...5),
                twinklePhase: Double.random(in: 0...(.pi * 2)),
                color: [
                    Color.white,
                    Color(hex: "00D4FF"),
                    Color(hex: "FFD700"),
                    Color(hex: "FF00FF"),
                    Color(hex: "7B2FFF")
                ].randomElement()!
            )
        }
    }

    // MARK: - 生成流星
    private func generateShootingStars(in size: CGSize) {
        shootingStars = (0..<5).map { index in
            ShootingStar(
                id: index,
                startX: CGFloat.random(in: size.width * 0.3...size.width),
                startY: CGFloat.random(in: 0...size.height * 0.3),
                length: CGFloat.random(in: 100...200),
                angle: Double.random(in: 200...250) * .pi / 180,
                speed: CGFloat.random(in: 400...700),
                duration: Double.random(in: 0.4...0.8),
                interval: Double.random(in: 4...12),
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...8),
                trailColor: [Color(hex: "00D4FF"), Color(hex: "7B2FFF"), Color.white].randomElement()!
            )
        }
    }

    // MARK: - 生成星云粒子
    private func generateNebulaParticles(in size: CGSize) {
        nebulaParticles = (0..<30).map { index in
            NebulaParticle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height * 0.6),
                size: CGFloat.random(in: 2...6),
                driftSpeed: Double.random(in: 0.1...0.3),
                phase: Double.random(in: 0...(.pi * 2)),
                color: [Color(hex: "00D4FF"), Color(hex: "7B2FFF"), Color(hex: "FF00FF")].randomElement()!
            )
        }
    }

    // MARK: - 绘制星云粒子
    private func drawNebulaParticle(context: GraphicsContext, particle: NebulaParticle, time: TimeInterval) {
        let offsetX = sin(time * particle.driftSpeed + particle.phase) * 30
        let offsetY = cos(time * particle.driftSpeed * 0.7 + particle.phase) * 20
        let pulse = sin(time * 2 + particle.phase) * 0.3 + 0.7

        let x = particle.x + CGFloat(offsetX)
        let y = particle.y + CGFloat(offsetY)

        // 外发光
        let glowRect = CGRect(
            x: x - particle.size * 3,
            y: y - particle.size * 3,
            width: particle.size * 6,
            height: particle.size * 6
        )
        context.fill(
            Circle().path(in: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    particle.color.opacity(0.3 * pulse),
                    .clear
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: particle.size * 3
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
            with: .color(particle.color.opacity(0.6 * pulse))
        )
    }

    // MARK: - 绘制星星
    private func drawStar(context: GraphicsContext, star: Star, time: TimeInterval) {
        // 闪烁效果
        let twinkle = sin(time * star.twinkleSpeed + star.twinklePhase)
        let opacity = star.baseOpacity * (0.5 + twinkle * 0.5)

        let rect = CGRect(
            x: star.x - star.size / 2,
            y: star.y - star.size / 2,
            width: star.size,
            height: star.size
        )

        // 星星发光
        if star.size > 2 {
            let glowRect = rect.insetBy(dx: -star.size * 1.5, dy: -star.size * 1.5)
            context.fill(
                Circle().path(in: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        star.color.opacity(opacity * 0.4),
                        .clear
                    ]),
                    center: CGPoint(x: star.x, y: star.y),
                    startRadius: 0,
                    endRadius: star.size * 2.5
                )
            )
        }

        // 星星主体
        context.fill(
            Circle().path(in: rect),
            with: .color(star.color.opacity(opacity))
        )

        // 十字光芒（较大的星星）
        if star.size > 3 {
            let rayLength = star.size * 3
            var horizontalPath = Path()
            horizontalPath.move(to: CGPoint(x: star.x - rayLength, y: star.y))
            horizontalPath.addLine(to: CGPoint(x: star.x + rayLength, y: star.y))

            var verticalPath = Path()
            verticalPath.move(to: CGPoint(x: star.x, y: star.y - rayLength))
            verticalPath.addLine(to: CGPoint(x: star.x, y: star.y + rayLength))

            // 对角线光芒
            var diag1 = Path()
            diag1.move(to: CGPoint(x: star.x - rayLength * 0.7, y: star.y - rayLength * 0.7))
            diag1.addLine(to: CGPoint(x: star.x + rayLength * 0.7, y: star.y + rayLength * 0.7))

            var diag2 = Path()
            diag2.move(to: CGPoint(x: star.x + rayLength * 0.7, y: star.y - rayLength * 0.7))
            diag2.addLine(to: CGPoint(x: star.x - rayLength * 0.7, y: star.y + rayLength * 0.7))

            context.stroke(horizontalPath, with: .color(star.color.opacity(opacity * 0.5)), lineWidth: 0.8)
            context.stroke(verticalPath, with: .color(star.color.opacity(opacity * 0.5)), lineWidth: 0.8)
            context.stroke(diag1, with: .color(star.color.opacity(opacity * 0.3)), lineWidth: 0.5)
            context.stroke(diag2, with: .color(star.color.opacity(opacity * 0.3)), lineWidth: 0.5)
        }
    }

    // MARK: - 绘制流星
    private func drawShootingStar(context: GraphicsContext, star: ShootingStar, time: TimeInterval, canvasSize: CGSize) {
        let elapsed = time - star.startTime
        if elapsed < 0 { return }

        let cycleTime = star.duration + star.interval
        let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleTime)

        guard cycleProgress < star.duration else { return }

        let progress = cycleProgress / star.duration

        // 流星位置
        let distance = progress * Double(star.speed) * star.duration
        let currentX = star.startX + CGFloat(distance * cos(star.angle))
        let currentY = star.startY - CGFloat(distance * sin(star.angle))

        // 流星尾巴
        let tailX = currentX - CGFloat(cos(star.angle)) * star.length
        let tailY = currentY + CGFloat(sin(star.angle)) * star.length

        // 渐隐效果
        let opacity = progress < 0.7 ? 1.0 : (1.0 - progress) / 0.3

        // 外发光（更宽）
        var outerGlowPath = Path()
        outerGlowPath.move(to: CGPoint(x: tailX, y: tailY))
        outerGlowPath.addLine(to: CGPoint(x: currentX, y: currentY))

        context.stroke(
            outerGlowPath,
            with: .linearGradient(
                Gradient(colors: [
                    .clear,
                    star.trailColor.opacity(opacity * 0.2),
                    star.trailColor.opacity(opacity * 0.4)
                ]),
                startPoint: CGPoint(x: tailX, y: tailY),
                endPoint: CGPoint(x: currentX, y: currentY)
            ),
            lineWidth: 8
        )

        // 流星发光
        var glowPath = Path()
        glowPath.move(to: CGPoint(x: tailX, y: tailY))
        glowPath.addLine(to: CGPoint(x: currentX, y: currentY))

        context.stroke(
            glowPath,
            with: .linearGradient(
                Gradient(colors: [
                    .clear,
                    star.trailColor.opacity(opacity * 0.5),
                    Color.white.opacity(opacity)
                ]),
                startPoint: CGPoint(x: tailX, y: tailY),
                endPoint: CGPoint(x: currentX, y: currentY)
            ),
            lineWidth: 4
        )

        // 流星主体
        context.stroke(
            glowPath,
            with: .linearGradient(
                Gradient(colors: [
                    .clear,
                    Color.white.opacity(opacity * 0.8),
                    Color.white.opacity(opacity)
                ]),
                startPoint: CGPoint(x: tailX, y: tailY),
                endPoint: CGPoint(x: currentX, y: currentY)
            ),
            lineWidth: 2
        )

        // 流星头部
        let headRect = CGRect(x: currentX - 4, y: currentY - 4, width: 8, height: 8)
        context.fill(
            Circle().path(in: headRect),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(opacity),
                    star.trailColor.opacity(opacity * 0.5),
                    .clear
                ]),
                center: CGPoint(x: currentX, y: currentY),
                startRadius: 0,
                endRadius: 4
            )
        )
    }
}

// MARK: - 星座画布
struct ConstellationCanvas: View {
    let size: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/10)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let twinkle = sin(time * 2) * 0.3 + 0.7

            Canvas { context, _ in
                let constellation: [(CGFloat, CGFloat)] = [
                    (0.1, 0.15), (0.15, 0.2), (0.2, 0.18),
                    (0.22, 0.25), (0.18, 0.3)
                ]

                var path = Path()
                for (i, point) in constellation.enumerated() {
                    let x = size.width * point.0
                    let y = size.height * point.1
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                context.stroke(
                    path,
                    with: .color(Color(hex: "00D4FF").opacity(0.15 * twinkle)),
                    lineWidth: 1
                )

                for point in constellation {
                    let x = size.width * point.0
                    let y = size.height * point.1
                    let rect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color(hex: "00D4FF").opacity(0.4 * twinkle))
                    )
                }
            }
        }
    }
}

// MARK: - 星云画布
struct NebulaCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let nebulaPositions: [(CGFloat, CGFloat, Color, CGFloat)] = [
                    (0.2, 0.3, Color(hex: "7B2FFF"), 150),
                    (0.7, 0.2, Color(hex: "00D4FF"), 180),
                    (0.5, 0.5, Color(hex: "FF00FF"), 120),
                    (0.3, 0.7, Color(hex: "00D4FF"), 100),
                    (0.8, 0.6, Color(hex: "7B2FFF"), 130),
                ]

                for (xRatio, yRatio, color, baseSize) in nebulaPositions {
                    let pulse = sin(time * 0.3 + Double(xRatio) * 10) * 0.2 + 0.8
                    let nebulaSize = baseSize * CGFloat(pulse)

                    let center = CGPoint(
                        x: canvasSize.width * xRatio + sin(time * 0.2 + Double(yRatio) * 5) * 20,
                        y: canvasSize.height * yRatio + cos(time * 0.15 + Double(xRatio) * 5) * 15
                    )

                    let rect = CGRect(
                        x: center.x - nebulaSize,
                        y: center.y - nebulaSize,
                        width: nebulaSize * 2,
                        height: nebulaSize * 2
                    )

                    context.fill(
                        Ellipse().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                color.opacity(0.15 * pulse),
                                color.opacity(0.05 * pulse),
                                .clear
                            ]),
                            center: center,
                            startRadius: 0,
                            endRadius: nebulaSize
                        )
                    )
                }
            }
        }
    }
}

// MARK: - 银河画布
struct MilkyWayCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                drawMilkyWayBand(context: context, canvasSize: canvasSize, time: time)
                drawMilkyWayDust(context: context, canvasSize: canvasSize, time: time)
            }
        }
    }

    private func drawMilkyWayBand(context: GraphicsContext, canvasSize: CGSize, time: TimeInterval) {
        let milkyWayPath = Path { path in
            path.move(to: CGPoint(x: 0, y: canvasSize.height * 0.1))
            path.addQuadCurve(
                to: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.5),
                control: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.3)
            )
            path.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.6))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: canvasSize.height * 0.2),
                control: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.4)
            )
            path.closeSubpath()
        }

        let shimmer = sin(time * 0.3) * 0.15 + 0.85

        context.fill(
            milkyWayPath,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: "7B2FFF").opacity(0.08 * shimmer),
                    Color(hex: "00D4FF").opacity(0.06 * shimmer),
                    Color(hex: "FF00FF").opacity(0.05 * shimmer),
                    Color(hex: "00D4FF").opacity(0.04 * shimmer)
                ]),
                startPoint: CGPoint(x: 0, y: canvasSize.height * 0.15),
                endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.55)
            )
        )
    }

    private func drawMilkyWayDust(context: GraphicsContext, canvasSize: CGSize, time: TimeInterval) {
        let shimmer = sin(time * 0.3) * 0.15 + 0.85
        let dustColors: [Color] = [Color(hex: "7B2FFF"), Color(hex: "00D4FF"), Color(hex: "FF00FF")]

        for i in 0..<20 {
            let xRatio = 0.1 + CGFloat(i % 10) * 0.08
            let x = canvasSize.width * xRatio
            let baseY = canvasSize.height * 0.2 + xRatio * canvasSize.height * 0.3
            let y = baseY + sin(time * 0.2 + Double(i)) * 20
            let dustSize: CGFloat = 30 + CGFloat(i % 5) * 10

            let dustRect = CGRect(x: x - dustSize, y: y - dustSize / 2, width: dustSize * 2, height: dustSize)

            context.fill(
                Ellipse().path(in: dustRect),
                with: .radialGradient(
                    Gradient(colors: [dustColors[i % 3].opacity(0.06 * shimmer), .clear]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: dustSize
                )
            )
        }
    }
}

// MARK: - 多彩星云光斑画布
struct ColorfulNebulaSpotsCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/15)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let spots: [(CGFloat, CGFloat, CGFloat, Color)] = [
                    (0.15, 0.25, 120, Color(hex: "FF00FF")),
                    (0.85, 0.35, 100, Color(hex: "00D4FF")),
                    (0.5, 0.15, 80, Color(hex: "7B2FFF")),
                    (0.25, 0.6, 90, Color(hex: "00E400")),
                    (0.75, 0.7, 110, Color(hex: "FFD700")),
                ]

                for (xRatio, yRatio, baseSize, color) in spots {
                    let pulse = sin(time * 0.4 + Double(xRatio + yRatio) * 5) * 0.2 + 0.8
                    let spotSize = baseSize * CGFloat(pulse)

                    let x = canvasSize.width * xRatio + sin(time * 0.2 + Double(yRatio) * 3) * 30
                    let y = canvasSize.height * yRatio + cos(time * 0.15 + Double(xRatio) * 3) * 20

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
                                color.opacity(0.12 * pulse),
                                color.opacity(0.05 * pulse),
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
}

// MARK: - 增强极光画布
struct EnhancedAuroraCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                drawAuroraWaves(context: context, canvasSize: canvasSize, time: time)
                drawAuroraPillars(context: context, canvasSize: canvasSize, time: time)
            }
        }
    }

    // 绘制极光波浪
    private func drawAuroraWaves(context: GraphicsContext, canvasSize: CGSize, time: TimeInterval) {
        let waveCount = 6
        let baseY = canvasSize.height * 0.2

        let auroraColors: [[Color]] = [
            [Color(hex: "00E400"), Color(hex: "00FF80")],
            [Color(hex: "00D4FF"), Color(hex: "00FFFF")],
            [Color(hex: "7B2FFF"), Color(hex: "9B4FFF")],
            [Color(hex: "FF00FF"), Color(hex: "FF69B4")],
            [Color(hex: "FFD700"), Color(hex: "FFA500")],
            [Color(hex: "00E400"), Color(hex: "00D4FF")]
        ]

        for wave in 0..<waveCount {
            let waveOffset = CGFloat(wave) / CGFloat(waveCount)
            let colors = auroraColors[wave % auroraColors.count]

            var path = Path()
            path.move(to: CGPoint(x: 0, y: canvasSize.height))

            for x in stride(from: 0, through: canvasSize.width, by: 3) {
                let progress = x / canvasSize.width
                let wave1 = sin((progress + time * 0.1 + Double(waveOffset)) * .pi * 2) * 50
                let wave2 = sin((progress + time * 0.15 + Double(waveOffset) * 2) * .pi * 3) * 30
                let wave3 = sin((progress + time * 0.08 + Double(waveOffset) * 3) * .pi * 4) * 20
                let wave4 = sin((progress + time * 0.2 + Double(waveOffset) * 4) * .pi * 5) * 10
                let y = baseY + CGFloat(wave1 + wave2 + wave3 + wave4) + CGFloat(wave) * 25

                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
            path.closeSubpath()

            let opacity = 0.1 - Double(wave) * 0.012

            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        colors[0].opacity(opacity),
                        colors[1].opacity(opacity * 0.6),
                        colors[0].opacity(opacity * 0.3),
                        .clear
                    ]),
                    startPoint: CGPoint(x: canvasSize.width / 2, y: baseY),
                    endPoint: CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.65)
                )
            )
        }
    }

    // 绘制极光光柱
    private func drawAuroraPillars(context: GraphicsContext, canvasSize: CGSize, time: TimeInterval) {
        let auroraColors: [Color] = [
            Color(hex: "00E400"), Color(hex: "00D4FF"), Color(hex: "7B2FFF"),
            Color(hex: "FF00FF"), Color(hex: "FFD700"), Color(hex: "00E400")
        ]

        for i in 0..<12 {
            let baseX = canvasSize.width * CGFloat(i) / 11
            let sway = sin(time * 0.5 + Double(i) * 0.5) * 30
            let x = baseX + CGFloat(sway)

            let pillarHeight = canvasSize.height * 0.4 * (0.5 + sin(time * 0.3 + Double(i)) * 0.3)
            let pillarWidth: CGFloat = 15 + CGFloat(sin(time * 0.4 + Double(i))) * 8

            var pillarPath = Path()
            pillarPath.move(to: CGPoint(x: x - pillarWidth / 2, y: 0))
            pillarPath.addLine(to: CGPoint(x: x + pillarWidth / 2, y: 0))
            pillarPath.addLine(to: CGPoint(x: x + pillarWidth * 0.3, y: pillarHeight))
            pillarPath.addLine(to: CGPoint(x: x - pillarWidth * 0.3, y: pillarHeight))
            pillarPath.closeSubpath()

            let pillarColor = auroraColors[i % auroraColors.count]
            let pillarOpacity = 0.05 + sin(time * 0.6 + Double(i)) * 0.025

            context.fill(
                pillarPath,
                with: .linearGradient(
                    Gradient(colors: [
                        pillarColor.opacity(pillarOpacity),
                        pillarColor.opacity(pillarOpacity * 0.3),
                        .clear
                    ]),
                    startPoint: CGPoint(x: x, y: 0),
                    endPoint: CGPoint(x: x, y: pillarHeight)
                )
            )
        }
    }
}

// MARK: - 月亮视图
struct MoonView: View {
    let phase: MoonPhase
    let size: CGFloat
    let glowScale: CGFloat

    var body: some View {
        ZStack {
            // 外层光晕（多层）
            ForEach(0..<3, id: \.self) { layer in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                [Color(hex: "00D4FF"), Color(hex: "7B2FFF"), Color(hex: "FF00FF")][layer].opacity(0.15 - Double(layer) * 0.04),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * (0.5 + CGFloat(layer) * 0.2),
                            endRadius: size * (1.5 + CGFloat(layer) * 0.5)
                        )
                    )
                    .frame(width: size * (3 + CGFloat(layer)), height: size * (3 + CGFloat(layer)))
                    .scaleEffect(glowScale)
            }

            // 月亮主体
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "F0F0F0"),
                            Color(hex: "D8D8D8"),
                            Color(hex: "C0C0C0"),
                            Color(hex: "A8A8A8")
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    MoonSurfaceView(size: size)
                )
                .overlay(
                    MoonPhaseShadow(phase: phase, size: size)
                )
                .shadow(color: Color(hex: "00D4FF").opacity(0.6), radius: 25)
                .shadow(color: Color(hex: "7B2FFF").opacity(0.4), radius: 40)
                .shadow(color: Color.white.opacity(0.3), radius: 15)
        }
    }
}

// MARK: - 月球表面纹理
struct MoonSurfaceView: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, _ in
            // 模拟月球环形山（更多细节）
            let craters: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (0.3, 0.25, 0.1, 0.4),
                (0.6, 0.35, 0.14, 0.35),
                (0.45, 0.55, 0.12, 0.4),
                (0.7, 0.6, 0.07, 0.45),
                (0.25, 0.7, 0.08, 0.4),
                (0.55, 0.75, 0.06, 0.35),
                (0.35, 0.4, 0.05, 0.3),
                (0.65, 0.45, 0.04, 0.35),
                (0.5, 0.3, 0.06, 0.3),
            ]

            for (xRatio, yRatio, sizeRatio, opacity) in craters {
                let craterSize = size * sizeRatio
                let rect = CGRect(
                    x: size * xRatio - craterSize / 2,
                    y: size * yRatio - craterSize / 2,
                    width: craterSize,
                    height: craterSize
                )

                // 环形山阴影
                context.fill(
                    Circle().path(in: rect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(hex: "808080").opacity(opacity),
                            Color(hex: "909090").opacity(opacity * 0.5),
                            .clear
                        ]),
                        center: CGPoint(x: size * xRatio, y: size * yRatio),
                        startRadius: 0,
                        endRadius: craterSize / 2
                    )
                )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - 月相阴影
struct MoonPhaseShadow: View {
    let phase: MoonPhase
    let size: CGFloat

    var body: some View {
        Canvas { context, _ in
            switch phase {
            case .fullMoon:
                break                                           // 满月无阴影

            case .newMoon:
                // 新月几乎全黑
                context.fill(
                    Circle().path(in: CGRect(x: 0, y: 0, width: size, height: size)),
                    with: .color(Color.black.opacity(0.92))
                )

            case .firstQuarter, .lastQuarter:
                // 半月
                var path = Path()
                path.addArc(
                    center: CGPoint(x: size/2, y: size/2),
                    radius: size/2,
                    startAngle: .degrees(phase == .firstQuarter ? -90 : 90),
                    endAngle: .degrees(phase == .firstQuarter ? 90 : 270),
                    clockwise: false
                )
                path.closeSubpath()
                context.fill(path, with: .color(Color.black.opacity(0.85)))

            default:
                // 其他月相使用渐变模拟
                let offset: CGFloat = {
                    switch phase {
                    case .waxingCrescent: return size * 0.35
                    case .waxingGibbous: return -size * 0.35
                    case .waningGibbous: return -size * 0.35
                    case .waningCrescent: return size * 0.35
                    default: return 0
                    }
                }()

                let shadowRect = CGRect(x: offset, y: 0, width: size, height: size)
                context.fill(
                    Circle().path(in: shadowRect),
                    with: .color(Color.black.opacity(0.85))
                )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - 星星数据
struct Star: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let baseOpacity: Double
    let twinkleSpeed: Double
    let twinklePhase: Double
    let color: Color
}

// MARK: - 流星数据
struct ShootingStar: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let length: CGFloat
    let angle: Double
    let speed: CGFloat
    let duration: Double
    let interval: Double
    let startTime: TimeInterval
    let trailColor: Color                                       // 尾迹颜色
}

// MARK: - 星云粒子数据
struct NebulaParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let driftSpeed: Double
    let phase: Double
    let color: Color
}

// MARK: - 萤火虫数据
struct Firefly: Identifiable {
    let id: Int
    let baseX: CGFloat                  // 基础X位置
    let baseY: CGFloat                  // 基础Y位置
    let size: CGFloat                   // 大小
    let color: Color                    // 发光颜色
    let floatSpeedX: Double             // X轴漂浮速度
    let floatSpeedY: Double             // Y轴漂浮速度
    let floatAmplitudeX: CGFloat        // X轴漂浮幅度
    let floatAmplitudeY: CGFloat        // Y轴漂浮幅度
    let blinkSpeed: Double              // 闪烁速度
    let blinkPhase: Double              // 闪烁相位
    let phase: Double                   // 漂浮相位
}

// MARK: - 银河星点数据
struct MilkyWayStar: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let brightness: Double
    let twinkleSpeed: Double
    let phase: Double
    let color: Color
}

// MARK: - 预览
#Preview("满月") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "0d0d2b"), Color(hex: "050514"), Color(hex: "000008")],
            startPoint: .top,
            endPoint: .bottom
        )
        NightAnimation(moonPhase: .fullMoon)
    }
    .ignoresSafeArea()
}

#Preview("新月") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "0a0a20"), Color(hex: "030310"), Color(hex: "000005")],
            startPoint: .top,
            endPoint: .bottom
        )
        NightAnimation(moonPhase: .newMoon)
    }
    .ignoresSafeArea()
}

#Preview("上弦月") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "0d0d2b"), Color(hex: "050514"), Color(hex: "000008")],
            startPoint: .top,
            endPoint: .bottom
        )
        NightAnimation(moonPhase: .firstQuarter)
    }
    .ignoresSafeArea()
}
