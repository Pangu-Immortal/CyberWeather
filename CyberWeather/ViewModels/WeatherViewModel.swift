//
//  WeatherViewModel.swift
//  CyberWeather
//
//  天气业务逻辑视图模型
//  负责协调定位服务和天气服务，管理 UI 状态
//  支持自动刷新功能（默认30分钟）
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

// MARK: - 加载状态枚举
enum LoadingState: Equatable {
    case idle                   // 空闲
    case loading                // 加载中
    case loaded                 // 加载完成
    case error(String)          // 错误
}

// MARK: - 天气视图模型
/// 管理天气数据获取、刷新和状态
@MainActor
@Observable
class WeatherViewModel {

    // MARK: - 可观察属性
    var weatherData: WeatherData? // 天气数据
    var loadingState: LoadingState = .idle // 加载状态
    var showLocationPermissionAlert: Bool = false // 是否显示定位权限提示

    // MARK: - 私有属性
    private let locationService = LocationService.shared // 定位服务
    private let weatherService = WeatherService.shared // 天气服务
    private let settings = AppSettings.shared // 应用设置
    private var refreshTimer: Timer? // 自动刷新定时器
    private var settingsObserver: AnyCancellable? // 设置变更观察者
    private var lastRefreshDate: Date? // 上次刷新时间

    // MARK: - 计算属性

    /// 是否正在加载
    var isLoading: Bool {
        if case .loading = loadingState { return true }
        return false
    }

    /// 错误信息
    var errorMessage: String? {
        if case .error(let message) = loadingState { return message }
        return nil
    }

    /// 当前城市名称
    var cityName: String {
        weatherData?.location.name ?? locationService.cityName
    }

    /// 当前温度（格式化）
    var currentTemperature: String {
        guard let temp = weatherData?.current.temperature else { return "--" }
        return String(format: "%.0f", temp)
    }

    /// 体感温度
    var feelsLikeTemperature: String {
        guard let temp = weatherData?.current.apparentTemperature else { return "--" }
        return String(format: "%.0f", temp)
    }

    /// 天气描述
    var weatherDescription: String {
        weatherData?.current.weatherDescription ?? "加载中"
    }

    /// 天气图标名称
    var weatherIconName: String {
        guard let code = weatherData?.current.weatherCode else { return "cloud.fill" }
        return WeatherCodeHelper.icon(for: code, isDay: isDay)
    }

    /// 是否白天
    var isDay: Bool {
        weatherData?.current.isDay ?? true
    }

    /// 最后更新时间
    var lastUpdatedText: String {
        guard let date = weatherData?.lastUpdated else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm 更新"
        return formatter.string(from: date)
    }

    // MARK: - 初始化
    init() {
        print("[WeatherViewModel] 初始化") // 日志
        setupAutoRefresh() // 设置自动刷新
    }

    // MARK: - 公开方法

    /// 加载天气数据
    func loadWeather() async {
        print("[WeatherViewModel] 开始加载天气数据") // 日志
        loadingState = .loading

        do {
            // 获取位置
            let location = await getLocation()
            let cityName = await locationService.getCityName(for: location)

            print("[WeatherViewModel] 位置获取成功: \(cityName), \(location.coordinate)") // 日志

            // 获取天气
            let weather = try await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: cityName
            )

            self.weatherData = weather
            self.loadingState = .loaded

            print("[WeatherViewModel] 天气数据加载成功") // 日志

        } catch {
            print("[WeatherViewModel] 加载失败: \(error)") // 日志
            loadingState = .error(error.localizedDescription)

            // 加载失败时尝试使用默认位置
            await loadDefaultWeather()
        }
    }

    /// 刷新天气数据
    func refreshWeather() async {
        print("[WeatherViewModel] 刷新天气数据") // 日志
        await loadWeather()
    }

    /// 请求定位权限
    func requestLocationPermission() {
        print("[WeatherViewModel] 请求定位权限") // 日志
        locationService.requestPermission()
    }

    // MARK: - 私有方法

    /// 获取位置（带错误处理）
    private func getLocation() async -> CLLocation {
        // 检查定位权限
        if !locationService.authorizationStatus.isAuthorized &&
           locationService.authorizationStatus != .notDetermined {
            print("[WeatherViewModel] 无定位权限，使用默认位置") // 日志
            return LocationService.defaultLocation
        }

        do {
            return try await locationService.getLocation()
        } catch {
            print("[WeatherViewModel] 定位失败: \(error)") // 日志
            return LocationService.defaultLocation
        }
    }

    /// 使用默认位置加载天气
    private func loadDefaultWeather() async {
        print("[WeatherViewModel] 使用默认位置加载天气") // 日志

        do {
            let weather = try await weatherService.fetchWeather(
                latitude: LocationService.defaultLocation.coordinate.latitude,
                longitude: LocationService.defaultLocation.coordinate.longitude,
                locationName: LocationService.defaultCityName
            )

            self.weatherData = weather
            self.loadingState = .loaded

            print("[WeatherViewModel] 默认位置天气加载成功") // 日志

        } catch {
            print("[WeatherViewModel] 默认位置天气加载也失败: \(error)") // 日志
            // 保持之前的错误状态
        }
    }

    // MARK: - 自动刷新

    /// 设置自动刷新定时器
    private func setupAutoRefresh() {
        print("[WeatherViewModel] 设置自动刷新") // 日志
        startAutoRefreshTimer() // 启动定时器
    }

    /// 启动自动刷新定时器
    private func startAutoRefreshTimer() {
        stopAutoRefresh() // 先停止已有定时器

        // 检查是否启用自动更新
        guard settings.autoUpdate else {
            print("[WeatherViewModel] 自动更新已关闭") // 日志
            return
        }

        // 获取刷新间隔
        guard let interval = settings.updateFrequency.seconds else {
            print("[WeatherViewModel] 更新频率设置为手动，不启动定时器") // 日志
            return
        }

        print("[WeatherViewModel] 启动自动刷新定时器，间隔: \(interval)秒") // 日志

        // 创建定时器（在主线程运行）
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.autoRefreshWeather()
            }
        }

        // 将定时器添加到 common 模式，确保滚动时也能触发
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        lastRefreshDate = Date()
    }

    /// 停止自动刷新定时器
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("[WeatherViewModel] 自动刷新定时器已停止") // 日志
    }

    /// 自动刷新天气（由定时器触发）
    private func autoRefreshWeather() async {
        // 记录刷新时间
        let now = Date()
        if let last = lastRefreshDate {
            let elapsed = now.timeIntervalSince(last)
            print("[WeatherViewModel] 自动刷新触发，距上次刷新: \(Int(elapsed))秒") // 日志
        }
        lastRefreshDate = now

        // 执行刷新
        await refreshWeather()
    }

    /// 更新自动刷新设置（当设置变更时调用）
    func updateAutoRefreshSettings() {
        print("[WeatherViewModel] 更新自动刷新设置") // 日志
        startAutoRefreshTimer() // 重新配置定时器
    }
}

// MARK: - Preview 扩展
extension WeatherViewModel {
    /// 用于预览的模拟 ViewModel
    static var preview: WeatherViewModel {
        let vm = WeatherViewModel()
        vm.weatherData = WeatherData(
            location: LocationInfo(
                name: "北京市",
                latitude: 39.9,
                longitude: 116.4,
                timezone: "Asia/Shanghai"
            ),
            current: CurrentWeatherData(
                temperature: 25,
                apparentTemperature: 27,
                humidity: 65,
                weatherCode: 0,
                windSpeed: 12,
                windDirection: 135,
                pressure: 1013,
                uvIndex: 6,
                visibility: 10,
                isDay: true
            ),
            hourly: [],
            daily: [],
            lastUpdated: Date()
        )
        vm.loadingState = .loaded
        return vm
    }
}
