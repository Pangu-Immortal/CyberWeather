//
//  WeatherService.swift
//  CyberWeather
//
//  统一天气服务
//  实现多源API自动切换机制
//  优先级: Open-Meteo → wthrcdn → Visual Crossing
//  支持缓存和自动更新
//

import Foundation
import CoreLocation

// MARK: - API源枚举
enum WeatherAPISource: String, CaseIterable {
    case openMeteo = "Open-Meteo"
    case wthrcdn = "wthrcdn"
    case visualCrossing = "Visual Crossing"

    var priority: Int {
        switch self {
        case .openMeteo: return 0      // 最高优先级
        case .wthrcdn: return 1
        case .visualCrossing: return 2
        }
    }

    var description: String {
        switch self {
        case .openMeteo: return "Open-Meteo (免费无限制)"
        case .wthrcdn: return "中国天气网 (国内源)"
        case .visualCrossing: return "Visual Crossing (备用)"
        }
    }
}

// MARK: - 错误类型
enum WeatherError: Error, LocalizedError {
    case invalidURL                         // URL 无效
    case invalidResponse                    // 响应无效
    case httpError(Int)                     // HTTP 错误
    case decodingError(Error)               // JSON 解码错误
    case networkError(Error)                // 网络错误
    case allSourcesFailed([String: Error])  // 所有源都失败
    case locationNotAvailable               // 位置不可用

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "网络请求配置错误，请稍后重试"
        case .invalidResponse:
            return "服务器响应异常，请稍后重试"
        case .httpError(let code):
            switch code {
            case 400..<500:
                return "请求出错，请检查网络设置"
            case 500..<600:
                return "服务器繁忙，请稍后重试"
            default:
                return "网络异常 (\(code))，请稍后重试"
            }
        case .decodingError:
            return "数据解析失败，请更新应用后重试"
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    return "网络连接已断开，请检查网络设置"
                case NSURLErrorTimedOut:
                    return "网络请求超时，请检查网络状况"
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    return "无法连接到服务器，请稍后重试"
                default:
                    return "网络连接失败，请检查网络设置"
                }
            }
            return "网络连接失败，请检查网络设置"
        case .allSourcesFailed:
            return "天气服务暂时不可用，请稍后重试"
        case .locationNotAvailable:
            return "无法获取位置信息，请检查定位权限"
        }
    }

    /// 用于调试的详细信息
    var debugDescription: String {
        switch self {
        case .invalidURL:
            return "[DEBUG] Invalid URL configuration"
        case .invalidResponse:
            return "[DEBUG] Server returned invalid response"
        case .httpError(let code):
            return "[DEBUG] HTTP error: \(code)"
        case .decodingError(let error):
            return "[DEBUG] Decoding error: \(error)"
        case .networkError(let error):
            return "[DEBUG] Network error: \(error)"
        case .allSourcesFailed(let errors):
            let details = errors.map { "\($0.key): \($0.value)" }.joined(separator: "; ")
            return "[DEBUG] All sources failed: \(details)"
        case .locationNotAvailable:
            return "[DEBUG] Location not available"
        }
    }
}

// MARK: - 统一天气服务
actor WeatherService {
    // MARK: - 单例
    static let shared = WeatherService()

    // MARK: - 服务实例
    private let openMeteoService = OpenMeteoService.shared

    // MARK: - 状态
    private var lastUsedSource: WeatherAPISource = .openMeteo
    private var sourceErrors: [WeatherAPISource: Date] = [:]
    private let errorCooldown: TimeInterval = 300  // 5分钟冷却时间

    // MARK: - 缓存
    private var cache: [String: CachedWeatherData] = [:]
    private let cacheExpiration: TimeInterval = 600  // 10分钟缓存有效期

    private struct CachedWeatherData {
        let data: WeatherData
        let timestamp: Date
        let source: WeatherAPISource
    }

    // MARK: - 初始化
    private init() {
        print("[WeatherService] 初始化统一天气服务")
    }

    // MARK: - 获取天气数据（自动切换源）
    func fetchWeather(
        latitude: Double,
        longitude: Double,
        locationName: String
    ) async throws -> WeatherData {
        print("[WeatherService] 开始获取天气: (\(latitude), \(longitude)) - \(locationName)")

        // 检查缓存
        let cacheKey = String(format: "%.2f_%.2f", latitude, longitude)
        if let cached = getCached(for: cacheKey) {
            print("[WeatherService] 使用缓存数据")
            return cached
        }

        var errors: [String: Error] = [:]
        let sortedSources = WeatherAPISource.allCases.sorted { $0.priority < $1.priority }

        for source in sortedSources {
            // 检查该源是否在冷却中
            if let errorTime = sourceErrors[source],
               Date().timeIntervalSince(errorTime) < errorCooldown {
                print("[WeatherService] \(source.rawValue) 处于冷却中，跳过")
                continue
            }

            do {
                let data = try await fetchFromSource(
                    source,
                    latitude: latitude,
                    longitude: longitude,
                    cityName: locationName
                )
                lastUsedSource = source
                // 清除该源的错误记录
                sourceErrors[source] = nil
                // 缓存数据
                setCache(data, for: cacheKey, source: source)
                print("[WeatherService] ✅ 成功从 \(source.rawValue) 获取数据")
                return data
            } catch {
                print("[WeatherService] ❌ \(source.rawValue) 失败: \(error.localizedDescription)")
                errors[source.rawValue] = error
                sourceErrors[source] = Date()
            }
        }

        throw WeatherError.allSourcesFailed(errors)
    }

    // MARK: - 从指定源获取数据
    private func fetchFromSource(
        _ source: WeatherAPISource,
        latitude: Double,
        longitude: Double,
        cityName: String
    ) async throws -> WeatherData {
        switch source {
        case .openMeteo:
            return try await fetchFromOpenMeteo(
                latitude: latitude,
                longitude: longitude,
                cityName: cityName
            )

        case .wthrcdn:
            return try await fetchFromWthrcdn(
                cityName: cityName,
                latitude: latitude,
                longitude: longitude
            )

        case .visualCrossing:
            return try await fetchFromVisualCrossing(
                latitude: latitude,
                longitude: longitude,
                cityName: cityName
            )
        }
    }

    // MARK: - Open-Meteo 请求
    private func fetchFromOpenMeteo(
        latitude: Double,
        longitude: Double,
        cityName: String
    ) async throws -> WeatherData {
        let response = try await openMeteoService.fetchWeather(
            latitude: latitude,
            longitude: longitude
        )
        return await openMeteoService.convertToWeatherData(response, cityName: cityName)
    }

    // MARK: - wthrcdn 请求（中国天气源）
    private func fetchFromWthrcdn(
        cityName: String,
        latitude: Double,
        longitude: Double
    ) async throws -> WeatherData {
        // 构建URL
        let encodedCity = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cityName
        let urlString = "http://wthrcdn.etouch.cn/weather_mini?city=\(encodedCity)"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        // 解析JSON
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: Any] else {
            throw WeatherError.decodingError(NSError(domain: "JSON", code: -1))
        }

        // 转换为WeatherData
        return convertWthrcdnToWeatherData(dataDict, cityName: cityName, latitude: latitude, longitude: longitude)
    }

    // MARK: - Visual Crossing 请求
    private func fetchFromVisualCrossing(
        latitude: Double,
        longitude: Double,
        cityName: String
    ) async throws -> WeatherData {
        let apiKey = "DEMO_KEY"  // 实际使用时替换为有效的API Key
        let urlString = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(latitude),\(longitude)?unitGroup=metric&key=\(apiKey)&contentType=json"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        // 解析JSON
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WeatherError.decodingError(NSError(domain: "JSON", code: -1))
        }

        // 转换为WeatherData
        return convertVisualCrossingToWeatherData(json, cityName: cityName, latitude: latitude, longitude: longitude)
    }

    // MARK: - wthrcdn 数据转换
    private func convertWthrcdnToWeatherData(
        _ data: [String: Any],
        cityName: String,
        latitude: Double,
        longitude: Double
    ) -> WeatherData {
        let wendu = Double(data["wendu"] as? String ?? "20") ?? 20
        let forecast = data["forecast"] as? [[String: Any]] ?? []

        // 构建位置信息
        let location = LocationInfo(
            name: cityName,
            latitude: latitude,
            longitude: longitude,
            timezone: "Asia/Shanghai"
        )

        // 构建当前天气
        let currentWeather = CurrentWeatherData(
            temperature: wendu,
            apparentTemperature: wendu,
            humidity: 60,
            weatherCode: 0,
            windSpeed: 10,
            windDirection: 180,
            pressure: 1013,
            uvIndex: 5,
            visibility: 10,
            isDay: true
        )

        // 构建每日预报
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        var dailyData: [DailyWeatherData] = []
        for (index, day) in forecast.prefix(7).enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date()
            let dateString = dateFormatter.string(from: date)
            let high = extractTemp(from: day["high"] as? String ?? "")
            let low = extractTemp(from: day["low"] as? String ?? "")

            let sunriseDate = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: date) ?? date
            let sunsetDate = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: date) ?? date

            dailyData.append(DailyWeatherData(
                date: dateString,
                weatherCode: 0,
                temperatureMax: high,
                temperatureMin: low,
                apparentTemperatureMax: high,
                apparentTemperatureMin: low,
                sunrise: timeFormatter.string(from: sunriseDate),
                sunset: timeFormatter.string(from: sunsetDate),
                uvIndexMax: 5,
                precipitationSum: 0,
                precipitationProbabilityMax: 0,
                windSpeedMax: 10,
                windDirectionDominant: 180
            ))
        }

        return WeatherData(
            location: location,
            current: currentWeather,
            hourly: [],
            daily: dailyData,
            lastUpdated: Date()
        )
    }

    // MARK: - Visual Crossing 数据转换
    private func convertVisualCrossingToWeatherData(
        _ data: [String: Any],
        cityName: String,
        latitude: Double,
        longitude: Double
    ) -> WeatherData {
        let currentConditions = data["currentConditions"] as? [String: Any] ?? [:]
        let days = data["days"] as? [[String: Any]] ?? []

        // 构建位置信息
        let location = LocationInfo(
            name: cityName,
            latitude: latitude,
            longitude: longitude,
            timezone: data["timezone"] as? String ?? "Asia/Shanghai"
        )

        // 当前天气
        let currentWeather = CurrentWeatherData(
            temperature: currentConditions["temp"] as? Double ?? 20,
            apparentTemperature: currentConditions["feelslike"] as? Double ?? 20,
            humidity: Int(currentConditions["humidity"] as? Double ?? 60),
            weatherCode: 0,
            windSpeed: currentConditions["windspeed"] as? Double ?? 10,
            windDirection: Int(currentConditions["winddir"] as? Double ?? 180),
            pressure: currentConditions["pressure"] as? Double ?? 1013,
            uvIndex: currentConditions["uvindex"] as? Double ?? 5,
            visibility: currentConditions["visibility"] as? Double ?? 10,
            isDay: true
        )

        // 每日预报
        var dailyData: [DailyWeatherData] = []

        for day in days.prefix(15) {
            let dateString = day["datetime"] as? String ?? ""
            let sunrise = day["sunrise"] as? String ?? "06:30:00"
            let sunset = day["sunset"] as? String ?? "18:30:00"

            dailyData.append(DailyWeatherData(
                date: dateString,
                weatherCode: 0,
                temperatureMax: day["tempmax"] as? Double ?? 25,
                temperatureMin: day["tempmin"] as? Double ?? 15,
                apparentTemperatureMax: day["feelslikemax"] as? Double ?? 25,
                apparentTemperatureMin: day["feelslikemin"] as? Double ?? 15,
                sunrise: "\(dateString)T\(sunrise)",
                sunset: "\(dateString)T\(sunset)",
                uvIndexMax: day["uvindex"] as? Double ?? 5,
                precipitationSum: day["precip"] as? Double ?? 0,
                precipitationProbabilityMax: Int(day["precipprob"] as? Double ?? 0),
                windSpeedMax: day["windspeed"] as? Double ?? 10,
                windDirectionDominant: Int(day["winddir"] as? Double ?? 180)
            ))
        }

        return WeatherData(
            location: location,
            current: currentWeather,
            hourly: [],
            daily: dailyData,
            lastUpdated: Date()
        )
    }

    // MARK: - 辅助方法

    private func extractTemp(from string: String) -> Double {
        let digits = string.filter { $0.isNumber || $0 == "-" }
        return Double(digits) ?? 20
    }

    // MARK: - 缓存方法

    private func getCached(for key: String) -> WeatherData? {
        guard let cached = cache[key] else { return nil }

        if Date().timeIntervalSince(cached.timestamp) > cacheExpiration {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.data
    }

    private func setCache(_ data: WeatherData, for key: String, source: WeatherAPISource) {
        cache[key] = CachedWeatherData(
            data: data,
            timestamp: Date(),
            source: source
        )
    }

    // MARK: - 公开方法

    /// 获取当前使用的数据源
    func getCurrentSource() -> WeatherAPISource {
        return lastUsedSource
    }

    /// 重置错误状态
    func resetErrors() {
        sourceErrors.removeAll()
        print("[WeatherService] 已重置所有源的错误状态")
    }

    /// 清除缓存
    func clearCache() {
        cache.removeAll()
        print("[WeatherService] 缓存已清空")
    }

    /// 检查源状态
    func getSourceStatus() -> [(source: WeatherAPISource, available: Bool, cooldownRemaining: TimeInterval?)] {
        return WeatherAPISource.allCases.map { source in
            if let errorTime = sourceErrors[source] {
                let elapsed = Date().timeIntervalSince(errorTime)
                if elapsed < errorCooldown {
                    return (source, false, errorCooldown - elapsed)
                }
            }
            return (source, true, nil)
        }
    }
}

// MARK: - 自动更新管理器
@Observable
class WeatherUpdateManager {
    static let shared = WeatherUpdateManager()

    private var timer: Timer?
    private(set) var lastUpdateTime: Date?
    private(set) var isUpdating = false

    private init() {}

    // MARK: - 开始自动更新
    func startAutoUpdate(interval: TimeInterval, action: @escaping () async -> Void) {
        stopAutoUpdate()

        print("[WeatherUpdateManager] 启动自动更新，间隔: \(interval)秒")

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, !self.isUpdating else { return }

            Task {
                await MainActor.run {
                    self.isUpdating = true
                }
                await action()
                await MainActor.run {
                    self.isUpdating = false
                    self.lastUpdateTime = Date()
                }
            }
        }
    }

    // MARK: - 停止自动更新
    func stopAutoUpdate() {
        timer?.invalidate()
        timer = nil
        print("[WeatherUpdateManager] 自动更新已停止")
    }

    // MARK: - 手动触发更新
    func triggerUpdate(action: @escaping () async -> Void) {
        guard !isUpdating else {
            print("[WeatherUpdateManager] 更新进行中，跳过")
            return
        }

        Task {
            await MainActor.run {
                isUpdating = true
            }
            await action()
            await MainActor.run {
                isUpdating = false
                lastUpdateTime = Date()
            }
        }
    }
}
