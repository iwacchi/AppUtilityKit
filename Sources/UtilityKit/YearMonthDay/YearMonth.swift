//
//  YearMonth.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/22.
//

public import Foundation

/// 年と月の組を表す値型。
/// グレゴリオ暦（proleptic Gregorian）を前提とし、`Hashable` / `Comparable` に準拠しています。
/// `Comparable` は `(year, month)` の辞書式順序で比較されます。
public struct YearMonth: Hashable, Comparable, @unchecked Sendable {

    public enum Component {
        case year, month
    }

    /// 西暦年。許容範囲は `1...9999`。
    public let year: Int

    /// 月（1 = 1月, 12 = 12月）。許容範囲は `1...12`。
    public let month: Int

    /// 年と月を指定して初期化します。
    /// 与えられた値が許容範囲外の場合は `nil` を返します。
    /// - Parameters:
    ///   - year: 西暦年（1...9999）
    ///   - month: 月（1...12）
    public init?(year: Int, month: Int) {
        guard (1...9999).contains(year), (1...12).contains(month) else { return nil }
        self.year = year
        self.month = month
    }

    /// `Date` から **グレゴリオ暦** の年・月を抽出します（`Calendar(identifier: .gregorian)`）。
    public init(date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
    }

    public init(yearMonthDay: YearMonthDay) {
        self.year = yearMonthDay.year
        self.month = yearMonthDay.month
    }

    public var yearMonthDays: [YearMonthDay] {
        let calendar = Calendar.current
        let maxDayOfMonth: Int = calendar.range(of: .day, in: .month, for: date)?.count ?? 1
        return (1...maxDayOfMonth).map { day in .init(year: year, month: month, day: day)! }
    }

    public var weekOfMonth: [Int] {
        let yearMonthDays = self.yearMonthDays
        var weekOfYears: [Int] = []
        for yearMonthDay in yearMonthDays {
            let weekOfYear = yearMonthDay.weekOfMonth
            if !weekOfYears.contains(weekOfYear) {
                weekOfYears.append(weekOfYear)
            }
        }
        return weekOfYears
    }

    public static var current: YearMonth {
        .init(date: Date())
    }

    /// この `YearMonth` の**月初日（1日 00:00）**を表す `Date` を返します。
    /// カレンダーは明示的にグレゴリオ暦を使用します。タイムゾーンは `Calendar` のデフォルト（通常は `.current`）が使われます。
    /// 不正状態は `preconditionFailure` でクラッシュさせ、早期に検知します。
    public var date: Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        // 月初日の 00:00 を生成する
        comps.day = 1
        // initで範囲チェック済みのため、ここで失敗することは想定していません
        guard let date = Calendar(identifier: .gregorian).date(from: comps) else {
            preconditionFailure("Invalid YearMonth")
        }
        return date
    }

    public func move(_ component: YearMonth.Component, value: Int) -> YearMonth? {
        switch component {
        case .year:
            let newYear = year + value
            guard (1...9999).contains(newYear) else { return nil }
            return YearMonth(year: newYear, month: month)
        case .month:
            // Normalize (year, month) as a zero-based month index, then add value
            let totalMonths = year * 12 + (month - 1) + value
            let newYear = totalMonths / 12
            let newMonth = (totalMonths % 12) + 1
            guard (1...9999).contains(newYear), (1...12).contains(newMonth) else { return nil }
            return YearMonth(year: newYear, month: newMonth)
        }
    }

    public static var max: YearMonth {
        let defaultMax: YearMonth = .init(year: 9999, month: 12)!
        guard let maxYear = YearMonthDayRange.range.maxYear else {
            return defaultMax
        }
        return .init(year: maxYear, month: 12) ?? defaultMax
    }

    public static var min: YearMonth {
        let defaultMin: YearMonth = .init(year: 1, month: 1)!
        guard let minYear = YearMonthDayRange.range.minYear else {
            return defaultMin
        }
        return .init(year: minYear, month: 1) ?? defaultMin
    }

    // MARK: - Comparable

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

}
