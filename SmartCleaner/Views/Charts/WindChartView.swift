//
//  WindChartView.swift
//  SmartCleaner
//
//  风力趋势图
//  展示风速和风向变化
//  包含风向指示箭头
//  赛博朋克风格
//

import SwiftUI
import Charts

// MARK: - 风力数据点
struct WindDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let speed: Double         // 风速 km/h
    let direction: Int        // 风向角度 0-360
    let dayName: String

    var directionName: String {
        let directions = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
        let index = Int((Double(direction) + 22.5) / 45.0) % 8
        return directions[index]
    }

    var beaufortScale: Int {
        // 蒲福风力等级
        switch speed {
        case 0..<1: return 0
        case 1..<6: return 1
        case 6..<12: return 2
        case 12..<20: return 3
        case 20..<29: return 4
        case 29..<39: return 5
        case 39..<50: return 6
        case 50..<62: return 7
        case 62..<75: return 8
        case 75..<89: return 9
        case 89..<103: return 10
        case 103..<118: return 11
        default: return 12
        }
    }
}

// MARK: - 风力趋势图
struct WindChartView: View {
    let dailyData: [DailyWeatherData]
    let settings: AppSettings

    @State private var selectedPoint: WindDataPoint?

    private var dataPoints: [WindDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "E"

        return dailyData.prefix(15).enumerated().compactMap { index, data in
            guard let date = dateFormatter.date(from: data.date) else { return nil }
            return WindDataPoint(
                date: date,
                speed: data.windSpeedMax,
                direction: data.windDirectionDominant,
                dayName: index == 0 ? "今天" : (index == 1 ? "明天" : dayFormatter.string(from: date))
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "wind")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "FF00FF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("风力趋势")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 当前风力等级
                if let first = dataPoints.first {
                    Text("\(first.beaufortScale)级 \(first.directionName)风")
                        .font(.caption)
                        .foregroundColor(Color(hex: "00D4FF"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "00D4FF").opacity(0.2))
                        .cornerRadius(8)
                }
            }

            // 选中信息
            if let selected = selectedPoint {
                HStack {
                    Text(selected.dayName)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "00D4FF"))
                    Spacer()
                    Text(settings.formatWindSpeed(selected.speed))
                        .foregroundColor(Color(hex: "00D4FF"))
                    Text("|")
                        .foregroundColor(.gray)
                    Text("\(selected.beaufortScale)级 \(selected.directionName)风")
                        .foregroundColor(Color(hex: "FF00FF"))

                    // 风向箭头
                    Image(systemName: "arrow.up")
                        .rotationEffect(.degrees(Double(selected.direction)))
                        .foregroundColor(Color(hex: "FF00FF"))
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            // 图表
            Chart {
                // 风速区域填充
                ForEach(dataPoints) { point in
                    AreaMark(
                        x: .value("日期", point.date),
                        y: .value("风速", point.speed)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "00D4FF").opacity(0.4),
                                Color(hex: "00D4FF").opacity(0.1),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // 风速曲线
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("风速", point.speed)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "FF00FF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // 数据点 + 风向指示
                ForEach(dataPoints) { point in
                    PointMark(
                        x: .value("日期", point.date),
                        y: .value("风速", point.speed)
                    )
                    .foregroundStyle(Color(hex: "00D4FF"))
                    .symbolSize(40)
                    .annotation(position: .top, spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(Double(point.direction)))
                            .foregroundColor(Color(hex: "FF00FF").opacity(0.8))
                    }
                }

                // 选中指示线
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
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel {
                        if let speed = value.as(Double.self) {
                            Text(settings.formatWindSpeed(speed))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
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
            .frame(height: 180)
            .padding(.top, 8)
            .onAppear {
                // 默认选中今天的数据
                if selectedPoint == nil, let first = dataPoints.first {
                    selectedPoint = first
                }
            }

            // 风力等级说明
            HStack(spacing: 4) {
                ForEach([
                    ("0-2级", "微风", Color(hex: "00D4FF").opacity(0.3)),
                    ("3-4级", "和风", Color(hex: "00D4FF").opacity(0.6)),
                    ("5-6级", "劲风", Color(hex: "00D4FF")),
                    ("7+级", "大风", Color(hex: "FF6B00"))
                ], id: \.0) { level, name, color in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text("\(level)")
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
                                    Color(hex: "00D4FF").opacity(0.3),
                                    Color(hex: "FF00FF").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
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

        WindChartView(
            dailyData: (0..<7).map { i in
                let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
                let dateString = dateFormatter.string(from: date)
                let sunriseDate = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: date)!
                let sunsetDate = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: date)!
                return DailyWeatherData(
                    date: dateString,
                    weatherCode: 0,
                    temperatureMax: 30,
                    temperatureMin: 20,
                    apparentTemperatureMax: 31,
                    apparentTemperatureMin: 19,
                    sunrise: timeFormatter.string(from: sunriseDate),
                    sunset: timeFormatter.string(from: sunsetDate),
                    uvIndexMax: 5,
                    precipitationSum: 0,
                    precipitationProbabilityMax: 0,
                    windSpeedMax: Double.random(in: 5...40),
                    windDirectionDominant: Int.random(in: 0...360)
                )
            },
            settings: AppSettings.shared
        )
        .padding()
    }
}
