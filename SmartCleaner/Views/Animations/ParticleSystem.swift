//
//  ParticleSystem.swift
//  SmartCleaner
//
//  通用粒子系统
//  可复用于各种天气动画和特效
//  支持多种粒子类型：点、线、形状
//  支持自定义运动轨迹、颜色、生命周期
//

import SwiftUI

// MARK: - 粒子类型
enum ParticleType {
    case dot                // 圆点
    case line               // 线条
    case star               // 星形
    case spark              // 火花
    case snow               // 雪花
    case rain               // 雨滴
    case custom(AnyShape)   // 自定义形状
}

// MARK: - 运动模式
enum ParticleMotion {
    case fall               // 下落
    case rise               // 上升
    case float              // 漂浮
    case spiral             // 螺旋
    case radial             // 径向扩散
    case wind(CGFloat)      // 风力影响（角度）
}

// MARK: - 粒子数据
struct SystemParticle: Identifiable {
    let id: Int                                                // 唯一标识
    var x: CGFloat                                             // X坐标
    var y: CGFloat                                             // Y坐标
    var size: CGFloat                                          // 尺寸
    var speed: CGFloat                                         // 速度
    var angle: Double                                          // 运动角度
    var rotation: Double                                       // 旋转角度
    var rotationSpeed: Double                                  // 旋转速度
    var opacity: Double                                        // 透明度
    var color: Color                                           // 颜色
    var startTime: TimeInterval                                // 开始时间
    var lifetime: Double                                       // 生命周期
    var phase: Double                                          // 相位偏移
}

// MARK: - 粒子系统配置
struct ParticleSystemConfig {
    var particleCount: Int = 50                                // 粒子数量
    var particleType: ParticleType = .dot                      // 粒子类型
    var motion: ParticleMotion = .fall                         // 运动模式
    var sizeRange: ClosedRange<CGFloat> = 2...6                // 尺寸范围
    var speedRange: ClosedRange<CGFloat> = 50...150            // 速度范围
    var opacityRange: ClosedRange<Double> = 0.3...0.8          // 透明度范围
    var lifetimeRange: ClosedRange<Double> = 3...8             // 生命周期范围
    var colors: [Color] = [.white]                             // 颜色列表
    var hasGlow: Bool = true                                   // 是否有发光
    var glowRadius: CGFloat = 5                                // 发光半径
    var hasTrail: Bool = false                                 // 是否有拖尾
    var trailLength: Int = 5                                   // 拖尾长度
    var rotationEnabled: Bool = false                          // 是否旋转
    var rotationSpeedRange: ClosedRange<Double> = 0.5...2      // 旋转速度范围
    var spawnArea: CGRect? = nil                               // 生成区域（nil为全屏）
}

// MARK: - 通用粒子系统
struct ParticleSystem: View {
    let config: ParticleSystemConfig                           // 配置

    @State private var particles: [SystemParticle] = []       // 粒子数组
    @State private var trails: [[CGPoint]] = []               // 拖尾数组

    init(config: ParticleSystemConfig = ParticleSystemConfig()) {
        self.config = config
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1/60)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    for (index, particle) in particles.enumerated() {
                        drawParticle(
                            context: context,
                            particle: particle,
                            time: time,
                            size: size,
                            trailIndex: index
                        )
                    }
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                if config.hasTrail {
                    trails = Array(repeating: [], count: config.particleCount)
                }
            }
        }
    }

    // MARK: - 生成粒子
    private func generateParticles(in size: CGSize) {
        let spawnArea = config.spawnArea ?? CGRect(origin: .zero, size: size)

        particles = (0..<config.particleCount).map { index in
            let startX = CGFloat.random(in: spawnArea.minX...spawnArea.maxX)
            let startY: CGFloat

            switch config.motion {
            case .fall:
                startY = CGFloat.random(in: -size.height...0)
            case .rise:
                startY = CGFloat.random(in: size.height...(size.height * 2))
            case .float, .spiral, .radial, .wind:
                startY = CGFloat.random(in: spawnArea.minY...spawnArea.maxY)
            }

            return SystemParticle(
                id: index,
                x: startX,
                y: startY,
                size: CGFloat.random(in: config.sizeRange),
                speed: CGFloat.random(in: config.speedRange),
                angle: motionAngle,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: config.rotationSpeedRange),
                opacity: Double.random(in: config.opacityRange),
                color: config.colors.randomElement() ?? .white,
                startTime: Date.timeIntervalSinceReferenceDate + Double.random(in: 0...3),
                lifetime: Double.random(in: config.lifetimeRange),
                phase: Double.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - 计算运动角度
    private var motionAngle: Double {
        switch config.motion {
        case .fall:
            return .pi / 2                                     // 向下
        case .rise:
            return -.pi / 2                                    // 向上
        case .float:
            return Double.random(in: 0...(.pi * 2))            // 随机
        case .spiral:
            return 0                                           // 初始角度
        case .radial:
            return Double.random(in: 0...(.pi * 2))            // 径向随机
        case .wind(let angle):
            return Double(angle) * .pi / 180                   // 风向角度
        }
    }

    // MARK: - 绘制粒子
    private func drawParticle(
        context: GraphicsContext,
        particle: SystemParticle,
        time: TimeInterval,
        size: CGSize,
        trailIndex: Int
    ) {
        let elapsed = time - particle.startTime
        if elapsed < 0 { return }

        // 计算生命周期进度
        let lifeProgress = (elapsed.truncatingRemainder(dividingBy: particle.lifetime)) / particle.lifetime

        // 计算当前位置
        let position = calculatePosition(
            particle: particle,
            elapsed: elapsed,
            canvasSize: size
        )

        // 超出边界则跳过
        guard position.x >= -50 && position.x <= size.width + 50 &&
              position.y >= -50 && position.y <= size.height + 50 else { return }

        // 计算当前透明度（带淡入淡出）
        let fadeIn = min(lifeProgress * 5, 1.0)
        let fadeOut = min((1 - lifeProgress) * 3, 1.0)
        let currentOpacity = particle.opacity * fadeIn * fadeOut

        // 计算当前旋转
        let currentRotation = config.rotationEnabled
            ? particle.rotation + elapsed * particle.rotationSpeed * 360
            : 0

        // 绘制发光
        if config.hasGlow {
            drawGlow(
                context: context,
                position: position,
                particle: particle,
                opacity: currentOpacity
            )
        }

        // 绘制粒子主体
        drawParticleShape(
            context: context,
            position: position,
            particle: particle,
            rotation: currentRotation,
            opacity: currentOpacity
        )
    }

    // MARK: - 计算位置
    private func calculatePosition(
        particle: SystemParticle,
        elapsed: TimeInterval,
        canvasSize: CGSize
    ) -> CGPoint {
        var x = particle.x
        var y = particle.y

        switch config.motion {
        case .fall:
            // 循环下落
            let totalDistance = canvasSize.height + 100
            let progress = (elapsed * Double(particle.speed)).truncatingRemainder(dividingBy: Double(totalDistance))
            y = particle.y + CGFloat(progress)
            // 轻微左右摆动
            x += sin(elapsed * 2 + particle.phase) * 10

        case .rise:
            // 循环上升
            let totalDistance = canvasSize.height + 100
            let progress = (elapsed * Double(particle.speed)).truncatingRemainder(dividingBy: Double(totalDistance))
            y = particle.y - CGFloat(progress)
            // 轻微摆动
            x += sin(elapsed * 1.5 + particle.phase) * 15

        case .float:
            // 漂浮运动
            x = particle.x + CGFloat(sin(elapsed * 0.5 + particle.phase) * 30)
            y = particle.y + CGFloat(cos(elapsed * 0.3 + particle.phase) * 20)

        case .spiral:
            // 螺旋运动
            let spiralRadius = CGFloat(elapsed * 10).truncatingRemainder(dividingBy: 100)
            let spiralAngle = elapsed * 2 + particle.phase
            x = particle.x + cos(CGFloat(spiralAngle)) * spiralRadius
            y = particle.y + sin(CGFloat(spiralAngle)) * spiralRadius + CGFloat(elapsed * Double(particle.speed) * 0.5)

        case .radial:
            // 径向扩散
            let distance = CGFloat(elapsed) * particle.speed
            x = particle.x + cos(CGFloat(particle.angle)) * distance
            y = particle.y + sin(CGFloat(particle.angle)) * distance

        case .wind(let windAngle):
            // 风力影响
            let radians = Double(windAngle) * .pi / 180
            let baseSpeed = Double(particle.speed)
            x = particle.x + CGFloat(cos(radians) * elapsed * baseSpeed * 0.3)
            y = particle.y + CGFloat(sin(radians) * elapsed * baseSpeed + elapsed * baseSpeed * 0.7)
        }

        // 确保循环
        x = x.truncatingRemainder(dividingBy: canvasSize.width + 100)
        if x < -50 { x += canvasSize.width + 100 }

        y = y.truncatingRemainder(dividingBy: canvasSize.height + 100)
        if case .rise = config.motion {
            if y > canvasSize.height + 50 { y -= canvasSize.height + 100 }
        }

        return CGPoint(x: x, y: y)
    }

    // MARK: - 绘制发光
    private func drawGlow(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        opacity: Double
    ) {
        let glowRect = CGRect(
            x: position.x - config.glowRadius,
            y: position.y - config.glowRadius,
            width: config.glowRadius * 2,
            height: config.glowRadius * 2
        )

        context.fill(
            Circle().path(in: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    particle.color.opacity(opacity * 0.5),
                    particle.color.opacity(opacity * 0.2),
                    Color.clear
                ]),
                center: position,
                startRadius: 0,
                endRadius: config.glowRadius
            )
        )
    }

    // MARK: - 绘制粒子形状
    private func drawParticleShape(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        rotation: Double,
        opacity: Double
    ) {
        var ctx = context

        // 应用旋转
        if config.rotationEnabled {
            ctx.translateBy(x: position.x, y: position.y)
            ctx.rotate(by: .degrees(rotation))
            ctx.translateBy(x: -position.x, y: -position.y)
        }

        switch config.particleType {
        case .dot:
            drawDot(context: ctx, position: position, particle: particle, opacity: opacity)

        case .line:
            drawLine(context: ctx, position: position, particle: particle, opacity: opacity)

        case .star:
            drawStar(context: ctx, position: position, particle: particle, opacity: opacity)

        case .spark:
            drawSpark(context: ctx, position: position, particle: particle, opacity: opacity)

        case .snow:
            drawSnowflake(context: ctx, position: position, particle: particle, opacity: opacity)

        case .rain:
            drawRaindrop(context: ctx, position: position, particle: particle, opacity: opacity)

        case .custom:
            drawDot(context: ctx, position: position, particle: particle, opacity: opacity)
        }
    }

    // MARK: - 绘制圆点
    private func drawDot(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        opacity: Double
    ) {
        let rect = CGRect(
            x: position.x - particle.size / 2,
            y: position.y - particle.size / 2,
            width: particle.size,
            height: particle.size
        )

        context.fill(
            Circle().path(in: rect),
            with: .color(particle.color.opacity(opacity))
        )
    }

    // MARK: - 绘制线条
    private func drawLine(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        opacity: Double
    ) {
        var path = Path()
        path.move(to: CGPoint(x: position.x, y: position.y - particle.size))
        path.addLine(to: CGPoint(x: position.x, y: position.y + particle.size))

        context.stroke(
            path,
            with: .color(particle.color.opacity(opacity)),
            lineWidth: max(1, particle.size / 4)
        )
    }

    // MARK: - 绘制星形
    private func drawStar(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        opacity: Double
    ) {
        var path = Path()
        let points = 4
        let innerRadius = particle.size * 0.4
        let outerRadius = particle.size

        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2

            let point = CGPoint(
                x: position.x + cos(CGFloat(angle)) * radius,
                y: position.y + sin(CGFloat(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        context.fill(
            path,
            with: .color(particle.color.opacity(opacity))
        )
    }

    // MARK: - 绘制火花
    private func drawSpark(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        opacity: Double
    ) {
        // 中心点
        let centerRect = CGRect(
            x: position.x - particle.size * 0.3,
            y: position.y - particle.size * 0.3,
            width: particle.size * 0.6,
            height: particle.size * 0.6
        )

        context.fill(
            Circle().path(in: centerRect),
            with: .color(Color.white.opacity(opacity))
        )

        // 四条射线
        for i in 0..<4 {
            var path = Path()
            let angle = Double(i) * .pi / 2
            path.move(to: position)
            path.addLine(to: CGPoint(
                x: position.x + cos(CGFloat(angle)) * particle.size,
                y: position.y + sin(CGFloat(angle)) * particle.size
            ))

            context.stroke(
                path,
                with: .color(particle.color.opacity(opacity * 0.7)),
                lineWidth: 1
            )
        }
    }

    // MARK: - 绘制雪花
    private func drawSnowflake(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        opacity: Double
    ) {
        // 六角形雪花
        for i in 0..<6 {
            var path = Path()
            let angle = Double(i) * .pi / 3
            path.move(to: position)
            path.addLine(to: CGPoint(
                x: position.x + cos(CGFloat(angle)) * particle.size,
                y: position.y + sin(CGFloat(angle)) * particle.size
            ))

            context.stroke(
                path,
                with: .color(particle.color.opacity(opacity)),
                lineWidth: 1
            )

            // 小分支
            let branchStart = CGPoint(
                x: position.x + cos(CGFloat(angle)) * particle.size * 0.6,
                y: position.y + sin(CGFloat(angle)) * particle.size * 0.6
            )

            for j in [-1, 1] {
                var branchPath = Path()
                let branchAngle = angle + Double(j) * .pi / 6
                branchPath.move(to: branchStart)
                branchPath.addLine(to: CGPoint(
                    x: branchStart.x + cos(CGFloat(branchAngle)) * particle.size * 0.3,
                    y: branchStart.y + sin(CGFloat(branchAngle)) * particle.size * 0.3
                ))

                context.stroke(
                    branchPath,
                    with: .color(particle.color.opacity(opacity * 0.7)),
                    lineWidth: 0.5
                )
            }
        }
    }

    // MARK: - 绘制雨滴
    private func drawRaindrop(
        context: GraphicsContext,
        position: CGPoint,
        particle: SystemParticle,
        opacity: Double
    ) {
        // 雨滴形状（线条带头）
        var path = Path()
        path.move(to: CGPoint(x: position.x, y: position.y - particle.size * 2))
        path.addLine(to: CGPoint(x: position.x, y: position.y))

        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color.clear,
                    particle.color.opacity(opacity * 0.5),
                    particle.color.opacity(opacity)
                ]),
                startPoint: CGPoint(x: position.x, y: position.y - particle.size * 2),
                endPoint: position
            ),
            lineWidth: 1.5
        )

        // 雨滴头部亮点
        let headRect = CGRect(
            x: position.x - 1,
            y: position.y - 1,
            width: 2,
            height: 2
        )

        context.fill(
            Circle().path(in: headRect),
            with: .color(Color.white.opacity(opacity))
        )
    }
}

// MARK: - 便捷构造器
extension ParticleSystem {
    /// 霓虹粒子（默认赛博朋克风格）
    static func neon(count: Int = 30) -> ParticleSystem {
        var config = ParticleSystemConfig()
        config.particleCount = count
        config.particleType = .dot
        config.motion = .float
        config.sizeRange = 2...5
        config.speedRange = 10...30
        config.opacityRange = 0.3...0.7
        config.colors = [
            Color(hex: "00D4FF"),
            Color(hex: "7B2FFF"),
            Color(hex: "FF00FF")
        ]
        config.hasGlow = true
        config.glowRadius = 8
        return ParticleSystem(config: config)
    }

    /// 雨滴粒子
    static func rain(intensity: Int = 100) -> ParticleSystem {
        var config = ParticleSystemConfig()
        config.particleCount = intensity
        config.particleType = .rain
        config.motion = .fall
        config.sizeRange = 15...30
        config.speedRange = 400...800
        config.opacityRange = 0.4...0.8
        config.colors = [Color(hex: "00D4FF"), Color.white]
        config.hasGlow = false
        return ParticleSystem(config: config)
    }

    /// 雪花粒子
    static func snow(intensity: Int = 50) -> ParticleSystem {
        var config = ParticleSystemConfig()
        config.particleCount = intensity
        config.particleType = .snow
        config.motion = .wind(15)
        config.sizeRange = 4...10
        config.speedRange = 30...80
        config.opacityRange = 0.5...0.9
        config.colors = [.white, Color(hex: "E0FFFF")]
        config.hasGlow = true
        config.glowRadius = 5
        config.rotationEnabled = true
        config.rotationSpeedRange = 0.2...1
        return ParticleSystem(config: config)
    }

    /// 星空粒子
    static func stars(count: Int = 80) -> ParticleSystem {
        var config = ParticleSystemConfig()
        config.particleCount = count
        config.particleType = .star
        config.motion = .float
        config.sizeRange = 1...4
        config.speedRange = 1...5
        config.opacityRange = 0.3...1.0
        config.lifetimeRange = 2...5
        config.colors = [.white, Color(hex: "FFD700"), Color(hex: "00D4FF")]
        config.hasGlow = true
        config.glowRadius = 3
        return ParticleSystem(config: config)
    }

    /// 火花粒子
    static func sparks(count: Int = 20) -> ParticleSystem {
        var config = ParticleSystemConfig()
        config.particleCount = count
        config.particleType = .spark
        config.motion = .rise
        config.sizeRange = 3...8
        config.speedRange = 50...150
        config.opacityRange = 0.5...1.0
        config.lifetimeRange = 1...3
        config.colors = [
            Color(hex: "FFD700"),
            Color(hex: "FF6B00"),
            Color(hex: "FF00FF")
        ]
        config.hasGlow = true
        config.glowRadius = 6
        return ParticleSystem(config: config)
    }
}

// MARK: - 预览
#Preview("Neon Particles") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        ParticleSystem.neon(count: 40)
    }
}

#Preview("Rain Particles") {
    ZStack {
        Color(hex: "1a2a4a").ignoresSafeArea()
        ParticleSystem.rain(intensity: 80)
    }
}

#Preview("Snow Particles") {
    ZStack {
        Color(hex: "1a1a3e").ignoresSafeArea()
        ParticleSystem.snow(intensity: 60)
    }
}

#Preview("Stars Particles") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        ParticleSystem.stars(count: 100)
    }
}

#Preview("Sparks Particles") {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        ParticleSystem.sparks(count: 30)
    }
}
