//
//  TravelAdviceDisplayView.swift
//  SmartCleaner
//
//  出行建议视图
//  基于天气数据生成每日出行建议
//  赛博朋克风格卡片
//

import SwiftUI

// MARK: - 出行建议视图
struct TravelAdviceDisplayView: View {
    let advices: [TravelAdviceDisplay]

    @State private var expandedIndex: Int? = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00D4FF"), Color(hex: "00E400")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("出行建议")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 今日评分
                if let todayAdvice = advices.first {
                    HStack(spacing: 4) {
                        Image(systemName: todayAdvice.rating.icon)
                            .foregroundColor(todayAdvice.rating.color)
                        Text("\(todayAdvice.score)分")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(todayAdvice.rating.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(todayAdvice.rating.color.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(todayAdvice.rating.color.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
            }

            // 建议列表
            VStack(spacing: 10) {
                ForEach(Array(advices.enumerated()), id: \.element.id) { index, advice in
                    TravelAdviceDisplayCard(
                        advice: advice,
                        isExpanded: expandedIndex == index,
                        isToday: index == 0
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if expandedIndex == index {
                                expandedIndex = nil
                            } else {
                                expandedIndex = index
                            }
                        }
                    }
                }
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
                                    Color(hex: "00E400").opacity(0.2)
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

// MARK: - 单条出行建议卡片
struct TravelAdviceDisplayCard: View {
    let advice: TravelAdviceDisplay
    let isExpanded: Bool
    let isToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 主要信息行
            HStack {
                // 日期
                VStack(alignment: .leading, spacing: 2) {
                    Text(advice.dayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isToday ? Color(hex: "00D4FF") : .white)

                    Text(advice.dateString)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // 评分
                HStack(spacing: 6) {
                    // 评分进度环
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 36, height: 36)

                        Circle()
                            .trim(from: 0, to: CGFloat(advice.score) / 100)
                            .stroke(
                                advice.rating.color,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: advice.rating.color.opacity(0.5), radius: 3)

                        Text("\(advice.score)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(advice.rating.color)
                    }

                    // 评级
                    VStack(alignment: .leading, spacing: 1) {
                        Text(advice.rating.text)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(advice.rating.color)

                        Image(systemName: advice.rating.icon)
                            .font(.system(size: 10))
                            .foregroundColor(advice.rating.color.opacity(0.7))
                    }
                }

                // 展开箭头
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }

            // 展开内容
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    // 建议内容
                    Text(advice.summary)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)

                    // 注意事项
                    if !advice.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("注意事项")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "00D4FF"))

                            ForEach(advice.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: "00D4FF"))
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 6)

                                    Text(tip)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }

                    // 天气概要
                    HStack(spacing: 16) {
                        weatherInfoItem(icon: "thermometer", value: advice.temperatureRange)
                        weatherInfoItem(icon: "drop.fill", value: "\(advice.precipitation)%")
                        weatherInfoItem(icon: "wind", value: advice.windInfo)
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1a1a3e").opacity(isExpanded ? 0.8 : 0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isExpanded
                                ? advice.rating.color.opacity(0.3)
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - 天气信息项
    private func weatherInfoItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - 出行评级扩展
extension TravelRating {
    var color: Color {
        switch self {
        case .excellent: return Color(hex: "00E400")
        case .good: return Color(hex: "00D4FF")
        case .moderate: return Color(hex: "FFD700")
        case .poor: return Color(hex: "FF6B00")
        case .bad: return Color(hex: "FF0000")
        }
    }

    var text: String {
        switch self {
        case .excellent: return "极佳"
        case .good: return "适宜"
        case .moderate: return "一般"
        case .poor: return "较差"
        case .bad: return "不宜"
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .moderate: return "hand.raised.fill"
        case .poor: return "exclamationmark.triangle.fill"
        case .bad: return "xmark.circle.fill"
        }
    }
}

// MARK: - 预览
#Preview {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        ScrollView {
            TravelAdviceDisplayView(
                advices: [
                    TravelAdviceDisplay(
                        date: Date(),
                        dayName: "今天",
                        dateString: "1月29日",
                        score: 85,
                        rating: .good,
                        summary: "今日天气晴好，气温适中，非常适合外出活动。空气质量良好，可以进行户外运动。",
                        tips: ["建议携带太阳镜和防晒霜", "午后紫外线较强，避免长时间暴晒"],
                        temperatureRange: "18-25°C",
                        precipitation: 10,
                        windInfo: "东南风 2级"
                    ),
                    TravelAdviceDisplay(
                        date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                        dayName: "明天",
                        dateString: "1月30日",
                        score: 72,
                        rating: .moderate,
                        summary: "明天多云转阴，下午有小雨可能，外出建议携带雨具。",
                        tips: ["建议携带雨伞", "穿着舒适的防水鞋"],
                        temperatureRange: "15-22°C",
                        precipitation: 60,
                        windInfo: "东风 3级"
                    ),
                    TravelAdviceDisplay(
                        date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                        dayName: "后天",
                        dateString: "1月31日",
                        score: 45,
                        rating: .poor,
                        summary: "后天有中雨，不建议进行长时间户外活动。",
                        tips: ["尽量减少外出", "如需外出请做好防雨准备"],
                        temperatureRange: "12-18°C",
                        precipitation: 85,
                        windInfo: "东北风 4级"
                    )
                ]
            )
            .padding()
        }
    }
}
