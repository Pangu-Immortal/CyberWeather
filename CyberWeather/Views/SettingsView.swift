//
//  SettingsView.swift
//  CyberWeather
//
//  设置页面
//  包含单位转换、更新频率、通知设置等
//  赛博朋克玻璃拟态风格
//

import SwiftUI

// MARK: - 设置视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings

    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [
                        Color(hex: "0a0a1a"),
                        Color(hex: "14142e"),
                        Color(hex: "0a0a1a")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 单位设置
                        unitSettingsSection

                        // 更新设置
                        updateSettingsSection

                        // 通知设置
                        notificationSettingsSection

                        // 界面设置
                        interfaceSettingsSection

                        // 关于
                        aboutSection

                        // 重置按钮
                        resetButton
                    }
                    .padding()
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "14142e"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "00D4FF"))
                }
            }
            .alert("重置设置", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) {}
                Button("重置", role: .destructive) {
                    settings.resetToDefaults()
                }
            } message: {
                Text("确定要将所有设置恢复为默认值吗？")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 单位设置
    private var unitSettingsSection: some View {
        SettingsSection(title: "单位设置", icon: "ruler") {
            VStack(spacing: 0) {
                // 温度单位
                SettingsPicker(
                    title: "温度单位",
                    selection: $settings.temperatureUnit,
                    options: TemperatureUnit.allCases,
                    displayName: { $0.name }
                )

                Divider()
                    .background(Color.white.opacity(0.1))

                // 风速单位
                SettingsPicker(
                    title: "风速单位",
                    selection: $settings.windSpeedUnit,
                    options: WindSpeedUnit.allCases,
                    displayName: { $0.name }
                )

                Divider()
                    .background(Color.white.opacity(0.1))

                // 气压单位
                SettingsPicker(
                    title: "气压单位",
                    selection: $settings.pressureUnit,
                    options: PressureUnit.allCases,
                    displayName: { $0.name }
                )
            }
        }
    }

    // MARK: - 更新设置
    private var updateSettingsSection: some View {
        SettingsSection(title: "数据更新", icon: "arrow.clockwise") {
            VStack(spacing: 0) {
                // 自动更新开关
                SettingsToggle(
                    title: "自动更新",
                    subtitle: "自动获取最新天气数据",
                    isOn: $settings.autoUpdate
                )

                if settings.autoUpdate {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    // 更新频率
                    SettingsPicker(
                        title: "更新频率",
                        selection: $settings.updateFrequency,
                        options: UpdateFrequency.allCases,
                        displayName: { $0.name }
                    )
                }
            }
        }
    }

    // MARK: - 通知设置
    private var notificationSettingsSection: some View {
        SettingsSection(title: "通知提醒", icon: "bell.badge") {
            VStack(spacing: 0) {
                // 天气预警
                SettingsToggle(
                    title: "天气预警",
                    subtitle: "接收恶劣天气预警通知",
                    isOn: $settings.weatherAlert
                )

                if settings.weatherAlert {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    // 预警时间范围
                    SettingsPicker(
                        title: "预警时段",
                        selection: $settings.alertTimeRange,
                        options: AlertTimeRange.allCases,
                        displayName: { $0.name }
                    )

                    if settings.alertTimeRange == .custom {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        // 自定义时间
                        HStack {
                            Text("开始时间")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $settings.alertStartHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(hex: "00D4FF"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        HStack {
                            Text("结束时间")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $settings.alertEndHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(hex: "00D4FF"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // 每日天气推送
                SettingsToggle(
                    title: "每日天气",
                    subtitle: "每天定时推送今日天气",
                    isOn: $settings.dailyNotification
                )

                if settings.dailyNotification {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    HStack {
                        Text("推送时间")
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $settings.dailyNotificationHour) {
                            ForEach(5..<12, id: \.self) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color(hex: "00D4FF"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - 界面设置
    private var interfaceSettingsSection: some View {
        SettingsSection(title: "界面设置", icon: "paintbrush") {
            VStack(spacing: 0) {
                // 触感反馈
                SettingsToggle(
                    title: "触感反馈",
                    subtitle: "操作时提供震动反馈",
                    isOn: $settings.hapticFeedback
                )

                Divider()
                    .background(Color.white.opacity(0.1))

                // 动画效果
                SettingsToggle(
                    title: "动画效果",
                    subtitle: "天气背景动画和过渡效果",
                    isOn: $settings.animationEnabled
                )
            }
        }
    }

    // MARK: - 关于
    private var aboutSection: some View {
        SettingsSection(title: "关于", icon: "info.circle") {
            VStack(spacing: 0) {
                // 版本
                HStack {
                    Text("版本")
                        .foregroundColor(.white)
                    Spacer()
                    Text("2.0.0")
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .background(Color.white.opacity(0.1))

                // 数据来源
                HStack {
                    Text("数据来源")
                        .foregroundColor(.white)
                    Spacer()
                    Text("Open-Meteo API")
                        .foregroundColor(Color(hex: "00D4FF"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - 重置按钮
    private var resetButton: some View {
        Button {
            showResetAlert = true
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("重置所有设置")
            }
            .foregroundColor(Color(hex: "FF6B00"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "FF6B00").opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "FF6B00").opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 10)
    }
}

// MARK: - 设置区块
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.leading, 4)

            // 内容卡片
            content
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "1a1a3e").opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
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
}

// MARK: - 设置开关
struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .toggleStyle(CyberToggleStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - 设置选择器
struct SettingsPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(hex: "00D4FF"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - 赛博风格开关
struct CyberToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                Capsule()
                    .fill(
                        configuration.isOn
                            ? LinearGradient(
                                colors: [Color(hex: "00D4FF"), Color(hex: "7B2FFF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: 50, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(
                                configuration.isOn
                                    ? Color(hex: "00D4FF").opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: configuration.isOn ? Color(hex: "00D4FF").opacity(0.3) : .clear,
                        radius: 5
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: configuration.isOn ? 11 : -11)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - 预览
#Preview {
    SettingsView(settings: AppSettings.shared)
}
