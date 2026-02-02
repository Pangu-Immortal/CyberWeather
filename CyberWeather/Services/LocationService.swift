//
//  LocationService.swift
//  CyberWeather
//
//  定位服务
//  使用 CoreLocation 获取用户当前位置
//  并通过反地理编码获取城市名称
//

import Foundation
import CoreLocation
import Combine

// MARK: - 定位服务类
/// 负责获取用户位置和城市名称
@MainActor
class LocationService: NSObject, ObservableObject {

    // MARK: - 单例
    static let shared = LocationService()

    // MARK: - 发布属性
    @Published var currentLocation: CLLocation? // 当前位置
    @Published var cityName: String = "定位中..." // 城市名称
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined // 授权状态
    @Published var isLoading: Bool = false // 是否正在加载
    @Published var errorMessage: String? // 错误信息

    // MARK: - 私有属性
    private let locationManager = CLLocationManager() // 定位管理器
    private let geocoder = CLGeocoder() // 地理编码器
    private var locationContinuation: CheckedContinuation<CLLocation, Error>? // 异步延续

    // MARK: - 默认位置（北京）
    static let defaultLocation = CLLocation(latitude: 39.9042, longitude: 116.4074)
    static let defaultCityName = "北京市"

    // MARK: - 初始化
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // 精度设为公里级，省电
        authorizationStatus = locationManager.authorizationStatus
        print("[LocationService] 初始化完成，授权状态: \(authorizationStatus.rawValue)") // 日志
    }

    // MARK: - 公开方法

    /// 请求定位权限
    func requestPermission() {
        print("[LocationService] 请求定位权限") // 日志
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始定位
    func startLocationUpdate() {
        print("[LocationService] 开始定位") // 日志
        isLoading = true
        errorMessage = nil

        switch authorizationStatus {
        case .notDetermined:
            requestPermission() // 尚未决定，请求权限
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation() // 已授权，请求位置
        case .denied, .restricted:
            handleLocationDenied() // 被拒绝或受限
        @unknown default:
            handleLocationDenied()
        }
    }

    /// 异步获取位置
    func getLocation() async throws -> CLLocation {
        print("[LocationService] 异步获取位置") // 日志

        // 如果已有位置，直接返回
        if let location = currentLocation {
            return location
        }

        // 检查权限
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("[LocationService] 无定位权限，返回默认位置") // 日志
            return Self.defaultLocation
        }

        // 使用 continuation 等待位置更新
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }

    /// 获取城市名称
    func getCityName(for location: CLLocation) async -> String {
        print("[LocationService] 获取城市名称，坐标: \(location.coordinate)") // 日志

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                // 优先使用 locality（城市），其次 administrativeArea（省/直辖市）
                let name = placemark.locality ?? placemark.administrativeArea ?? Self.defaultCityName
                print("[LocationService] 城市名称: \(name)") // 日志
                return name
            }
        } catch {
            print("[LocationService] 反地理编码失败: \(error)") // 日志
        }

        return Self.defaultCityName
    }

    // MARK: - 私有方法

    /// 处理定位被拒绝的情况
    private func handleLocationDenied() {
        print("[LocationService] 定位被拒绝，使用默认位置") // 日志
        isLoading = false
        errorMessage = "定位权限被拒绝，显示默认城市"
        currentLocation = Self.defaultLocation
        cityName = Self.defaultCityName
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {

    /// 授权状态变化回调
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            print("[LocationService] 授权状态变化: \(manager.authorizationStatus.rawValue)") // 日志

            // 如果刚获得授权，开始定位
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    /// 位置更新回调
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            print("[LocationService] 位置更新: \(location.coordinate)") // 日志
            self.currentLocation = location
            self.isLoading = false

            // 获取城市名称
            self.cityName = await self.getCityName(for: location)

            // 完成异步等待
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    /// 定位失败回调
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("[LocationService] 定位失败: \(error)") // 日志
            self.isLoading = false

            // 检查是否是权限错误
            if let clError = error as? CLError, clError.code == .denied {
                self.handleLocationDenied()
            } else {
                self.errorMessage = "定位失败: \(error.localizedDescription)"
                // 使用默认位置
                self.currentLocation = Self.defaultLocation
                self.cityName = Self.defaultCityName
            }

            // 完成异步等待（使用默认位置）
            self.locationContinuation?.resume(returning: Self.defaultLocation)
            self.locationContinuation = nil
        }
    }
}

// MARK: - 授权状态扩展
extension CLAuthorizationStatus {
    /// 是否已授权
    var isAuthorized: Bool {
        self == .authorizedWhenInUse || self == .authorizedAlways
    }

    /// 状态描述
    var description: String {
        switch self {
        case .notDetermined: return "未确定"
        case .restricted: return "受限"
        case .denied: return "已拒绝"
        case .authorizedAlways: return "始终允许"
        case .authorizedWhenInUse: return "使用时允许"
        @unknown default: return "未知"
        }
    }
}
