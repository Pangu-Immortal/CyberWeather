//
//  OpenMeteoService.swift
//  CyberWeather
//
//  Open-Meteo 天气API服务（主API）
//  免费无限制，支持16天预报 + 逐小时数据
//  API文档: https://open-meteo.com/en/docs
//

import Foundation

// MARK: - Open-Meteo API 响应模型
struct OpenMeteoResponse: Codable {
    let latitude: Double                    // 纬度
    let longitude: Double                   // 经度
    let timezone: String                    // 时区
    let current: OpenMeteoCurrent?          // 当前天气
    let hourly: OpenMeteoHourly?            // 小时预报
    let daily: OpenMeteoDaily?              // 每日预报
}

struct OpenMeteoCurrent: Codable {
    let time: String                        // 时间
    let temperature_2m: Double              // 温度
    let relative_humidity_2m: Int           // 相对湿度
    let apparent_temperature: Double        // 体感温度
    let weather_code: Int                   // 天气代码
    let wind_speed_10m: Double              // 风速
    let wind_direction_10m: Int             // 风向
    let pressure_msl: Double                // 海平面气压
    let uv_index: Double?                   // 紫外线指数
    let visibility: Double?                 // 能见度
    let is_day: Int?                        // 是否白天
}

struct OpenMeteoHourly: Codable {
    let time: [String]                      // 时间数组
    let temperature_2m: [Double]            // 温度数组
    let relative_humidity_2m: [Int]         // 湿度数组
    let apparent_temperature: [Double]      // 体感温度
    let precipitation_probability: [Int]    // 降水概率
    let precipitation: [Double]             // 降水量
    let weather_code: [Int]                 // 天气代码
    let wind_speed_10m: [Double]            // 风速
    let wind_direction_10m: [Int]           // 风向
    let uv_index: [Double]?                 // 紫外线指数
    let visibility: [Double]?               // 能见度
    let is_day: [Int]?                      // 是否白天
}

struct OpenMeteoDaily: Codable {
    let time: [String]                      // 日期数组
    let weather_code: [Int]                 // 天气代码
    let temperature_2m_max: [Double]        // 最高温度
    let temperature_2m_min: [Double]        // 最低温度
    let apparent_temperature_max: [Double]  // 体感最高温
    let apparent_temperature_min: [Double]  // 体感最低温
    let sunrise: [String]                   // 日出时间
    let sunset: [String]                    // 日落时间
    let uv_index_max: [Double]              // 最大紫外线指数
    let precipitation_sum: [Double]         // 降水总量
    let precipitation_probability_max: [Int] // 最大降水概率
    let wind_speed_10m_max: [Double]        // 最大风速
    let wind_direction_10m_dominant: [Int]  // 主导风向
}

// MARK: - Open-Meteo 服务
actor OpenMeteoService {

    // MARK: - 单例
    static let shared = OpenMeteoService()

    // MARK: - API配置
    private let baseURL = "https://api.open-meteo.com/v1/forecast"

    // MARK: - 获取完整天气数据（16天预报）
    func fetchWeather(latitude: Double, longitude: Double) async throws -> OpenMeteoResponse {
        // 构建URL参数
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "timezone", value: "auto"),
            // 当前天气
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,pressure_msl,uv_index,visibility,is_day"),
            // 小时预报（168小时=7天）
            URLQueryItem(name: "hourly", value: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,precipitation,weather_code,wind_speed_10m,wind_direction_10m,uv_index,visibility,is_day"),
            // 每日预报（16天）
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant"),
            URLQueryItem(name: "forecast_days", value: "16")
        ]

        guard let url = components.url else {
            throw WeatherAPIError.invalidURL
        }

        print("[OpenMeteoService] 请求URL: \(url)") // 日志

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherAPIError.invalidResponse
        }

        print("[OpenMeteoService] HTTP状态码: \(httpResponse.statusCode)") // 日志

        guard httpResponse.statusCode == 200 else {
            throw WeatherAPIError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(OpenMeteoResponse.self, from: data)

        print("[OpenMeteoService] 数据解析成功，每日预报天数: \(result.daily?.time.count ?? 0)") // 日志

        return result
    }

    // MARK: - 转换为统一天气模型
    func convertToWeatherData(_ response: OpenMeteoResponse, cityName: String) -> WeatherData {
        // 当前天气
        let current = CurrentWeatherData(
            temperature: response.current?.temperature_2m ?? 0,
            apparentTemperature: response.current?.apparent_temperature ?? 0,
            humidity: response.current?.relative_humidity_2m ?? 0,
            weatherCode: response.current?.weather_code ?? 0,
            windSpeed: response.current?.wind_speed_10m ?? 0,
            windDirection: response.current?.wind_direction_10m ?? 0,
            pressure: response.current?.pressure_msl ?? 1013,
            uvIndex: response.current?.uv_index ?? 0,
            visibility: (response.current?.visibility ?? 10000) / 1000, // 转换为km
            isDay: (response.current?.is_day ?? 1) == 1
        )

        // 小时预报（从当前小时开始）
        var hourlyData: [HourlyWeatherData] = []
        if let hourly = response.hourly {
            // 找到当前时间对应的索引
            let now = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: now)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: now)

            // 查找当前小时的起始索引
            var startIndex = 0
            for (index, timeStr) in hourly.time.enumerated() {
                // timeStr 格式: "2024-01-29T19:00"
                if timeStr.hasPrefix(todayString) {
                    let hourPart = timeStr.suffix(5).prefix(2) // 提取小时部分
                    if let hour = Int(hourPart), hour >= currentHour {
                        startIndex = index
                        break
                    }
                }
            }

            // 从当前小时开始取48小时数据
            let endIndex = min(startIndex + 48, hourly.time.count)
            for i in startIndex..<endIndex {
                let hour = HourlyWeatherData(
                    time: hourly.time[i],
                    temperature: hourly.temperature_2m[i],
                    apparentTemperature: hourly.apparent_temperature[i],
                    humidity: hourly.relative_humidity_2m[i],
                    precipitationProbability: hourly.precipitation_probability[i],
                    precipitation: hourly.precipitation[i],
                    weatherCode: hourly.weather_code[i],
                    windSpeed: hourly.wind_speed_10m[i],
                    windDirection: hourly.wind_direction_10m[i],
                    uvIndex: hourly.uv_index?[i] ?? 0,
                    visibility: (hourly.visibility?[i] ?? 10000) / 1000,
                    isDay: (hourly.is_day?[i] ?? 1) == 1
                )
                hourlyData.append(hour)
            }

            print("[OpenMeteoService] 小时预报从索引\(startIndex)开始，当前小时:\(currentHour)") // 日志
        }

        // 每日预报
        var dailyData: [DailyWeatherData] = []
        if let daily = response.daily {
            for i in 0..<daily.time.count {
                let day = DailyWeatherData(
                    date: daily.time[i],
                    weatherCode: daily.weather_code[i],
                    temperatureMax: daily.temperature_2m_max[i],
                    temperatureMin: daily.temperature_2m_min[i],
                    apparentTemperatureMax: daily.apparent_temperature_max[i],
                    apparentTemperatureMin: daily.apparent_temperature_min[i],
                    sunrise: daily.sunrise[i],
                    sunset: daily.sunset[i],
                    uvIndexMax: daily.uv_index_max[i],
                    precipitationSum: daily.precipitation_sum[i],
                    precipitationProbabilityMax: daily.precipitation_probability_max[i],
                    windSpeedMax: daily.wind_speed_10m_max[i],
                    windDirectionDominant: daily.wind_direction_10m_dominant[i]
                )
                dailyData.append(day)
            }
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
}

// MARK: - API错误类型
enum WeatherAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case noData
    case allAPIsFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .noData:
            return "没有数据"
        case .allAPIsFailed:
            return "所有天气API均不可用"
        }
    }
}
