//
//  ContentView.swift
//  CyberWeather
//
//  主视图容器
//  整合所有天气视图组件，管理整体布局和交互
//

import SwiftUI

// MARK: - 主视图
/// 应用的根视图，整合所有天气相关组件
struct ContentView: View {

    // MARK: - 属性
    @State private var viewModel = WeatherViewModel() // 天气视图模型
    @State private var showErrorAlert: Bool = false // 是否显示错误弹窗
    @State private var showSettings: Bool = false // 是否显示设置页面

    // MARK: - 视图
    var body: some View {
        ZStack {
            // 动态天气背景（根据当前天气和时间自动切换）
            weatherBackground

            // 主内容
            ScrollView(showsIndicators: false) {
                VStack(spacing: CyberTheme.Spacing.lg) {
                    // 头部（刷新按钮 + 设置按钮）
                    WeatherHeaderView(
                        onRefresh: { Task { await viewModel.refreshWeather() } },
                        onSettings: { showSettings = true },
                        isRefreshing: viewModel.isLoading
                    )

                    // 主天气显示
                    MainWeatherView(
                        weatherData: viewModel.weatherData,
                        isLoading: viewModel.isLoading
                    )

                    // 小时预报
                    if let hourly = viewModel.weatherData?.hourlyForecast, !hourly.isEmpty {
                        HourlyForecastView(forecasts: hourly)
                    } else if viewModel.isLoading {
                        HourlyForecastEmptyView()
                    }

                    // 天气预报（7天/15天切换，移除重复的DailyForecastView）
                    if let daily = viewModel.weatherData?.daily, !daily.isEmpty {
                        Extended15DayView(
                            dailyData: daily,
                            settings: AppSettings.shared
                        )
                        .padding(.horizontal, CyberTheme.Spacing.md)
                    } else if viewModel.isLoading {
                        DailyForecastEmptyView()
                    }

                    // 天气详情
                    WeatherDetailView(details: viewModel.weatherData?.details)

                    // 生活指数
                    if let data = viewModel.weatherData {
                        LifeIndexView(indices: data.lifeIndices)
                            .padding(.horizontal, CyberTheme.Spacing.md)
                    } else if viewModel.isLoading {
                        LifeIndexEmptyView()
                    }

                    // 出行建议
                    if let data = viewModel.weatherData {
                        TravelAdviceDisplayView(advices: data.travelAdvices)
                            .padding(.horizontal, CyberTheme.Spacing.md)
                    } else if viewModel.isLoading {
                        TravelAdviceEmptyView()
                    }

                    // 数据图表区域（合并为可折叠区域）
                    if let daily = viewModel.weatherData?.daily, !daily.isEmpty {
                        WeatherChartsSection(
                            dailyData: daily,
                            settings: AppSettings.shared
                        )
                        .padding(.horizontal, CyberTheme.Spacing.md)
                    }

                    // 底部间距
                    Spacer()
                        .frame(height: CyberTheme.Spacing.xl)
                }
            }
            .refreshable {
                await viewModel.refreshWeather() // 下拉刷新
            }

            // 首次加载遮罩
            if viewModel.weatherData == nil && viewModel.isLoading {
                loadingOverlay
            }
        }
        .task {
            await viewModel.loadWeather() // 首次加载天气数据
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil // 显示错误提示
        }
        .alert("加载失败", isPresented: $showErrorAlert) {
            Button("重试") {
                Task { await viewModel.refreshWeather() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: AppSettings.shared)
        }
        .onChange(of: showSettings) { _, isShowing in
            // 设置页面关闭时，更新自动刷新配置
            if !isShowing {
                viewModel.updateAutoRefreshSettings()
            }
        }
    }

    // MARK: - 加载遮罩
    private var loadingOverlay: some View {
        ZStack {
            CyberTheme.darkBackground.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: CyberTheme.Spacing.lg) {
                CyberLoadingView()

                GlowingText(
                    "正在获取天气数据...",
                    font: .subheadline,
                    glowColor: CyberTheme.neonBlue,
                    glowRadius: 10
                )
            }
        }
        .transition(.opacity)
    }

    // MARK: - 动态天气背景
    @ViewBuilder
    private var weatherBackground: some View {
        if let data = viewModel.weatherData {
            // 有天气数据时显示动态天气背景动画
            WeatherAnimationView(
                weatherType: data.weatherType,
                isDay: data.current.isDay,
                animationEnabled: true  // 启用动画
            )
        } else {
            // 无数据时显示动态赛博朋克背景
            CyberBackground(showGrid: true, showScanline: true, showParticles: true, intensity: .normal)
        }
    }
}

// MARK: - 生活指数空状态
struct LifeIndexEmptyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundStyle(CyberTheme.primaryGradient)
                Text("生活指数")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            // 占位网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1a1a3e").opacity(0.5))
                        .frame(height: 90)
                        .shimmering()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "14142e").opacity(0.8))
        )
        .padding(.horizontal, CyberTheme.Spacing.md)
    }
}

// MARK: - 出行建议空状态
struct TravelAdviceEmptyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(CyberTheme.primaryGradient)
                Text("出行建议")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            // 占位列表
            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1a1a3e").opacity(0.5))
                        .frame(height: 70)
                        .shimmering()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "14142e").opacity(0.8))
        )
        .padding(.horizontal, CyberTheme.Spacing.md)
    }
}

// MARK: - 数据图表区域
/// 合并所有图表到一个可折叠区域
struct WeatherChartsSection: View {
    let dailyData: [DailyWeatherData]
    let settings: AppSettings

    @State private var isExpanded: Bool = false         // 是否展开
    @State private var selectedChart: ChartType = .temperature // 当前选中的图表

    enum ChartType: String, CaseIterable {
        case temperature = "温度"
        case precipitation = "降水"
        case wind = "风力"
        case aqi = "空气"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和展开按钮
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("数据图表")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "收起" : "展开")
                            .font(.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: "00D4FF"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(hex: "00D4FF").opacity(0.15))
                    )
                }
            }

            if isExpanded {
                // 图表类型选择器
                HStack(spacing: 8) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedChart = type
                            }
                        } label: {
                            Text(type.rawValue)
                                .font(.caption)
                                .fontWeight(selectedChart == type ? .semibold : .regular)
                                .foregroundColor(selectedChart == type ? .white : Color(hex: "00D4FF"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedChart == type
                                            ? LinearGradient(
                                                colors: [Color(hex: "00D4FF").opacity(0.4), Color(hex: "7B2FFF").opacity(0.4)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            : LinearGradient(
                                                colors: [Color.clear, Color.clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedChart == type
                                                ? Color(hex: "00D4FF").opacity(0.5)
                                                : Color(hex: "00D4FF").opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                }

                // 图表内容
                Group {
                    switch selectedChart {
                    case .temperature:
                        TemperatureChartView(dailyData: dailyData, settings: settings)
                    case .precipitation:
                        PrecipitationChartView(dailyData: dailyData)
                    case .wind:
                        WindChartView(dailyData: dailyData, settings: settings)
                    case .aqi:
                        AQIChartView(dailyData: dailyData)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "14142e").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00D4FF").opacity(0.2),
                                    Color(hex: "7B2FFF").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - 闪烁效果修饰器
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 400 - 200)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - 预览
#Preview("ContentView") {
    ContentView()
}
