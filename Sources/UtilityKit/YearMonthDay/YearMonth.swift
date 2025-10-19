//
//  YearMonth.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/22.

public import Foundation

/// 年と月の組を表す値型。
/// グレゴリオ暦（proleptic Gregorian）を前提とし、`Hashable` / `Comparable` に準拠します。
/// `Comparable` は `(year, month)` の辞書式順序で比較されます。
/// - Thread-safety: 値型・不変（全プロパティ `let`）のため論理的には Sendable。ただし一部の計算に `Calendar.current` を参照するため、念のため `@unchecked Sendable` を付与しています。
/// - Calendar 方針: 生成と比較は **グレゴリオ暦固定**。一方、月の日数や週番号の派生値は `Calendar.current` のロケール/タイムゾーン設定の影響を受けます。
public struct YearMonth: Hashable, Comparable, @unchecked Sendable {

    /// `move(_:, value:)` の加減算単位。
    /// - Note: `.month` の演算は整数演算で正規化しているため、負方向の丸め（0 方向）に起因する直感との差異が出る場合があります。
    public enum Component {
        case year, month
    }

    /// 西暦年（1...9999）。0 年は扱いません（天文学的年番号とは異なる前提）。
    public let year: Int

    /// 月（1...12）。
    public let month: Int

    /// 年と月を指定して初期化します。
    /// 与えられた値が許容範囲外の場合は `nil` を返します。
    /// - Parameters:
    ///   - year: 西暦年（1...9999）
    ///   - month: 月（1...12）
    /// - Invariant: 成功時は常に `YearMonth.min...YearMonth.max` の範囲に収まります。
    public init?(year: Int, month: Int) {
        guard (1...9999).contains(year), (1...12).contains(month) else { return nil }
        self.year = year
        self.month = month
    }

    /// `Date` から **グレゴリオ暦** の年・月を抽出します（`Calendar(identifier: .gregorian)`）。
    /// - Warning: 呼び出し元の `Date` の生成ポリシー（タイムゾーン/ロケール）によっては、同一瞬間でも暦の月が異なることがあります。射影の一貫性が必要なら共通の方針を共有してください。
    public init(date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
    }

    /// `YearMonthDay` から年・月のみを抽出して生成します（`day` は破棄）。
    public init(yearMonthDay: YearMonthDay) {
        self.year = yearMonthDay.year
        self.month = yearMonthDay.month
    }

    /// 当月の全日（1日〜末日）を `YearMonthDay` 配列として返します。
    /// - Depends on: `Calendar.current` による月の日数計算（ロケール/タイムゾーンの影響を受けます）。
    /// - Performance: 単純生成（O(当月日数)）。UI バインディング等で頻繁に呼ぶ場合はキャッシュを検討。
    public var yearMonthDays: [YearMonthDay] {
        let calendar = Calendar.current
        // 月の日数はローカルカレンダーで評価（閏年/暦の差異に注意）
        let maxDayOfMonth: Int = calendar.range(of: .day, in: .month, for: date)?.count ?? 1
        return (1...maxDayOfMonth).map { day in .init(year: year, month: month, day: day)! }
    }

    /// 当月に存在する「月内週番号」の集合を、**出現順に** 重複なしで返します。
    /// - Depends on: `YearMonthDay.weekOfMonth` の定義および `Calendar` の `firstWeekday`/`minimumDaysInFirstWeek`。
    /// - Note: 並び順は 1日から走査した**初出順**であり、数値順にソートはしていません。
    public var weekOfMonth: [Int] {
        let yearMonthDays = self.yearMonthDays
        var weekOfYears: [Int] = []
        for yearMonthDay in yearMonthDays {
            let weekOfYear = yearMonthDay.weekOfMonth
            // 初出の週番号だけを保持（順序は初出順）
            if !weekOfYears.contains(weekOfYear) {
                weekOfYears.append(weekOfYear)
            }
        }
        return weekOfYears
    }
    
    /// `firstWeekday` を指定して、当月に存在する「月内週番号」の集合を返します（重複なし・初出順）。
    /// - Parameter firstWeekday: 週の開始曜日ポリシー。内部で一時的に `Calendar.current.firstWeekday` を上書きして評価します。
    /// - Important: `minimumDaysInFirstWeek` は変更しません。厳格な ISO 週定義が必要ならカスタム `Calendar` を別途設計してください。
    public func weekOfMonth(firstWeekday: Date.Weekday) -> [Int] {
        let yearMonthDays = self.yearMonthDays
        var weekOfYears: [Int] = []
        for yearMonthDay in yearMonthDays {
            let weekOfYear = yearMonthDay.weekOfMonth(firstWeekday: firstWeekday)
            // 初出の週番号だけを保持（順序は初出順）
            if !weekOfYears.contains(weekOfYear) {
                weekOfYears.append(weekOfYear)
            }
        }
        return weekOfYears
    }

    /// システム現在日時に基づく“今月”（ローカルタイムゾーン）。
    /// - Testing: 単体テストでは固定タイムゾーン/固定日時の注入を推奨。
    public static var current: YearMonth {
        .init(date: Date())
    }

    /// この `YearMonth` の**月初日（1日 00:00）**を表す `Date` を返します。
    /// - Calendar: 明示的にグレゴリオ暦を使用します。
    /// - TimeZone: `Calendar(identifier: .gregorian)` のデフォルト（通常はシステムのローカルタイムゾーン）に従います。
    /// - Failure: 初期化が不正である場合は `preconditionFailure` として扱い、開発早期に検知します。
    public var date: Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        // 月初日（1日 00:00）を生成する
        // 初期化時に範囲チェック済みのため、ここでの生成失敗はプログラミングエラー
        comps.day = 1
        guard let date = Calendar(identifier: .gregorian).date(from: comps) else {
            preconditionFailure("Invalid YearMonth")
        }
        return date
    }

    /// 年または月を指定量だけ加減算します。
    /// - Parameters:
    ///   - component: `.year` または `.month`
    ///   - value: 加算(正)・減算(負)の量
    /// - Returns: 範囲外に出る場合は `nil`。
    /// - Important: `.month` は通算月で正規化する整数演算です。**負方向** のとき Swift の除算は 0 方向へ丸められるため、期待とずれるケースがあります（例外系はテストで要確認）。
    public func move(_ component: YearMonth.Component, value: Int) -> YearMonth? {
        switch component {
        case .year:
            let newYear = year + value
            guard (1...9999).contains(newYear) else { return nil }
            return YearMonth(year: newYear, month: month)
        case .month:
            // 年月を「通算月（0始まり）」に正規化してから加減算
            // 負方向の丸め規則（0 方向）に注意
            let totalMonths = year * 12 + (month - 1) + value
            let newYear = totalMonths / 12
            let newMonth = (totalMonths % 12) + 1
            guard (1...9999).contains(newYear), (1...12).contains(newMonth) else { return nil }
            return YearMonth(year: newYear, month: newMonth)
        }
    }

    /// 取りうる最大の年月。`YearMonthDayRange.range.maxYear` が未設定なら `9999-12`。
    /// - Integration: アプリ全体のスコープ（フィルタ範囲）に合わせて `YearMonthDayRange` の値を調整してください。
    public static var max: YearMonth {
        let defaultMax: YearMonth = .init(year: 9999, month: 12)!
        guard let maxYear = YearMonthDayRange.range.maxYear else {
            return defaultMax
        }
        return .init(year: maxYear, month: 12) ?? defaultMax
    }

    /// 取りうる最小の年月。`YearMonthDayRange.range.minYear` が未設定なら `0001-01`。
    /// - Integration: アプリ全体のスコープ（フィルタ範囲）に合わせて `YearMonthDayRange` の値を調整してください。
    public static var min: YearMonth {
        let defaultMin: YearMonth = .init(year: 1, month: 1)!
        guard let minYear = YearMonthDayRange.range.minYear else {
            return defaultMin
        }
        return .init(year: minYear, month: 1) ?? defaultMin
    }

    /// 年→月の辞書式順序で比較します。日や時刻情報は持ちません。
    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

}
