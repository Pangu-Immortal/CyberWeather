//
//  Date+Formatter.swift
//  SmartCleaner
//
//  日期格式化扩展
//  提供天气应用常用的日期时间格式化方法
//  支持中英文、相对时间、自定义格式
//

import Foundation

// MARK: - 日期格式化扩展
extension Date {

    // MARK: - 预定义格式器

    /// 时间格式器（HH:mm）
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// 12小时制时间格式器
    private static let time12Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.amSymbol = "上午"
        formatter.pmSymbol = "下午"
        return formatter
    }()

    /// 星期格式器
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// 短星期格式器
    private static let shortWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// 日期格式器（MM月dd日）
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// 完整日期格式器
    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// ISO日期格式器
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// 月日格式器
    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()

    // MARK: - 时间格式化

    /// 24小时制时间（如：14:30）
    var timeString: String {
        Self.timeFormatter.string(from: self)
    }

    /// 12小时制时间（如：下午 2:30）
    var time12String: String {
        Self.time12Formatter.string(from: self)
    }

    /// 小时数字（0-23）
    var hourString: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        return "\(hour)时"
    }

    /// 小时数字带前缀0（00-23）
    var hourPaddedString: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        return String(format: "%02d:00", hour)
    }

    // MARK: - 星期格式化

    /// 完整星期（如：星期一）
    var weekdayString: String {
        Self.weekdayFormatter.string(from: self)
    }

    /// 短星期（如：周一）
    var shortWeekdayString: String {
        let weekday = Self.shortWeekdayFormatter.string(from: self)
        return weekday.replacingOccurrences(of: "周", with: "周")
    }

    /// 极短星期（如：一）
    var veryShortWeekdayString: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        let symbols = ["日", "一", "二", "三", "四", "五", "六"]
        return symbols[weekday - 1]
    }

    /// 今天/明天/后天/星期X 的智能显示
    var smartWeekdayString: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "今天"
        } else if calendar.isDateInTomorrow(self) {
            return "明天"
        } else if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: Date()),
                  calendar.isDate(self, inSameDayAs: dayAfterTomorrow) {
            return "后天"
        } else {
            return shortWeekdayString
        }
    }

    // MARK: - 日期格式化

    /// 月日格式（如：12月25日）
    var dateString: String {
        Self.dateFormatter.string(from: self)
    }

    /// 完整日期（如：2024年12月25日）
    var fullDateString: String {
        Self.fullDateFormatter.string(from: self)
    }

    /// ISO格式日期（如：2024-12-25）
    var isoDateString: String {
        Self.isoDateFormatter.string(from: self)
    }

    /// 短日期（如：12/25）
    var monthDayString: String {
        Self.monthDayFormatter.string(from: self)
    }

    /// 日期数字（1-31）
    var dayString: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        return "\(day)"
    }

    /// 月份数字（1-12）
    var monthString: String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        return "\(month)月"
    }

    // MARK: - 相对时间

    /// 相对时间描述（如：刚刚、5分钟前、1小时前）
    var relativeTimeString: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)天前"
        } else {
            return dateString
        }
    }

    /// 更新时间描述（用于显示数据更新时间）
    var updateTimeString: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "今天 \(timeString) 更新"
        } else if calendar.isDateInYesterday(self) {
            return "昨天 \(timeString) 更新"
        } else {
            return "\(dateString) \(timeString) 更新"
        }
    }

    // MARK: - 日出日落时间

    /// 日出日落时间格式（如：06:30）
    var sunTimeString: String {
        timeString
    }

    // MARK: - 预报时间

    /// 小时预报时间（智能显示"现在"或时间）
    func hourlyForecastString(currentDate: Date = Date()) -> String {
        let calendar = Calendar.current

        if calendar.isDate(self, equalTo: currentDate, toGranularity: .hour) {
            return "现在"
        } else {
            return hourPaddedString
        }
    }

    /// 每日预报日期（智能显示今天/明天/周X + 日期）
    var dailyForecastString: String {
        "\(smartWeekdayString) \(monthDayString)"
    }

    // MARK: - 时段判断

    /// 是否是白天（6:00 - 18:00）
    var isDaytime: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        return hour >= 6 && hour < 18
    }

    /// 是否是夜间（18:00 - 6:00）
    var isNighttime: Bool {
        !isDaytime
    }

    /// 获取时段描述（凌晨/早晨/上午/中午/下午/傍晚/晚上/深夜）
    var periodOfDay: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)

        switch hour {
        case 0..<3:
            return "深夜"
        case 3..<6:
            return "凌晨"
        case 6..<9:
            return "早晨"
        case 9..<12:
            return "上午"
        case 12..<14:
            return "中午"
        case 14..<17:
            return "下午"
        case 17..<19:
            return "傍晚"
        case 19..<22:
            return "晚上"
        default:
            return "深夜"
        }
    }

    // MARK: - 工具方法

    /// 从ISO字符串创建日期
    static func from(isoString: String) -> Date? {
        isoDateFormatter.date(from: isoString)
    }

    /// 获取今天的开始时间
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// 获取明天的日期
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
    }

    /// 获取指定天数后的日期
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    /// 获取指定小时后的日期
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }

    /// 判断是否是同一天
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// 判断是否是同一小时
    func isSameHour(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .hour)
    }
}

// MARK: - 时间范围格式化
extension ClosedRange where Bound == Date {
    /// 时间范围字符串（如：14:00 - 18:00）
    var timeRangeString: String {
        "\(lowerBound.timeString) - \(upperBound.timeString)"
    }

    /// 日期范围字符串（如：12月25日 - 12月31日）
    var dateRangeString: String {
        "\(lowerBound.dateString) - \(upperBound.dateString)"
    }
}

// MARK: - 预览辅助
#if DEBUG
extension Date {
    /// 创建测试日期
    static func testDate(year: Int = 2024, month: Int = 12, day: Int = 25, hour: Int = 14, minute: Int = 30) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
#endif
