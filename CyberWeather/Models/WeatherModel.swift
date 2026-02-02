//
//  WeatherModel.swift
//  CyberWeather
//
//  天气数据模型（统一数据结构）
//  支持多源API数据转换
//  包含完整的天气、预报、生活指数数据
//

import Foundation

// MARK: - 统一天气数据模型
struct WeatherData: Codable {
    let location: LocationInfo              // 位置信息
    let current: CurrentWeatherData         // 当前天气
    let hourly: [HourlyWeatherData]         // 小时预报
    let daily: [DailyWeatherData]           // 每日预报
    let lastUpdated: Date                   // 最后更新时间

    // 计算属性：7天预报
    var sevenDayForecast: [DailyWeatherData] {
        Array(daily.prefix(7))
    }

    // 计算属性：15天预报
    var fifteenDayForecast: [DailyWeatherData] {
        Array(daily.prefix(15))
    }

    // 计算属性：24小时预报
    var twentyFourHourForecast: [HourlyWeatherData] {
        Array(hourly.prefix(24))
    }

    // 计算属性：48小时预报
    var fortyEightHourForecast: [HourlyWeatherData] {
        Array(hourly.prefix(48))
    }
}

// MARK: - 位置信息
struct LocationInfo: Codable {
    let name: String                        // 城市名称
    let latitude: Double                    // 纬度
    let longitude: Double                   // 经度
    let timezone: String                    // 时区
}

// MARK: - 当前天气数据
struct CurrentWeatherData: Codable {
    let temperature: Double                 // 温度 (℃)
    let apparentTemperature: Double         // 体感温度 (℃)
    let humidity: Int                       // 相对湿度 (%)
    let weatherCode: Int                    // 天气代码
    let windSpeed: Double                   // 风速 (km/h)
    let windDirection: Int                  // 风向 (度)
    let pressure: Double                    // 气压 (hPa)
    let uvIndex: Double                     // 紫外线指数
    let visibility: Double                  // 能见度 (km)
    let isDay: Bool                         // 是否白天

    // 计算属性：天气描述
    var weatherDescription: String {
        WeatherCodeHelper.description(for: weatherCode)
    }

    // 计算属性：天气图标
    var weatherIcon: String {
        WeatherCodeHelper.icon(for: weatherCode, isDay: isDay)
    }

    // 计算属性：风向描述
    var windDirectionDescription: String {
        let directions = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
        let index = Int((Double(windDirection) + 22.5) / 45.0) % 8
        return directions[index] + "风"
    }

    // 计算属性：风力等级
    var windLevel: Int {
        switch windSpeed {
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
        case 103..<117: return 11
        default: return 12
        }
    }
}

// MARK: - 小时预报数据
struct HourlyWeatherData: Codable, Identifiable {
    var id: String { time }

    let time: String                        // ISO8601时间
    let temperature: Double                 // 温度
    let apparentTemperature: Double         // 体感温度
    let humidity: Int                       // 湿度
    let precipitationProbability: Int       // 降水概率 (%)
    let precipitation: Double               // 降水量 (mm)
    let weatherCode: Int                    // 天气代码
    let windSpeed: Double                   // 风速
    let windDirection: Int                  // 风向
    let uvIndex: Double                     // 紫外线指数
    let visibility: Double                  // 能见度
    let isDay: Bool                         // 是否白天

    // 计算属性：小时（0-23）
    var hour: Int {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        if let date = formatter.date(from: time) {
            return Calendar.current.component(.hour, from: date)
        }
        // 尝试其他格式
        if time.count >= 13 {
            return Int(time.suffix(5).prefix(2)) ?? 0
        }
        return 0
    }

    // 计算属性：格式化时间
    var formattedTime: String {
        let h = hour
        return String(format: "%02d:00", h)
    }

    // 计算属性：天气图标
    var weatherIcon: String {
        WeatherCodeHelper.icon(for: weatherCode, isDay: isDay)
    }
}

// MARK: - 每日预报数据
struct DailyWeatherData: Codable, Identifiable {
    var id: String { date }

    let date: String                        // 日期 yyyy-MM-dd
    let weatherCode: Int                    // 天气代码
    let temperatureMax: Double              // 最高温度
    let temperatureMin: Double              // 最低温度
    let apparentTemperatureMax: Double      // 体感最高
    let apparentTemperatureMin: Double      // 体感最低
    let sunrise: String                     // 日出时间
    let sunset: String                      // 日落时间
    let uvIndexMax: Double                  // 最大紫外线指数
    let precipitationSum: Double            // 降水总量 (mm)
    let precipitationProbabilityMax: Int    // 最大降水概率 (%)
    let windSpeedMax: Double                // 最大风速
    let windDirectionDominant: Int          // 主导风向

    // 计算属性：星期几
    var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateObj = formatter.date(from: date) {
            let calendar = Calendar.current
            if calendar.isDateInToday(dateObj) {
                return "今天"
            } else if calendar.isDateInTomorrow(dateObj) {
                return "明天"
            } else {
                let weekdayFormatter = DateFormatter()
                weekdayFormatter.locale = Locale(identifier: "zh_CN")
                weekdayFormatter.dateFormat = "EEEE"
                return weekdayFormatter.string(from: dateObj)
            }
        }
        return date
    }

    // 计算属性：简短星期
    var shortWeekday: String {
        let full = weekday
        if full == "今天" || full == "明天" { return full }
        return String(full.suffix(2)) // "周一" etc
    }

    // 计算属性：月日
    var monthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateObj = formatter.date(from: date) {
            let mdFormatter = DateFormatter()
            mdFormatter.dateFormat = "M/d"
            return mdFormatter.string(from: dateObj)
        }
        return ""
    }

    // 计算属性：天气描述
    var weatherDescription: String {
        WeatherCodeHelper.description(for: weatherCode)
    }

    // 计算属性：天气图标
    var weatherIcon: String {
        WeatherCodeHelper.icon(for: weatherCode, isDay: true)
    }

    // 计算属性：日出时间（仅时分）
    var sunriseTime: String {
        extractTime(from: sunrise)
    }

    // 计算属性：日落时间（仅时分）
    var sunsetTime: String {
        extractTime(from: sunset)
    }

    private func extractTime(from dateString: String) -> String {
        if dateString.contains("T") {
            let parts = dateString.components(separatedBy: "T")
            if parts.count > 1 {
                return String(parts[1].prefix(5))
            }
        }
        return dateString
    }
}

// MARK: - 生活指数数据
struct LifeIndexData {
    let dressing: LifeIndexItem         // 穿衣指数
    let ultraviolet: LifeIndexItem      // 紫外线指数
    let exercise: LifeIndexItem         // 运动指数
    let carWash: LifeIndexItem          // 洗车指数
    let comfort: LifeIndexItem          // 舒适度指数
    let airQuality: LifeIndexItem       // 空气质量指数
    let travel: LifeIndexItem           // 出行指数
    let allergy: LifeIndexItem          // 过敏指数
}

struct LifeIndexItem {
    let name: String                // 指数名称
    let level: String               // 等级
    let description: String         // 描述
    let icon: String                // 图标

    // 预设等级颜色
    var levelColor: String {
        switch level {
        case "优", "舒适", "适宜", "非常适宜":
            return "neonGreen"
        case "良", "较舒适", "较适宜":
            return "neonBlue"
        case "中等", "一般":
            return "neonYellow"
        case "较差", "不适宜", "较不适宜":
            return "neonOrange"
        case "差", "很不适宜", "极不适宜":
            return "neonPink"
        default:
            return "neonBlue"
        }
    }
}

// MARK: - 天气代码辅助类
struct WeatherCodeHelper {
    /// WMO 天气代码转描述
    static func description(for code: Int) -> String {
        switch code {
        case 0: return "晴"
        case 1: return "晴间多云"
        case 2: return "多云"
        case 3: return "阴"
        case 45: return "雾"
        case 48: return "雾凇"
        case 51: return "小毛毛雨"
        case 53: return "毛毛雨"
        case 55: return "大毛毛雨"
        case 56: return "冻毛毛雨"
        case 57: return "强冻毛毛雨"
        case 61: return "小雨"
        case 63: return "中雨"
        case 65: return "大雨"
        case 66: return "冻雨"
        case 67: return "强冻雨"
        case 71: return "小雪"
        case 73: return "中雪"
        case 75: return "大雪"
        case 77: return "雪粒"
        case 80: return "阵雨"
        case 81: return "中阵雨"
        case 82: return "强阵雨"
        case 85: return "小阵雪"
        case 86: return "大阵雪"
        case 95: return "雷阵雨"
        case 96: return "雷阵雨伴小冰雹"
        case 99: return "雷阵雨伴大冰雹"
        default: return "未知"
        }
    }

    /// WMO 天气代码转SF Symbol图标
    static func icon(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 2:
            return "cloud.fill"
        case 3:
            return "smoke.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55:
            return "cloud.drizzle.fill"
        case 56, 57:
            return "cloud.sleet.fill"
        case 61, 63, 65:
            return "cloud.rain.fill"
        case 66, 67:
            return "cloud.sleet.fill"
        case 71, 73, 75, 77:
            return "cloud.snow.fill"
        case 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        }
    }

    /// 天气代码判断天气类型
    static func weatherType(for code: Int) -> WeatherType {
        switch code {
        case 0: return .sunny
        case 1, 2: return .partlyCloudy
        case 3: return .cloudy
        case 45, 48: return .foggy
        case 51...67: return .rainy
        case 71...86: return .snowy
        case 95...99: return .thunderstorm
        default: return .sunny
        }
    }
}

// MARK: - 天气类型枚举
enum WeatherType: String, CaseIterable {
    case sunny = "sunny"
    case partlyCloudy = "partlyCloudy"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case thunderstorm = "thunderstorm"
    case foggy = "foggy"

    var animationName: String {
        switch self {
        case .sunny: return "SunnyAnimation"
        case .partlyCloudy: return "CloudyAnimation"
        case .cloudy: return "CloudyAnimation"
        case .rainy: return "RainyAnimation"
        case .snowy: return "SnowyAnimation"
        case .thunderstorm: return "ThunderAnimation"
        case .foggy: return "FoggyAnimation"
        }
    }
}

// MARK: - 出行建议
struct TravelAdvice {
    let date: String                // 日期
    let overallScore: Int           // 综合评分 (0-100)
    let overallAdvice: String       // 综合建议
    let details: [TravelAdviceItem] // 详细建议

    struct TravelAdviceItem {
        let category: String        // 类别
        let advice: String          // 建议
        let icon: String            // 图标
    }
}

// MARK: - 生活指数计算器
struct LifeIndexCalculator {
    /// 根据天气数据计算生活指数
    static func calculate(from weather: CurrentWeatherData, daily: DailyWeatherData?) -> LifeIndexData {
        return LifeIndexData(
            dressing: calculateDressing(temperature: weather.temperature),
            ultraviolet: calculateUV(uvIndex: weather.uvIndex),
            exercise: calculateExercise(weather: weather),
            carWash: calculateCarWash(weather: weather, daily: daily),
            comfort: calculateComfort(weather: weather),
            airQuality: calculateAirQuality(visibility: weather.visibility),
            travel: calculateTravel(weather: weather),
            allergy: calculateAllergy(weather: weather)
        )
    }

    // 穿衣指数
    private static func calculateDressing(temperature: Double) -> LifeIndexItem {
        let (level, desc, icon): (String, String, String)
        switch temperature {
        case ..<5:
            level = "寒冷"
            desc = "建议穿羽绒服、厚棉衣、毛皮大衣等保暖衣物"
            icon = "figure.skiing.downhill"
        case 5..<10:
            level = "冷"
            desc = "建议穿棉衣、厚毛衣、皮夹克等保暖衣物"
            icon = "figure.walk"
        case 10..<18:
            level = "凉爽"
            desc = "建议穿薄外套、卫衣、毛衣等春秋装"
            icon = "tshirt.fill"
        case 18..<25:
            level = "舒适"
            desc = "建议穿长袖衬衫、薄T恤、休闲装"
            icon = "tshirt"
        case 25..<30:
            level = "温暖"
            desc = "建议穿短袖T恤、短裤、薄裙等夏装"
            icon = "sun.max"
        default:
            level = "炎热"
            desc = "建议穿轻薄透气的衣物，注意防晒"
            icon = "sun.max.fill"
        }
        return LifeIndexItem(name: "穿衣指数", level: level, description: desc, icon: icon)
    }

    // 紫外线指数
    private static func calculateUV(uvIndex: Double) -> LifeIndexItem {
        let (level, desc, icon): (String, String, String)
        switch uvIndex {
        case 0..<3:
            level = "弱"
            desc = "紫外线较弱，无需特别防护"
            icon = "sun.min"
        case 3..<6:
            level = "中等"
            desc = "紫外线中等，建议涂抹防晒霜"
            icon = "sun.max"
        case 6..<8:
            level = "强"
            desc = "紫外线较强，外出需做好防护"
            icon = "sun.max.fill"
        case 8..<11:
            level = "很强"
            desc = "紫外线很强，尽量减少户外活动"
            icon = "sun.max.trianglebadge.exclamationmark"
        default:
            level = "极强"
            desc = "紫外线极强，避免外出"
            icon = "sun.max.trianglebadge.exclamationmark.fill"
        }
        return LifeIndexItem(name: "紫外线指数", level: level, description: desc, icon: icon)
    }

    // 运动指数
    private static func calculateExercise(weather: CurrentWeatherData) -> LifeIndexItem {
        let (level, desc): (String, String)
        if weather.weatherCode >= 51 { // 降水天气
            level = "不适宜"
            desc = "有降水，不适宜户外运动"
        } else if weather.temperature < 0 || weather.temperature > 35 {
            level = "较不适宜"
            desc = "温度过高或过低，建议室内运动"
        } else if weather.windSpeed > 30 {
            level = "较不适宜"
            desc = "风力较大，建议室内运动"
        } else if weather.temperature >= 15 && weather.temperature <= 28 {
            level = "非常适宜"
            desc = "天气舒适，非常适合户外运动"
        } else {
            level = "适宜"
            desc = "天气适宜运动，注意补充水分"
        }
        return LifeIndexItem(name: "运动指数", level: level, description: desc, icon: "figure.run")
    }

    // 洗车指数
    private static func calculateCarWash(weather: CurrentWeatherData, daily: DailyWeatherData?) -> LifeIndexItem {
        let (level, desc): (String, String)
        let precipProb = daily?.precipitationProbabilityMax ?? 0
        if precipProb > 50 || weather.weatherCode >= 51 {
            level = "不适宜"
            desc = "近期有降水，洗车后容易脏"
        } else if precipProb > 30 {
            level = "较不适宜"
            desc = "有降水可能，不建议洗车"
        } else if weather.windSpeed > 20 {
            level = "较不适宜"
            desc = "风力较大，洗车后容易沾灰"
        } else {
            level = "适宜"
            desc = "天气晴好，适合洗车"
        }
        return LifeIndexItem(name: "洗车指数", level: level, description: desc, icon: "car.fill")
    }

    // 舒适度指数
    private static func calculateComfort(weather: CurrentWeatherData) -> LifeIndexItem {
        let (level, desc): (String, String)
        let temp = weather.apparentTemperature
        let humidity = weather.humidity

        if temp >= 18 && temp <= 26 && humidity >= 40 && humidity <= 70 {
            level = "舒适"
            desc = "体感舒适，非常宜人"
        } else if temp >= 10 && temp <= 30 && humidity >= 30 && humidity <= 80 {
            level = "较舒适"
            desc = "体感较为舒适"
        } else if temp < 5 || temp > 35 || humidity > 85 {
            level = "不舒适"
            desc = "体感不适，建议减少外出"
        } else {
            level = "一般"
            desc = "体感一般，注意增减衣物"
        }
        return LifeIndexItem(name: "舒适度", level: level, description: desc, icon: "person.fill")
    }

    // 空气质量指数（基于能见度估算）
    private static func calculateAirQuality(visibility: Double) -> LifeIndexItem {
        let (level, desc): (String, String)
        switch visibility {
        case 10...:
            level = "优"
            desc = "空气质量优秀，适合户外活动"
        case 6..<10:
            level = "良"
            desc = "空气质量良好"
        case 3..<6:
            level = "轻度污染"
            desc = "空气质量一般，敏感人群注意"
        case 1..<3:
            level = "中度污染"
            desc = "空气质量较差，建议减少外出"
        default:
            level = "重度污染"
            desc = "空气质量差，避免户外活动"
        }
        return LifeIndexItem(name: "空气质量", level: level, description: desc, icon: "aqi.medium")
    }

    // 出行指数
    private static func calculateTravel(weather: CurrentWeatherData) -> LifeIndexItem {
        let (level, desc): (String, String)
        if weather.weatherCode >= 95 {
            level = "不适宜"
            desc = "雷暴天气，不适宜出行"
        } else if weather.weatherCode >= 51 {
            level = "较不适宜"
            desc = "有降水，出行需带雨具"
        } else if weather.visibility < 1 {
            level = "不适宜"
            desc = "能见度很低，不适宜出行"
        } else if weather.windSpeed > 40 {
            level = "较不适宜"
            desc = "风力很大，出行注意安全"
        } else if weather.weatherCode <= 2 && weather.visibility > 5 {
            level = "非常适宜"
            desc = "天气晴好，非常适合出行"
        } else {
            level = "适宜"
            desc = "天气适宜出行"
        }
        return LifeIndexItem(name: "出行指数", level: level, description: desc, icon: "car.side")
    }

    // 过敏指数
    private static func calculateAllergy(weather: CurrentWeatherData) -> LifeIndexItem {
        let (level, desc): (String, String)
        if weather.humidity > 70 || weather.weatherCode >= 51 {
            level = "低"
            desc = "湿度较高，花粉传播受限"
        } else if weather.windSpeed > 20 && weather.humidity < 50 {
            level = "高"
            desc = "风大干燥，易引发过敏"
        } else {
            level = "中等"
            desc = "过敏人群需适当防护"
        }
        return LifeIndexItem(name: "过敏指数", level: level, description: desc, icon: "allergens")
    }
}

// MARK: - 出行建议生成器
struct TravelAdviceGenerator {
    /// 根据天气数据生成出行建议
    static func generate(from daily: DailyWeatherData, current: CurrentWeatherData?) -> TravelAdvice {
        var details: [TravelAdvice.TravelAdviceItem] = []
        var score = 100

        // 天气影响
        let weatherType = WeatherCodeHelper.weatherType(for: daily.weatherCode)
        switch weatherType {
        case .sunny:
            details.append(.init(category: "天气", advice: "天气晴好，适合各类户外活动", icon: "sun.max.fill"))
        case .partlyCloudy:
            details.append(.init(category: "天气", advice: "多云天气，适合出行", icon: "cloud.sun.fill"))
            score -= 5
        case .cloudy:
            details.append(.init(category: "天气", advice: "阴天，带把伞以防万一", icon: "cloud.fill"))
            score -= 10
        case .rainy:
            details.append(.init(category: "天气", advice: "有雨，记得带伞，注意路滑", icon: "cloud.rain.fill"))
            score -= 30
        case .snowy:
            details.append(.init(category: "天气", advice: "有雪，注意保暖和路面结冰", icon: "cloud.snow.fill"))
            score -= 40
        case .thunderstorm:
            details.append(.init(category: "天气", advice: "雷暴天气，建议减少外出", icon: "cloud.bolt.rain.fill"))
            score -= 50
        case .foggy:
            details.append(.init(category: "天气", advice: "有雾，能见度低，驾车需谨慎", icon: "cloud.fog.fill"))
            score -= 25
        }

        // 温度影响
        let avgTemp = (daily.temperatureMax + daily.temperatureMin) / 2
        if avgTemp < 0 {
            details.append(.init(category: "温度", advice: "气温很低，注意防寒保暖", icon: "thermometer.snowflake"))
            score -= 15
        } else if avgTemp < 10 {
            details.append(.init(category: "温度", advice: "气温较低，多穿衣服", icon: "thermometer.low"))
            score -= 5
        } else if avgTemp > 35 {
            details.append(.init(category: "温度", advice: "高温天气，注意防暑降温", icon: "thermometer.sun.fill"))
            score -= 20
        } else if avgTemp > 28 {
            details.append(.init(category: "温度", advice: "天气较热，注意补充水分", icon: "thermometer.medium"))
            score -= 5
        } else {
            details.append(.init(category: "温度", advice: "气温适宜，体感舒适", icon: "thermometer.medium"))
        }

        // 紫外线影响
        if daily.uvIndexMax > 6 {
            details.append(.init(category: "防晒", advice: "紫外线强，外出需做好防晒", icon: "sun.max.trianglebadge.exclamationmark"))
            score -= 10
        } else if daily.uvIndexMax > 3 {
            details.append(.init(category: "防晒", advice: "紫外线中等，建议涂防晒霜", icon: "sun.max"))
        }

        // 风力影响
        if daily.windSpeedMax > 40 {
            details.append(.init(category: "风力", advice: "风力很大，注意高空坠物", icon: "wind"))
            score -= 15
        } else if daily.windSpeedMax > 25 {
            details.append(.init(category: "风力", advice: "有风，注意防风", icon: "wind"))
            score -= 5
        }

        // 综合建议
        let overallAdvice: String
        switch score {
        case 90...100:
            overallAdvice = "今天非常适合出行，享受美好的一天吧！"
        case 70..<90:
            overallAdvice = "今天适合出行，稍作准备即可。"
        case 50..<70:
            overallAdvice = "今天出行需注意天气变化，做好准备。"
        case 30..<50:
            overallAdvice = "今天天气较差，非必要建议减少外出。"
        default:
            overallAdvice = "今天天气恶劣，建议待在室内。"
        }

        return TravelAdvice(
            date: daily.date,
            overallScore: max(0, score),
            overallAdvice: overallAdvice,
            details: details
        )
    }
}
