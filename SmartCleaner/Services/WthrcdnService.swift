//
//  WthrcdnService.swift
//  SmartCleaner
//
//  国内备用天气API服务
//  无需API Key，支持5天预报
//  当 Open-Meteo 不可用时自动切换
//

import Foundation

// MARK: - wthrcdn API 响应模型（XML解析后转JSON结构）
struct WthrcdnResponse: Codable {
    let city: String                        // 城市名
    let updatetime: String                  // 更新时间
    let wendu: String                       // 当前温度
    let shidu: String                       // 湿度
    let fengxiang: String                   // 风向
    let fengli: String                      // 风力
    let sunrise: String                     // 日出
    let sunset: String                      // 日落
    let forecast: [WthrcdnForecast]         // 预报列表
}

struct WthrcdnForecast: Codable {
    let date: String                        // 日期
    let high: String                        // 最高温
    let low: String                         // 最低温
    let dayType: String                     // 白天天气
    let nightType: String                   // 夜间天气
    let dayFengxiang: String                // 白天风向
    let nightFengxiang: String              // 夜间风向
    let dayFengli: String                   // 白天风力
    let nightFengli: String                 // 夜间风力
}

// MARK: - wthrcdn 服务
actor WthrcdnService {

    // MARK: - 单例
    static let shared = WthrcdnService()

    // MARK: - API配置
    private let baseURL = "http://wthrcdn.etouch.cn/WeatherApi"

    // MARK: - 获取天气数据（通过城市名）
    func fetchWeather(cityName: String) async throws -> WthrcdnResponse {
        // URL编码城市名
        guard let encodedCity = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw WeatherAPIError.invalidURL
        }

        let urlString = "\(baseURL)?city=\(encodedCity)"
        guard let url = URL(string: urlString) else {
            throw WeatherAPIError.invalidURL
        }

        print("[WthrcdnService] 请求URL: \(url)") // 日志

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherAPIError.invalidResponse
        }

        print("[WthrcdnService] HTTP状态码: \(httpResponse.statusCode)") // 日志

        guard httpResponse.statusCode == 200 else {
            throw WeatherAPIError.httpError(httpResponse.statusCode)
        }

        // 解析XML数据
        let result = try parseXMLData(data)
        print("[WthrcdnService] 数据解析成功，城市: \(result.city)") // 日志

        return result
    }

    // MARK: - 解析XML数据
    private func parseXMLData(_ data: Data) throws -> WthrcdnResponse {
        let parser = WthrcdnXMLParser(data: data)
        guard let result = parser.parse() else {
            throw WeatherAPIError.decodingError(NSError(domain: "XMLParsing", code: -1))
        }
        return result
    }

    // MARK: - 转换为统一天气模型
    func convertToWeatherData(_ response: WthrcdnResponse, latitude: Double, longitude: Double) -> WeatherData {
        // 解析当前温度
        let currentTemp = Double(response.wendu) ?? 0

        // 解析湿度
        let humidity = Int(response.shidu.replacingOccurrences(of: "%", with: "")) ?? 50

        // 解析风力
        let windSpeed = parseWindSpeed(response.fengli)

        // 当前天气
        let current = CurrentWeatherData(
            temperature: currentTemp,
            apparentTemperature: currentTemp,
            humidity: humidity,
            weatherCode: weatherTypeToCode(response.forecast.first?.dayType ?? "晴"),
            windSpeed: windSpeed,
            windDirection: windDirectionToDegree(response.fengxiang),
            pressure: 1013,
            uvIndex: 5,
            visibility: 10,
            isDay: true
        )

        // 每日预报
        var dailyData: [DailyWeatherData] = []
        for (index, forecast) in response.forecast.enumerated() {
            // 解析温度
            let highTemp = Double(forecast.high.replacingOccurrences(of: "高温 ", with: "").replacingOccurrences(of: "℃", with: "")) ?? 20
            let lowTemp = Double(forecast.low.replacingOccurrences(of: "低温 ", with: "").replacingOccurrences(of: "℃", with: "")) ?? 10

            // 生成日期
            let date = Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let day = DailyWeatherData(
                date: dateFormatter.string(from: date),
                weatherCode: weatherTypeToCode(forecast.dayType),
                temperatureMax: highTemp,
                temperatureMin: lowTemp,
                apparentTemperatureMax: highTemp,
                apparentTemperatureMin: lowTemp,
                sunrise: response.sunrise,
                sunset: response.sunset,
                uvIndexMax: 5,
                precipitationSum: forecast.dayType.contains("雨") ? 10 : 0,
                precipitationProbabilityMax: forecast.dayType.contains("雨") ? 80 : 10,
                windSpeedMax: parseWindSpeed(forecast.dayFengli),
                windDirectionDominant: windDirectionToDegree(forecast.dayFengxiang)
            )
            dailyData.append(day)
        }

        // 生成小时预报（基于当前数据插值）
        var hourlyData: [HourlyWeatherData] = []
        let now = Date()
        for i in 0..<24 {
            let hourDate = Calendar.current.date(byAdding: .hour, value: i, to: now) ?? now
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

            let hour = HourlyWeatherData(
                time: dateFormatter.string(from: hourDate),
                temperature: currentTemp + Double.random(in: -2...2),
                apparentTemperature: currentTemp + Double.random(in: -2...2),
                humidity: humidity + Int.random(in: -5...5),
                precipitationProbability: response.forecast.first?.dayType.contains("雨") == true ? 60 : 10,
                precipitation: 0,
                weatherCode: current.weatherCode,
                windSpeed: windSpeed,
                windDirection: current.windDirection,
                uvIndex: 5,
                visibility: 10,
                isDay: i >= 6 && i <= 18
            )
            hourlyData.append(hour)
        }

        return WeatherData(
            location: LocationInfo(
                name: response.city,
                latitude: latitude,
                longitude: longitude,
                timezone: "Asia/Shanghai"
            ),
            current: current,
            hourly: hourlyData,
            daily: dailyData,
            lastUpdated: Date()
        )
    }

    // MARK: - 辅助方法

    /// 天气类型转天气代码
    private func weatherTypeToCode(_ type: String) -> Int {
        if type.contains("晴") { return 0 }
        if type.contains("多云") { return 2 }
        if type.contains("阴") { return 3 }
        if type.contains("雷") { return 95 }
        if type.contains("大雨") { return 65 }
        if type.contains("中雨") { return 63 }
        if type.contains("小雨") || type.contains("雨") { return 61 }
        if type.contains("大雪") { return 75 }
        if type.contains("中雪") { return 73 }
        if type.contains("小雪") || type.contains("雪") { return 71 }
        if type.contains("雾") { return 45 }
        if type.contains("霾") { return 48 }
        return 0
    }

    /// 风向转角度
    private func windDirectionToDegree(_ direction: String) -> Int {
        switch direction {
        case "北风": return 0
        case "东北风": return 45
        case "东风": return 90
        case "东南风": return 135
        case "南风": return 180
        case "西南风": return 225
        case "西风": return 270
        case "西北风": return 315
        default: return 0
        }
    }

    /// 解析风力等级
    private func parseWindSpeed(_ fengli: String) -> Double {
        // 风力格式: "3-4级" 或 "<3级"
        if fengli.contains("<") {
            return 5 // 小于3级约等于5km/h
        }
        if let range = fengli.range(of: "\\d+", options: .regularExpression) {
            let level = Int(fengli[range]) ?? 3
            return Double(level) * 5 // 粗略换算
        }
        return 10
    }
}

// MARK: - XML解析器
class WthrcdnXMLParser: NSObject, XMLParserDelegate {
    private var data: Data
    private var result: WthrcdnResponse?

    private var currentElement = ""
    private var currentText = ""

    private var city = ""
    private var updatetime = ""
    private var wendu = ""
    private var shidu = ""
    private var fengxiang = ""
    private var fengli = ""
    private var sunrise = ""
    private var sunset = ""
    private var forecasts: [WthrcdnForecast] = []

    // 临时预报数据
    private var forecastDate = ""
    private var forecastHigh = ""
    private var forecastLow = ""
    private var forecastDayType = ""
    private var forecastNightType = ""
    private var forecastDayFx = ""
    private var forecastNightFx = ""
    private var forecastDayFl = ""
    private var forecastNightFl = ""
    private var inForecast = false
    private var inDay = false
    private var inNight = false

    init(data: Data) {
        self.data = data
    }

    func parse() -> WthrcdnResponse? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return result
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""

        if elementName == "weather" {
            inForecast = true
            forecastDate = ""
            forecastHigh = ""
            forecastLow = ""
            forecastDayType = ""
            forecastNightType = ""
            forecastDayFx = ""
            forecastNightFx = ""
            forecastDayFl = ""
            forecastNightFl = ""
        } else if elementName == "day" {
            inDay = true
        } else if elementName == "night" {
            inNight = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if !inForecast {
            // 解析基本信息
            switch elementName {
            case "city": city = currentText
            case "updatetime": updatetime = currentText
            case "wendu": wendu = currentText
            case "shidu": shidu = currentText
            case "fengxiang": fengxiang = currentText
            case "fengli": fengli = currentText.replacingOccurrences(of: "<![CDATA[", with: "").replacingOccurrences(of: "]]>", with: "")
            case "sunrise_1": sunrise = currentText
            case "sunset_1": sunset = currentText
            default: break
            }
        } else {
            // 解析预报信息
            if inDay {
                switch elementName {
                case "type": forecastDayType = currentText
                case "fengxiang": forecastDayFx = currentText
                case "fengli": forecastDayFl = currentText.replacingOccurrences(of: "<![CDATA[", with: "").replacingOccurrences(of: "]]>", with: "")
                case "day": inDay = false
                default: break
                }
            } else if inNight {
                switch elementName {
                case "type": forecastNightType = currentText
                case "fengxiang": forecastNightFx = currentText
                case "fengli": forecastNightFl = currentText.replacingOccurrences(of: "<![CDATA[", with: "").replacingOccurrences(of: "]]>", with: "")
                case "night": inNight = false
                default: break
                }
            } else {
                switch elementName {
                case "date": forecastDate = currentText
                case "high": forecastHigh = currentText
                case "low": forecastLow = currentText
                default: break
                }
            }

            if elementName == "weather" {
                let forecast = WthrcdnForecast(
                    date: forecastDate,
                    high: forecastHigh,
                    low: forecastLow,
                    dayType: forecastDayType,
                    nightType: forecastNightType,
                    dayFengxiang: forecastDayFx,
                    nightFengxiang: forecastNightFx,
                    dayFengli: forecastDayFl,
                    nightFengli: forecastNightFl
                )
                forecasts.append(forecast)
                inForecast = false
            }
        }

        currentElement = ""
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        result = WthrcdnResponse(
            city: city,
            updatetime: updatetime,
            wendu: wendu,
            shidu: shidu,
            fengxiang: fengxiang,
            fengli: fengli,
            sunrise: sunrise,
            sunset: sunset,
            forecast: forecasts
        )
    }
}
