//
//  YearMonthDay.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/22.
//

public import Foundation

/// 年・月・日を持つ不変値型
/// - 目的: Calendar/TimeZone に依存しがちな `Date` の直接比較を避け、純粋な年月日で扱う
/// - 不変化: 内部状態の破壊を避けるため、`year/month/day` は `let` にする
public struct YearMonthDay: Hashable, Comparable, @unchecked Sendable {
    
    // MARK: - Calendar Policy
    /// 週番号や曜日の計算ポリシー（現状は **日本向けに `Calendar.current` を採用**）。
    /// 将来 ISO 週準拠に切り替える場合は、ここを `Calendar(identifier: .iso8601)` 等に置き換えるだけで全呼び出しを切り替えられる。
    private static var weekCalendar: Calendar { Calendar.current }
    
    /// 日付移動の単位
    /// - Note: 年・月・日はグレゴリオ暦の解釈を前提とします。
    public enum Component {
        case year, month, day
    }
    
    public let year: Int
    
    public let month: Int
    
    public let day: Int
    
    /// 曜日（`date.weekday` を経由）
    /// - Important: `Date` の `weekday` 拡張が別途存在することを前提とします。拡張のカレンダー/タイムゾーン設定に依存します。
    public var weekday: Date.Weekday {
        return date.weekday
    }
    
    /// 週番号（`date.weekOfYear` を経由）
    /// - Important: `Date` 側の拡張実装に依存します。ISO週かどうかなどは拡張の仕様に準拠します。
    public var weekOfMonth: Int {
        return date.weekOfMonth
    }
    
    /// 年月へ射影（`YearMonth` 補助型に変換）
    public var yearMonth: YearMonth {
        return .init(yearMonthDay: self)
    }
    
    // MARK: - Initialization

    /// 不正な日付（例: 2025-02-30）をはじくためのバリデーション付き初期化子（**グレゴリオ暦固定**）
    /// - Parameters:
    ///   - year: 西暦年（1〜）
    ///   - month: 1〜12
    ///   - day: 1〜31（実在する日付であること）
    /// - Note: `Calendar(identifier: .gregorian)` で検証。タイムゾーンの違いで日付がズレないよう、カレンダーは固定します。
    public init?(year: Int, month: Int, day: Int) {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        guard Calendar(identifier: .gregorian).date(from: comps) != nil else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }
    
    /// 週番号と曜日から日付を生成します（ローカルカレンダー依存）。
    /// - Note: 週番号の解釈は `YearMonthDay.weekCalendar` に従います（現状は `Calendar.current`）。
    /// - Parameters:
    ///   - year: 暦年（`yearForWeekOfYear` ではありません）
    ///   - weekOfYear: 週番号（`Calendar` の週定義に依存）
    ///   - weekday: 曜日
    /// - Important: `Calendar.current` を利用するため、ロケールやタイムゾーンによって結果が異なる可能性があります。
    ///   ISO 週番号を用いる場合は `Calendar(identifier: .iso8601)` と `yearForWeekOfYear` を使う別実装を検討してください。
    public init?(year: Int, month: Int, weekOfMonth: Int, weekday: Date.Weekday) {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.weekOfMonth = weekOfMonth; comps.weekday = weekday.rawValue
        guard let date = Self.weekCalendar.date(from: comps) else {
            return nil
        }
        self.year = date.year
        self.month = date.month
        self.day = date.day
    }

    /// `Date` から **グレゴリオ暦** の年月日を抽出（`Calendar(identifier: .gregorian)`）
    public init(date: Date) {
        let cal = Calendar(identifier: .gregorian)
        self.year = cal.component(.year, from: date)
        self.month = cal.component(.month, from: date)
        self.day = cal.component(.day, from: date)
    }

    /// `YearMonthDay` を **グレゴリオ暦** の `Date`（当日の 00:00）に変換します。
    /// - Precondition: 事前バリデーション済みのため生成失敗はプログラミングエラーとして扱います。
    /// - Note: タイムゾーンは `Calendar(identifier: .gregorian)` のデフォルト（システムの現地時刻）に従います。
    public var date: Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        guard let d = Calendar(identifier: .gregorian).date(from: comps) else {
            preconditionFailure("Invalid YearMonthDay")
        }
        return d
    }

    // MARK: - Comparison

    /// 年→月→日の辞書式順序で比較（早い日付が小さい）
    public static func < (lhs: YearMonthDay, rhs: YearMonthDay) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
    // MARK: - Utilities

    /// システムの現在日時を基にした“今日”の年月日（ローカルタイムゾーン）
    public static var current: YearMonthDay {
        .init(date: Date())
    }
    
    /// 明日（1日進めた値）
    public var tomorrow: YearMonthDay {
        return move(.day, value: 1)
    }

    /// 昨日（1日戻した値）
    public var yesterday: YearMonthDay {
        return move(.day, value: -1)
    }
    
    /// 指定の `YearMonth` と年・月が一致するか
    /// - Parameter yearMonth: 比較対象の年・月
    /// - Returns: 同一なら `true`
    public func isSameYearMonth(_ yearMonth: YearMonth) -> Bool {
        return self.year == yearMonth.year && self.month == yearMonth.month
    }
    
    /// 指定した単位で年月日を加減算します。
    /// - Parameters:
    ///   - component: `.year` / `.month` / `.day`
    ///   - value: 加算(正)・減算(負)する量
    /// - Returns: 生成できない日付（例: 2025-01-31 を 1 ヶ月進める → 2025-02-31）になった場合は **変更前の値を返します**。
    /// - Important: `.day` の移動は `Calendar.current` を使用するため、端末のローカルタイムゾーンや DST の影響を受けます。厳密にグレゴリオ暦固定にしたい場合は、必要に応じて `Calendar(identifier: .gregorian)` を渡す実装へ見直してください。
    public func move(_ component: YearMonthDay.Component, value: Int) -> YearMonthDay {
        switch component {
        case .year:
            return .init(year: year + value, month: month, day: day) ?? self
        case .month:
            // 年月を通算月に変換してから加算し、年と月へ復元（1月=1、…、12月=12）。
            // 日が新しい月の最大日を超える場合は初期化に失敗し、呼び出し元へ現値を返します。
            let totalMonths = year * 12 + (month - 1) + value
            let newYear = totalMonths / 12
            let newMonth = (totalMonths % 12) + 1
            return .init(year: newYear, month: newMonth, day: day) ?? self
        case .day:
            // ローカルカレンダーで日単位の加減算（DST 跨ぎを含む）。
            let calendar = Calendar.current
            guard let newDate = calendar.date(byAdding: .day, value: value, to: self.date) else {
                return self
            }
            return .init(date: newDate)
        }
    }
    
    // MARK: - Range Helpers

    /// 取りうる最小の年月日。`YearMonthDayRange.range.minYear` が存在しない場合は `0001-01-01`。
    /// - Note: 外部依存（`YearMonthDayRange`）の値に基づきます。
    public static var min: YearMonthDay {
        let defaultMin: YearMonthDay = .init(year: 1, month: 1, day: 1)!
        guard let minYear = YearMonthDayRange.range.minYear else {
            return defaultMin
        }
        return .init(year: minYear, month: 1, day: 1) ?? defaultMin
    }
    
    /// 取りうる最大の年月日。`YearMonthDayRange.range.maxYear` が存在しない場合は `9999-12-31`。
    /// - Note: 外部依存（`YearMonthDayRange`）の値に基づきます。
    public static var max: YearMonthDay {
        let defaultMax: YearMonthDay = .init(year: 9999, month: 12, day: 31)!
        guard let maxYear = YearMonthDayRange.range.maxYear else {
            return defaultMax
        }
        return .init(year: maxYear, month: 12, day: 31) ?? defaultMax
    }
    
    /// 任意カレンダー/タイムゾーンで `Date` に変換（正午を経由して DST 影響を避ける）
    public func date(in calendar: Calendar = .current, timeZone: TimeZone = .current) -> Date? {
        var cal = calendar
        cal.timeZone = timeZone
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = 12   // 00:00 が存在しない日のガードとして正午を採用
        guard let noon = cal.date(from: comps) else { return nil }
        return cal.startOfDay(for: noon)
    }
}
