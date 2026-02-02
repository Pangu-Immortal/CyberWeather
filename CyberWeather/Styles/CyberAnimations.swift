//
//  CyberAnimations.swift
//  CyberWeather
//
//  赛博朋克动画工具集
//  定义各种动画效果和过渡动画
//

import SwiftUI

// MARK: - 动画工具集
/// 提供常用的赛博朋克风格动画
enum CyberAnimations {

    // MARK: - 弹性动画

    /// 标准弹性动画
    static var spring: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    }

    /// 快速弹性动画
    static var quickSpring: Animation {
        .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    }

    /// 柔和弹性动画
    static var softSpring: Animation {
        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    }

    // MARK: - 缓动动画

    /// 标准缓入缓出
    static var easeInOut: Animation {
        .easeInOut(duration: CyberTheme.Animation.standard)
    }

    /// 快速缓动
    static var quickEase: Animation {
        .easeInOut(duration: CyberTheme.Animation.fast)
    }

    /// 慢速缓动
    static var slowEase: Animation {
        .easeInOut(duration: CyberTheme.Animation.slow)
    }

    // MARK: - 无限循环动画

    /// 呼吸动画（循环）
    static var breathing: Animation {
        .easeInOut(duration: CyberTheme.Animation.breathing)
            .repeatForever(autoreverses: true)
    }

    /// 旋转动画（循环）
    static func rotation(duration: Double = 10) -> Animation {
        .linear(duration: duration)
            .repeatForever(autoreverses: false)
    }

    /// 脉冲动画（循环）
    static var pulse: Animation {
        .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
    }

    // MARK: - 延迟动画

    /// 带延迟的动画
    static func delayed(_ delay: Double) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.7)
            .delay(delay)
    }

    /// 级联延迟（用于列表动画）
    static func cascade(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.7)
            .delay(Double(index) * baseDelay)
    }
}

// MARK: - 过渡效果
extension AnyTransition {

    /// 从底部滑入 + 渐显
    static var slideUpFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// 从左侧滑入
    static var slideFromLeft: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// 缩放 + 渐显
    static var scaleFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }

    /// 赛博朋克风格闪烁出现
    static var cyberGlitch: AnyTransition {
        .modifier(
            active: GlitchModifier(isActive: true),
            identity: GlitchModifier(isActive: false)
        )
    }
}

// MARK: - 闪烁修饰器
/// 模拟数字闪烁的效果
struct GlitchModifier: ViewModifier {

    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 0 : 1)
            .offset(x: isActive ? CGFloat.random(in: -5...5) : 0)
            .blur(radius: isActive ? 2 : 0)
    }
}

// MARK: - 加载动画视图
/// 赛博朋克风格的加载动画
struct CyberLoadingView: View {

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonPink, CyberTheme.neonBlue],
                        center: .center,
                        startAngle: .degrees(rotation),
                        endAngle: .degrees(rotation + 360)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .shadow(color: CyberTheme.neonBlue.opacity(0.5), radius: 10)

            // 内圈
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [CyberTheme.neonPink, CyberTheme.neonBlue, CyberTheme.neonPink],
                        center: .center,
                        startAngle: .degrees(-rotation),
                        endAngle: .degrees(-rotation + 360)
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
                )
                .frame(width: 35, height: 35)

            // 中心点
            Circle()
                .fill(CyberTheme.neonBlue)
                .frame(width: 8, height: 8)
                .scaleEffect(scale)
                .shadow(color: CyberTheme.neonBlue, radius: 5)
        }
        .onAppear {
            withAnimation(CyberAnimations.rotation(duration: 2)) {
                rotation = 360
            }
            withAnimation(CyberAnimations.pulse) {
                scale = 1.3
            }
        }
    }
}

// MARK: - 进度条视图
/// 赛博朋克风格的进度条
struct CyberProgressBar: View {

    let progress: Double // 0 到 1
    let height: CGFloat

    @State private var animatedProgress: Double = 0
    @State private var glowOffset: CGFloat = -100

    init(progress: Double, height: CGFloat = 6) {
        self.progress = progress
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(CyberTheme.cardBackground)

                // 进度条
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [CyberTheme.neonBlue, CyberTheme.neonPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
                    .shadow(color: CyberTheme.neonBlue.opacity(0.5), radius: 5)

                // 流光效果
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50)
                    .offset(x: glowOffset)
                    .mask(
                        RoundedRectangle(cornerRadius: height / 2)
                            .frame(width: geometry.size.width * animatedProgress)
                    )
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
            withAnimation(
                .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                glowOffset = 300
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - 预览
#Preview("CyberLoadingView") {
    ZStack {
        CyberTheme.darkBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            CyberLoadingView()

            CyberProgressBar(progress: 0.7)
                .padding(.horizontal, 40)
        }
    }
}
