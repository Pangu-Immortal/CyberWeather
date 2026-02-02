//
//  CyberBackground.swift
//  CyberWeather
//
//  赛博朋克背景组件 - 增强版
//  包含12层丰富的视觉效果：深空背景、极光波浪、全息网格、能量流、
//  霓虹光球、电路脉冲、数据流、六边形矩阵、脉冲环、浮动全息图、扫描线、光束
//

import SwiftUI

// MARK: - 能量流数据结构
/// 流动的能量线条
struct EnergyStream: Identifiable {
    let id = UUID()
    var startX: CGFloat      // 起始X
    var startY: CGFloat      // 起始Y
    var length: CGFloat      // 长度
    var angle: CGFloat       // 角度
    var speed: CGFloat       // 流动速度
    var width: CGFloat       // 宽度
    var color: Color         // 颜色
    var phase: CGFloat       // 相位
}

// MARK: - 霓虹光球数据结构
/// 漂浮的发光球体
struct NeonOrb: Identifiable {
    let id = UUID()
    var x: CGFloat           // X位置
    var y: CGFloat           // Y位置
    var radius: CGFloat      // 半径
    var color: Color         // 颜色
    var pulseSpeed: CGFloat  // 脉动速度
    var floatSpeed: CGFloat  // 漂浮速度
    var floatRange: CGFloat  // 漂浮范围
    var phase: CGFloat       // 相位偏移
}

// MARK: - 电路节点数据结构
/// 电路板上的节点
struct CircuitNode: Identifiable {
    let id = UUID()
    var x: CGFloat           // X位置
    var y: CGFloat           // Y位置
    var connections: [Int]   // 连接的节点索引
    var isActive: Bool       // 是否激活
    var pulsePhase: CGFloat  // 脉冲相位
}

// MARK: - 六边形单元数据结构
/// 六边形矩阵单元
struct HexCell: Identifiable {
    let id = UUID()
    var centerX: CGFloat     // 中心X
    var centerY: CGFloat     // 中心Y
    var size: CGFloat        // 大小
    var glowIntensity: CGFloat // 发光强度
    var phase: CGFloat       // 相位
}

// MARK: - 脉冲环数据结构
/// 扩散的圆环
struct PulseRing: Identifiable {
    let id = UUID()
    var centerX: CGFloat     // 中心X
    var centerY: CGFloat     // 中心Y
    var maxRadius: CGFloat   // 最大半径
    var speed: CGFloat       // 扩散速度
    var color: Color         // 颜色
    var phase: CGFloat       // 相位
}

// MARK: - 全息图形数据结构
/// 浮动的全息几何体
struct HologramShape: Identifiable {
    let id = UUID()
    var x: CGFloat           // X位置
    var y: CGFloat           // Y位置
    var size: CGFloat        // 大小
    var rotation: CGFloat    // 旋转角度
    var rotationSpeed: CGFloat // 旋转速度
    var shapeType: Int       // 形状类型 (0=三角, 1=方形, 2=六边形, 3=菱形)
    var color: Color         // 颜色
    var floatPhase: CGFloat  // 漂浮相位
}

// MARK: - 背景光束数据结构
/// 体积光束（用于赛博背景）
struct CyberLightBeam: Identifiable {
    let id = UUID()
    var x: CGFloat           // X位置
    var width: CGFloat       // 宽度
    var color: Color         // 颜色
    var intensity: CGFloat   // 强度
    var swaySpeed: CGFloat   // 摇摆速度
    var swayAmount: CGFloat  // 摇摆幅度
}

// MARK: - 数据粒子数据结构
/// 垂直流动的数据粒子
struct DataParticle: Identifiable {
    let id = UUID()
    var x: CGFloat           // X位置
    var y: CGFloat           // Y位置
    var speed: CGFloat       // 下落速度
    var size: CGFloat        // 大小
    var brightness: CGFloat  // 亮度
    var color: Color         // 颜色
    var trailLength: Int     // 尾迹长度
}

// MARK: - 赛博背景（增强版）
/// 完整的赛博朋克风格背景，包含12层丰富的视觉效果
struct CyberBackground: View {

    let showGrid: Bool           // 是否显示网格
    let showScanline: Bool       // 是否显示扫描线
    let showParticles: Bool      // 是否显示粒子
    let intensity: BackgroundIntensity // 背景强度

    /// 背景强度等级
    enum BackgroundIntensity {
        case minimal   // 最小 - 仅基础效果
        case normal    // 普通 - 中等效果
        case rich      // 丰富 - 全部效果

        var orbCount: Int {
            switch self {
            case .minimal: return 3
            case .normal: return 6
            case .rich: return 10
            }
        }

        var streamCount: Int {
            switch self {
            case .minimal: return 5
            case .normal: return 10
            case .rich: return 18
            }
        }

        var hexCount: Int {
            switch self {
            case .minimal: return 0
            case .normal: return 15
            case .rich: return 30
            }
        }

        var pulseRingCount: Int {
            switch self {
            case .minimal: return 1
            case .normal: return 3
            case .rich: return 5
            }
        }

        var hologramCount: Int {
            switch self {
            case .minimal: return 0
            case .normal: return 3
            case .rich: return 6
            }
        }

        var beamCount: Int {
            switch self {
            case .minimal: return 2
            case .normal: return 4
            case .rich: return 7
            }
        }

        var dataParticleCount: Int {
            switch self {
            case .minimal: return 20
            case .normal: return 40
            case .rich: return 70
            }
        }
    }

    // 状态变量
    @State private var energyStreams: [EnergyStream] = []
    @State private var neonOrbs: [NeonOrb] = []
    @State private var hexCells: [HexCell] = []
    @State private var pulseRings: [PulseRing] = []
    @State private var hologramShapes: [HologramShape] = []
    @State private var lightBeams: [CyberLightBeam] = []
    @State private var dataParticles: [DataParticle] = []
    @State private var circuitNodes: [CircuitNode] = []

    init(
        showGrid: Bool = true,
        showScanline: Bool = true,
        showParticles: Bool = true,
        intensity: BackgroundIntensity = .rich
    ) {
        self.showGrid = showGrid
        self.showScanline = showScanline
        self.showParticles = showParticles
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            TimelineView(.animation(minimumInterval: 1/60)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, canvasSize in
                    // ========== 第1层：深空背景 ==========
                    drawDeepSpaceBackground(context: context, size: canvasSize, time: time)

                    // ========== 第2层：极光波浪 ==========
                    drawAuroraWaves(context: context, size: canvasSize, time: time)

                    // ========== 第3层：光束 ==========
                    drawLightBeams(context: context, size: canvasSize, time: time)

                    // ========== 第4层：全息网格 ==========
                    if showGrid {
                        drawHolographicGrid(context: context, size: canvasSize, time: time)
                    }

                    // ========== 第5层：六边形矩阵 ==========
                    if intensity != .minimal {
                        drawHexagonMatrix(context: context, size: canvasSize, time: time)
                    }

                    // ========== 第6层：能量流 ==========
                    drawEnergyStreams(context: context, size: canvasSize, time: time)

                    // ========== 第7层：电路脉冲 ==========
                    if intensity == .rich {
                        drawCircuitPulses(context: context, size: canvasSize, time: time)
                    }

                    // ========== 第8层：数据流粒子 ==========
                    if showParticles {
                        drawDataParticles(context: context, size: canvasSize, time: time)
                    }

                    // ========== 第9层：霓虹光球 ==========
                    drawNeonOrbs(context: context, size: canvasSize, time: time)

                    // ========== 第10层：脉冲环 ==========
                    drawPulseRings(context: context, size: canvasSize, time: time)

                    // ========== 第11层：浮动全息图 ==========
                    if intensity != .minimal {
                        drawHologramShapes(context: context, size: canvasSize, time: time)
                    }

                    // ========== 第12层：扫描线 ==========
                    if showScanline {
                        drawEnhancedScanlines(context: context, size: canvasSize, time: time)
                    }
                }
                .drawingGroup() // GPU加速
            }
            .onAppear {
                initializeAllElements(in: size)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 初始化所有元素
    private func initializeAllElements(in size: CGSize) {
        generateEnergyStreams(in: size)
        generateNeonOrbs(in: size)
        generateHexCells(in: size)
        generatePulseRings(in: size)
        generateHologramShapes(in: size)
        generateLightBeams(in: size)
        generateDataParticles(in: size)
        generateCircuitNodes(in: size)
    }

    // MARK: - 第1层：深空背景
    private func drawDeepSpaceBackground(context: GraphicsContext, size: CGSize, time: Double) {
        // 基础深空渐变
        let baseGradient = Gradient(colors: [
            Color(red: 0.02, green: 0.02, blue: 0.08),
            Color(red: 0.05, green: 0.03, blue: 0.12),
            Color(red: 0.03, green: 0.02, blue: 0.1),
            Color(red: 0.01, green: 0.01, blue: 0.05)
        ])

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                baseGradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )

        // 添加星云效果
        let nebulaPhase = time * 0.1
        for i in 0..<3 {
            let nebulaCenterX = size.width * (0.2 + CGFloat(i) * 0.3) + sin(nebulaPhase + Double(i)) * 30
            let nebulaCenterY = size.height * (0.3 + CGFloat(i) * 0.2) + cos(nebulaPhase * 0.7 + Double(i)) * 20
            let nebulaRadius = size.width * 0.4

            let nebulaColors: [Color] = [
                Color(red: 0.1, green: 0.0, blue: 0.2).opacity(0.15),
                Color(red: 0.0, green: 0.1, blue: 0.2).opacity(0.1),
                Color(red: 0.1, green: 0.05, blue: 0.15).opacity(0.08)
            ]

            let nebulaGradient = Gradient(colors: [
                nebulaColors[i % 3],
                nebulaColors[i % 3].opacity(0)
            ])

            context.fill(
                Circle().path(in: CGRect(
                    x: nebulaCenterX - nebulaRadius,
                    y: nebulaCenterY - nebulaRadius,
                    width: nebulaRadius * 2,
                    height: nebulaRadius * 2
                )),
                with: .radialGradient(
                    nebulaGradient,
                    center: CGPoint(x: nebulaCenterX, y: nebulaCenterY),
                    startRadius: 0,
                    endRadius: nebulaRadius
                )
            )
        }

        // 闪烁的星星
        let starCount = 60
        for i in 0..<starCount {
            let seed = Double(i * 12345)
            let starX = CGFloat((seed.truncatingRemainder(dividingBy: 1000)) / 1000) * size.width
            let starY = CGFloat(((seed * 1.5).truncatingRemainder(dividingBy: 1000)) / 1000) * size.height
            let starSize = CGFloat(1 + (seed.truncatingRemainder(dividingBy: 3)))
            let twinkle = (sin(time * (2 + seed.truncatingRemainder(dividingBy: 2)) + seed) + 1) / 2

            let starRect = CGRect(
                x: starX - starSize/2,
                y: starY - starSize/2,
                width: starSize,
                height: starSize
            )

            // 星星光晕
            context.fill(
                Circle().path(in: starRect.insetBy(dx: -starSize, dy: -starSize)),
                with: .color(Color.white.opacity(twinkle * 0.15))
            )

            // 星星本体
            context.fill(
                Circle().path(in: starRect),
                with: .color(Color.white.opacity(0.5 + twinkle * 0.5))
            )
        }
    }

    // MARK: - 第2层：极光波浪
    private func drawAuroraWaves(context: GraphicsContext, size: CGSize, time: Double) {
        let auroraColors: [(Color, CGFloat)] = [
            (CyberTheme.neonBlue, 0.15),
            (CyberTheme.neonPurple, 0.12),
            (CyberTheme.neonPink, 0.08),
            (Color(red: 0, green: 1, blue: 0.5), 0.1)
        ]

        for (index, (color, opacity)) in auroraColors.enumerated() {
            var path = Path()
            let waveOffset = time * (0.3 + Double(index) * 0.1)
            let baseY = size.height * (0.15 + CGFloat(index) * 0.08)

            path.move(to: CGPoint(x: 0, y: baseY))

            for x in stride(from: 0, through: size.width, by: 4) {
                let normalizedX = x / size.width
                let wave1 = sin(normalizedX * 4 + waveOffset) * 30
                let wave2 = sin(normalizedX * 8 + waveOffset * 1.5) * 15
                let wave3 = sin(normalizedX * 2 + waveOffset * 0.5) * 40
                let y = baseY + wave1 + wave2 + wave3
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.closeSubpath()

            let gradient = Gradient(colors: [
                color.opacity(opacity),
                color.opacity(opacity * 0.5),
                color.opacity(0)
            ])

            context.fill(path, with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: size.width/2, y: baseY - 50),
                endPoint: CGPoint(x: size.width/2, y: baseY + 150)
            ))
        }
    }

    // MARK: - 第3层：光束
    private func drawLightBeams(context: GraphicsContext, size: CGSize, time: Double) {
        for beam in lightBeams {
            let sway = sin(time * beam.swaySpeed) * beam.swayAmount
            let beamX = beam.x + sway

            // 光束渐变
            let beamGradient = Gradient(colors: [
                beam.color.opacity(0),
                beam.color.opacity(beam.intensity * 0.3),
                beam.color.opacity(beam.intensity * 0.5),
                beam.color.opacity(beam.intensity * 0.3),
                beam.color.opacity(0)
            ])

            var beamPath = Path()
            beamPath.move(to: CGPoint(x: beamX - beam.width/2, y: 0))
            beamPath.addLine(to: CGPoint(x: beamX + beam.width/2, y: 0))
            beamPath.addLine(to: CGPoint(x: beamX + beam.width * 1.5, y: size.height))
            beamPath.addLine(to: CGPoint(x: beamX - beam.width * 1.5, y: size.height))
            beamPath.closeSubpath()

            context.fill(beamPath, with: .linearGradient(
                beamGradient,
                startPoint: CGPoint(x: beamX - beam.width, y: size.height/2),
                endPoint: CGPoint(x: beamX + beam.width, y: size.height/2)
            ))
        }
    }

    // MARK: - 第4层：全息网格
    private func drawHolographicGrid(context: GraphicsContext, size: CGSize, time: Double) {
        let gridSpacing: CGFloat = 40
        let perspectiveFactor: CGFloat = 0.6
        let wavePhase = time * 0.5

        // 水平线（带透视）
        for i in 0..<Int(size.height / gridSpacing) + 5 {
            let baseY = CGFloat(i) * gridSpacing
            let perspectiveY = size.height * 0.3 + (baseY - size.height * 0.3) * perspectiveFactor
            let wave = sin(wavePhase + Double(i) * 0.3) * 2

            let alpha = 0.1 + (1 - baseY / size.height) * 0.1

            var path = Path()
            path.move(to: CGPoint(x: 0, y: perspectiveY + wave))
            path.addLine(to: CGPoint(x: size.width, y: perspectiveY + wave))

            context.stroke(
                path,
                with: .color(CyberTheme.neonBlue.opacity(alpha)),
                lineWidth: 0.5
            )
        }

        // 垂直线（向远处汇聚）
        let vanishingPoint = CGPoint(x: size.width / 2, y: size.height * 0.1)
        let lineCount = 20

        for i in 0..<lineCount {
            let bottomX = CGFloat(i) * size.width / CGFloat(lineCount - 1)
            let wave = sin(wavePhase + Double(i) * 0.2) * 3

            var path = Path()
            path.move(to: CGPoint(x: bottomX + wave, y: size.height))
            path.addLine(to: CGPoint(
                x: vanishingPoint.x + (bottomX - vanishingPoint.x) * 0.3,
                y: vanishingPoint.y
            ))

            let alpha = 0.08 + abs(CGFloat(i) - CGFloat(lineCount)/2) / CGFloat(lineCount) * 0.1
            context.stroke(
                path,
                with: .color(CyberTheme.neonBlue.opacity(alpha)),
                lineWidth: 0.5
            )
        }

        // 网格交点发光
        let glowPoints = 15
        for i in 0..<glowPoints {
            let seed = Double(i * 7777)
            let px = CGFloat((seed.truncatingRemainder(dividingBy: 1000)) / 1000) * size.width
            let py = CGFloat(((seed * 2.3).truncatingRemainder(dividingBy: 1000)) / 1000) * size.height
            let pulse = (sin(time * 2 + seed * 0.1) + 1) / 2

            let glowSize: CGFloat = 3 + pulse * 2
            let glowRect = CGRect(x: px - glowSize, y: py - glowSize, width: glowSize * 2, height: glowSize * 2)

            context.fill(
                Circle().path(in: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        CyberTheme.neonBlue.opacity(0.6 * pulse),
                        CyberTheme.neonBlue.opacity(0)
                    ]),
                    center: CGPoint(x: px, y: py),
                    startRadius: 0,
                    endRadius: glowSize
                )
            )
        }
    }

    // MARK: - 第5层：六边形矩阵
    private func drawHexagonMatrix(context: GraphicsContext, size: CGSize, time: Double) {
        for hex in hexCells {
            let pulse = (sin(time * 1.5 + hex.phase) + 1) / 2
            let glowIntensity = hex.glowIntensity * (0.3 + pulse * 0.7)

            // 绘制六边形
            var hexPath = Path()
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3 - .pi / 6
                let px = hex.centerX + cos(angle) * hex.size
                let py = hex.centerY + sin(angle) * hex.size
                if i == 0 {
                    hexPath.move(to: CGPoint(x: px, y: py))
                } else {
                    hexPath.addLine(to: CGPoint(x: px, y: py))
                }
            }
            hexPath.closeSubpath()

            // 六边形边框发光
            context.stroke(
                hexPath,
                with: .color(CyberTheme.neonBlue.opacity(glowIntensity * 0.5)),
                lineWidth: 1
            )

            // 六边形填充
            context.fill(
                hexPath,
                with: .color(CyberTheme.neonBlue.opacity(glowIntensity * 0.05))
            )

            // 中心发光点
            if pulse > 0.7 {
                let centerGlow = CGRect(
                    x: hex.centerX - 2,
                    y: hex.centerY - 2,
                    width: 4,
                    height: 4
                )
                context.fill(
                    Circle().path(in: centerGlow),
                    with: .color(CyberTheme.neonBlue.opacity(glowIntensity))
                )
            }
        }
    }

    // MARK: - 第6层：能量流
    private func drawEnergyStreams(context: GraphicsContext, size: CGSize, time: Double) {
        for stream in energyStreams {
            let flowOffset = (time * stream.speed + stream.phase).truncatingRemainder(dividingBy: 1)

            let startX = stream.startX
            let startY = stream.startY
            let endX = startX + cos(stream.angle) * stream.length
            let endY = startY + sin(stream.angle) * stream.length

            // 绘制能量流主体
            var streamPath = Path()
            streamPath.move(to: CGPoint(x: startX, y: startY))

            // 添加波动
            let segments = 20
            for i in 1...segments {
                let t = CGFloat(i) / CGFloat(segments)
                let baseX = startX + (endX - startX) * t
                let baseY = startY + (endY - startY) * t
                let wave = sin(t * .pi * 4 + time * 3 + stream.phase) * 3
                let perpX = -sin(stream.angle) * wave
                let perpY = cos(stream.angle) * wave
                streamPath.addLine(to: CGPoint(x: baseX + perpX, y: baseY + perpY))
            }

            // 能量流发光
            context.stroke(
                streamPath,
                with: .color(stream.color.opacity(0.3)),
                style: StrokeStyle(lineWidth: stream.width + 4, lineCap: .round)
            )

            context.stroke(
                streamPath,
                with: .color(stream.color.opacity(0.6)),
                style: StrokeStyle(lineWidth: stream.width + 2, lineCap: .round)
            )

            context.stroke(
                streamPath,
                with: .color(stream.color.opacity(0.9)),
                style: StrokeStyle(lineWidth: stream.width, lineCap: .round)
            )

            // 流动的亮点
            let brightX = startX + (endX - startX) * flowOffset
            let brightY = startY + (endY - startY) * flowOffset
            let brightSize: CGFloat = stream.width * 2

            context.fill(
                Circle().path(in: CGRect(
                    x: brightX - brightSize,
                    y: brightY - brightSize,
                    width: brightSize * 2,
                    height: brightSize * 2
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.9),
                        stream.color.opacity(0.5),
                        stream.color.opacity(0)
                    ]),
                    center: CGPoint(x: brightX, y: brightY),
                    startRadius: 0,
                    endRadius: brightSize
                )
            )
        }
    }

    // MARK: - 第7层：电路脉冲
    private func drawCircuitPulses(context: GraphicsContext, size: CGSize, time: Double) {
        let pulseSpeed = time * 2

        for node in circuitNodes {
            let nodePulse = (sin(pulseSpeed + node.pulsePhase) + 1) / 2

            // 节点发光
            let nodeSize: CGFloat = 4 + nodePulse * 2
            let nodeRect = CGRect(
                x: node.x - nodeSize,
                y: node.y - nodeSize,
                width: nodeSize * 2,
                height: nodeSize * 2
            )

            // 外发光
            context.fill(
                Circle().path(in: nodeRect.insetBy(dx: -5, dy: -5)),
                with: .color(CyberTheme.neonBlue.opacity(0.2 * nodePulse))
            )

            // 节点本体
            context.fill(
                Circle().path(in: nodeRect),
                with: .color(CyberTheme.neonBlue.opacity(0.5 + nodePulse * 0.5))
            )

            // 绘制到其他节点的连接线
            for targetIndex in node.connections {
                guard targetIndex < circuitNodes.count else { continue }
                let target = circuitNodes[targetIndex]

                var linePath = Path()
                linePath.move(to: CGPoint(x: node.x, y: node.y))

                // L型连接
                let midX = (node.x + target.x) / 2
                linePath.addLine(to: CGPoint(x: midX, y: node.y))
                linePath.addLine(to: CGPoint(x: midX, y: target.y))
                linePath.addLine(to: CGPoint(x: target.x, y: target.y))

                context.stroke(
                    linePath,
                    with: .color(CyberTheme.neonBlue.opacity(0.15 + nodePulse * 0.1)),
                    lineWidth: 1
                )

                // 脉冲亮点沿线移动
                let pulseProgress = (pulseSpeed + node.pulsePhase).truncatingRemainder(dividingBy: 3) / 3
                let pulseX: CGFloat
                let pulseY: CGFloat

                if pulseProgress < 0.33 {
                    let t = pulseProgress / 0.33
                    pulseX = node.x + (midX - node.x) * t
                    pulseY = node.y
                } else if pulseProgress < 0.66 {
                    let t = (pulseProgress - 0.33) / 0.33
                    pulseX = midX
                    pulseY = node.y + (target.y - node.y) * t
                } else {
                    let t = (pulseProgress - 0.66) / 0.34
                    pulseX = midX + (target.x - midX) * t
                    pulseY = target.y
                }

                context.fill(
                    Circle().path(in: CGRect(x: pulseX - 2, y: pulseY - 2, width: 4, height: 4)),
                    with: .color(Color.white.opacity(0.8))
                )
            }
        }
    }

    // MARK: - 第8层：数据流粒子
    private func drawDataParticles(context: GraphicsContext, size: CGSize, time: Double) {
        for particle in dataParticles {
            let y = (particle.y + time * particle.speed).truncatingRemainder(dividingBy: size.height + 100) - 50

            // 绘制尾迹
            for i in 0..<particle.trailLength {
                let trailY = y - CGFloat(i) * 4
                let trailAlpha = particle.brightness * (1 - CGFloat(i) / CGFloat(particle.trailLength))
                let trailSize = particle.size * (1 - CGFloat(i) / CGFloat(particle.trailLength) * 0.5)

                guard trailY > 0 && trailY < size.height else { continue }

                let trailRect = CGRect(
                    x: particle.x - trailSize/2,
                    y: trailY - trailSize/2,
                    width: trailSize,
                    height: trailSize
                )

                context.fill(
                    Circle().path(in: trailRect),
                    with: .color(particle.color.opacity(trailAlpha))
                )
            }

            // 粒子本体
            guard y > 0 && y < size.height else { continue }

            let particleRect = CGRect(
                x: particle.x - particle.size/2,
                y: y - particle.size/2,
                width: particle.size,
                height: particle.size
            )

            // 发光效果
            context.fill(
                Circle().path(in: particleRect.insetBy(dx: -particle.size, dy: -particle.size)),
                with: .color(particle.color.opacity(particle.brightness * 0.3))
            )

            context.fill(
                Circle().path(in: particleRect),
                with: .color(particle.color.opacity(particle.brightness))
            )
        }
    }

    // MARK: - 第9层：霓虹光球
    private func drawNeonOrbs(context: GraphicsContext, size: CGSize, time: Double) {
        for orb in neonOrbs {
            let floatY = orb.y + sin(time * orb.floatSpeed + orb.phase) * orb.floatRange
            let pulse = (sin(time * orb.pulseSpeed + orb.phase) + 1) / 2
            let currentRadius = orb.radius * (0.8 + pulse * 0.4)

            // 外层光晕
            let outerGlowRect = CGRect(
                x: orb.x - currentRadius * 3,
                y: floatY - currentRadius * 3,
                width: currentRadius * 6,
                height: currentRadius * 6
            )

            context.fill(
                Circle().path(in: outerGlowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        orb.color.opacity(0.2 * pulse),
                        orb.color.opacity(0.1 * pulse),
                        orb.color.opacity(0)
                    ]),
                    center: CGPoint(x: orb.x, y: floatY),
                    startRadius: 0,
                    endRadius: currentRadius * 3
                )
            )

            // 中层光晕
            let midGlowRect = CGRect(
                x: orb.x - currentRadius * 1.8,
                y: floatY - currentRadius * 1.8,
                width: currentRadius * 3.6,
                height: currentRadius * 3.6
            )

            context.fill(
                Circle().path(in: midGlowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        orb.color.opacity(0.4),
                        orb.color.opacity(0.2),
                        orb.color.opacity(0)
                    ]),
                    center: CGPoint(x: orb.x, y: floatY),
                    startRadius: 0,
                    endRadius: currentRadius * 1.8
                )
            )

            // 核心
            let coreRect = CGRect(
                x: orb.x - currentRadius,
                y: floatY - currentRadius,
                width: currentRadius * 2,
                height: currentRadius * 2
            )

            context.fill(
                Circle().path(in: coreRect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.9),
                        orb.color.opacity(0.8),
                        orb.color.opacity(0.5)
                    ]),
                    center: CGPoint(x: orb.x, y: floatY),
                    startRadius: 0,
                    endRadius: currentRadius
                )
            )
        }
    }

    // MARK: - 第10层：脉冲环
    private func drawPulseRings(context: GraphicsContext, size: CGSize, time: Double) {
        for ring in pulseRings {
            let progress = ((time * ring.speed + ring.phase).truncatingRemainder(dividingBy: 4)) / 4
            let currentRadius = ring.maxRadius * progress
            let alpha = (1 - progress) * 0.5

            guard currentRadius > 0 else { continue }

            // 外环
            let ringPath = Circle().path(in: CGRect(
                x: ring.centerX - currentRadius,
                y: ring.centerY - currentRadius,
                width: currentRadius * 2,
                height: currentRadius * 2
            ))

            context.stroke(
                ringPath,
                with: .color(ring.color.opacity(alpha)),
                lineWidth: 2
            )

            // 内部发光
            context.stroke(
                ringPath,
                with: .color(ring.color.opacity(alpha * 0.5)),
                lineWidth: 6
            )
        }
    }

    // MARK: - 第11层：浮动全息图
    private func drawHologramShapes(context: GraphicsContext, size: CGSize, time: Double) {
        for shape in hologramShapes {
            let floatOffset = sin(time * 0.8 + shape.floatPhase) * 10
            let currentY = shape.y + floatOffset
            let rotation = shape.rotation + time * shape.rotationSpeed

            var shapePath = Path()

            switch shape.shapeType {
            case 0: // 三角形
                for i in 0..<3 {
                    let angle = rotation + CGFloat(i) * .pi * 2 / 3
                    let px = shape.x + cos(angle) * shape.size
                    let py = currentY + sin(angle) * shape.size
                    if i == 0 {
                        shapePath.move(to: CGPoint(x: px, y: py))
                    } else {
                        shapePath.addLine(to: CGPoint(x: px, y: py))
                    }
                }

            case 1: // 方形
                for i in 0..<4 {
                    let angle = rotation + CGFloat(i) * .pi / 2 + .pi / 4
                    let px = shape.x + cos(angle) * shape.size
                    let py = currentY + sin(angle) * shape.size
                    if i == 0 {
                        shapePath.move(to: CGPoint(x: px, y: py))
                    } else {
                        shapePath.addLine(to: CGPoint(x: px, y: py))
                    }
                }

            case 2: // 六边形
                for i in 0..<6 {
                    let angle = rotation + CGFloat(i) * .pi / 3
                    let px = shape.x + cos(angle) * shape.size
                    let py = currentY + sin(angle) * shape.size
                    if i == 0 {
                        shapePath.move(to: CGPoint(x: px, y: py))
                    } else {
                        shapePath.addLine(to: CGPoint(x: px, y: py))
                    }
                }

            default: // 菱形
                let points = [
                    CGPoint(x: shape.x, y: currentY - shape.size),
                    CGPoint(x: shape.x + shape.size * 0.7, y: currentY),
                    CGPoint(x: shape.x, y: currentY + shape.size),
                    CGPoint(x: shape.x - shape.size * 0.7, y: currentY)
                ]
                shapePath.move(to: points[0])
                for i in 1..<4 {
                    shapePath.addLine(to: points[i])
                }
            }

            shapePath.closeSubpath()

            // 全息扫描线效果
            let scanLineY = currentY - shape.size + (time * 50).truncatingRemainder(dividingBy: shape.size * 2)

            // 形状边框
            context.stroke(
                shapePath,
                with: .color(shape.color.opacity(0.6)),
                lineWidth: 1.5
            )

            // 形状填充
            context.fill(
                shapePath,
                with: .color(shape.color.opacity(0.08))
            )

            // 全息发光
            context.stroke(
                shapePath,
                with: .color(shape.color.opacity(0.2)),
                lineWidth: 4
            )

            // 扫描线
            var scanPath = Path()
            scanPath.move(to: CGPoint(x: shape.x - shape.size, y: scanLineY))
            scanPath.addLine(to: CGPoint(x: shape.x + shape.size, y: scanLineY))

            context.stroke(
                scanPath,
                with: .color(Color.white.opacity(0.5)),
                lineWidth: 1
            )
        }
    }

    // MARK: - 第12层：增强扫描线
    private func drawEnhancedScanlines(context: GraphicsContext, size: CGSize, time: Double) {
        // 静态扫描线纹理
        let lineSpacing: CGFloat = 4
        var y: CGFloat = 0
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(Color.white.opacity(0.015)), lineWidth: 1)
            y += lineSpacing
        }

        // 移动的亮扫描线
        let scanY = (time * 100).truncatingRemainder(dividingBy: size.height + 100) - 50

        // 扫描线光晕
        let scanGradient = Gradient(colors: [
            Color.white.opacity(0),
            Color.white.opacity(0.1),
            CyberTheme.neonBlue.opacity(0.15),
            Color.white.opacity(0.1),
            Color.white.opacity(0)
        ])

        context.fill(
            Path(CGRect(x: 0, y: scanY - 30, width: size.width, height: 60)),
            with: .linearGradient(
                scanGradient,
                startPoint: CGPoint(x: 0, y: scanY - 30),
                endPoint: CGPoint(x: 0, y: scanY + 30)
            )
        )

        // 亮扫描线本体
        var scanPath = Path()
        scanPath.move(to: CGPoint(x: 0, y: scanY))
        scanPath.addLine(to: CGPoint(x: size.width, y: scanY))
        context.stroke(scanPath, with: .color(Color.white.opacity(0.3)), lineWidth: 1)
    }

    // MARK: - 生成能量流
    private func generateEnergyStreams(in size: CGSize) {
        let colors: [Color] = [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink, CyberTheme.neonGreen]

        energyStreams = (0..<intensity.streamCount).map { i in
            EnergyStream(
                startX: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: 0...size.height),
                length: CGFloat.random(in: 80...200),
                angle: CGFloat.random(in: 0...(.pi * 2)),
                speed: CGFloat.random(in: 0.5...1.5),
                width: CGFloat.random(in: 1...3),
                color: colors[i % colors.count],
                phase: CGFloat.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - 生成霓虹光球
    private func generateNeonOrbs(in size: CGSize) {
        let colors: [Color] = [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink, CyberTheme.neonGreen, Color(hex: 0xFFD700)]

        neonOrbs = (0..<intensity.orbCount).map { i in
            NeonOrb(
                x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.9),
                radius: CGFloat.random(in: 8...20),
                color: colors[i % colors.count],
                pulseSpeed: CGFloat.random(in: 1...3),
                floatSpeed: CGFloat.random(in: 0.5...1.5),
                floatRange: CGFloat.random(in: 10...30),
                phase: CGFloat.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - 生成六边形单元
    private func generateHexCells(in size: CGSize) {
        guard intensity.hexCount > 0 else {
            hexCells = []
            return
        }

        hexCells = (0..<intensity.hexCount).map { i in
            HexCell(
                centerX: CGFloat.random(in: 0...size.width),
                centerY: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 20...40),
                glowIntensity: CGFloat.random(in: 0.3...0.8),
                phase: CGFloat.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - 生成脉冲环
    private func generatePulseRings(in size: CGSize) {
        let colors: [Color] = [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink]

        pulseRings = (0..<intensity.pulseRingCount).map { i in
            PulseRing(
                centerX: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                centerY: CGFloat.random(in: size.height * 0.2...size.height * 0.8),
                maxRadius: CGFloat.random(in: 80...150),
                speed: CGFloat.random(in: 0.3...0.8),
                color: colors[i % colors.count],
                phase: CGFloat.random(in: 0...4)
            )
        }
    }

    // MARK: - 生成全息图形
    private func generateHologramShapes(in size: CGSize) {
        guard intensity.hologramCount > 0 else {
            hologramShapes = []
            return
        }

        let colors: [Color] = [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink, CyberTheme.neonGreen]

        hologramShapes = (0..<intensity.hologramCount).map { i in
            HologramShape(
                x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.9),
                size: CGFloat.random(in: 25...50),
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotationSpeed: CGFloat.random(in: 0.2...0.8),
                shapeType: Int.random(in: 0...3),
                color: colors[i % colors.count],
                floatPhase: CGFloat.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - 生成光束
    private func generateLightBeams(in size: CGSize) {
        let colors: [Color] = [
            CyberTheme.neonBlue.opacity(0.3),
            CyberTheme.neonPurple.opacity(0.25),
            CyberTheme.neonPink.opacity(0.2),
            Color.white.opacity(0.15)
        ]

        lightBeams = (0..<intensity.beamCount).map { i in
            CyberLightBeam(
                x: CGFloat.random(in: 0...size.width),
                width: CGFloat.random(in: 30...80),
                color: colors[i % colors.count],
                intensity: CGFloat.random(in: 0.3...0.7),
                swaySpeed: CGFloat.random(in: 0.3...0.8),
                swayAmount: CGFloat.random(in: 20...50)
            )
        }
    }

    // MARK: - 生成数据粒子
    private func generateDataParticles(in size: CGSize) {
        let colors: [Color] = [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink, CyberTheme.neonGreen]

        dataParticles = (0..<intensity.dataParticleCount).map { i in
            DataParticle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                speed: CGFloat.random(in: 20...80),
                size: CGFloat.random(in: 2...5),
                brightness: CGFloat.random(in: 0.4...0.9),
                color: colors[i % colors.count],
                trailLength: Int.random(in: 3...8)
            )
        }
    }

    // MARK: - 生成电路节点
    private func generateCircuitNodes(in size: CGSize) {
        let nodeCount = 20
        var nodes: [CircuitNode] = []

        // 生成节点位置
        for i in 0..<nodeCount {
            let node = CircuitNode(
                x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.9),
                connections: [],
                isActive: Bool.random(),
                pulsePhase: CGFloat.random(in: 0...(.pi * 2))
            )
            nodes.append(node)
        }

        // 建立连接（每个节点连接1-2个最近的节点）
        for i in 0..<nodeCount {
            var distances: [(Int, CGFloat)] = []
            for j in 0..<nodeCount {
                if i != j {
                    let dx = nodes[i].x - nodes[j].x
                    let dy = nodes[i].y - nodes[j].y
                    let dist = sqrt(dx * dx + dy * dy)
                    distances.append((j, dist))
                }
            }
            distances.sort { $0.1 < $1.1 }

            let connectionCount = Int.random(in: 1...2)
            nodes[i].connections = Array(distances.prefix(connectionCount).map { $0.0 })
        }

        circuitNodes = nodes
    }
}

// MARK: - 网格覆盖层
/// 赛博朋克风格的网格线条
struct GridOverlay: View {

    let spacing: CGFloat
    let lineWidth: CGFloat
    let color: Color

    init(
        spacing: CGFloat = 30,
        lineWidth: CGFloat = 0.5,
        color: Color = CyberTheme.neonBlue
    ) {
        self.spacing = spacing
        self.lineWidth = lineWidth
        self.color = color
    }

    var body: some View {
        Canvas { context, size in
            // 垂直线
            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(color.opacity(0.3)), lineWidth: lineWidth)
                x += spacing
            }

            // 水平线
            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color.opacity(0.3)), lineWidth: lineWidth)
                y += spacing
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 扫描线效果
/// 静态扫描线纹理（移除动画避免闪烁）
struct ScanlineOverlay: View {

    var body: some View {
        Canvas { context, size in
            // 绘制静态水平扫描线纹理
            let lineSpacing: CGFloat = 4    // 扫描线间距
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.white.opacity(0.02)), lineWidth: 1)
                y += lineSpacing
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)            // 不响应触摸事件
    }
}

// MARK: - 渐变动画背景
/// 颜色渐变流动的背景
struct AnimatedGradientBackground: View {

    @State private var animateGradient: Bool = false

    let colors: [Color]

    init(colors: [Color] = [CyberTheme.darkBackground, CyberTheme.darkBlue, Color(hex: 0x1B0A2E)]) {
        self.colors = colors
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: CyberTheme.Animation.gradientFlow)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - 霓虹边框背景
/// 带霓虹流动边框的容器背景
struct NeonBorderBackground: View {

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // 旋转的渐变边框
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AngularGradient(
                        colors: [
                            CyberTheme.neonBlue,
                            CyberTheme.neonPurple,
                            CyberTheme.neonPink,
                            CyberTheme.neonBlue
                        ],
                        center: .center,
                        startAngle: .degrees(rotation),
                        endAngle: .degrees(rotation + 360)
                    ),
                    lineWidth: 2
                )
                .blur(radius: 3)

            // 实际边框
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AngularGradient(
                        colors: [
                            CyberTheme.neonBlue,
                            CyberTheme.neonPurple,
                            CyberTheme.neonPink,
                            CyberTheme.neonBlue
                        ],
                        center: .center,
                        startAngle: .degrees(rotation),
                        endAngle: .degrees(rotation + 360)
                    ),
                    lineWidth: 1
                )

            // 内部背景
            RoundedRectangle(cornerRadius: 18)
                .fill(CyberTheme.cardBackground)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - 预览
#Preview("CyberBackground - Rich") {
    CyberBackground(intensity: .rich)
}

#Preview("CyberBackground - Normal") {
    CyberBackground(intensity: .normal)
}

#Preview("CyberBackground - Minimal") {
    CyberBackground(intensity: .minimal)
}

#Preview("GridOverlay") {
    ZStack {
        Color.black.ignoresSafeArea()
        GridOverlay()
    }
}
