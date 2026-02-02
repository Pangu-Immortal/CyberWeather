//
//  ViewModels.swift
//  SmartCleaner
//
//  视图专用数据类型
//  用于UI展示的数据结构
//  与业务模型解耦
//

import Foundation
import SwiftUI

// MARK: - 生活指数类型
enum LifeIndexType: String, CaseIterable, Identifiable {
    case dressing = "dressing"      // 穿衣
    case uv = "uv"                  // 紫外线
    case exercise = "exercise"      // 运动
    case carWash = "carWash"        // 洗车
    case comfort = "comfort"        // 舒适度
    case airQuality = "airQuality"  // 空气质量
    case travel = "travel"          // 出行
    case allergy = "allergy"        // 过敏

    var id: String { rawValue }

    var name: String {
        switch self {
        case .dressing: return "穿衣"
        case .uv: return "紫外线"
        case .exercise: return "运动"
        case .carWash: return "洗车"
        case .comfort: return "舒适度"
        case .airQuality: return "空气质量"
        case .travel: return "出行"
        case .allergy: return "过敏"
        }
    }
}

// MARK: - 生活指数（视图用）
struct LifeIndex: Identifiable {
    let id = UUID()
    let type: LifeIndexType         // 指数类型
    let level: String               // 等级（如：舒适、适宜、强）
    let value: Int                  // 数值 0-100
    let advice: String              // 建议
}

// MARK: - 出行评级
enum TravelRating: String, CaseIterable {
    case excellent = "excellent"    // 极佳
    case good = "good"              // 适宜
    case moderate = "moderate"      // 一般
    case poor = "poor"              // 较差
    case bad = "bad"                // 不宜
}

// MARK: - 出行建议（视图用）
struct TravelAdviceDisplay: Identifiable {
    let id = UUID()
    let date: Date                  // 日期
    let dayName: String             // 星期名（今天、明天、周一等）
    let dateString: String          // 日期字符串（1月29日）
    let score: Int                  // 评分 0-100
    let rating: TravelRating        // 评级
    let summary: String             // 综合建议
    let tips: [String]              // 注意事项列表
    let temperatureRange: String    // 温度范围（如：18-25°C）
    let precipitation: Int          // 降水概率 %
    let windInfo: String            // 风力信息（如：东南风 2级）
}

// MARK: - 每日预报（视图用）
struct DailyForecast: Identifiable {
    let id = UUID()
    let dayName: String             // 星期几（今天、明天、周一等）
    let dateString: String          // 日期字符串（1月29日）
    let iconName: String            // SF Symbols 图标名
    let weatherCode: Int            // 天气代码
    let lowTemp: Double             // 最低温度
    let highTemp: Double            // 最高温度
    let description: String         // 天气描述
    let precipitationProbability: Int // 降水概率
    let uvIndex: Double             // 紫外线指数
}

// MARK: - 小时预报（视图用）
struct HourlyForecast: Identifiable {
    let id = UUID()
    let hour: String                // 小时（如：14:00、现在）
    let iconName: String            // SF Symbols 图标名
    let weatherCode: Int            // 天气代码
    let temperature: Double         // 温度
    let precipitation: Int          // 降水概率 %
    let isNow: Bool                 // 是否是当前时间
    let humidity: Int               // 湿度 %
    let windSpeed: Double           // 风速 km/h
    let uvIndex: Double             // 紫外线指数
    let apparentTemperature: Double // 体感温度
}

// MARK: - 天气详情（视图用）
struct WeatherDetails {
    let windSpeed: Double           // 风速
    let windDirection: Double       // 风向角度
    let windDirectionText: String   // 风向文字（如：东南风）
    let humidity: Int               // 湿度 %
    let visibility: Double          // 能见度 km
    let uvIndex: Double             // 紫外线指数
    let sunrise: String             // 日出时间
    let sunset: String              // 日落时间
    let pressure: Double            // 气压 hPa
    let precipitation: Double       // 降水量 mm
    let apparentTemperature: Double // 体感温度
}

// MARK: - WeatherData 视图类型扩展
extension WeatherData {
    /// 转换为小时预报视图类型
    var hourlyForecast: [HourlyForecast] {
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH:00"
        let now = Calendar.current.component(.hour, from: Date())

        return hourly.prefix(24).enumerated().map { index, data in
            let isNow = index == 0
            let hour = isNow ? "现在" : hourFormatter.string(from: data.dateObject ?? Date())

            return HourlyForecast(
                hour: hour,
                iconName: WeatherCodeHelper.icon(for: data.weatherCode, isDay: data.dateObject?.isDay ?? true),
                weatherCode: data.weatherCode,
                temperature: data.temperature,
                precipitation: data.precipitationProbability,
                isNow: isNow,
                humidity: data.humidity,
                windSpeed: data.windSpeed,
                uvIndex: data.uvIndex,
                apparentTemperature: data.apparentTemperature
            )
        }
    }

    /// 转换为每日预报视图类型
    var dailyForecast: [DailyForecast] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M月d日"
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "EEEE"

        return daily.prefix(7).enumerated().map { index, data in
            let date = dateFormatter.date(from: data.date) ?? Date()
            let dayName: String
            if index == 0 {
                dayName = "今天"
            } else if index == 1 {
                dayName = "明天"
            } else {
                dayName = dayFormatter.string(from: date)
            }

            return DailyForecast(
                dayName: dayName,
                dateString: displayFormatter.string(from: date),
                iconName: WeatherCodeHelper.icon(for: data.weatherCode, isDay: true),
                weatherCode: data.weatherCode,
                lowTemp: data.temperatureMin,
                highTemp: data.temperatureMax,
                description: WeatherCodeHelper.description(for: data.weatherCode),
                precipitationProbability: data.precipitationProbabilityMax,
                uvIndex: data.uvIndexMax
            )
        }
    }

    /// 转换为天气详情视图类型
    var details: WeatherDetails? {
        guard let today = daily.first else { return nil }

        let directions = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
        let index = ((current.windDirection % 360) + 22) / 45 % 8
        let windDirectionText = directions[index]

        // 提取日出日落时间
        let sunriseTime = extractTime(from: today.sunrise)
        let sunsetTime = extractTime(from: today.sunset)

        return WeatherDetails(
            windSpeed: current.windSpeed,
            windDirection: Double(current.windDirection),
            windDirectionText: windDirectionText,
            humidity: current.humidity,
            visibility: current.visibility,
            uvIndex: current.uvIndex,
            sunrise: sunriseTime,
            sunset: sunsetTime,
            pressure: current.pressure,
            precipitation: today.precipitationSum,
            apparentTemperature: current.apparentTemperature
        )
    }

    /// 从时间字符串中提取 HH:mm 格式
    private func extractTime(from timeString: String) -> String {
        // 尝试解析 yyyy-MM-dd'T'HH:mm 格式
        if timeString.contains("T") {
            let components = timeString.components(separatedBy: "T")
            if components.count == 2 {
                return String(components[1].prefix(5))
            }
        }
        return timeString
    }
}

// MARK: - HourlyWeatherData 扩展
extension HourlyWeatherData {
    /// 转换时间字符串为 Date 对象
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: time)
    }
}

// MARK: - Date 扩展
extension Date {
    /// 判断是否为白天（6:00 - 18:00）
    var isDay: Bool {
        let hour = Calendar.current.component(.hour, from: self)
        return hour >= 6 && hour < 18
    }
}

// MARK: - WeatherData 生活指数扩展
extension WeatherData {
    /// 转换为生活指数视图类型
    var lifeIndices: [LifeIndex] {
        let indexData = LifeIndexCalculator.calculate(from: current, daily: daily.first)

        // 计算各项指数值（0-100）
        func levelToValue(_ level: String) -> Int {
            switch level {
            case "优", "非常适宜", "舒适", "弱", "低":
                return 85 + Int.random(in: 0...10)
            case "良", "适宜", "较舒适", "中等":
                return 70 + Int.random(in: 0...10)
            case "一般", "凉爽", "温暖":
                return 55 + Int.random(in: 0...10)
            case "轻度污染", "较不适宜", "强", "冷", "高":
                return 40 + Int.random(in: 0...10)
            case "中度污染", "不适宜", "很强", "寒冷":
                return 25 + Int.random(in: 0...10)
            case "重度污染", "极不适宜", "极强", "炎热":
                return 10 + Int.random(in: 0...10)
            default:
                return 50 + Int.random(in: 0...10)
            }
        }

        return [
            LifeIndex(type: .dressing, level: indexData.dressing.level, value: levelToValue(indexData.dressing.level), advice: indexData.dressing.description),
            LifeIndex(type: .uv, level: indexData.ultraviolet.level, value: levelToValue(indexData.ultraviolet.level), advice: indexData.ultraviolet.description),
            LifeIndex(type: .exercise, level: indexData.exercise.level, value: levelToValue(indexData.exercise.level), advice: indexData.exercise.description),
            LifeIndex(type: .carWash, level: indexData.carWash.level, value: levelToValue(indexData.carWash.level), advice: indexData.carWash.description),
            LifeIndex(type: .comfort, level: indexData.comfort.level, value: levelToValue(indexData.comfort.level), advice: indexData.comfort.description),
            LifeIndex(type: .airQuality, level: indexData.airQuality.level, value: levelToValue(indexData.airQuality.level), advice: indexData.airQuality.description),
            LifeIndex(type: .travel, level: indexData.travel.level, value: levelToValue(indexData.travel.level), advice: indexData.travel.description),
            LifeIndex(type: .allergy, level: indexData.allergy.level, value: levelToValue(indexData.allergy.level), advice: indexData.allergy.description)
        ]
    }

    /// 转换为出行建议视图类型（未来3天）
    var travelAdvices: [TravelAdviceDisplay] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M月d日"
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "EEEE"

        let directions = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]

        return daily.prefix(5).enumerated().map { index, data in
            let advice = TravelAdviceGenerator.generate(from: data, current: index == 0 ? current : nil)
            let date = dateFormatter.date(from: data.date) ?? Date()

            let dayName: String
            if index == 0 {
                dayName = "今天"
            } else if index == 1 {
                dayName = "明天"
            } else if index == 2 {
                dayName = "后天"
            } else {
                dayName = dayFormatter.string(from: date)
            }

            // 风向
            let windIndex = ((data.windDirectionDominant % 360) + 22) / 45 % 8
            let windDirection = directions[windIndex]
            let windLevel = windSpeedToLevel(data.windSpeedMax)

            // 评级
            let rating: TravelRating
            switch advice.overallScore {
            case 85...100: rating = .excellent
            case 70..<85: rating = .good
            case 50..<70: rating = .moderate
            case 30..<50: rating = .poor
            default: rating = .bad
            }

            // 提取tips
            let tips = advice.details.map { $0.advice }

            return TravelAdviceDisplay(
                date: date,
                dayName: dayName,
                dateString: displayFormatter.string(from: date),
                score: advice.overallScore,
                rating: rating,
                summary: advice.overallAdvice,
                tips: tips,
                temperatureRange: "\(Int(data.temperatureMin))-\(Int(data.temperatureMax))°C",
                precipitation: data.precipitationProbabilityMax,
                windInfo: "\(windDirection)风 \(windLevel)级"
            )
        }
    }

    /// 风速转风力等级
    private func windSpeedToLevel(_ speed: Double) -> Int {
        switch speed {
        case 0..<1: return 0
        case 1..<6: return 1
        case 6..<12: return 2
        case 12..<20: return 3
        case 20..<29: return 4
        case 29..<39: return 5
        case 39..<50: return 6
        case 50..<62: return 7
        default: return 8
        }
    }

    /// 获取当前天气类型
    var weatherType: WeatherType {
        WeatherCodeHelper.weatherType(for: current.weatherCode)
    }
}
