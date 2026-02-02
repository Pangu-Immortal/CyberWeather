//
//  SettingsModel.swift
//  CyberWeather
//
//  设置数据模型
//  使用 @AppStorage 实现持久化
//  包含温度单位、风速单位、更新频率等设置
//

import Foundation
import SwiftUI

// MARK: - 温度单位
enum TemperatureUnit: String, CaseIterable, Codable {
    case celsius = "celsius"        // 摄氏度
    case fahrenheit = "fahrenheit"  // 华氏度
    case kelvin = "kelvin"          // 开尔文

    var symbol: String {
        switch self {
        case .celsius: return "℃"
        case .fahrenheit: return "℉"
        case .kelvin: return "K"
        }
    }

    var name: String {
        switch self {
        case .celsius: return "摄氏度"
        case .fahrenheit: return "华氏度"
        case .kelvin: return "开尔文"
        }
    }

    /// 从摄氏度转换
    func convert(from celsius: Double) -> Double {
        switch self {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9 / 5 + 32
        case .kelvin: return celsius + 273.15
        }
    }

    /// 格式化温度
    func format(_ celsius: Double, showUnit: Bool = true) -> String {
        let value = convert(from: celsius)
        let rounded = Int(value.rounded())
        return showUnit ? "\(rounded)\(symbol)" : "\(rounded)°"
    }
}

// MARK: - 风速单位
enum WindSpeedUnit: String, CaseIterable, Codable {
    case kmh = "kmh"        // 公里/小时
    case ms = "ms"          // 米/秒
    case mph = "mph"        // 英里/小时
    case knots = "knots"    // 节

    var symbol: String {
        switch self {
        case .kmh: return "km/h"
        case .ms: return "m/s"
        case .mph: return "mph"
        case .knots: return "kn"
        }
    }

    var name: String {
        switch self {
        case .kmh: return "公里/小时"
        case .ms: return "米/秒"
        case .mph: return "英里/小时"
        case .knots: return "节"
        }
    }

    /// 从 km/h 转换
    func convert(from kmh: Double) -> Double {
        switch self {
        case .kmh: return kmh
        case .ms: return kmh / 3.6
        case .mph: return kmh / 1.609344
        case .knots: return kmh / 1.852
        }
    }

    /// 格式化风速
    func format(_ kmh: Double) -> String {
        let value = convert(from: kmh)
        return String(format: "%.1f %@", value, symbol)
    }
}

// MARK: - 气压单位
enum PressureUnit: String, CaseIterable, Codable {
    case hPa = "hPa"        // 百帕
    case mmHg = "mmHg"      // 毫米汞柱
    case inHg = "inHg"      // 英寸汞柱
    case atm = "atm"        // 标准大气压

    var symbol: String {
        rawValue
    }

    var name: String {
        switch self {
        case .hPa: return "百帕"
        case .mmHg: return "毫米汞柱"
        case .inHg: return "英寸汞柱"
        case .atm: return "标准大气压"
        }
    }

    /// 从 hPa 转换
    func convert(from hPa: Double) -> Double {
        switch self {
        case .hPa: return hPa
        case .mmHg: return hPa * 0.75006
        case .inHg: return hPa * 0.02953
        case .atm: return hPa / 1013.25
        }
    }

    /// 格式化气压
    func format(_ hPa: Double) -> String {
        let value = convert(from: hPa)
        switch self {
        case .hPa:
            return String(format: "%.0f %@", value, symbol)
        case .mmHg:
            return String(format: "%.1f %@", value, symbol)
        case .inHg:
            return String(format: "%.2f %@", value, symbol)
        case .atm:
            return String(format: "%.3f %@", value, symbol)
        }
    }
}

// MARK: - 更新频率
enum UpdateFrequency: String, CaseIterable, Codable {
    case manual = "manual"      // 手动
    case minutes15 = "15min"    // 15分钟
    case minutes30 = "30min"    // 30分钟
    case hour1 = "1hour"        // 1小时
    case hours3 = "3hours"      // 3小时

    var name: String {
        switch self {
        case .manual: return "手动"
        case .minutes15: return "15分钟"
        case .minutes30: return "30分钟"
        case .hour1: return "1小时"
        case .hours3: return "3小时"
        }
    }

    var seconds: TimeInterval? {
        switch self {
        case .manual: return nil
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hour1: return 60 * 60
        case .hours3: return 3 * 60 * 60
        }
    }
}

// MARK: - 预警时间
enum AlertTimeRange: String, CaseIterable, Codable {
    case always = "always"      // 全天
    case daytime = "daytime"    // 白天 (6:00-22:00)
    case custom = "custom"      // 自定义

    var name: String {
        switch self {
        case .always: return "全天"
        case .daytime: return "白天 (6:00-22:00)"
        case .custom: return "自定义"
        }
    }
}

// MARK: - 应用设置
@Observable
class AppSettings {
    // MARK: - 单例
    static let shared = AppSettings()

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let temperatureUnit = "temperatureUnit"
        static let windSpeedUnit = "windSpeedUnit"
        static let pressureUnit = "pressureUnit"
        static let autoUpdate = "autoUpdate"
        static let updateFrequency = "updateFrequency"
        static let weatherAlert = "weatherAlert"
        static let alertTimeRange = "alertTimeRange"
        static let alertStartHour = "alertStartHour"
        static let alertEndHour = "alertEndHour"
        static let dailyNotification = "dailyNotification"
        static let dailyNotificationHour = "dailyNotificationHour"
        static let hapticFeedback = "hapticFeedback"
        static let animationEnabled = "animationEnabled"
    }

    // MARK: - 单位设置
    var temperatureUnit: TemperatureUnit {
        didSet { save(temperatureUnit.rawValue, forKey: Keys.temperatureUnit) }
    }

    var windSpeedUnit: WindSpeedUnit {
        didSet { save(windSpeedUnit.rawValue, forKey: Keys.windSpeedUnit) }
    }

    var pressureUnit: PressureUnit {
        didSet { save(pressureUnit.rawValue, forKey: Keys.pressureUnit) }
    }

    // MARK: - 更新设置
    var autoUpdate: Bool {
        didSet { save(autoUpdate, forKey: Keys.autoUpdate) }
    }

    var updateFrequency: UpdateFrequency {
        didSet { save(updateFrequency.rawValue, forKey: Keys.updateFrequency) }
    }

    // MARK: - 预警设置
    var weatherAlert: Bool {
        didSet { save(weatherAlert, forKey: Keys.weatherAlert) }
    }

    var alertTimeRange: AlertTimeRange {
        didSet { save(alertTimeRange.rawValue, forKey: Keys.alertTimeRange) }
    }

    var alertStartHour: Int {
        didSet { save(alertStartHour, forKey: Keys.alertStartHour) }
    }

    var alertEndHour: Int {
        didSet { save(alertEndHour, forKey: Keys.alertEndHour) }
    }

    // MARK: - 通知设置
    var dailyNotification: Bool {
        didSet { save(dailyNotification, forKey: Keys.dailyNotification) }
    }

    var dailyNotificationHour: Int {
        didSet { save(dailyNotificationHour, forKey: Keys.dailyNotificationHour) }
    }

    // MARK: - 界面设置
    var hapticFeedback: Bool {
        didSet { save(hapticFeedback, forKey: Keys.hapticFeedback) }
    }

    var animationEnabled: Bool {
        didSet { save(animationEnabled, forKey: Keys.animationEnabled) }
    }

    // MARK: - 初始化
    private init() {
        let defaults = UserDefaults.standard

        // 加载单位设置
        temperatureUnit = TemperatureUnit(rawValue: defaults.string(forKey: Keys.temperatureUnit) ?? "") ?? .celsius
        windSpeedUnit = WindSpeedUnit(rawValue: defaults.string(forKey: Keys.windSpeedUnit) ?? "") ?? .kmh
        pressureUnit = PressureUnit(rawValue: defaults.string(forKey: Keys.pressureUnit) ?? "") ?? .hPa

        // 加载更新设置（默认30分钟自动刷新）
        autoUpdate = defaults.object(forKey: Keys.autoUpdate) as? Bool ?? true
        updateFrequency = UpdateFrequency(rawValue: defaults.string(forKey: Keys.updateFrequency) ?? "") ?? .minutes30

        // 加载预警设置
        weatherAlert = defaults.object(forKey: Keys.weatherAlert) as? Bool ?? true
        alertTimeRange = AlertTimeRange(rawValue: defaults.string(forKey: Keys.alertTimeRange) ?? "") ?? .daytime
        alertStartHour = defaults.object(forKey: Keys.alertStartHour) as? Int ?? 6
        alertEndHour = defaults.object(forKey: Keys.alertEndHour) as? Int ?? 22

        // 加载通知设置
        dailyNotification = defaults.object(forKey: Keys.dailyNotification) as? Bool ?? false
        dailyNotificationHour = defaults.object(forKey: Keys.dailyNotificationHour) as? Int ?? 7

        // 加载界面设置
        hapticFeedback = defaults.object(forKey: Keys.hapticFeedback) as? Bool ?? true
        animationEnabled = defaults.object(forKey: Keys.animationEnabled) as? Bool ?? true

        print("[AppSettings] 设置已加载") // 日志
    }

    // MARK: - 私有方法

    private func save(_ value: Any, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        print("[AppSettings] 保存设置: \(key) = \(value)") // 日志
    }

    // MARK: - 公开方法

    /// 格式化温度
    func formatTemperature(_ celsius: Double, showUnit: Bool = true) -> String {
        temperatureUnit.format(celsius, showUnit: showUnit)
    }

    /// 格式化风速
    func formatWindSpeed(_ kmh: Double) -> String {
        windSpeedUnit.format(kmh)
    }

    /// 格式化气压
    func formatPressure(_ hPa: Double) -> String {
        pressureUnit.format(hPa)
    }

    /// 检查是否在预警时间范围内
    func isInAlertTimeRange() -> Bool {
        guard weatherAlert else { return false }

        let hour = Calendar.current.component(.hour, from: Date())

        switch alertTimeRange {
        case .always:
            return true
        case .daytime:
            return hour >= 6 && hour < 22
        case .custom:
            if alertStartHour <= alertEndHour {
                return hour >= alertStartHour && hour < alertEndHour
            } else {
                // 跨午夜
                return hour >= alertStartHour || hour < alertEndHour
            }
        }
    }

    /// 重置所有设置
    func resetToDefaults() {
        temperatureUnit = .celsius
        windSpeedUnit = .kmh
        pressureUnit = .hPa
        autoUpdate = true
        updateFrequency = .minutes30  // 默认30分钟自动刷新
        weatherAlert = true
        alertTimeRange = .daytime
        alertStartHour = 6
        alertEndHour = 22
        dailyNotification = false
        dailyNotificationHour = 7
        hapticFeedback = true
        animationEnabled = true

        print("[AppSettings] 设置已重置为默认值") // 日志
    }
}
