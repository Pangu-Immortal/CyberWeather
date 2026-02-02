//
//  PrecipitationChartView.swift
//  CyberWeather
//
//  降水概率图表
//  展示未来几天降水概率柱状图
//  包含降水量信息
//  赛博朋克风格渐变
//

import SwiftUI
import Charts

// MARK: - 降水数据点
struct PrecipitationDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let probability: Int      // 降水概率 0-100
    let amount: Double        // 降水量 mm
    let dayName: String
}

// MARK: - 降水概率图表
struct PrecipitationChartView: View {
    let dailyData: [DailyWeatherData]

    @State private var selectedPoint: PrecipitationDataPoint?

    private var dataPoints: [PrecipitationDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "E"

        return dailyData.prefix(15).enumerated().compactMap { index, data in
            guard let date = dateFormatter.date(from: data.date) else { return nil }
            return PrecipitationDataPoint(
                date: date,
                probability: data.precipitationProbabilityMax,
                amount: data.precipitationSum,
                dayName: index == 0 ? "今天" : (index == 1 ? "明天" : dayFormatter.string(from: date))
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("降水概率")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 图例
                HStack(spacing: 16) {
                    legendItem(color: Color(hex: "00D4FF"), text: "概率")
                    legendItem(color: Color(hex: "7B2FFF"), text: "降水量")
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
                    Text("概率 \(selected.probability)%")
                        .foregroundColor(Color(hex: "00D4FF"))
                    Text("|")
                        .foregroundColor(.gray)
                    Text("降水量 \(String(format: "%.1f", selected.amount))mm")
                        .foregroundColor(Color(hex: "7B2FFF"))
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            // 图表
            Chart {
                ForEach(dataPoints) { point in
                    // 降水概率柱状图
                    BarMark(
                        x: .value("日期", point.date),
                        y: .value("概率", point.probability)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "00D4FF").opacity(0.8),
                                Color(hex: "00D4FF").opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)

                    // 降水量点
                    if point.amount > 0 {
                        PointMark(
                            x: .value("日期", point.date),
                            y: .value("降水量缩放", min(point.amount * 10, 100))
                        )
                        .foregroundStyle(Color(hex: "7B2FFF"))
                        .symbolSize(max(20, point.amount * 5))
                        .annotation(position: .top) {
                            if point.amount > 1 {
                                Text("\(String(format: "%.1f", point.amount))")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(hex: "7B2FFF"))
                            }
                        }
                    }
                }

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
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel {
                        if let prob = value.as(Int.self) {
                            Text("\(prob)%")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
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

            // 降水等级说明
            HStack(spacing: 8) {
                precipitationLevel(range: "0-30%", level: "低", color: Color(hex: "00D4FF").opacity(0.3))
                precipitationLevel(range: "30-60%", level: "中", color: Color(hex: "00D4FF").opacity(0.6))
                precipitationLevel(range: "60-100%", level: "高", color: Color(hex: "00D4FF"))
            }
            .font(.caption2)
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
                                    Color(hex: "7B2FFF").opacity(0.3)
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

    // MARK: - 降水等级
    private func precipitationLevel(range: String, level: String, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text("\(range) \(level)")
                .foregroundColor(.white.opacity(0.5))
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

        PrecipitationChartView(
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
                    precipitationSum: Double.random(in: 0...20),
                    precipitationProbabilityMax: Int.random(in: 0...100),
                    windSpeedMax: 10,
                    windDirectionDominant: 180
                )
            }
        )
        .padding()
    }
}
