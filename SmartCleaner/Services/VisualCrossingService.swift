//
//  VisualCrossingService.swift
//  SmartCleaner
//
//  Visual Crossing 备用天气API服务
//  免费1000次/天，支持15天预报
//  当前两个API都不可用时自动切换
//  API文档: https://www.visualcrossing.com/weather-api
//

import Foundation

// MARK: - Visual Crossing API 响应模型
struct VisualCrossingResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let currentConditions: VCCurrentConditions?
    let days: [VCDayData]
}

struct VCCurrentConditions: Codable {
    let temp: Double                        // 温度（华氏或摄氏取决于参数）
    let feelslike: Double                   // 体感温度
    let humidity: Double                    // 湿度
    let conditions: String                  // 天气描述
    let icon: String                        // 图标代码
    let windspeed: Double                   // 风速
    let winddir: Double                     // 风向
    let pressure: Double                    // 气压
    let uvindex: Double                     // 紫外线指数
    let visibility: Double                  // 能见度
    let sunrise: String?                    // 日出
    let sunset: String?                     // 日落
}

struct VCDayData: Codable {
    let datetime: String                    // 日期
    let tempmax: Double                     // 最高温度
    let tempmin: Double                     // 最低温度
    let temp: Double                        // 平均温度
    let feelslikemax: Double                // 体感最高
    let feelslikemin: Double                // 体感最低
    let humidity: Double                    // 湿度
    let precip: Double?                     // 降水量
    let precipprob: Double?                 // 降水概率
    let windspeed: Double                   // 风速
    let winddir: Double                     // 风向
    let pressure: Double                    // 气压
    let uvindex: Double                     // 紫外线指数
    let visibility: Double                  // 能见度
    let sunrise: String                     // 日出
    let sunset: String                      // 日落
    let conditions: String                  // 天气描述
    let icon: String                        // 图标代码
    let hours: [VCHourData]?                // 小时数据
}

struct VCHourData: Codable {
    let datetime: String                    // 时间
    let temp: Double                        // 温度
    let feelslike: Double                   // 体感温度
    let humidity: Double                    // 湿度
    let precip: Double?                     // 降水量
    let precipprob: Double?                 // 降水概率
    let windspeed: Double                   // 风速
    let winddir: Double                     // 风向
    let uvindex: Double                     // 紫外线指数
    let visibility: Double                  // 能见度
    let conditions: String                  // 天气描述
    let icon: String                        // 图标代码
}

// MARK: - Visual Crossing 服务
actor VisualCrossingService {

    // MARK: - 单例
    static let shared = VisualCrossingService()

    // MARK: - API配置
    private let baseURL = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline"
    // 免费API Key（仅用于非商业用途）
    private let apiKey = "DEMO_KEY" // 用户可替换为自己的Key

    // MARK: - 获取天气数据
    func fetchWeather(latitude: Double, longitude: Double) async throws -> VisualCrossingResponse {
        // 构建URL
        let location = "\(latitude),\(longitude)"
        let urlString = "\(baseURL)/\(location)?unitGroup=metric&key=\(apiKey)&include=hours,current&contentType=json"

        guard let url = URL(string: urlString) else {
            throw WeatherAPIError.invalidURL
        }

        print("[VisualCrossingService] 请求URL: \(url)") // 日志

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherAPIError.invalidResponse
        }

        print("[VisualCrossingService] HTTP状态码: \(httpResponse.statusCode)") // 日志

        guard httpResponse.statusCode == 200 else {
            throw WeatherAPIError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(VisualCrossingResponse.self, from: data)

        print("[VisualCrossingService] 数据解析成功，预报天数: \(result.days.count)") // 日志

        return result
    }

    // MARK: - 转换为统一天气模型
    func convertToWeatherData(_ response: VisualCrossingResponse, cityName: String) -> WeatherData {
        // 当前天气
        let current = CurrentWeatherData(
            temperature: response.currentConditions?.temp ?? response.days.first?.temp ?? 0,
            apparentTemperature: response.currentConditions?.feelslike ?? response.days.first?.temp ?? 0,
            humidity: Int(response.currentConditions?.humidity ?? response.days.first?.humidity ?? 50),
            weatherCode: iconToWeatherCode(response.currentConditions?.icon ?? response.days.first?.icon ?? "clear-day"),
            windSpeed: response.currentConditions?.windspeed ?? response.days.first?.windspeed ?? 0,
            windDirection: Int(response.currentConditions?.winddir ?? response.days.first?.winddir ?? 0),
            pressure: response.currentConditions?.pressure ?? response.days.first?.pressure ?? 1013,
            uvIndex: response.currentConditions?.uvindex ?? response.days.first?.uvindex ?? 0,
            visibility: response.currentConditions?.visibility ?? response.days.first?.visibility ?? 10,
            isDay: true
        )

        // 小时预报
        var hourlyData: [HourlyWeatherData] = []
        for day in response.days.prefix(2) { // 取两天的小时数据
            if let hours = day.hours {
                for hour in hours {
                    let hourData = HourlyWeatherData(
                        time: "\(day.datetime)T\(hour.datetime)",
                        temperature: hour.temp,
                        apparentTemperature: hour.feelslike,
                        humidity: Int(hour.humidity),
                        precipitationProbability: Int(hour.precipprob ?? 0),
                        precipitation: hour.precip ?? 0,
                        weatherCode: iconToWeatherCode(hour.icon),
                        windSpeed: hour.windspeed,
                        windDirection: Int(hour.winddir),
                        uvIndex: hour.uvindex,
                        visibility: hour.visibility,
                        isDay: !hour.icon.contains("night")
                    )
                    hourlyData.append(hourData)
                }
            }
        }

        // 每日预报
        var dailyData: [DailyWeatherData] = []
        for day in response.days {
            let dayData = DailyWeatherData(
                date: day.datetime,
                weatherCode: iconToWeatherCode(day.icon),
                temperatureMax: day.tempmax,
                temperatureMin: day.tempmin,
                apparentTemperatureMax: day.feelslikemax,
                apparentTemperatureMin: day.feelslikemin,
                sunrise: day.sunrise,
                sunset: day.sunset,
                uvIndexMax: day.uvindex,
                precipitationSum: day.precip ?? 0,
                precipitationProbabilityMax: Int(day.precipprob ?? 0),
                windSpeedMax: day.windspeed,
                windDirectionDominant: Int(day.winddir)
            )
            dailyData.append(dayData)
        }

        return WeatherData(
            location: LocationInfo(
                name: cityName,
                latitude: response.latitude,
                longitude: response.longitude,
                timezone: response.timezone
            ),
            current: current,
            hourly: hourlyData,
            daily: dailyData,
            lastUpdated: Date()
        )
    }

    // MARK: - 图标代码转天气代码
    private func iconToWeatherCode(_ icon: String) -> Int {
        switch icon {
        case "clear-day", "clear-night":
            return 0
        case "partly-cloudy-day", "partly-cloudy-night":
            return 2
        case "cloudy":
            return 3
        case "rain":
            return 61
        case "showers-day", "showers-night":
            return 80
        case "thunder-rain", "thunder-showers-day", "thunder-showers-night":
            return 95
        case "snow":
            return 71
        case "snow-showers-day", "snow-showers-night":
            return 85
        case "fog":
            return 45
        case "wind":
            return 0
        default:
            return 0
        }
    }
}
