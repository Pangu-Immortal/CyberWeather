//
//  TemperatureChartView.swift
//  SmartCleaner
//
//  温度趋势图
//  展示7天/15天温度变化曲线
//  包含最高温和最低温双曲线
//  赛博朋克风格渐变填充
//

import SwiftUI
import Charts

// MARK: - 温度数据点
struct TemperatureDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let high: Double
    let low: Double
    let dayName: String

    var average: Double {
        (high + low) / 2
    }
}

// MARK: - 温度趋势图
struct TemperatureChartView: View {
    let dailyData: [DailyWeatherData]
    let settings: AppSettings

    @State private var selectedPoint: TemperatureDataPoint?
    @State private var animationProgress: CGFloat = 0

    private var dataPoints: [TemperatureDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "E"  // 周几

        return dailyData.prefix(15).enumerated().compactMap { index, data in
            guard let date = dateFormatter.date(from: data.date) else { return nil }
            return TemperatureDataPoint(
                date: date,
                high: data.temperatureMax,
                low: data.temperatureMin,
                dayName: index == 0 ? "今天" : (index == 1 ? "明天" : dayFormatter.string(from: date))
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "thermometer")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B00"), Color(hex: "FFD700")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("温度趋势")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 图例
                HStack(spacing: 16) {
                    legendItem(color: Color(hex: "FF6B00"), text: "最高")
                    legendItem(color: Color(hex: "00D4FF"), text: "最低")
                }
                .font(.caption)
            }

            // 选中信息
            if let selected = selectedPoint {
                HStack {
                    Text(selected.dayName)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "00D4FF"))
                    Spacer()
                    Text("最高 \(settings.formatTemperature(selected.high))")
                        .foregroundColor(Color(hex: "FF6B00"))
                    Text("/")
                        .foregroundColor(.gray)
                    Text("最低 \(settings.formatTemperature(selected.low))")
                        .foregroundColor(Color(hex: "00D4FF"))
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            // 图表
            Chart {
                // 最高温区域填充
                ForEach(dataPoints) { point in
                    AreaMark(
                        x: .value("日期", point.date),
                        yStart: .value("低温", point.low),
                        yEnd: .value("高温", point.high)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "FF6B00").opacity(0.3),
                                Color(hex: "00D4FF").opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // 最高温曲线
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("高温", point.high)
                    )
                    .foregroundStyle(Color(hex: "FF6B00"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol {
                        Circle()
                            .fill(Color(hex: "FF6B00"))
                            .frame(width: 6, height: 6)
                            .shadow(color: Color(hex: "FF6B00").opacity(0.5), radius: 4)
                    }
                }

                // 最低温曲线
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("低温", point.low)
                    )
                    .foregroundStyle(Color(hex: "00D4FF"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol {
                        Circle()
                            .fill(Color(hex: "00D4FF"))
                            .frame(width: 6, height: 6)
                            .shadow(color: Color(hex: "00D4FF").opacity(0.5), radius: 4)
                    }
                }

                // 选中指示线
                if let selected = selectedPoint {
                    RuleMark(x: .value("选中", selected.date))
                        .foregroundStyle(Color.white.opacity(0.5))
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
                        if let temp = value.as(Double.self) {
                            Text(settings.formatTemperature(temp, showUnit: false))
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
                                .onEnded { _ in
                                    // 可选：结束后清除选中
                                    // selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)
            .padding(.top, 8)
            .onAppear {
                // 默认选中今天的数据
                if selectedPoint == nil, let first = dataPoints.first {
                    selectedPoint = first
                }
            }
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
                                    Color(hex: "FF6B00").opacity(0.3),
                                    Color(hex: "00D4FF").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - 图例项
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.white.opacity(0.7))
        }
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

        TemperatureChartView(
            dailyData: (0..<7).map { i in
                let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
                let dateString = dateFormatter.string(from: date)
                let sunriseDate = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: date)!
                let sunsetDate = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: date)!
                return DailyWeatherData(
                    date: dateString,
                    weatherCode: 0,
                    temperatureMax: Double.random(in: 25...32),
                    temperatureMin: Double.random(in: 15...22),
                    apparentTemperatureMax: Double.random(in: 26...33),
                    apparentTemperatureMin: Double.random(in: 14...21),
                    sunrise: timeFormatter.string(from: sunriseDate),
                    sunset: timeFormatter.string(from: sunsetDate),
                    uvIndexMax: 5,
                    precipitationSum: 0,
                    precipitationProbabilityMax: 0,
                    windSpeedMax: 10,
                    windDirectionDominant: 180
                )
            },
            settings: AppSettings.shared
        )
        .padding()
    }
}
