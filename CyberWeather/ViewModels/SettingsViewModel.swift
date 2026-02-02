//
//  SettingsViewModel.swift
//  CyberWeather
//
//  设置视图模型
//  管理用户设置的持久化、单位转换、通知配置
//  使用 @Observable 实现响应式数据绑定
//

import Foundation
import SwiftUI

// MARK: - 设置视图模型
@Observable
class SettingsViewModel {

    // MARK: - 单例
    static let shared = SettingsViewModel()

    // MARK: - 设置项

    /// 温度单位
    var temperatureUnit: TemperatureUnit {
        didSet { saveSettings() }
    }

    /// 风速单位
    var windSpeedUnit: WindSpeedUnit {
        didSet { saveSettings() }
    }

    /// 气压单位
    var pressureUnit: PressureUnit {
        didSet { saveSettings() }
    }

    /// 自动更新开关
    var autoUpdateEnabled: Bool {
        didSet { saveSettings() }
    }

    /// 更新频率（分钟）
    var updateFrequency: Int {
        didSet { saveSettings() }
    }

    /// 天气预警开关
    var weatherAlertEnabled: Bool {
        didSet { saveSettings() }
    }

    /// 预警开始时间（小时）
    var alertStartHour: Int {
        didSet { saveSettings() }
    }

    /// 预警结束时间（小时）
    var alertEndHour: Int {
        didSet { saveSettings() }
    }

    /// 当前主题
    var currentTheme: AppTheme {
        didSet { saveSettings() }
    }

    /// 是否使用系统定位
    var useSystemLocation: Bool {
        didSet { saveSettings() }
    }

    /// 默认城市
    var defaultCity: String {
        didSet { saveSettings() }
    }

    // MARK: - UserDefaults 键
    private enum Keys {
        static let temperatureUnit = "settings.temperatureUnit"
        static let windSpeedUnit = "settings.windSpeedUnit"
        static let pressureUnit = "settings.pressureUnit"
        static let autoUpdateEnabled = "settings.autoUpdateEnabled"
        static let updateFrequency = "settings.updateFrequency"
        static let weatherAlertEnabled = "settings.weatherAlertEnabled"
        static let alertStartHour = "settings.alertStartHour"
        static let alertEndHour = "settings.alertEndHour"
        static let currentTheme = "settings.currentTheme"
        static let useSystemLocation = "settings.useSystemLocation"
        static let defaultCity = "settings.defaultCity"
    }

    // MARK: - 初始化
    private init() {
        // 从 UserDefaults 加载设置
        let defaults = UserDefaults.standard

        self.temperatureUnit = TemperatureUnit(rawValue: defaults.string(forKey: Keys.temperatureUnit) ?? "") ?? .celsius
        self.windSpeedUnit = WindSpeedUnit(rawValue: defaults.string(forKey: Keys.windSpeedUnit) ?? "") ?? .kmh
        self.pressureUnit = PressureUnit(rawValue: defaults.string(forKey: Keys.pressureUnit) ?? "") ?? .hPa
        self.autoUpdateEnabled = defaults.object(forKey: Keys.autoUpdateEnabled) as? Bool ?? true
        self.updateFrequency = defaults.object(forKey: Keys.updateFrequency) as? Int ?? 30
        self.weatherAlertEnabled = defaults.object(forKey: Keys.weatherAlertEnabled) as? Bool ?? true
        self.alertStartHour = defaults.object(forKey: Keys.alertStartHour) as? Int ?? 7
        self.alertEndHour = defaults.object(forKey: Keys.alertEndHour) as? Int ?? 22
        self.currentTheme = AppTheme(rawValue: defaults.string(forKey: Keys.currentTheme) ?? "") ?? .cyber
        self.useSystemLocation = defaults.object(forKey: Keys.useSystemLocation) as? Bool ?? true
        self.defaultCity = defaults.string(forKey: Keys.defaultCity) ?? "北京市"
    }

    // MARK: - 保存设置
    private func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(temperatureUnit.rawValue, forKey: Keys.temperatureUnit)
        defaults.set(windSpeedUnit.rawValue, forKey: Keys.windSpeedUnit)
        defaults.set(pressureUnit.rawValue, forKey: Keys.pressureUnit)
        defaults.set(autoUpdateEnabled, forKey: Keys.autoUpdateEnabled)
        defaults.set(updateFrequency, forKey: Keys.updateFrequency)
        defaults.set(weatherAlertEnabled, forKey: Keys.weatherAlertEnabled)
        defaults.set(alertStartHour, forKey: Keys.alertStartHour)
        defaults.set(alertEndHour, forKey: Keys.alertEndHour)
        defaults.set(currentTheme.rawValue, forKey: Keys.currentTheme)
        defaults.set(useSystemLocation, forKey: Keys.useSystemLocation)
        defaults.set(defaultCity, forKey: Keys.defaultCity)
    }

    // MARK: - 重置设置
    func resetToDefaults() {
        temperatureUnit = .celsius
        windSpeedUnit = .kmh
        pressureUnit = .hPa
        autoUpdateEnabled = true
        updateFrequency = 30
        weatherAlertEnabled = true
        alertStartHour = 7
        alertEndHour = 22
        currentTheme = .cyber
        useSystemLocation = true
        defaultCity = "北京市"
    }

    // MARK: - 温度转换
    func convertTemperature(_ celsius: Double) -> Double {
        switch temperatureUnit {
        case .celsius:
            return celsius
        case .fahrenheit:
            return celsius * 9.0 / 5.0 + 32.0
        case .kelvin:
            return celsius + 273.15
        }
    }

    /// 格式化温度字符串
    func formatTemperature(_ celsius: Double) -> String {
        let converted = convertTemperature(celsius)
        return "\(Int(round(converted)))\(temperatureUnit.symbol)"
    }

    // MARK: - 风速转换
    func convertWindSpeed(_ kmh: Double) -> Double {
        switch windSpeedUnit {
        case .kmh:
            return kmh
        case .ms:
            return kmh / 3.6
        case .mph:
            return kmh * 0.621371
        case .knots:
            return kmh * 0.539957
        }
    }

    /// 格式化风速字符串
    func formatWindSpeed(_ kmh: Double) -> String {
        let converted = convertWindSpeed(kmh)
        return String(format: "%.1f %@", converted, windSpeedUnit.symbol)
    }

    // MARK: - 气压转换
    func convertPressure(_ hPa: Double) -> Double {
        switch pressureUnit {
        case .hPa:
            return hPa
        case .mmHg:
            return hPa * 0.750062
        case .inHg:
            return hPa * 0.02953
        case .atm:
            return hPa / 1013.25
        }
    }

    /// 格式化气压字符串
    func formatPressure(_ hPa: Double) -> String {
        let converted = convertPressure(hPa)
        switch pressureUnit {
        case .hPa:
            return "\(Int(round(converted))) \(pressureUnit.symbol)"
        case .mmHg:
            return "\(Int(round(converted))) \(pressureUnit.symbol)"
        case .inHg:
            return String(format: "%.2f %@", converted, pressureUnit.symbol)
        case .atm:
            return String(format: "%.3f %@", converted, pressureUnit.symbol)
        }
    }

    // MARK: - 更新频率选项
    var updateFrequencyOptions: [Int] {
        [15, 30, 60, 120, 180]
    }

    func updateFrequencyString(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            return "\(minutes / 60)小时"
        }
    }

    // MARK: - 预警时间验证
    func isValidAlertTime() -> Bool {
        alertStartHour < alertEndHour
    }

    /// 当前时间是否在预警时段内
    func isCurrentTimeInAlertPeriod() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= alertStartHour && hour < alertEndHour
    }

    // MARK: - 计算属性

    /// 预警时段描述
    var alertPeriodDescription: String {
        "\(String(format: "%02d:00", alertStartHour)) - \(String(format: "%02d:00", alertEndHour))"
    }

    /// 下次更新时间
    var nextUpdateTime: Date {
        Date().addingTimeInterval(Double(updateFrequency * 60))
    }
}

// MARK: - 应用主题
enum AppTheme: String, CaseIterable {
    case cyber = "cyber"        // 赛博朋克
    case dark = "dark"          // 深色
    case light = "light"        // 浅色
    case auto = "auto"          // 跟随系统

    var displayName: String {
        switch self {
        case .cyber: return "赛博朋克"
        case .dark: return "深色"
        case .light: return "浅色"
        case .auto: return "跟随系统"
        }
    }

    var icon: String {
        switch self {
        case .cyber: return "sparkles"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .auto: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - 预览辅助
#if DEBUG
extension SettingsViewModel {
    static var preview: SettingsViewModel {
        let vm = SettingsViewModel.shared
        vm.temperatureUnit = .celsius
        vm.windSpeedUnit = .kmh
        vm.pressureUnit = .hPa
        return vm
    }
}
#endif
