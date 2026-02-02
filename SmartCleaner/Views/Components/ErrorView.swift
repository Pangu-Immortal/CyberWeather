//
//  ErrorView.swift
//  SmartCleaner
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
    case unknown                    // 未知错误

    /// 从错误信息推断类型
    static func from(message: String) -> UserFriendlyError {
        let lowercased = message.lowercased()
        if lowercased.contains("网络") || lowercased.contains("network") || lowercased.contains("connection") {
            return .network
        } else if lowercased.contains("位置") || lowercased.contains("location") || lowercased.contains("定位") {
            return .location
        } else if lowercased.contains("服务器") || lowercased.contains("server") || lowercased.contains("http") {
            return .server
        }
        return .unknown
    }

    var icon: String {
        switch self {
        case .network: return "wifi.slash"
        case .location: return "location.slash"
        case .server: return "server.rack"
        case .unknown: return "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch self {
        case .network: return CyberTheme.neonBlue
        case .location: return CyberTheme.neonPurple
        case .server: return CyberTheme.neonOrange
        case .unknown: return CyberTheme.neonPink
        }
    }

    var title: String {
        switch self {
        case .network: return "网络连接失败"
        case .location: return "定位服务异常"
        case .server: return "服务暂时不可用"
        case .unknown: return "出了点问题"
        }
    }

    var suggestion: String {
        switch self {
        case .network:
            return "请检查网络连接后重试"
        case .location:
            return "请确保已开启定位权限"
        case .server:
            return "服务器繁忙，请稍后重试"
        case .unknown:
            return "请稍后重试或检查网络设置"
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
                .foregroundStyle(errorType.color)
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
                .foregroundStyle(CyberTheme.textPrimary)

            // 建议
            Text(errorType.suggestion)
                .font(.subheadline)
                .foregroundStyle(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)

            // 详细错误（开发调试用，生产环境可隐藏）
            #if DEBUG
            Text(message)
                .font(.caption2)
                .foregroundStyle(CyberTheme.textTertiary)
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
                        .foregroundStyle(CyberTheme.textSecondary)
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
                    .foregroundStyle(CyberTheme.textPrimary)
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
                .foregroundStyle(CyberTheme.neonOrange)

            Text(message)
                .font(.caption)
                .foregroundStyle(CyberTheme.textPrimary)
                .lineLimit(2)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(CyberTheme.textTertiary)
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
                    .foregroundStyle(CyberTheme.neonPurple.opacity(0.6))
            }

            VStack(spacing: CyberTheme.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(CyberTheme.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(CyberTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(CyberTheme.textPrimary)
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
                    .foregroundStyle(CyberTheme.neonBlue)
                    .neonGlow(color: CyberTheme.neonBlue, radius: 10)
            }

            // 文字
            VStack(spacing: CyberTheme.Spacing.sm) {
                Text("需要定位权限")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(CyberTheme.textPrimary)

                Text("开启定位权限以获取您所在位置的精准天气信息")
                    .font(.subheadline)
                    .foregroundStyle(CyberTheme.textSecondary)
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
                    .foregroundStyle(CyberTheme.textPrimary)
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
                        .foregroundStyle(CyberTheme.textTertiary)
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
