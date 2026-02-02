//
//  HourlyForecastView.swift
//  CyberWeather
//
//  小时预报视图（增强版）
//  横向滚动展示未来 24 小时的详细天气预报
//  支持紧凑/详细两种显示模式
//  包含温度、降水概率、湿度、风速等信息
//

import SwiftUI

// MARK: - 显示模式
enum HourlyDisplayMode {
    case compact    // 紧凑模式（仅温度）
    case detailed   // 详细模式（含降水概率、湿度等）
}

// MARK: - 小时预报视图
/// 横向滚动的小时天气预报
struct HourlyForecastView: View {

    // MARK: - 属性
    let forecasts: [HourlyForecast]                     // 小时预报数据
    @State private var displayMode: HourlyDisplayMode = .compact  // 显示模式
    @State private var isVisible: Bool = false          // 动画可见性

    // MARK: - 视图
    var body: some View {
        VStack(alignment: .leading, spacing: CyberTheme.Spacing.sm) {
            // 标题
            sectionHeader

            // 滚动区域
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CyberTheme.Spacing.sm) {
                    ForEach(Array(forecasts.enumerated()), id: \.element.id) { index, forecast in
                        if displayMode == .compact {
                            HourlyItemCompactView(forecast: forecast)
                                .slideInFromBottom(delay: Double(index) * 0.03, isVisible: isVisible)
                        } else {
                            HourlyItemDetailedView(forecast: forecast)
                                .slideInFromBottom(delay: Double(index) * 0.03, isVisible: isVisible)
                        }
                    }
                }
                .padding(.horizontal, CyberTheme.Spacing.md)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.1)) {
                isVisible = true
            }
        }
    }

    // MARK: - 标题区域
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "clock.fill")
                .font(.caption)
                .foregroundStyle(CyberTheme.neonBlue)

            Text("24 小时预报")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(CyberTheme.textPrimary)

            Spacer()

            // 模式切换按钮
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    displayMode = displayMode == .compact ? .detailed : .compact
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: displayMode == .compact ? "list.bullet" : "square.grid.2x2")
                        .font(.caption)
                    Text(displayMode == .compact ? "详细" : "简洁")
                        .font(.caption2)
                }
                .foregroundStyle(CyberTheme.neonPurple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(CyberTheme.neonPurple.opacity(0.15))
                )
            }
        }
        .padding(.horizontal, CyberTheme.Spacing.md)
    }
}

// MARK: - 紧凑模式单项
/// 紧凑模式下的单个小时天气卡片
struct HourlyItemCompactView: View {

    let forecast: HourlyForecast
    @State private var glowIntensity: Double = 1.0

    var body: some View {
        VStack(spacing: CyberTheme.Spacing.xs) {
            // 时间
            Text(forecast.hour)
                .font(.caption2)
                .fontWeight(forecast.isNow ? .bold : .regular)
                .foregroundStyle(forecast.isNow ? CyberTheme.neonBlue : CyberTheme.textSecondary)

            // 天气图标
            SmallWeatherIcon(
                iconName: forecast.iconName,
                weatherCode: forecast.weatherCode,
                size: 26
            )

            // 温度
            Text(String(format: "%.0f°", forecast.temperature))
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(CyberTheme.textPrimary)

            // 降水概率（仅当有降水可能时显示）
            if forecast.precipitation > 10 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text("\(forecast.precipitation)%")
                        .font(.system(size: 10))
                }
                .foregroundStyle(CyberTheme.neonBlue.opacity(0.8))
            }
        }
        .frame(width: 56, height: forecast.precipitation > 10 ? 110 : 95)
        .padding(.vertical, 6)
        .background(compactBackground)
        .clipShape(RoundedRectangle(cornerRadius: CyberTheme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: CyberTheme.CornerRadius.medium)
                .stroke(
                    forecast.isNow ? CyberTheme.neonBlue.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(color: forecast.isNow ? CyberTheme.neonBlue.opacity(0.3) : Color.clear, radius: 8)
    }

    private var compactBackground: some View {
        Group {
            if forecast.isNow {
                LinearGradient(
                    colors: [
                        CyberTheme.neonBlue.opacity(0.2),
                        CyberTheme.cardBackground.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                CyberTheme.cardBackground.opacity(0.6)
            }
        }
    }
}

// MARK: - 详细模式单项
/// 详细模式下的单个小时天气卡片
struct HourlyItemDetailedView: View {

    let forecast: HourlyForecast

    var body: some View {
        VStack(spacing: CyberTheme.Spacing.xs) {
            // 时间
            Text(forecast.hour)
                .font(.caption2)
                .fontWeight(forecast.isNow ? .bold : .regular)
                .foregroundStyle(forecast.isNow ? CyberTheme.neonBlue : CyberTheme.textSecondary)

            // 天气图标
            SmallWeatherIcon(
                iconName: forecast.iconName,
                weatherCode: forecast.weatherCode,
                size: 24
            )

            // 温度
            Text(String(format: "%.0f°", forecast.temperature))
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(CyberTheme.textPrimary)

            Divider()
                .frame(width: 40)
                .background(CyberTheme.textTertiary.opacity(0.3))

            // 体感温度
            detailRow(icon: "thermometer.medium", value: "\(Int(forecast.apparentTemperature))°", color: temperatureColor)

            // 降水概率
            detailRow(icon: "drop.fill", value: "\(forecast.precipitation)%", color: precipitationColor)

            // 湿度
            detailRow(icon: "humidity.fill", value: "\(forecast.humidity)%", color: humidityColor)

            // 风速
            detailRow(icon: "wind", value: String(format: "%.0f", forecast.windSpeed), color: CyberTheme.textSecondary)
        }
        .frame(width: 65, height: 180)
        .padding(.vertical, 8)
        .background(detailedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CyberTheme.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: CyberTheme.CornerRadius.large)
                .stroke(
                    forecast.isNow ? CyberTheme.neonBlue.opacity(0.5) : CyberTheme.neonPurple.opacity(0.2),
                    lineWidth: forecast.isNow ? 1.5 : 0.5
                )
        )
        .shadow(color: forecast.isNow ? CyberTheme.neonBlue.opacity(0.3) : Color.clear, radius: 8)
    }

    // MARK: - 详细信息行
    private func detailRow(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color.opacity(0.8))
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(CyberTheme.textSecondary)
        }
    }

    // MARK: - 颜色计算
    private var temperatureColor: Color {
        let temp = forecast.apparentTemperature
        if temp > 30 { return CyberTheme.neonOrange }
        if temp > 20 { return CyberTheme.neonYellow }
        if temp < 10 { return CyberTheme.neonBlue }
        return CyberTheme.neonGreen
    }

    private var precipitationColor: Color {
        let prob = forecast.precipitation
        if prob > 70 { return CyberTheme.neonBlue }
        if prob > 40 { return CyberTheme.neonPurple }
        return CyberTheme.textSecondary
    }

    private var humidityColor: Color {
        let hum = forecast.humidity
        if hum > 80 { return CyberTheme.neonBlue }
        if hum > 60 { return CyberTheme.neonPurple.opacity(0.8) }
        return CyberTheme.textSecondary
    }

    private var detailedBackground: some View {
        Group {
            if forecast.isNow {
                LinearGradient(
                    colors: [
                        CyberTheme.neonBlue.opacity(0.15),
                        CyberTheme.neonPurple.opacity(0.1),
                        CyberTheme.cardBackground.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        CyberTheme.cardBackground.opacity(0.7),
                        CyberTheme.cardBackground.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - 旧版单项视图（向后兼容）
struct HourlyItemView: View {

    let forecast: HourlyForecast

    @State private var glowIntensity: Double = 1.0

    var body: some View {
        HourlyItemCompactView(forecast: forecast)
    }
}

// MARK: - 空状态视图
/// 无数据时显示的占位视图
struct HourlyForecastEmptyView: View {

    var body: some View {
        VStack(spacing: CyberTheme.Spacing.sm) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(CyberTheme.neonBlue)

                Text("24 小时预报")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(CyberTheme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, CyberTheme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CyberTheme.Spacing.sm) {
                    ForEach(0..<8, id: \.self) { _ in
                        HourlyItemPlaceholder()
                    }
                }
                .padding(.horizontal, CyberTheme.Spacing.md)
            }
        }
    }
}

// MARK: - 占位项
/// 加载时显示的占位视图
struct HourlyItemPlaceholder: View {

    @State private var opacity: Double = 0.3

    var body: some View {
        VStack(spacing: CyberTheme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 4)
                .fill(CyberTheme.textTertiary)
                .frame(width: 30, height: 12)

            Circle()
                .fill(CyberTheme.textTertiary)
                .frame(width: 28, height: 28)

            RoundedRectangle(cornerRadius: 4)
                .fill(CyberTheme.textTertiary)
                .frame(width: 25, height: 16)
        }
        .frame(width: 56, height: 95)
        .padding(.vertical, 6)
        .glassBackground(cornerRadius: CyberTheme.CornerRadius.medium)
        .opacity(opacity)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1)
                .repeatForever(autoreverses: true)
            ) {
                opacity = 0.6
            }
        }
    }
}

// MARK: - 预览
#Preview("HourlyForecastView Compact") {
    ZStack {
        CyberBackground()

        VStack {
            Spacer()

            HourlyForecastView(forecasts: (0..<24).map { i in
                let hour = Calendar.current.date(byAdding: .hour, value: i, to: Date())!
                let hourFormatter = DateFormatter()
                hourFormatter.dateFormat = "HH:00"

                return HourlyForecast(
                    hour: i == 0 ? "现在" : hourFormatter.string(from: hour),
                    iconName: i < 6 || i > 18 ? "moon.stars.fill" : "sun.max.fill",
                    weatherCode: 0,
                    temperature: Double.random(in: 20...30),
                    precipitation: Int.random(in: 0...50),
                    isNow: i == 0,
                    humidity: Int.random(in: 40...90),
                    windSpeed: Double.random(in: 5...25),
                    uvIndex: Double.random(in: 1...10),
                    apparentTemperature: Double.random(in: 18...32)
                )
            })

            Spacer()
        }
    }
}

#Preview("HourlyForecastEmptyView") {
    ZStack {
        CyberBackground()

        VStack {
            Spacer()

            HourlyForecastEmptyView()

            Spacer()
        }
    }
}
