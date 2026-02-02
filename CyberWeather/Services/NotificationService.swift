//
//  NotificationService.swift
//  CyberWeather
//
//  天气预警通知服务
//  管理本地通知的授权、调度、发送
//  支持天气预警、定时提醒、更新通知
//

import Foundation
import UserNotifications

// MARK: - 通知类型
enum WeatherNotificationType: String {
    case weatherAlert = "weather_alert"      // 天气预警
    case dailyForecast = "daily_forecast"    // 每日预报
    case rainAlert = "rain_alert"            // 降雨提醒
    case tempChange = "temp_change"          // 温度变化
    case airQuality = "air_quality"          // 空气质量
    case uvIndex = "uv_index"                // 紫外线提醒
}

// MARK: - 通知服务
@MainActor
class NotificationService: NSObject {

    // MARK: - 单例
    static let shared = NotificationService()

    // MARK: - 属性
    private let center = UNUserNotificationCenter.current()
    private(set) var isAuthorized: Bool = false

    // MARK: - 初始化
    private override init() {
        super.init()
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - 授权管理

    /// 请求通知授权
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("【通知】授权请求失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 检查授权状态
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// 获取当前授权状态
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - 发送通知

    /// 发送天气预警通知
    func sendWeatherAlert(
        title: String,
        body: String,
        type: WeatherNotificationType,
        delay: TimeInterval = 0
    ) async {
        guard isAuthorized else {
            print("【通知】未授权，无法发送通知")
            return
        }

        // 检查是否在预警时段内
        let settings = SettingsViewModel.shared
        if !settings.weatherAlertEnabled {
            print("【通知】天气预警已关闭")
            return
        }

        if !settings.isCurrentTimeInAlertPeriod() {
            print("【通知】当前时间不在预警时段内")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.rawValue

        // 添加自定义数据
        content.userInfo = [
            "type": type.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("【通知】已发送: \(title)")
        } catch {
            print("【通知】发送失败: \(error.localizedDescription)")
        }
    }

    /// 发送降雨提醒
    func sendRainAlert(probability: Int, time: String) async {
        let title = "🌧️ 降雨提醒"
        let body = "\(time)有\(probability)%概率降雨，记得带伞！"

        await sendWeatherAlert(
            title: title,
            body: body,
            type: .rainAlert
        )
    }

    /// 发送温度变化提醒
    func sendTemperatureChangeAlert(from: Int, to: Int, period: String) async {
        let diff = to - from
        let direction = diff > 0 ? "升高" : "降低"
        let title = "🌡️ 温度变化提醒"
        let body = "\(period)气温将\(direction)\(abs(diff))°C，请注意添减衣物"

        await sendWeatherAlert(
            title: title,
            body: body,
            type: .tempChange
        )
    }

    /// 发送空气质量提醒
    func sendAirQualityAlert(aqi: Int, level: String) async {
        let title = "💨 空气质量提醒"
        let body = "当前AQI指数\(aqi)，空气质量\(level)"

        await sendWeatherAlert(
            title: title,
            body: body,
            type: .airQuality
        )
    }

    /// 发送紫外线提醒
    func sendUVIndexAlert(uvIndex: Int) async {
        let level: String
        switch uvIndex {
        case 0...2: level = "弱"
        case 3...5: level = "中等"
        case 6...7: level = "强"
        case 8...10: level = "很强"
        default: level = "极强"
        }

        let title = "☀️ 紫外线提醒"
        let body = "今日紫外线指数\(uvIndex)(\(level))，外出请做好防晒"

        await sendWeatherAlert(
            title: title,
            body: body,
            type: .uvIndex
        )
    }

    // MARK: - 定时通知

    /// 设置每日预报通知
    func scheduleDailyForecast(at hour: Int, minute: Int = 0) async {
        guard isAuthorized else { return }

        // 先取消已有的每日预报通知
        center.removePendingNotificationRequests(withIdentifiers: ["daily_forecast"])

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "📅 今日天气"
        content.body = "点击查看今天的天气详情"
        content.sound = .default
        content.categoryIdentifier = WeatherNotificationType.dailyForecast.rawValue

        let request = UNNotificationRequest(
            identifier: "daily_forecast",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("【通知】已设置每日预报: \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("【通知】设置每日预报失败: \(error.localizedDescription)")
        }
    }

    /// 取消每日预报通知
    func cancelDailyForecast() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily_forecast"])
        print("【通知】已取消每日预报")
    }

    // MARK: - 通知管理

    /// 取消所有待发送通知
    func cancelAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
        print("【通知】已取消所有待发送通知")
    }

    /// 清除所有已发送通知
    func clearAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
        print("【通知】已清除所有已发送通知")
    }

    /// 获取待发送通知数量
    func getPendingNotificationsCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }

    /// 获取所有待发送通知
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - 天气变化检测

    /// 分析天气数据并发送必要的通知
    func analyzeAndNotify(currentWeather: WeatherData, forecast: [DailyWeatherData]) async {
        // 检查降雨概率
        if let todayForecast = forecast.first {
            if todayForecast.precipitationProbabilityMax > 50 {
                await sendRainAlert(
                    probability: todayForecast.precipitationProbabilityMax,
                    time: "今天"
                )
            }
        }

        // 检查温度变化
        if forecast.count >= 2 {
            let today = forecast[0]
            let tomorrow = forecast[1]
            let tempDiff = tomorrow.temperatureMax - today.temperatureMax

            if abs(tempDiff) >= 5 {
                await sendTemperatureChangeAlert(
                    from: Int(today.temperatureMax),
                    to: Int(tomorrow.temperatureMax),
                    period: "明天"
                )
            }
        }

        // 检查空气质量（如果有数据）
        // 检查紫外线指数（如果有数据）
    }
}

// MARK: - 通知代理扩展
extension NotificationService: UNUserNotificationCenterDelegate {

    /// 前台收到通知时
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // 前台也显示通知
        return [.banner, .sound, .badge]
    }

    /// 用户点击通知时
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        if let typeString = userInfo["type"] as? String,
           let type = WeatherNotificationType(rawValue: typeString) {
            print("【通知】用户点击了通知: \(type)")

            // 根据类型处理不同的跳转逻辑
            // 这里可以通过 NotificationCenter 发送事件，让主界面响应
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .weatherNotificationTapped,
                    object: nil,
                    userInfo: ["type": type]
                )
            }
        }
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let weatherNotificationTapped = Notification.Name("weatherNotificationTapped")
}
