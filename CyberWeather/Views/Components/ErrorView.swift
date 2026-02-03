//
//  ErrorView.swift
//  CyberWeather
//
//  错误展示视图组件
//  提供友好的错误提示和重试按钮
//  支持不同类型的错误场景（网络、定位、服务器等）
//

import SwiftUI

// MARK: - 错误类型（用户友好）
enum UserFriendlyError {
    case network                    // 网络错误
    case location                   // 定位错误
    case server                     // 服务器错误
    case apiCooldown               // API 冷却中
    case unknown                    // 未知错误

    /// 从错误信息推断类型
    static func from(message: String) -> UserFriendlyError {
        let lowercased = message.lowercased()
        if lowercased.contains("冷却") || lowercased.contains("cooldown") {
            return .apiCooldown
        } else if lowercased.contains("网络") || lowercased.contains("network") || lowercased.contains("connection") || lowercased.contains("offline") || lowercased.contains("离线") {
            return .network
        } else if lowercased.contains("位置") || lowercased.contains("location") || lowercased.contains("定位") {
            return .location
        } else if lowercased.contains("服务器") || lowercased.contains("server") || lowercased.contains("http") || lowercased.contains("500") {
            return .server
        }
        return .unknown
    }

    var icon: String {
        switch self {
        case .network: return "wifi.slash"
        case .location: return "location.slash"
        case .server: return "server.rack"
        case .apiCooldown: return "clock.arrow.circlepath"
        case .unknown: return "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch self {
        case .network: return CyberTheme.neonBlue
        case .location: return CyberTheme.neonPurple
        case .server: return CyberTheme.neonOrange
        case .apiCooldown: return CyberTheme.neonBlue
        case .unknown: return CyberTheme.neonPink
        }
    }

    var title: String {
        switch self {
        case .network: return "网络连接失败"
        case .location: return "定位服务异常"
        case .server: return "服务暂时不可用"
        case .apiCooldown: return "请求太频繁"
        case .unknown: return "出了点问题"
        }
    }

    var suggestion: String {
        switch self {
        case .network:
            return "请检查您的 Wi-Fi 或移动网络是否正常连接"
        case .location:
            return "请在「设置」中允许本应用访问您的位置"
        case .server:
            return "天气服务器正在维护中，请稍后再试"
        case .apiCooldown:
            return "请稍后重试，服务正在恢复中"
        case .unknown:
            return "遇到了意外问题，请稍后重试"
        }
    }

    /// 用户友好的详细解释
    var detailExplanation: String {
        switch self {
        case .network:
            return "无法连接到天气服务，可能是网络不稳定或者您的设备暂时离线。"
        case .location:
            return "需要定位权限才能为您提供当地的精准天气。您也可以选择使用默认位置。"
        case .server:
            return "我们的天气数据提供商暂时无法响应，这通常会在几分钟内恢复。"
        case .apiCooldown:
            return "为了保护服务稳定性，短时间内请求次数有限制，请稍等后自动恢复。"
        case .unknown:
            return "发生了未知错误，请尝试重新打开应用或检查网络设置。"
        }
    }
}

// MARK: - 赛博朋克风格错误弹窗
/// 全屏弹窗样式，美观友好
struct CyberErrorAlert: View {

    let errorType: UserFriendlyError
    var onRetry: (() -> Void)?
    var onDismiss: (() -> Void)?

    @State private var isAnimating: Bool = false
    @State private var showContent: Bool = false

    init(message: String, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.errorType = UserFriendlyError.from(message: message)
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    init(errorType: UserFriendlyError, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.errorType = errorType
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss?()
                }

            // 弹窗卡片
            VStack(spacing: 0) {
                // 顶部装饰条
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(errorType.color.opacity(0.8 - Double(i) * 0.1))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                VStack(spacing: 20) {
                    // 错误图标
                    errorIconSection

                    // 错误信息
                    errorTextSection

                    // 操作按钮
                    actionButtonsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1a1a2e").opacity(0.98),
                                Color(hex: "16213e").opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        errorType.color.opacity(0.6),
                                        errorType.color.opacity(0.2),
                                        errorType.color.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: errorType.color.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    // MARK: - 错误图标区域
    private var errorIconSection: some View {
        ZStack {
            // 外层发光圆环
            Circle()
                .stroke(errorType.color.opacity(0.3), lineWidth: 2)
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // 中层渐变背景
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            errorType.color.opacity(0.2),
                            errorType.color.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 45
                    )
                )
                .frame(width: 90, height: 90)

            // 内层实心背景
            Circle()
                .fill(Color(hex: "0f0f1a"))
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(errorType.color.opacity(0.5), lineWidth: 1)
                )

            // 图标
            Image(systemName: errorType.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(errorType.color)
                .shadow(color: errorType.color.opacity(0.8), radius: 8)
        }
    }

    // MARK: - 错误文字区域
    private var errorTextSection: some View {
        VStack(spacing: 12) {
            // 主标题
            Text(errorType.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // 简短建议
            Text(errorType.suggestion)
                .font(.subheadline)
                .foregroundColor(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)

            // 详细解释
            Text(errorType.detailExplanation)
                .font(.caption)
                .foregroundColor(CyberTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
    }

    // MARK: - 操作按钮区域
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // 重试按钮
            if let onRetry = onRetry {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onRetry()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                        Text("重新加载")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        errorType.color.opacity(0.5),
                                        errorType.color.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(errorType.color.opacity(0.6), lineWidth: 1)
                            )
                    )
                }
            }

            // 关闭按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showContent = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss?()
                }
            }) {
                Text("稍后再试")
                    .font(.subheadline)
                    .foregroundColor(CyberTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - 轻量级 Toast 提示
/// 顶部或底部的小提示条
struct CyberToast: View {

    let message: String
    let type: UserFriendlyError
    var onDismiss: (() -> Void)?

    @State private var isVisible: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: type.icon)
                .font(.subheadline)
                .foregroundColor(type.color)

            // 文字
            VStack(alignment: .leading, spacing: 2) {
                Text(type.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(message)
                    .font(.caption)
                    .foregroundColor(CyberTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // 关闭按钮
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(CyberTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1a1a2e").opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(type.color.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: type.color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - 错误提示视图
/// 友好的错误展示组件
struct ErrorView: View {

    // MARK: - 属性
    let message: String                             // 错误信息
    var onRetry: (() -> Void)?                      // 重试回调
    var onDismiss: (() -> Void)?                    // 关闭回调

    @State private var isAnimating: Bool = false    // 动画状态

    // MARK: - 计算属性
    private var errorType: UserFriendlyError {
        UserFriendlyError.from(message: message)
    }

    // MARK: - 视图
    var body: some View {
        VStack(spacing: CyberTheme.Spacing.lg) {
            // 错误图标
            errorIconView

            // 错误信息
            errorMessageView

            // 操作按钮
            actionButtons
        }
        .padding(CyberTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: CyberTheme.CornerRadius.large)
        .padding(.horizontal, CyberTheme.Spacing.lg)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    // MARK: - 错误图标
    private var errorIconView: some View {
        ZStack {
            // 外圈发光
            Circle()
                .fill(errorType.color.opacity(0.15))
                .frame(width: 80, height: 80)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // 内圈
            Circle()
                .fill(CyberTheme.cardBackground)
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .stroke(errorType.color.opacity(0.5), lineWidth: 2)
                )

            // 图标
            Image(systemName: errorType.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(errorType.color)
                .neonGlow(color: errorType.color, radius: 10)
        }
    }

    // MARK: - 错误信息
    private var errorMessageView: some View {
        VStack(spacing: CyberTheme.Spacing.sm) {
            // 标题
            Text(errorType.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyberTheme.textPrimary)

            // 建议
            Text(errorType.suggestion)
                .font(.subheadline)
                .foregroundColor(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)

            // 详细错误（开发调试用，生产环境可隐藏）
            #if DEBUG
            Text(message)
                .font(.caption2)
                .foregroundColor(CyberTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, CyberTheme.Spacing.xs)
            #endif
        }
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        HStack(spacing: CyberTheme.Spacing.md) {
            // 关闭按钮（如果有回调）
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("关闭")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyberTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CyberTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(CyberTheme.cardBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(CyberTheme.textTertiary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }

            // 重试按钮（如果有回调）
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: CyberTheme.Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("重试")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CyberTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CyberTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [errorType.color.opacity(0.3), errorType.color.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(errorType.color.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

// MARK: - 轻量级错误提示横幅
/// 页面顶部或底部的错误提示条
struct ErrorBanner: View {

    let message: String
    var onDismiss: (() -> Void)?

    @State private var isVisible: Bool = false

    var body: some View {
        HStack(spacing: CyberTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.subheadline)
                .foregroundColor(CyberTheme.neonOrange)

            Text(message)
                .font(.caption)
                .foregroundColor(CyberTheme.textPrimary)
                .lineLimit(2)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(CyberTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, CyberTheme.Spacing.md)
        .padding(.vertical, CyberTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CyberTheme.CornerRadius.medium)
                .fill(CyberTheme.neonOrange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: CyberTheme.CornerRadius.medium)
                        .stroke(CyberTheme.neonOrange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, CyberTheme.Spacing.md)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - 空状态视图
/// 当数据为空时显示
struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var isAnimating: Bool = false

    var body: some View {
        VStack(spacing: CyberTheme.Spacing.lg) {
            // 图标
            ZStack {
                Circle()
                    .fill(CyberTheme.neonPurple.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(CyberTheme.neonPurple.opacity(0.6))
            }

            VStack(spacing: CyberTheme.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(CyberTheme.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(CyberTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyberTheme.textPrimary)
                        .padding(.horizontal, CyberTheme.Spacing.lg)
                        .padding(.vertical, CyberTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(CyberTheme.neonPurple.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(CyberTheme.neonPurple.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(CyberTheme.Spacing.xl)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - 定位权限提示视图
struct LocationPermissionView: View {

    var onRequestPermission: () -> Void
    var onUseDefault: () -> Void

    var body: some View {
        VStack(spacing: CyberTheme.Spacing.lg) {
            // 图标
            ZStack {
                Circle()
                    .fill(CyberTheme.neonBlue.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "location.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(CyberTheme.neonBlue)
                    .neonGlow(color: CyberTheme.neonBlue, radius: 10)
            }

            // 文字
            VStack(spacing: CyberTheme.Spacing.sm) {
                Text("需要定位权限")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyberTheme.textPrimary)

                Text("开启定位权限以获取您所在位置的精准天气信息")
                    .font(.subheadline)
                    .foregroundColor(CyberTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // 按钮
            VStack(spacing: CyberTheme.Spacing.sm) {
                Button(action: onRequestPermission) {
                    HStack(spacing: CyberTheme.Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text("开启定位")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CyberTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CyberTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [CyberTheme.neonBlue.opacity(0.3), CyberTheme.neonPurple.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(CyberTheme.neonBlue.opacity(0.5), lineWidth: 1)
                            )
                    )
                }

                Button(action: onUseDefault) {
                    Text("使用默认位置")
                        .font(.caption)
                        .foregroundColor(CyberTheme.textTertiary)
                }
            }
        }
        .padding(CyberTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: CyberTheme.CornerRadius.large)
        .padding(.horizontal, CyberTheme.Spacing.lg)
    }
}

// MARK: - 预览
#Preview("ErrorView - Network") {
    ZStack {
        CyberBackground()

        ErrorView(
            message: "网络连接失败，请检查网络设置",
            onRetry: { print("Retry") },
            onDismiss: { print("Dismiss") }
        )
    }
}

#Preview("ErrorView - Location") {
    ZStack {
        CyberBackground()

        ErrorView(
            message: "无法获取位置信息",
            onRetry: { print("Retry") }
        )
    }
}

#Preview("ErrorView - Server") {
    ZStack {
        CyberBackground()

        ErrorView(
            message: "服务器错误 (500)",
            onRetry: { print("Retry") }
        )
    }
}

#Preview("ErrorBanner") {
    ZStack {
        CyberBackground()

        VStack {
            ErrorBanner(
                message: "数据加载失败，正在使用缓存数据"
            ) {
                print("Dismiss")
            }
            Spacer()
        }
        .padding(.top, 60)
    }
}

#Preview("EmptyStateView") {
    ZStack {
        CyberBackground()

        EmptyStateView(
            icon: "cloud.sun",
            title: "暂无天气数据",
            message: "请检查网络连接后重新加载",
            actionTitle: "重新加载",
            action: { print("Reload") }
        )
    }
}

#Preview("LocationPermissionView") {
    ZStack {
        CyberBackground()

        LocationPermissionView(
            onRequestPermission: { print("Request") },
            onUseDefault: { print("Use Default") }
        )
    }
}
