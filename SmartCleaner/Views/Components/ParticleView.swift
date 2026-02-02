//
//  ParticleView.swift
//  SmartCleaner
//
//  粒子效果组件
//  实现赛博朋克风格的漂浮粒子动画
//

import SwiftUI

// MARK: - 粒子数据结构
/// 单个粒子的属性
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat // X 坐标
    var y: CGFloat // Y 坐标
    var size: CGFloat // 粒子大小
    var opacity: Double // 透明度
    var color: Color // 颜色
    var speedX: CGFloat // X 方向速度
    var speedY: CGFloat // Y 方向速度
}

// MARK: - 粒子视图
/// 漂浮的霓虹粒子效果
struct ParticleView: View {

    // MARK: - 属性
    let particleCount: Int // 粒子数量
    let colors: [Color] // 粒子颜色组

    @State private var particles: [Particle] = []
    @State private var animationProgress: CGFloat = 0

    // MARK: - 初始化
    init(
        particleCount: Int = 30,
        colors: [Color] = [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink]
    ) {
        self.particleCount = particleCount
        self.colors = colors
    }

    // MARK: - 视图
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate // 当前时间

                    for particle in particles {
                        // 计算粒子位置（随时间移动）
                        let x = particle.x + sin(time * Double(particle.speedX)) * 20
                        let y = (particle.y + CGFloat(time) * particle.speedY).truncatingRemainder(dividingBy: size.height)

                        // 绘制粒子（带模糊效果模拟发光）
                        let rect = CGRect(
                            x: x - particle.size / 2,
                            y: y - particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )

                        // 外层光晕
                        context.fill(
                            Circle().path(in: rect.insetBy(dx: -particle.size * 0.5, dy: -particle.size * 0.5)),
                            with: .color(particle.color.opacity(particle.opacity * 0.3))
                        )

                        // 内层粒子
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(particle.color.opacity(particle.opacity))
                        )
                    }
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 生成粒子
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8),
                color: colors.randomElement() ?? CyberTheme.neonBlue,
                speedX: CGFloat.random(in: 0.5...2),
                speedY: CGFloat.random(in: 5...15)
            )
        }
    }
}

// MARK: - 星空粒子
/// 闪烁的星空效果
struct StarfieldView: View {

    let starCount: Int

    @State private var stars: [Star] = []

    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        var opacity: Double
        let blinkSpeed: Double
    }

    init(starCount: Int = 50) {
        self.starCount = starCount
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.1)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    for star in stars {
                        // 计算闪烁透明度
                        let blinkOpacity = (sin(time * star.blinkSpeed) + 1) / 2 * star.opacity

                        let rect = CGRect(
                            x: star.x - star.size / 2,
                            y: star.y - star.size / 2,
                            width: star.size,
                            height: star.size
                        )

                        // 星星光晕
                        context.fill(
                            Circle().path(in: rect.insetBy(dx: -star.size, dy: -star.size)),
                            with: .color(Color.white.opacity(blinkOpacity * 0.2))
                        )

                        // 星星本体
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(Color.white.opacity(blinkOpacity))
                        )
                    }
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    private func generateStars(in size: CGSize) {
        stars = (0..<starCount).map { _ in
            Star(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.5...1.0),
                blinkSpeed: Double.random(in: 1...3)
            )
        }
    }
}

// MARK: - 雨滴效果
/// 赛博朋克风格的数字雨效果
struct DigitalRainView: View {

    let columnCount: Int
    let speed: Double

    @State private var columns: [RainColumn] = []

    struct RainColumn: Identifiable {
        let id = UUID()
        let x: CGFloat
        var y: CGFloat
        let speed: CGFloat
        let length: Int
        let characters: [Character]
    }

    init(columnCount: Int = 20, speed: Double = 1.0) {
        self.columnCount = columnCount
        self.speed = speed
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    for column in columns {
                        let y = (column.y + CGFloat(time * speed) * column.speed).truncatingRemainder(dividingBy: size.height + 200) - 100

                        for (index, char) in column.characters.enumerated() {
                            let charY = y + CGFloat(index * 15)
                            guard charY > -20 && charY < size.height + 20 else { continue }

                            let opacity = 1.0 - Double(index) / Double(column.length)
                            let text = Text(String(char))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(CyberTheme.neonGreen.opacity(opacity))

                            context.draw(text, at: CGPoint(x: column.x, y: charY))
                        }
                    }
                }
            }
            .onAppear {
                generateColumns(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    private func generateColumns(in size: CGSize) {
        let chars = Array("0123456789ABCDEFアイウエオカキクケコ")
        let columnWidth = size.width / CGFloat(columnCount)

        columns = (0..<columnCount).map { i in
            let length = Int.random(in: 5...15)
            return RainColumn(
                x: CGFloat(i) * columnWidth + columnWidth / 2,
                y: CGFloat.random(in: -200...size.height),
                speed: CGFloat.random(in: 30...80),
                length: length,
                characters: (0..<length).map { _ in chars.randomElement()! }
            )
        }
    }
}

// MARK: - 预览
#Preview("ParticleView") {
    ZStack {
        CyberTheme.darkBackground.ignoresSafeArea()
        ParticleView()
    }
}

#Preview("StarfieldView") {
    ZStack {
        CyberTheme.darkBackground.ignoresSafeArea()
        StarfieldView()
    }
}

#Preview("DigitalRainView") {
    ZStack {
        Color.black.ignoresSafeArea()
        DigitalRainView()
    }
}
