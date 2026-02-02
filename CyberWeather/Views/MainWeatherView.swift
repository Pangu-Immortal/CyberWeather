//
//  MainWeatherView.swift
//  CyberWeather
//
//  主天气视图
//  展示当前天气、温度和核心信息的主界面
//

import SwiftUI

// MARK: - 主天气视图
/// 天气应用的主要展示区域
struct MainWeatherView: View {

    // MARK: - 属性
    let weatherData: WeatherData? // 天气数据
    let isLoading: Bool // 是否加载中

    @State private var isVisible: Bool = false // 视图可见性（用于入场动画）

    // MARK: - 视图
    var body: some View {
        VStack(spacing: CyberTheme.Spacing.lg) {
            // 位置信息
            locationSection
                .slideInFromBottom(delay: 0, isVisible: isVisible)

            // 天气图标
            weatherIconSection
                .slideInFromBottom(delay: 0.1, isVisible: isVisible)

            // 温度显示
            temperatureSection
                .slideInFromBottom(delay: 0.2, isVisible: isVisible)

            // 天气描述
            descriptionSection
                .slideInFromBottom(delay: 0.3, isVisible: isVisible)
        }
        .padding(.top, CyberTheme.Spacing.xl)
        .onAppear {
            withAnimation(.easeOut(duration: 0.1)) {
                isVisible = true
            }
        }
    }

    // MARK: - 位置区域
    private var locationSection: some View {
        HStack(spacing: CyberTheme.Spacing.sm) {
            LocationIcon(animated: !isLoading)

            VStack(alignment: .leading, spacing: 2) {
                Text(weatherData?.location.name ?? "定位中...")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(CyberTheme.textPrimary)

                if let data = weatherData {
                    Text(formatLastUpdated(data.lastUpdated))
                        .font(.caption)
                        .foregroundStyle(CyberTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - 天气图标区域
    private var weatherIconSection: some View {
        Group {
            if isLoading {
                CyberLoadingView()
                    .frame(height: 100)
            } else if let data = weatherData {
                LargeWeatherIcon(
                    iconName: WeatherCodeHelper.icon(for: data.current.weatherCode, isDay: data.current.isDay),
                    weatherCode: data.current.weatherCode,
                    size: 100,
                    animated: true
                )
            } else {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(CyberTheme.textTertiary)
            }
        }
        .frame(height: 120)
    }

    // MARK: - 温度区域
    private var temperatureSection: some View {
        Group {
            if let data = weatherData {
                LargeTemperatureText(
                    String(format: "%.0f", data.current.temperature),
                    animated: true
                )
            } else {
                LargeTemperatureText("--", animated: false)
            }
        }
    }

    // MARK: - 描述区域
    private var descriptionSection: some View {
        HStack(spacing: CyberTheme.Spacing.md) {
            if let data = weatherData {
                // 天气描述
                GlowingText(
                    data.current.weatherDescription,
                    font: .title3,
                    glowColor: CyberTheme.weatherColor(for: data.current.weatherCode),
                    glowRadius: 10
                )

                // 分隔线
                Rectangle()
                    .fill(CyberTheme.textTertiary)
                    .frame(width: 1, height: 20)

                // 体感温度
                HStack(spacing: 4) {
                    Text("体感")
                        .font(.subheadline)
                        .foregroundStyle(CyberTheme.textSecondary)

                    Text(String(format: "%.0f°", data.current.apparentTemperature))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(CyberTheme.textPrimary)
                }
            } else {
                Text("加载中...")
                    .font(.title3)
                    .foregroundStyle(CyberTheme.textSecondary)
            }
        }
    }

    // MARK: - 辅助方法
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm 更新"
        return formatter.string(from: date)
    }
}

// MARK: - 天气头部视图
/// 包含刷新按钮和设置按钮的头部
struct WeatherHeaderView: View {

    let onRefresh: () -> Void
    let onSettings: () -> Void
    let isRefreshing: Bool

    var body: some View {
        HStack {
            // 应用标题
            HStack(spacing: CyberTheme.Spacing.xs) {
                Image(systemName: "cloud.sun.fill")
                    .font(.title3)
                    .foregroundStyle(CyberTheme.primaryGradient)

                Text("CyberWeather")
                    .font(.headline)
                    .foregroundStyle(CyberTheme.textPrimary)
            }

            Spacer()

            // 刷新按钮
            Button(action: onRefresh) {
                RefreshIcon(isRefreshing: isRefreshing)
            }
            .disabled(isRefreshing)

            // 设置按钮
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(CyberTheme.textSecondary)
                    .padding(8)
            }
        }
        .padding(.horizontal, CyberTheme.Spacing.md)
        .padding(.top, CyberTheme.Spacing.sm)
    }
}

// MARK: - 预览
#Preview("MainWeatherView") {
    ZStack {
        CyberBackground()
        MainWeatherView(
            weatherData: WeatherData(
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
            ),
            isLoading: false
        )
    }
}

#Preview("MainWeatherView Loading") {
    ZStack {
        CyberBackground()
        MainWeatherView(weatherData: nil, isLoading: true)
    }
}
