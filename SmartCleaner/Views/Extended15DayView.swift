//
//  Extended15DayView.swift
//  SmartCleaner
//
//  15天天气预报视图
//  详细展示未来15天的天气情况
//  赛博朋克风格列表
//

import SwiftUI

// MARK: - 15天预报视图
struct Extended15DayView: View {
    let dailyData: [DailyWeatherData]
    let settings: AppSettings

    @State private var selectedDay: DailyWeatherData?
    @State private var showingDayRange: DayRange = .sevenDays

    enum DayRange: String, CaseIterable {
        case sevenDays = "7天"
        case fifteenDays = "15天"
    }

    private var displayData: [DailyWeatherData] {
        switch showingDayRange {
        case .sevenDays:
            return Array(dailyData.prefix(7))
        case .fifteenDays:
            return Array(dailyData.prefix(15))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和切换
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("天气预报")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 天数切换
                Picker("", selection: $showingDayRange) {
                    ForEach(DayRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            // 天气列表
            VStack(spacing: 8) {
                ForEach(Array(displayData.enumerated()), id: \.element.date) { index, day in
                    DayForecastRow(
                        day: day,
                        index: index,
                        settings: settings,
                        isSelected: selectedDay?.date == day.date,
                        allTemps: displayData.flatMap { [$0.temperatureMin, $0.temperatureMax] }
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if selectedDay?.date == day.date {
                                selectedDay = nil
                            } else {
                                selectedDay = day
                            }
                        }
                    }
                }
            }

            // 选中日期详情
            if let selected = selectedDay {
                DayDetailCard(day: selected, settings: settings)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "14142e").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00D4FF").opacity(0.2),
                                    Color(hex: "7B2FFF").opacity(0.2)
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

// MARK: - 单日预报行
struct DayForecastRow: View {
    let day: DailyWeatherData
    let index: Int
    let settings: AppSettings
    let isSelected: Bool
    let allTemps: [Double]

    private var dayName: String {
        if index == 0 { return "今天" }
        if index == 1 { return "明天" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: day.date) else { return "" }

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "E"
        return dayFormatter.string(from: date)
    }

    private var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: day.date) else { return "" }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M/d"
        return displayFormatter.string(from: date)
    }

    private var weatherType: WeatherType {
        WeatherCodeHelper.weatherType(for: day.weatherCode)
    }

    // 温度条位置计算
    private var tempBarRange: (start: CGFloat, width: CGFloat) {
        guard let minTemp = allTemps.min(), let maxTemp = allTemps.max(), maxTemp > minTemp else {
            return (0, 1)
        }

        let range = maxTemp - minTemp
        let start = (day.temperatureMin - minTemp) / range
        let width = (day.temperatureMax - day.temperatureMin) / range

        return (CGFloat(start), CGFloat(max(0.1, width)))
    }

    var body: some View {
        HStack(spacing: 12) {
            // 日期
            VStack(alignment: .leading, spacing: 2) {
                Text(dayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(index == 0 ? Color(hex: "00D4FF") : .white)

                Text(dateString)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 45, alignment: .leading)

            // 天气图标
            Image(systemName: weatherType.iconName)
                .font(.title3)
                .foregroundStyle(weatherType.iconGradient)
                .frame(width: 30)

            // 降水概率
            if day.precipitationProbabilityMax > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                    Text("\(day.precipitationProbabilityMax)%")
                        .font(.caption2)
                }
                .foregroundColor(Color(hex: "00D4FF").opacity(0.8))
                .frame(width: 40)
            } else {
                Color.clear.frame(width: 40)
            }

            // 温度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)

                    // 温度范围
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00D4FF"), Color(hex: "FF6B00")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(20, geometry.size.width * tempBarRange.width),
                            height: 4
                        )
                        .offset(x: geometry.size.width * tempBarRange.start)
                        .shadow(color: Color(hex: "FF6B00").opacity(0.3), radius: 2)
                }
                .frame(height: geometry.size.height)
            }
            .frame(height: 20)

            // 最低温
            Text(settings.formatTemperature(day.temperatureMin, showUnit: false))
                .font(.subheadline)
                .foregroundColor(Color(hex: "00D4FF"))
                .frame(width: 35, alignment: .trailing)

            // 最高温
            Text(settings.formatTemperature(day.temperatureMax, showUnit: false))
                .font(.subheadline)
                .foregroundColor(Color(hex: "FF6B00"))
                .frame(width: 35, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "1a1a3e").opacity(isSelected ? 0.8 : 0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected
                                ? Color(hex: "00D4FF").opacity(0.4)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - 日详情卡片
struct DayDetailCard: View {
    let day: DailyWeatherData
    let settings: AppSettings

    private var weatherDescription: String {
        WeatherCodeHelper.description(for: day.weatherCode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 日期和天气
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(day.date))
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(weatherDescription)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "00D4FF"))
                }

                Spacer()

                // 温度范围
                VStack(alignment: .trailing, spacing: 2) {
                    Text(settings.formatTemperature(day.temperatureMax))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FF6B00"))

                    Text(settings.formatTemperature(day.temperatureMin))
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "00D4FF"))
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // 详细信息网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                detailItem(icon: "drop.fill", title: "降水概率", value: "\(day.precipitationProbabilityMax)%", color: Color(hex: "00D4FF"))
                detailItem(icon: "cloud.rain", title: "降水量", value: String(format: "%.1fmm", day.precipitationSum), color: Color(hex: "7B2FFF"))
                detailItem(icon: "wind", title: "风速", value: settings.formatWindSpeed(day.windSpeedMax), color: Color(hex: "FF00FF"))
                detailItem(icon: "sun.max.fill", title: "紫外线", value: uvLevel(day.uvIndexMax), color: Color(hex: "FFD700"))
                detailItem(icon: "sunrise.fill", title: "日出", value: formatTime(day.sunrise), color: Color(hex: "FF6B00"))
                detailItem(icon: "sunset.fill", title: "日落", value: formatTime(day.sunset), color: Color(hex: "FF6B00"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1a1a3e").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "00D4FF").opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - 详情项
    private func detailItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 辅助方法
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: dateString) else { return dateString }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "zh_CN")
        outputFormatter.dateFormat = "M月d日 EEEE"
        return outputFormatter.string(from: date)
    }

    private func formatTime(_ timeString: String) -> String {
        // 处理 yyyy-MM-dd'T'HH:mm 格式
        if timeString.contains("T") {
            let components = timeString.components(separatedBy: "T")
            if components.count == 2 {
                return String(components[1].prefix(5))
            }
        }
        return timeString
    }

    private func uvLevel(_ index: Double) -> String {
        switch index {
        case 0..<3: return "弱"
        case 3..<6: return "中等"
        case 6..<8: return "强"
        case 8..<11: return "很强"
        default: return "极强"
        }
    }
}

// MARK: - 天气类型图标扩展
extension WeatherType {
    var iconName: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .foggy: return "cloud.fog.fill"
        }
    }

    var iconGradient: LinearGradient {
        switch self {
        case .sunny:
            return LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FF6B00")], startPoint: .top, endPoint: .bottom)
        case .partlyCloudy:
            return LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "87CEEB")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .cloudy:
            return LinearGradient(colors: [Color(hex: "A0A0A0"), Color(hex: "606060")], startPoint: .top, endPoint: .bottom)
        case .rainy:
            return LinearGradient(colors: [Color(hex: "00D4FF"), Color(hex: "7B2FFF")], startPoint: .top, endPoint: .bottom)
        case .snowy:
            return LinearGradient(colors: [Color.white, Color(hex: "87CEEB")], startPoint: .top, endPoint: .bottom)
        case .thunderstorm:
            return LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "7B2FFF")], startPoint: .top, endPoint: .bottom)
        case .foggy:
            return LinearGradient(colors: [Color(hex: "A0A0A0"), Color(hex: "808080")], startPoint: .top, endPoint: .bottom)
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

        ScrollView {
            Extended15DayView(
                dailyData: (0..<15).map { i in
                    let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
                    let dateString = dateFormatter.string(from: date)
                    let sunriseDate = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: date)!
                    let sunsetDate = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: date)!
                    return DailyWeatherData(
                        date: dateString,
                        weatherCode: [0, 1, 2, 3, 45, 61, 63, 71, 80, 95].randomElement()!,
                        temperatureMax: Double.random(in: 20...32),
                        temperatureMin: Double.random(in: 10...20),
                        apparentTemperatureMax: Double.random(in: 21...33),
                        apparentTemperatureMin: Double.random(in: 9...19),
                        sunrise: timeFormatter.string(from: sunriseDate),
                        sunset: timeFormatter.string(from: sunsetDate),
                        uvIndexMax: Double.random(in: 1...11),
                        precipitationSum: Double.random(in: 0...20),
                        precipitationProbabilityMax: Int.random(in: 0...100),
                        windSpeedMax: Double.random(in: 5...30),
                        windDirectionDominant: Int.random(in: 0...360)
                    )
                },
                settings: AppSettings.shared
            )
            .padding()
        }
    }
}
