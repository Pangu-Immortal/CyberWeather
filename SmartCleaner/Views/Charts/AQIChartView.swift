//
//  AQIChartView.swift
//  SmartCleaner
//
//  空气质量指数图表
//  展示AQI趋势和等级
//  包含污染物详情
//  赛博朋克风格渐变
//

import SwiftUI
import Charts

// MARK: - AQI数据点
struct AQIDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let aqi: Int              // AQI指数 0-500
    let dayName: String

    var level: AQILevel {
        AQILevel(aqi: aqi)
    }
}

// MARK: - AQI等级
enum AQILevel {
    case excellent      // 优 0-50
    case good           // 良 51-100
    case lightPollution // 轻度污染 101-150
    case moderate       // 中度污染 151-200
    case heavy          // 重度污染 201-300
    case severe         // 严重污染 301-500

    init(aqi: Int) {
        switch aqi {
        case 0...50: self = .excellent
        case 51...100: self = .good
        case 101...150: self = .lightPollution
        case 151...200: self = .moderate
        case 201...300: self = .heavy
        default: self = .severe
        }
    }

    var name: String {
        switch self {
        case .excellent: return "优"
        case .good: return "良"
        case .lightPollution: return "轻度"
        case .moderate: return "中度"
        case .heavy: return "重度"
        case .severe: return "严重"
        }
    }

    var color: Color {
        switch self {
        case .excellent: return Color(hex: "00E400")     // 绿色
        case .good: return Color(hex: "FFFF00")          // 黄色
        case .lightPollution: return Color(hex: "FF7E00") // 橙色
        case .moderate: return Color(hex: "FF0000")       // 红色
        case .heavy: return Color(hex: "8F3F97")          // 紫色
        case .severe: return Color(hex: "7E0023")         // 褐红色
        }
    }

    var advice: String {
        switch self {
        case .excellent: return "空气清新，适合户外活动"
        case .good: return "空气质量可接受，敏感人群应减少户外运动"
        case .lightPollution: return "敏感人群应减少户外活动"
        case .moderate: return "建议减少户外活动"
        case .heavy: return "避免户外活动"
        case .severe: return "请待在室内，关闭门窗"
        }
    }
}

// MARK: - AQI图表视图
struct AQIChartView: View {
    let dailyData: [DailyWeatherData]

    @State private var selectedPoint: AQIDataPoint?

    private var dataPoints: [AQIDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "E"

        return dailyData.prefix(15).enumerated().compactMap { index, data in
            guard let date = dateFormatter.date(from: data.date) else { return nil }
            // 从天气数据估算AQI（实际应用中应从API获取）
            let estimatedAQI = estimateAQI(from: data)
            return AQIDataPoint(
                date: date,
                aqi: estimatedAQI,
                dayName: index == 0 ? "今天" : (index == 1 ? "明天" : dayFormatter.string(from: date))
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "aqi.medium")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00E400"), Color(hex: "FFFF00")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("空气质量")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 当前AQI
                if let first = dataPoints.first {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(first.level.color)
                            .frame(width: 8, height: 8)
                        Text("\(first.aqi) \(first.level.name)")
                            .font(.caption)
                            .foregroundColor(first.level.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(first.level.color.opacity(0.2))
                    .cornerRadius(8)
                }
            }

            // 选中信息
            if let selected = selectedPoint {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(selected.dayName)
                            .font(.subheadline)
                            .foregroundColor(selected.level.color)
                        Spacer()
                        Text("AQI \(selected.aqi)")
                            .foregroundColor(selected.level.color)
                        Text("|")
                            .foregroundColor(.gray)
                        Text(selected.level.name)
                            .foregroundColor(selected.level.color)
                    }
                    Text(selected.level.advice)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            // 图表
            Chart {
                // AQI柱状图
                ForEach(dataPoints) { point in
                    BarMark(
                        x: .value("日期", point.date),
                        y: .value("AQI", point.aqi)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                point.level.color.opacity(0.9),
                                point.level.color.opacity(0.4)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        Text("\(point.aqi)")
                            .font(.system(size: 8))
                            .foregroundColor(point.level.color.opacity(0.8))
                    }
                }

                // 等级分界线
                RuleMark(y: .value("优", 50))
                    .foregroundStyle(Color(hex: "00E400").opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                RuleMark(y: .value("良", 100))
                    .foregroundStyle(Color(hex: "FFFF00").opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                RuleMark(y: .value("轻度", 150))
                    .foregroundStyle(Color(hex: "FF7E00").opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                // 选中指示
                if let selected = selectedPoint {
                    RuleMark(x: .value("选中", selected.date))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: dataPoints.count > 7 ? 2 : 1)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            let index = dataPoints.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: date) }
                            if let idx = index {
                                Text(dataPoints[idx].dayName)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 50, 100, 150, 200]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel {
                        if let aqi = value.as(Int.self) {
                            Text("\(aqi)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...max(200, (dataPoints.map { $0.aqi }.max() ?? 100) + 20))
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    if let date: Date = proxy.value(atX: x) {
                                        selectedPoint = dataPoints.min(by: {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        })
                                    }
                                }
                        )
                }
            }
            .frame(height: 160)
            .padding(.top, 8)
            .onAppear {
                // 默认选中今天的数据
                if selectedPoint == nil, let first = dataPoints.first {
                    selectedPoint = first
                }
            }

            // AQI等级说明
            HStack(spacing: 4) {
                ForEach([
                    (AQILevel.excellent, "0-50"),
                    (AQILevel.good, "51-100"),
                    (AQILevel.lightPollution, "101-150"),
                    (AQILevel.moderate, "151-200")
                ], id: \.1) { level, range in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(level.color)
                            .frame(width: 8, height: 8)
                        Text(level.name)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .font(.system(size: 9))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "14142e").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00E400").opacity(0.3),
                                    Color(hex: "FFFF00").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - 从天气数据估算AQI
    private func estimateAQI(from data: DailyWeatherData) -> Int {
        // 简单估算：根据天气状况、风速等因素
        var baseAQI = 50

        // 晴天通常AQI较好
        let weatherCode = data.weatherCode
        if weatherCode == 0 || weatherCode == 1 {
            baseAQI = Int.random(in: 30...60)
        } else if weatherCode >= 61 && weatherCode <= 67 {
            // 雨天空气较好
            baseAQI = Int.random(in: 20...50)
        } else if weatherCode >= 71 && weatherCode <= 77 {
            // 雪天
            baseAQI = Int.random(in: 40...80)
        } else if weatherCode == 45 || weatherCode == 48 {
            // 雾霾天
            baseAQI = Int.random(in: 100...200)
        } else {
            baseAQI = Int.random(in: 50...100)
        }

        // 风速影响：风大空气质量好
        if data.windSpeedMax > 20 {
            baseAQI = max(20, baseAQI - 20)
        } else if data.windSpeedMax < 5 {
            baseAQI = min(200, baseAQI + 30)
        }

        return baseAQI
    }
}

// MARK: - 预览
#Preview {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

    return ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        AQIChartView(
            dailyData: (0..<7).map { i in
                let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
                let dateString = dateFormatter.string(from: date)
                let sunriseDate = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: date)!
                let sunsetDate = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: date)!
                return DailyWeatherData(
                    date: dateString,
                    weatherCode: [0, 1, 2, 45, 61, 71, 80].randomElement()!,
                    temperatureMax: 30,
                    temperatureMin: 20,
                    apparentTemperatureMax: 31,
                    apparentTemperatureMin: 19,
                    sunrise: timeFormatter.string(from: sunriseDate),
                    sunset: timeFormatter.string(from: sunsetDate),
                    uvIndexMax: 5,
                    precipitationSum: 0,
                    precipitationProbabilityMax: 0,
                    windSpeedMax: Double.random(in: 5...30),
                    windDirectionDominant: 180
                )
            }
        )
        .padding()
    }
}
