//
//  WeatherAnimationView.swift
//  SmartCleaner
//
//  天气动画容器视图
//  根据天气类型自动切换对应动画
//  支持白天/夜间模式
//

import SwiftUI

// MARK: - 天气动画容器
struct WeatherAnimationView: View {
    let weatherType: WeatherType    // 天气类型
    let isDay: Bool                 // 是否白天
    let animationEnabled: Bool      // 是否启用动画

    init(weatherType: WeatherType, isDay: Bool = true, animationEnabled: Bool = true) {
        self.weatherType = weatherType
        self.isDay = isDay
        self.animationEnabled = animationEnabled
    }

    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient

            // 天气动画
            if animationEnabled {
                weatherAnimation
            }

            // 扫描线叠加（静态纹理，不再闪烁）
            if animationEnabled {
                ScanlineOverlay()
                    .opacity(0.05)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 背景渐变
    @ViewBuilder
    private var backgroundGradient: some View {
        if isDay {
            dayBackgroundGradient
        } else {
            nightBackgroundGradient
        }
    }

    private var dayBackgroundGradient: some View {
        LinearGradient(
            colors: weatherType.dayGradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var nightBackgroundGradient: some View {
        LinearGradient(
            colors: weatherType.nightGradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - 天气动画
    @ViewBuilder
    private var weatherAnimation: some View {
        switch weatherType {
        case .sunny:
            if isDay {
                SunnyAnimation()
            } else {
                NightAnimation()
            }
        case .partlyCloudy:
            if isDay {
                CloudyAnimation(cloudDensity: .light)
                    .overlay(SunnyAnimation().opacity(0.6))
            } else {
                CloudyAnimation(cloudDensity: .light)
                    .overlay(NightAnimation().opacity(0.6))
            }
        case .cloudy:
            CloudyAnimation(cloudDensity: .heavy)
        case .rainy:
            ZStack {
                CloudyAnimation(cloudDensity: .heavy)
                RainyAnimation()
            }
        case .snowy:
            ZStack {
                CloudyAnimation(cloudDensity: .medium)
                SnowyAnimation()
            }
        case .thunderstorm:
            ZStack {
                CloudyAnimation(cloudDensity: .heavy)
                RainyAnimation(intensity: .heavy)
                // ThunderAnimation() // 移除闪电动画，避免闪烁
            }
        case .foggy:
            FoggyAnimation()
        }
    }
}

// MARK: - 天气类型渐变色扩展
extension WeatherType {
    /// 白天渐变色
    var dayGradientColors: [Color] {
        switch self {
        case .sunny:
            return [
                Color(hex: "1a1a3e"),
                Color(hex: "0d0d2b"),
                Color(hex: "0a0a1a")
            ]
        case .partlyCloudy:
            return [
                Color(hex: "1e1e4a"),
                Color(hex: "14142e"),
                Color(hex: "0a0a1a")
            ]
        case .cloudy:
            return [
                Color(hex: "2a2a4a"),
                Color(hex: "1a1a30"),
                Color(hex: "0d0d1a")
            ]
        case .rainy:
            return [
                Color(hex: "1a2a4a"),
                Color(hex: "0d1a30"),
                Color(hex: "050d1a")
            ]
        case .snowy:
            return [
                Color(hex: "2a3a5a"),
                Color(hex: "1a2a40"),
                Color(hex: "0d1a2a")
            ]
        case .thunderstorm:
            return [
                Color(hex: "1a1a3e"),
                Color(hex: "2d1a3e"),
                Color(hex: "0a0a1a")
            ]
        case .foggy:
            return [
                Color(hex: "2a2a3a"),
                Color(hex: "1a1a2a"),
                Color(hex: "0d0d1a")
            ]
        }
    }

    /// 夜间渐变色
    var nightGradientColors: [Color] {
        switch self {
        case .sunny:
            return [
                Color(hex: "0d0d2b"),
                Color(hex: "050514"),
                Color(hex: "000005")
            ]
        case .partlyCloudy:
            return [
                Color(hex: "14142e"),
                Color(hex: "0a0a1a"),
                Color(hex: "000005")
            ]
        case .cloudy:
            return [
                Color(hex: "1a1a2a"),
                Color(hex: "0d0d1a"),
                Color(hex: "000005")
            ]
        case .rainy:
            return [
                Color(hex: "0d1a30"),
                Color(hex: "050d1a"),
                Color(hex: "000005")
            ]
        case .snowy:
            return [
                Color(hex: "1a2a40"),
                Color(hex: "0d1a2a"),
                Color(hex: "000010")
            ]
        case .thunderstorm:
            return [
                Color(hex: "1a0d2b"),
                Color(hex: "0d0514"),
                Color(hex: "000005")
            ]
        case .foggy:
            return [
                Color(hex: "1a1a2a"),
                Color(hex: "0d0d14"),
                Color(hex: "000005")
            ]
        }
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 0) {
        WeatherAnimationView(weatherType: .sunny, isDay: true)
            .frame(height: 200)
        WeatherAnimationView(weatherType: .rainy, isDay: true)
            .frame(height: 200)
        WeatherAnimationView(weatherType: .snowy, isDay: false)
            .frame(height: 200)
    }
}
