//
//  DailyForecastView.swift
//  SmartCleaner
//
//  每日预报视图（增强版）
//  展示未来 7 天的详细天气预报
//  支持展开查看详情、温度趋势图、降水概率等
//

import SwiftUI

// MARK: - 每日预报视图
/// 7 天天气预报列表
struct DailyForecastView: View {

    // MARK: - 属性
    let forecasts: [DailyForecast]                      // 每日预报数据

    @State private var isVisible: Bool = false          // 动画可见性
    @State private var expandedId: UUID? = nil          // 展开的项目 ID
    @State private var showTrendChart: Bool = false     // 是否显示趋势图

    // MARK: - 计算温度范围
    private var tempRange: (min: Double, max: Double) {
        guard !forecasts.isEmpty else { return (0, 30) }
        let allTemps = forecasts.flatMap { [$0.lowTemp, $0.highTemp] }
        return (allTemps.min() ?? 0, allTemps.max() ?? 30)
    }

    // MARK: - 视图
    var body: some View {
        VStack(alignment: .leading, spacing: CyberTheme.Spacing.sm) {
            // 标题
            sectionHeader

            // 温度趋势图（可折叠）
            if showTrendChart {
                temperatureTrendChart
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // 预报列表
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(forecasts.enumerated()), id: \.element.id) { index, forecast in
                        DailyItemView(
                            forecast: forecast,
                            tempRange: tempRange,
                            isExpanded: expandedId == forecast.id
                        )
                        .onTapGesture {
                            withAnimation(CyberAnimations.spring) {
                                if expandedId == forecast.id {
                                    expandedId = nil
                                } else {
                                    expandedId = forecast.id
                                }
                            }
                        }
                        .slideInFromBottom(delay: Double(index) * 0.05, isVisible: isVisible)

                        // 分隔线（最后一项除外）
                        if index < forecasts.count - 1 {
                            Divider()
                                .background(CyberTheme.textTertiary.opacity(0.3))
                                .padding(.horizontal, CyberTheme.Spacing.md)
                        }
                    }
                }
            }
            .padding(.horizontal, CyberTheme.Spacing.md)
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
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(CyberTheme.neonPurple)

            Text("7 天预报")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(CyberTheme.textPrimary)

            Spacer()

            // 趋势图切换按钮
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showTrendChart.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showTrendChart ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis")
                        .font(.caption)
                    Text(showTrendChart ? "隐藏" : "趋势")
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

    // MARK: - 温度趋势图
    private var temperatureTrendChart: some View {
        GlassCard(padding: CyberTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: CyberTheme.Spacing.xs) {
                Text("温度趋势")
                    .font(.caption)
                    .foregroundStyle(CyberTheme.textSecondary)

                MiniTemperatureTrendView(forecasts: forecasts)
                    .frame(height: 80)
            }
        }
        .padding(.horizontal, CyberTheme.Spacing.md)
    }
}

// MARK: - 迷你温度趋势图
struct MiniTemperatureTrendView: View {

    let forecasts: [DailyForecast]

    private var tempRange: (min: Double, max: Double) {
        guard !forecasts.isEmpty else { return (0, 30) }
        let allTemps = forecasts.flatMap { [$0.lowTemp, $0.highTemp] }
        let minTemp = allTemps.min() ?? 0
        let maxTemp = allTemps.max() ?? 30
        return (minTemp - 2, maxTemp + 2) // 添加边距
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let itemWidth = width / CGFloat(max(forecasts.count, 1))
            let range = tempRange.max - tempRange.min

            ZStack {
                // 最高温曲线
                Path { path in
                    for (index, forecast) in forecasts.enumerated() {
                        let x = itemWidth * CGFloat(index) + itemWidth / 2
                        let yRatio = range > 0 ? (tempRange.max - forecast.highTemp) / range : 0.5
                        let y = height * 0.15 + (height * 0.7) * CGFloat(yRatio)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [CyberTheme.neonOrange, CyberTheme.neonPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // 最低温曲线
                Path { path in
                    for (index, forecast) in forecasts.enumerated() {
                        let x = itemWidth * CGFloat(index) + itemWidth / 2
                        let yRatio = range > 0 ? (tempRange.max - forecast.lowTemp) / range : 0.5
                        let y = height * 0.15 + (height * 0.7) * CGFloat(yRatio)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [CyberTheme.neonBlue, CyberTheme.neonPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // 数据点和标签
                ForEach(Array(forecasts.enumerated()), id: \.element.id) { index, forecast in
                    let x = itemWidth * CGFloat(index) + itemWidth / 2

                    // 最高温点
                    let highYRatio = range > 0 ? (tempRange.max - forecast.highTemp) / range : 0.5
                    let highY = height * 0.15 + (height * 0.7) * CGFloat(highYRatio)

                    Circle()
                        .fill(CyberTheme.neonOrange)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: highY)
                        .shadow(color: CyberTheme.neonOrange.opacity(0.6), radius: 3)

                    // 最低温点
                    let lowYRatio = range > 0 ? (tempRange.max - forecast.lowTemp) / range : 0.5
                    let lowY = height * 0.15 + (height * 0.7) * CGFloat(lowYRatio)

                    Circle()
                        .fill(CyberTheme.neonBlue)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: lowY)
                        .shadow(color: CyberTheme.neonBlue.opacity(0.6), radius: 3)

                    // 日期标签
                    Text(forecast.dayName.prefix(2))
                        .font(.system(size: 9))
                        .foregroundStyle(CyberTheme.textTertiary)
                        .position(x: x, y: height - 8)
                }
            }
        }
    }
}

// MARK: - 单日预报项
/// 显示单日的天气信息
struct DailyItemView: View {

    let forecast: DailyForecast
    let tempRange: (min: Double, max: Double)
    let isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 主要内容行
            HStack(spacing: CyberTheme.Spacing.md) {
                // 日期
                VStack(alignment: .leading, spacing: 2) {
                    Text(forecast.dayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(CyberTheme.textPrimary)

                    Text(forecast.dateString)
                        .font(.caption2)
                        .foregroundStyle(CyberTheme.textTertiary)
                }
                .frame(width: 50, alignment: .leading)

                // 天气图标
                SmallWeatherIcon(
                    iconName: forecast.iconName,
                    weatherCode: forecast.weatherCode,
                    size: 26
                )

                // 降水概率（显著时）
                if forecast.precipitationProbability > 20 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                        Text("\(forecast.precipitationProbability)%")
                            .font(.caption2)
                    }
                    .foregroundStyle(CyberTheme.neonBlue.opacity(0.8))
                    .frame(width: 40)
                } else {
                    Spacer()
                        .frame(width: 40)
                }

                // 温度范围条
                TemperatureRangeBar(
                    low: forecast.lowTemp,
                    high: forecast.highTemp,
                    globalMin: tempRange.min,
                    globalMax: tempRange.max
                )
                .frame(width: 80)

                // 温度数值
                HStack(spacing: CyberTheme.Spacing.xs) {
                    Text(String(format: "%.0f°", forecast.lowTemp))
                        .font(.subheadline)
                        .foregroundStyle(CyberTheme.neonBlue)

                    Text(String(format: "%.0f°", forecast.highTemp))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(CyberTheme.neonOrange)
                }
            }
            .padding(.horizontal, CyberTheme.Spacing.md)
            .padding(.vertical, CyberTheme.Spacing.sm)

            // 展开详情
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .contentShape(Rectangle()) // 使整行可点击
    }

    // MARK: - 展开内容
    private var expandedContent: some View {
        VStack(spacing: CyberTheme.Spacing.sm) {
            Divider()
                .background(CyberTheme.textTertiary.opacity(0.3))

            // 详细信息网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: CyberTheme.Spacing.sm) {
                // 天气描述
                detailItem(icon: "cloud.fill", title: "天气", value: forecast.description)

                // 紫外线指数
                detailItem(icon: "sun.max.fill", title: "紫外线", value: uvIndexText, color: uvIndexColor)

                // 降水概率
                detailItem(icon: "drop.fill", title: "降水", value: "\(forecast.precipitationProbability)%", color: precipitationColor)
            }
            .padding(.horizontal, CyberTheme.Spacing.md)

            // 提示行
            HStack {
                Spacer()
                Text("点击收起")
                    .font(.caption2)
                    .foregroundStyle(CyberTheme.textTertiary)
            }
            .padding(.horizontal, CyberTheme.Spacing.md)
            .padding(.bottom, CyberTheme.Spacing.sm)
        }
    }

    // MARK: - 详细信息项
    private func detailItem(icon: String, title: String, value: String, color: Color = CyberTheme.textSecondary) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color.opacity(0.8))

            Text(title)
                .font(.caption2)
                .foregroundStyle(CyberTheme.textTertiary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(CyberTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 紫外线文本和颜色
    private var uvIndexText: String {
        let uv = forecast.uvIndex
        switch uv {
        case 0..<3: return "弱"
        case 3..<6: return "中"
        case 6..<8: return "强"
        case 8..<11: return "很强"
        default: return "极强"
        }
    }

    private var uvIndexColor: Color {
        let uv = forecast.uvIndex
        switch uv {
        case 0..<3: return CyberTheme.neonGreen
        case 3..<6: return CyberTheme.neonYellow
        case 6..<8: return CyberTheme.neonOrange
        default: return CyberTheme.neonPink
        }
    }

    private var precipitationColor: Color {
        let prob = forecast.precipitationProbability
        if prob > 70 { return CyberTheme.neonBlue }
        if prob > 40 { return CyberTheme.neonPurple }
        return CyberTheme.textSecondary
    }
}

// MARK: - 温度范围条
/// 可视化显示温度范围的渐变条
struct TemperatureRangeBar: View {

    let low: Double                 // 当日最低温
    let high: Double                // 当日最高温
    let globalMin: Double           // 全局最低温
    let globalMax: Double           // 全局最高温

    var body: some View {
        GeometryReader { geometry in
            let totalRange = globalMax - globalMin
            let barWidth = geometry.size.width

            // 计算条的起止位置
            let startRatio = totalRange > 0 ? (low - globalMin) / totalRange : 0
            let endRatio = totalRange > 0 ? (high - globalMin) / totalRange : 1

            ZStack(alignment: .leading) {
                // 背景轨道
                Capsule()
                    .fill(CyberTheme.cardBackground)
                    .frame(height: 6)

                // 温度范围条
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [CyberTheme.neonBlue, CyberTheme.neonPurple, CyberTheme.neonOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(10, barWidth * (endRatio - startRatio)),
                        height: 6
                    )
                    .offset(x: barWidth * startRatio)
                    .shadow(color: CyberTheme.neonPurple.opacity(0.4), radius: 3)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - 空状态视图
struct DailyForecastEmptyView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: CyberTheme.Spacing.sm) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(CyberTheme.neonPurple)

                Text("7 天预报")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(CyberTheme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, CyberTheme.Spacing.md)

            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        DailyItemPlaceholder()

                        if index < 4 {
                            Divider()
                                .background(CyberTheme.textTertiary.opacity(0.3))
                                .padding(.horizontal, CyberTheme.Spacing.md)
                        }
                    }
                }
            }
            .padding(.horizontal, CyberTheme.Spacing.md)
        }
    }
}

// MARK: - 占位项
struct DailyItemPlaceholder: View {

    @State private var opacity: Double = 0.3

    var body: some View {
        HStack(spacing: CyberTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: 4)
                .fill(CyberTheme.textTertiary)
                .frame(width: 50, height: 16)

            Circle()
                .fill(CyberTheme.textTertiary)
                .frame(width: 26, height: 26)

            Spacer()

            RoundedRectangle(cornerRadius: 3)
                .fill(CyberTheme.textTertiary)
                .frame(width: 80, height: 6)

            RoundedRectangle(cornerRadius: 4)
                .fill(CyberTheme.textTertiary)
                .frame(width: 60, height: 16)
        }
        .padding(.horizontal, CyberTheme.Spacing.md)
        .padding(.vertical, CyberTheme.Spacing.sm)
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
#Preview("DailyForecastView") {
    ZStack {
        CyberBackground()

        ScrollView {
            DailyForecastView(forecasts: (0..<7).map { i in
                let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEEE"
                dayFormatter.locale = Locale(identifier: "zh_CN")
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M月d日"

                let dayName: String
                if i == 0 {
                    dayName = "今天"
                } else if i == 1 {
                    dayName = "明天"
                } else {
                    dayName = dayFormatter.string(from: date)
                }

                return DailyForecast(
                    dayName: dayName,
                    dateString: dateFormatter.string(from: date),
                    iconName: ["sun.max.fill", "cloud.sun.fill", "cloud.fill", "cloud.rain.fill"][Int.random(in: 0...3)],
                    weatherCode: [0, 1, 2, 61][Int.random(in: 0...3)],
                    lowTemp: Double(15 + i),
                    highTemp: Double(25 + i),
                    description: ["晴朗", "多云", "阴天", "小雨"][Int.random(in: 0...3)],
                    precipitationProbability: Int.random(in: 0...80),
                    uvIndex: Double.random(in: 2...10)
                )
            })
            .padding(.top, 100)
        }
    }
}

#Preview("DailyForecastEmptyView") {
    ZStack {
        CyberBackground()

        DailyForecastEmptyView()
            .padding(.top, 100)
    }
}
