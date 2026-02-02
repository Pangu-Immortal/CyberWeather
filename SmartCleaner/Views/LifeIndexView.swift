//
//  LifeIndexView.swift
//  SmartCleaner
//
//  生活指数视图
//  展示穿衣、紫外线、运动等8大指数
//  赛博朋克卡片风格
//

import SwiftUI

// MARK: - 生活指数视图
struct LifeIndexView: View {
    let indices: [LifeIndex]

    @State private var selectedIndex: LifeIndex?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF00FF"), Color(hex: "00D4FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("生活指数")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("今日建议")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            // 指数网格
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(indices) { index in
                    LifeIndexCard(index: index, isSelected: selectedIndex?.id == index.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if selectedIndex?.id == index.id {
                                    selectedIndex = nil
                                } else {
                                    selectedIndex = index
                                }
                            }
                        }
                }
            }

            // 选中详情
            if let selected = selectedIndex {
                LifeIndexDetailCard(index: selected)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
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
                                    Color(hex: "FF00FF").opacity(0.2),
                                    Color(hex: "00D4FF").opacity(0.2)
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

// MARK: - 单个指数卡片
struct LifeIndexCard: View {
    let index: LifeIndex
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                index.type.color.opacity(0.3),
                                index.type.color.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: index.type.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [index.type.color, index.type.color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: index.type.color.opacity(0.5), radius: 5)
            }

            // 名称
            Text(index.type.name)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            // 等级
            Text(index.level)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(index.type.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1a1a3e").opacity(isSelected ? 0.9 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected
                                ? index.type.color.opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? index.type.color.opacity(0.3) : .clear,
                    radius: 8
                )
        )
    }
}

// MARK: - 指数详情卡片
struct LifeIndexDetailCard: View {
    let index: LifeIndex

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Image(systemName: index.type.icon)
                    .foregroundColor(index.type.color)
                Text(index.type.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // 等级标签
                Text(index.level)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(index.type.color.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(index.type.color.opacity(0.5), lineWidth: 1)
                            )
                    )
            }

            // 建议内容
            Text(index.advice)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)

            // 指数条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    // 进度
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [index.type.color, index.type.color.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(index.value) / 100, height: 6)
                        .shadow(color: index.type.color.opacity(0.5), radius: 3)
                }
            }
            .frame(height: 6)

            // 数值
            HStack {
                Text("0")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
                Text("指数: \(index.value)")
                    .font(.caption)
                    .foregroundColor(index.type.color)
                Spacer()
                Text("100")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1a1a3e").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(index.type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 生活指数类型颜色和图标扩展
extension LifeIndexType {
    var color: Color {
        switch self {
        case .dressing: return Color(hex: "FF00FF")      // 穿衣 - 粉色
        case .uv: return Color(hex: "FFD700")            // 紫外线 - 金色
        case .exercise: return Color(hex: "00E400")      // 运动 - 绿色
        case .carWash: return Color(hex: "00D4FF")       // 洗车 - 蓝色
        case .comfort: return Color(hex: "FF6B00")       // 舒适度 - 橙色
        case .airQuality: return Color(hex: "7B2FFF")    // 空气 - 紫色
        case .travel: return Color(hex: "00BFFF")        // 旅游 - 天蓝
        case .allergy: return Color(hex: "FF4500")       // 过敏 - 橙红
        }
    }

    var icon: String {
        switch self {
        case .dressing: return "tshirt"
        case .uv: return "sun.max.fill"
        case .exercise: return "figure.run"
        case .carWash: return "car.fill"
        case .comfort: return "heart.fill"
        case .airQuality: return "wind"
        case .travel: return "airplane"
        case .allergy: return "allergens"
        }
    }
}

// MARK: - 预览
#Preview {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()

        ScrollView {
            LifeIndexView(
                indices: [
                    LifeIndex(type: .dressing, level: "舒适", value: 75, advice: "建议穿薄型T恤、短裤等清凉装扮，出门注意防晒"),
                    LifeIndex(type: .uv, level: "强", value: 85, advice: "紫外线较强，外出建议涂抹SPF30+防晒霜，戴太阳镜"),
                    LifeIndex(type: .exercise, level: "适宜", value: 80, advice: "天气不错，适合进行各类户外运动"),
                    LifeIndex(type: .carWash, level: "适宜", value: 70, advice: "未来两天无雨，适合洗车"),
                    LifeIndex(type: .comfort, level: "舒适", value: 78, advice: "今天体感舒适，适合户外活动"),
                    LifeIndex(type: .airQuality, level: "良", value: 65, advice: "空气质量良好，可正常户外活动"),
                    LifeIndex(type: .travel, level: "适宜", value: 82, advice: "天气适宜出游，记得做好防晒"),
                    LifeIndex(type: .allergy, level: "较低", value: 30, advice: "花粉浓度较低，过敏人群可放心外出")
                ]
            )
            .padding()
        }
    }
}
