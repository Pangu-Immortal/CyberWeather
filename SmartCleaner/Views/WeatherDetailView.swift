//
//  WeatherDetailView.swift
//  SmartCleaner
//
//  天气详情视图（增强版）
//  展示风速、湿度、气压、能见度、体感温度等详细天气信息
//  包含可视化指示器、颜色编码和环形进度图
//

import SwiftUI

// MARK: - 天气详情视图
/// 网格展示天气详细数据，支持展开查看更多
struct WeatherDetailView: View {

    // MARK: - 属性
    let details: WeatherDetails?                        // 天气详情数据

    @State private var isVisible: Bool = false          // 动画可见性
    @State private var showAllDetails: Bool = false     // 显示全部详情

    // MARK: - 网格布局
    private let columns = [
        GridItem(.flexible(), spacing: CyberTheme.Spacing.sm),
        GridItem(.flexible(), spacing: CyberTheme.Spacing.sm)
    ]

    // MARK: - 视图
    var body: some View {
        VStack(alignment: .leading, spacing: CyberTheme.Spacing.sm) {
            // 标题
            sectionHeader

            // 详情网格
            if let details = details {
                // 主要详情卡片（始终显示）
                GlassCard {
                    LazyVGrid(columns: columns, spacing: CyberTheme.Spacing.md) {
                        // 体感温度
                        DetailCardWithGauge(
                            icon: "thermometer.medium",
                            title: "体感温度",
                            value: String(format: "%.0f°", details.apparentTemperature),
                            progress: normalizeTemperature(details.apparentTemperature),
                            progressColor: temperatureColor(details.apparentTemperature),
                            subtitle: temperatureFeeling(details.apparentTemperature)
                        )
                        .slideInFromBottom(delay: 0, isVisible: isVisible)

                        // 湿度
                        DetailCardWithGauge(
                            icon: "humidity",
                            title: "湿度",
                            value: "\(details.humidity)%",
                            progress: Double(details.humidity) / 100,
                            progressColor: humidityColor(details.humidity),
                            subtitle: humidityLevel(details.humidity)
                        )
                        .slideInFromBottom(delay: 0.05, isVisible: isVisible)

                        // 风速
                        DetailCardWithGauge(
                            icon: "wind",
                            title: "风速",
                            value: String(format: "%.0f", details.windSpeed),
                            unit: "km/h",
                            progress: min(details.windSpeed / 60, 1.0),
                            progressColor: windColor(details.windSpeed),
                            subtitle: windLevel(details.windSpeed)
                        )
                        .slideInFromBottom(delay: 0.1, isVisible: isVisible)

                        // UV 指数
                        DetailCardWithGauge(
                            icon: "sun.max.fill",
                            title: "UV 指数",
                            value: String(format: "%.0f", details.uvIndex),
                            progress: min(details.uvIndex / 11, 1.0),
                            progressColor: uvColor(details.uvIndex),
                            subtitle: uvLevel(details.uvIndex)
                        )
                        .slideInFromBottom(delay: 0.15, isVisible: isVisible)
                    }
                }
                .padding(.horizontal, CyberTheme.Spacing.md)

                // 展开时显示更多详情
                if showAllDetails {
                    additionalDetailsSection(details)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 风向信息卡片
                windDirectionCard(details)
                    .padding(.horizontal, CyberTheme.Spacing.md)
                    .slideInFromBottom(delay: 0.2, isVisible: isVisible)

                // 日出日落卡片
                sunTimesCard(details)
                    .padding(.horizontal, CyberTheme.Spacing.md)
                    .slideInFromBottom(delay: 0.25, isVisible: isVisible)

            } else {
                // 占位视图
                WeatherDetailPlaceholder()
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
            Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundStyle(CyberTheme.neonGreen)

            Text("天气详情")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(CyberTheme.textPrimary)

            Spacer()

            // 展开/收起按钮
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showAllDetails.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showAllDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                    Text(showAllDetails ? "收起" : "更多")
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

    // MARK: - 额外详情区域
    private func additionalDetailsSection(_ details: WeatherDetails) -> some View {
        GlassCard {
            LazyVGrid(columns: columns, spacing: CyberTheme.Spacing.md) {
                // 气压
                DetailCardWithGauge(
                    icon: "gauge.medium",
                    title: "气压",
                    value: String(format: "%.0f", details.pressure),
                    unit: "hPa",
                    progress: normalizePressure(details.pressure),
                    progressColor: pressureColor(details.pressure),
                    subtitle: pressureLevel(details.pressure)
                )
                .slideInFromBottom(delay: 0, isVisible: true)

                // 能见度
                DetailCardWithGauge(
                    icon: "eye.fill",
                    title: "能见度",
                    value: String(format: "%.0f", details.visibility),
                    unit: "km",
                    progress: min(details.visibility / 20, 1.0),
                    progressColor: visibilityColor(details.visibility),
                    subtitle: visibilityLevel(details.visibility)
                )
                .slideInFromBottom(delay: 0.05, isVisible: true)

                // 降水量
                DetailCardItem(
                    icon: "drop.fill",
                    title: "降水量",
                    value: String(format: "%.1f", details.precipitation),
                    unit: "mm",
                    iconColor: CyberTheme.neonBlue
                )
                .slideInFromBottom(delay: 0.1, isVisible: true)

                // 露点温度（估算）
                DetailCardItem(
                    icon: "thermometer.snowflake",
                    title: "露点",
                    value: String(format: "%.0f°", calculateDewPoint(temp: details.apparentTemperature, humidity: details.humidity)),
                    iconColor: CyberTheme.neonPurple
                )
                .slideInFromBottom(delay: 0.15, isVisible: true)
            }
        }
        .padding(.horizontal, CyberTheme.Spacing.md)
    }

    // MARK: - 风向卡片
    private func windDirectionCard(_ details: WeatherDetails) -> some View {
        GlassCard {
            HStack {
                // 风向指南针
                ZStack {
                    // 外圈背景
                    Circle()
                        .fill(CyberTheme.cardBackground.opacity(0.5))
                        .frame(width: 60, height: 60)

                    // 外圈边框
                    Circle()
                        .stroke(CyberTheme.cardBorderGradient, lineWidth: 2)
                        .frame(width: 60, height: 60)

                    // 方向标记
                    ForEach(0..<8, id: \.self) { i in
                        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
                        let isCardinal = i % 2 == 0
                        Text(directions[i])
                            .font(.system(size: isCardinal ? 9 : 7, weight: isCardinal ? .bold : .medium))
                            .foregroundStyle(isCardinal ? CyberTheme.textSecondary : CyberTheme.textTertiary)
                            .offset(y: -24)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }

                    // 指针
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(CyberTheme.neonBlue)
                        .rotationEffect(.degrees(details.windDirection))
                        .neonGlow(color: CyberTheme.neonBlue, radius: 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("风向")
                        .font(.caption)
                        .foregroundStyle(CyberTheme.textSecondary)

                    HStack(spacing: 4) {
                        Text(details.windDirectionText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(CyberTheme.textPrimary)

                        Text("风")
                            .font(.subheadline)
                            .foregroundStyle(CyberTheme.textSecondary)
                    }

                    HStack(spacing: 8) {
                        Text("\(Int(details.windDirection))°")
                            .font(.caption)
                            .foregroundStyle(CyberTheme.textTertiary)

                        // 风力等级徽章
                        Text(windLevel(details.windSpeed))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(windColor(details.windSpeed))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(windColor(details.windSpeed).opacity(0.15))
                            )
                    }
                }

                Spacer()

                // 风速可视化
                VStack(alignment: .trailing, spacing: 4) {
                    Text("风速")
                        .font(.caption)
                        .foregroundStyle(CyberTheme.textSecondary)

                    Text(String(format: "%.0f", details.windSpeed))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(windColor(details.windSpeed))

                    Text("km/h")
                        .font(.caption2)
                        .foregroundStyle(CyberTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - 日出日落卡片
    private func sunTimesCard(_ details: WeatherDetails) -> some View {
        GlassCard {
            HStack(spacing: CyberTheme.Spacing.lg) {
                // 日出
                HStack(spacing: CyberTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(CyberTheme.neonYellow.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(CyberTheme.neonYellow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("日出")
                            .font(.caption)
                            .foregroundStyle(CyberTheme.textSecondary)

                        Text(details.sunrise)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(CyberTheme.textPrimary)
                    }
                }

                Spacer()

                // 日照进度条
                sunProgressBar(sunrise: details.sunrise, sunset: details.sunset)

                Spacer()

                // 日落
                HStack(spacing: CyberTheme.Spacing.sm) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("日落")
                            .font(.caption)
                            .foregroundStyle(CyberTheme.textSecondary)

                        Text(details.sunset)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(CyberTheme.textPrimary)
                    }

                    ZStack {
                        Circle()
                            .fill(CyberTheme.neonOrange.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "sunset.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(CyberTheme.neonOrange)
                    }
                }
            }
        }
    }

    // MARK: - 日照进度条
    private func sunProgressBar(sunrise: String, sunset: String) -> some View {
        GeometryReader { geometry in
            let progress = calculateSunProgress(sunrise: sunrise, sunset: sunset)
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                // 背景轨道
                Capsule()
                    .fill(CyberTheme.cardBackground)
                    .frame(height: 6)

                // 进度条
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [CyberTheme.neonYellow, CyberTheme.neonOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, width * progress), height: 6)

                // 太阳位置指示器
                if progress > 0 && progress < 1 {
                    Circle()
                        .fill(CyberTheme.neonYellow)
                        .frame(width: 12, height: 12)
                        .shadow(color: CyberTheme.neonYellow.opacity(0.6), radius: 4)
                        .offset(x: max(0, width * progress - 6))
                }
            }
        }
        .frame(height: 12)
        .frame(maxWidth: 80)
    }

    // MARK: - 辅助计算方法

    /// 计算日照进度（0-1）
    private func calculateSunProgress(sunrise: String, sunset: String) -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let sunriseDate = formatter.date(from: sunrise),
              let sunsetDate = formatter.date(from: sunset) else {
            return 0.5
        }

        let now = Date()
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        guard let nowMinutes = nowComponents.hour.map({ $0 * 60 + (nowComponents.minute ?? 0) }) else {
            return 0.5
        }

        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunriseDate)
        let sunsetComponents = calendar.dateComponents([.hour, .minute], from: sunsetDate)

        let sunriseMinutes = (sunriseComponents.hour ?? 6) * 60 + (sunriseComponents.minute ?? 0)
        let sunsetMinutes = (sunsetComponents.hour ?? 18) * 60 + (sunsetComponents.minute ?? 0)

        if nowMinutes < sunriseMinutes { return 0 }
        if nowMinutes > sunsetMinutes { return 1 }

        let totalDaylight = sunsetMinutes - sunriseMinutes
        let elapsed = nowMinutes - sunriseMinutes

        return Double(elapsed) / Double(totalDaylight)
    }

    /// 计算露点温度
    private func calculateDewPoint(temp: Double, humidity: Int) -> Double {
        // Magnus公式近似
        let a = 17.27
        let b = 237.7
        let alpha = ((a * temp) / (b + temp)) + log(Double(humidity) / 100)
        return (b * alpha) / (a - alpha)
    }

    // MARK: - 标准化方法

    private func normalizeTemperature(_ temp: Double) -> Double {
        // 假设温度范围 -20 到 45
        return (temp + 20) / 65
    }

    private func normalizePressure(_ pressure: Double) -> Double {
        // 正常气压范围 980-1040 hPa
        return (pressure - 980) / 60
    }

    // MARK: - 颜色方法

    private func temperatureColor(_ temp: Double) -> Color {
        switch temp {
        case ..<10: return CyberTheme.neonBlue
        case 10..<20: return CyberTheme.neonGreen
        case 20..<30: return CyberTheme.neonYellow
        case 30..<35: return CyberTheme.neonOrange
        default: return CyberTheme.neonPink
        }
    }

    private func humidityColor(_ humidity: Int) -> Color {
        switch humidity {
        case 0..<30: return CyberTheme.neonOrange
        case 30..<60: return CyberTheme.neonGreen
        case 60..<80: return CyberTheme.neonBlue
        default: return CyberTheme.neonPurple
        }
    }

    private func windColor(_ speed: Double) -> Color {
        switch speed {
        case 0..<10: return CyberTheme.neonGreen
        case 10..<20: return CyberTheme.neonBlue
        case 20..<40: return CyberTheme.neonYellow
        case 40..<60: return CyberTheme.neonOrange
        default: return CyberTheme.neonPink
        }
    }

    private func uvColor(_ index: Double) -> Color {
        switch index {
        case 0..<3: return CyberTheme.neonGreen
        case 3..<6: return CyberTheme.neonYellow
        case 6..<8: return CyberTheme.neonOrange
        case 8..<11: return CyberTheme.neonPink
        default: return CyberTheme.neonPurple
        }
    }

    private func pressureColor(_ pressure: Double) -> Color {
        switch pressure {
        case ..<1000: return CyberTheme.neonPurple
        case 1000..<1013: return CyberTheme.neonBlue
        case 1013..<1025: return CyberTheme.neonGreen
        default: return CyberTheme.neonYellow
        }
    }

    private func visibilityColor(_ visibility: Double) -> Color {
        switch visibility {
        case 0..<2: return CyberTheme.neonPink
        case 2..<5: return CyberTheme.neonOrange
        case 5..<10: return CyberTheme.neonYellow
        default: return CyberTheme.neonGreen
        }
    }

    // MARK: - 等级文本方法

    private func temperatureFeeling(_ temp: Double) -> String {
        switch temp {
        case ..<0: return "严寒"
        case 0..<10: return "寒冷"
        case 10..<18: return "凉爽"
        case 18..<26: return "舒适"
        case 26..<32: return "温暖"
        case 32..<38: return "炎热"
        default: return "酷热"
        }
    }

    private func humidityLevel(_ humidity: Int) -> String {
        switch humidity {
        case 0..<30: return "干燥"
        case 30..<60: return "舒适"
        case 60..<80: return "潮湿"
        default: return "闷湿"
        }
    }

    private func windLevel(_ speed: Double) -> String {
        switch speed {
        case 0..<1: return "无风"
        case 1..<6: return "微风"
        case 6..<12: return "轻风"
        case 12..<20: return "和风"
        case 20..<29: return "清风"
        case 29..<39: return "强风"
        case 39..<50: return "疾风"
        case 50..<62: return "大风"
        default: return "狂风"
        }
    }

    private func uvLevel(_ index: Double) -> String {
        switch index {
        case 0..<3: return "低"
        case 3..<6: return "中等"
        case 6..<8: return "高"
        case 8..<11: return "很高"
        default: return "极高"
        }
    }

    private func pressureLevel(_ pressure: Double) -> String {
        switch pressure {
        case ..<1000: return "低气压"
        case 1000..<1013: return "偏低"
        case 1013..<1025: return "正常"
        default: return "高气压"
        }
    }

    private func visibilityLevel(_ visibility: Double) -> String {
        switch visibility {
        case 0..<1: return "极差"
        case 1..<2: return "差"
        case 2..<5: return "一般"
        case 5..<10: return "良好"
        default: return "极佳"
        }
    }
}

// MARK: - 带环形进度的详情卡片
struct DetailCardWithGauge: View {

    let icon: String                    // SF Symbols 图标名
    let title: String                   // 标题
    let value: String                   // 数值
    var unit: String = ""               // 单位
    let progress: Double                // 进度 0-1
    let progressColor: Color            // 进度条颜色
    var subtitle: String = ""           // 副标题

    var body: some View {
        VStack(alignment: .leading, spacing: CyberTheme.Spacing.sm) {
            // 标题行
            HStack(spacing: CyberTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(progressColor)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(CyberTheme.textSecondary)

                Spacer()
            }

            // 数值和进度
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(value)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(CyberTheme.textPrimary)

                        if !unit.isEmpty {
                            Text(unit)
                                .font(.caption2)
                                .foregroundStyle(CyberTheme.textTertiary)
                        }
                    }

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(progressColor)
                    }
                }

                Spacer()

                // 环形进度
                ZStack {
                    // 背景环
                    Circle()
                        .stroke(CyberTheme.cardBackground, lineWidth: 4)
                        .frame(width: 36, height: 36)

                    // 进度环
                    Circle()
                        .trim(from: 0, to: min(max(progress, 0), 1))
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: progressColor.opacity(0.4), radius: 3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 占位视图
struct WeatherDetailPlaceholder: View {

    private let columns = [
        GridItem(.flexible(), spacing: CyberTheme.Spacing.sm),
        GridItem(.flexible(), spacing: CyberTheme.Spacing.sm)
    ]

    @State private var opacity: Double = 0.3

    var body: some View {
        GlassCard {
            LazyVGrid(columns: columns, spacing: CyberTheme.Spacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: CyberTheme.Spacing.sm) {
                        HStack(spacing: CyberTheme.Spacing.xs) {
                            Circle()
                                .fill(CyberTheme.textTertiary)
                                .frame(width: 14, height: 14)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(CyberTheme.textTertiary)
                                .frame(width: 40, height: 12)
                        }

                        RoundedRectangle(cornerRadius: 4)
                            .fill(CyberTheme.textTertiary)
                            .frame(width: 60, height: 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
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
}

// MARK: - 预览
#Preview("WeatherDetailView") {
    ZStack {
        CyberBackground()

        ScrollView {
            WeatherDetailView(details: WeatherDetails(
                windSpeed: 12.5,
                windDirection: 135,
                windDirectionText: "东南风",
                humidity: 65,
                visibility: 10,
                uvIndex: 6,
                sunrise: "06:30",
                sunset: "18:45",
                pressure: 1013,
                precipitation: 2.5,
                apparentTemperature: 26
            ))
            .padding(.top, 100)
        }
    }
}

#Preview("WeatherDetailView Expanded") {
    ZStack {
        CyberBackground()

        ScrollView {
            WeatherDetailView(details: WeatherDetails(
                windSpeed: 35,
                windDirection: 270,
                windDirectionText: "西风",
                humidity: 85,
                visibility: 5,
                uvIndex: 9,
                sunrise: "05:45",
                sunset: "19:30",
                pressure: 998,
                precipitation: 15.5,
                apparentTemperature: 32
            ))
            .padding(.top, 100)
        }
    }
}

#Preview("WeatherDetailPlaceholder") {
    ZStack {
        CyberBackground()

        WeatherDetailView(details: nil)
    }
}
