//
//  Date+Extension.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/17.
//

public import Foundation

// MARK: - Dateのユーティリティ拡張
/// - ポリシー: `DateFormatter` は `.autoupdatingCurrent` を使用。`Calendar` は **都度** `.current` を取得して長期保持しない（設定変更に追従）。強制アンラップは原則避ける。
/// - 対応OS: iOS 13+（iOS 15+ では `Date.FormatStyle` オーバーロードを提供）
extension Date {

    /// - Note: `DateFormatter` の weekday 系配列（`weekdaySymbols` / `shortWeekdaySymbols` など）は
    ///   常に **日曜始まり**（index 0 = Sun）です。`Calendar.firstWeekday` 設定の影響は受けないため、
    ///   `rawValue - 1` での参照は安全です。
    /// `Calendar.component(.weekday, from:)` に対応する曜日列挙。
    /// `rawValue` は 1=Sun, 2=Mon, ..., 7=Sat（`Calendar` の仕様に準拠）。
    /// 並び順は `rawValue` の昇順で比較（`Comparable`）。
    public enum Weekday: Int, Identifiable, Hashable, Codable, CaseIterable, Comparable, Equatable, @unchecked Sendable {

        public var id: Self { self }

        /// 1=Sun, 2=Mon, ..., 7=Sat （`Calendar` の仕様に準拠）
        case sunday = 1

        case monday = 2

        case tuesday = 3

        case wednesday = 4

        case thursday = 5

        case friday = 6

        case saturday = 7

        /// ロケール依存の極短い曜日名（例: "S" / "日"）
        public var veryShortName: String {
            Date.veryShortWeekdayNames[rawValue - 1]
        }

        /// ロケール依存の短い曜日名（例: "Sun" / "日"）
        public var shortName: String {
            Date.shortWeekdayNames[rawValue - 1]
        }

        /// ロケール依存のフル曜日名（例: "Sunday" / "日曜日"）
        public var name: String {
            Date.weekdayNames[rawValue - 1]
        }

        /// 単独表示用の極短い曜日名（文脈に依存しないスタンドアロン形）
        public var veryShortStandaloneName: String {
            Date.veryShortStandaloneWeekdayNames[rawValue - 1]
        }

        /// 単独表示用の短い曜日名（スタンドアロン形）
        public var shortStandaloneName: String {
            Date.shortStandaloneWeekdayNames[rawValue - 1]
        }

        /// 単独表示用のフル曜日名（スタンドアロン形）
        public var standaloneName: String {
            Date.standaloneWeekdayNames[rawValue - 1]
        }

        /// `rawValue`（1→7）の辞書式順序で比較
        public static func < (lhs: Date.Weekday, rhs: Date.Weekday) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        public static func allCases(firstWeekday: Date.Weekday) -> [Date.Weekday] {
            var weekdays = Self.allCases
            while weekdays.first != firstWeekday {
                let first = weekdays.removeFirst()
                weekdays.append(first)
            }
            return weekdays
        }

    }

    // MARK: - 午前/午後（AM/PM）
    /**
     午前/午後を表す区分。
    
     - AM: 0:00〜11:59
     - PM: 12:00〜23:59
    
     比較は `am < pm`。
     ロケールに応じた表示は `name` / `name(locale:)` を使用。
     */
    public enum DayPeriod: Int, Identifiable, Hashable, Codable, CaseIterable, Equatable, Comparable, @unchecked Sendable
    {

        public var id: Self { self }

        /// 0:00〜11:59
        case am = 0

        /// 12:00〜23:59
        case pm = 1

        /// 現在のロケールに合わせたAM/PMシンボル（例: ja_JP → 「午前/午後」, en_US → 「AM/PM」）
        public var name: String {
            return self == .am ? DF.make().amSymbol : DF.make().pmSymbol
        }

        /// 指定ロケールに合わせたAM/PMシンボルを返す
        public func name(locale: Locale) -> String {
            let dateFormatter = DF.make()
            dateFormatter.locale = locale
            return self == .am ? dateFormatter.amSymbol : dateFormatter.pmSymbol
        }

        public static func < (lhs: Date.DayPeriod, rhs: Date.DayPeriod) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        /// `date` のローカル時刻（`calendar` 基準）から区分を決定
        public init(date: Date, calendar: Calendar = .current) {
            let hour = calendar.component(.hour, from: date)
            self = hour < 12 ? .am : .pm
        }

        /// 0〜23 の時から区分を決定（範囲外は `nil`）
        public init?(hour24: Int) {
            if hour24 < 0 || hour24 >= 24 {
                return nil
            }
            self = hour24 < 12 ? .am : .pm
        }

    }

    /// ロケールに応じた曜日名（veryShort, 文脈依存）。`DF.make()` により設定変更へ自動追従
    internal static var veryShortWeekdayNames: [String] {
        return DF.make().veryShortWeekdaySymbols
    }

    /// ロケールに応じた曜日名（short, 文脈依存）
    internal static var shortWeekdayNames: [String] {
        return DF.make().shortWeekdaySymbols
    }

    /// ロケールに応じた曜日名（long, 文脈依存）
    internal static var weekdayNames: [String] {
        return DF.make().weekdaySymbols
    }

    /// ロケールに応じた曜日名（veryShort, スタンドアロン）
    internal static var veryShortStandaloneWeekdayNames: [String] {
        return DF.make().veryShortStandaloneWeekdaySymbols
    }

    /// ロケールに応じた曜日名（short, スタンドアロン）
    internal static var shortStandaloneWeekdayNames: [String] {
        return DF.make().shortStandaloneWeekdaySymbols
    }

    /// ロケールに応じた曜日名（long, スタンドアロン）
    internal static var standaloneWeekdayNames: [String] {
        return DF.make().standaloneWeekdaySymbols
    }

    /// 年月日と任意の時分秒から `Date` を生成（失敗時は `nil`）
    /// - Warning: `Calendar.date(from:)` は一部の不正な値を繰り上げ/繰り下げで正規化する場合があります
    ///   （例: 分=75 → 翌時の 15 分）。厳密な検証が必要な場合は、呼び出し側で範囲チェックを行ってください。
    public init?(
        year: Int,
        month: Int,
        day: Int,
        hour: Int? = nil,
        minute: Int? = nil,
        second: Int? = nil
    ) {
        let calendar = Calendar.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        self = date
    }

    // MARK: - Component setters

    /// 年のみを置き換えた `Date` を返します。
    /// - Parameter year: 西暦年。
    /// - Returns: 生成に失敗した場合は `nil`。存在しない日付（例: うるう日など）となる場合は `Calendar` の正規化により `nil` になり得ます。
    public func set(year: Int) -> Date? {
        let calendar = Calendar.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        return date
    }

    /// 月のみを置き換えた `Date` を返します。
    /// - Parameter month: 月（推奨範囲 1...12）。
    /// - Returns: 生成に失敗した場合は `nil`。範囲外の月や存在しない日（例: 31日が無い月）では `Calendar` により正規化または失敗する可能性があります。
    public func set(month: Int) -> Date? {
        let calendar = Calendar.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        return date
    }

    /// 日のみを置き換えた `Date` を返します。
    /// - Parameter day: 日（1...31。月により有効範囲は異なります）。
    /// - Returns: 生成に失敗した場合は `nil`。
    public func set(day: Int) -> Date? {
        let calendar = Calendar.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        return date
    }

    /// 時のみを置き換えた `Date` を返します。
    /// - Parameter hour: 時（推奨範囲 0...23）。
    /// - Returns: 生成に失敗した場合は `nil`。24 以上や負値を渡した場合、`Calendar` により翌日/前日へ繰り上げ・繰り下げされることがあります。
    public func set(hour: Int) -> Date? {
        let calendar = Calendar.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        return date
    }

    /// 分のみを置き換えた `Date` を返します。
    /// - Parameter minute: 分（推奨範囲 0...59）。
    /// - Returns: 生成に失敗した場合は `nil`。60 以上や負値を渡した場合、`Calendar` により繰り上げ・繰り下げされることがあります。
    public func set(minute: Int) -> Date? {
        let calendar = Calendar.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        return date
    }

    /// 時と分を同時に置き換えた `Date` を返します。
    /// - Parameters:
    ///   - hour: 時（0...23）
    ///   - minute: 分（0...59）
    /// - Returns: 生成に失敗した場合は `nil`。範囲外の値は `Calendar` により正規化されることがあります。
    public func set(hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        return date
    }

    /// 分単位で丸めます。
    /// - Parameters:
    ///   - interval: 丸め間隔（分）。**0 より大きい整数**を指定してください。
    ///   - roundUp: `true` なら切り上げ、`false` なら切り下げ。
    /// - Returns: 丸め後の `Date`。境界ちょうど（例: 15分刻みで 10:30 丸め、かつ `roundUp == true`）の場合は、**次の境界**（この例では 10:45）に進みます。59 を超える分は `Calendar` により次の時へ繰り上がります。
    /// - Note: `interval` が 60 の約数である必要はありません。範囲外の分は `Calendar` により正規化（繰り上がり/繰り下がり）されます。
    public func roundedToMinute(interval: Int, roundUp: Bool = false) -> Date {
        // 0 以下は危険（0 除算の可能性）なので早期リターン
        guard interval > 0 else { return self }

        let calendar = Calendar.current
        let nowMinute = self.minute
        let remainder = nowMinute % interval

        var newMinute =
            roundUp
            ? (remainder == 0 ? nowMinute + interval : nowMinute + (interval - remainder))
            : nowMinute - remainder

        // マイナスは 0 に丸め（interval が 60 より大きい場合の保険）
        if newMinute < 0 { newMinute = 0 }

        // 分丸め時は秒を 0 に正規化する
        let comps = DateComponents(
            year: self.year,
            month: self.month,
            day: self.day,
            hour: self.hour,
            minute: newMinute,
            second: 0
        )
        return calendar.date(from: comps) ?? self
    }

    /// 時単位で丸めます。
    /// - Parameters:
    ///   - interval: 丸め間隔（時）。**0 より大きい整数**を指定してください。
    ///   - roundUp: `true` なら切り上げ、`false` なら切り下げ。
    /// - Returns: 丸め後の `Date`。境界ちょうど（例: 3時間刻みで 06:00 丸め、かつ `roundUp == true`）の場合は、**次の境界**（この例では 09:00）に進みます。23 を超える時は `Calendar` により翌日へ繰り上がります。
    /// - Note: `interval` が 24 の約数である必要はありません。範囲外の時は `Calendar` により正規化（繰り上がり/繰り下がり）されます。
    public func roundedToHour(interval: Int, roundUp: Bool = false) -> Date {
        // 0 以下は危険（0 除算の可能性）なので早期リターン
        guard interval > 0 else { return self }

        let calendar = Calendar.current
        let nowHour = self.hour
        let remainder = nowHour % interval

        var newHour =
            roundUp
            ? (remainder == 0 ? nowHour + interval : nowHour + (interval - remainder))
            : nowHour - remainder

        if newHour < 0 { newHour = 0 }

        // 時丸め時は分・秒を 0 に正規化する
        let comps = DateComponents(
            year: self.year,
            month: self.month,
            day: self.day,
            hour: newHour,
            minute: 0,
            second: 0
        )
        return calendar.date(from: comps) ?? self
    }

    // MARK: - Calendar component accessors
    /// 現在のカレンダーに基づく年
    public var year: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: self)
    }

    /// 現在のカレンダーに基づく月（1...12）
    public var month: Int {
        let calendar = Calendar.current
        return calendar.component(.month, from: self)
    }

    /// 現在のカレンダーに基づく日（1...31）
    public var day: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: self)
    }

    /// `Weekday`（Sun=1 ... Sat=7）を返す
    public var weekday: Date.Weekday {
        let calendar = Calendar.current
        let rawValue = calendar.component(.weekday, from: self)
        return Date.Weekday(rawValue: rawValue) ?? .sunday
    }

    /// 時（0...23）
    public var hour: Int {
        let calendar = Calendar.current
        return calendar.component(.hour, from: self)
    }

    /// この日付の午前/午後区分（ローカルタイムゾーン）
    public var dayPeriod: DayPeriod {
        DayPeriod(date: self)
    }

    /// 分（0...59）
    public var minute: Int {
        let calendar = Calendar.current
        return calendar.component(.minute, from: self)
    }

    /// 秒（0...59）
    public var second: Int {
        let calendar = Calendar.current
        return calendar.component(.second, from: self)
    }

    /// 現在のカレンダーに基づく「その日が属する月内での週番号」。
    /// - Important: 週の始まり（`firstWeekday`）や年跨ぎ・月跨ぎの扱いはユーザー設定に依存します。
    ///   例として、月初が週の途中から始まる場合は `1` が短い週になることがあります。
    ///   UI 表示で「第 N 週」を示す用途では、`Calendar.current` の設定を前提にしてください。
    public var weekOfMonth: Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfMonth, from: self)
    }

    /// `self` から `date` までの「日」差を返します。
    ///
    /// - Important: 1日は **常に 86,400 秒** として計算します（DST による 23/25 時間日は考慮しません）。
    ///   「カレンダー上の日付差（例: 同日の判定や週跨ぎを厳密に取りたい）」が必要な場合は
    ///   `Calendar.dateComponents([.day], from: self.startOfDay, to: date.startOfDay).day` を用いる実装を検討してください。
    ///
    /// - Parameters:
    ///   - date: 比較対象の日時。
    ///   - isRoundUp: `true` の場合は**日単位での端数があれば 1 日に切り上げ**（絶対値ベース、ゼロは除く）。
    ///                `false` の場合は**端数切り捨て**（絶対値ベース）。
    ///                方向（過去/未来）は `self.distance(to:)`（= 秒差）の符号に従います。
    /// - Returns: `Int` の日差。`date` が未来なら正、過去なら負、同時刻なら 0。
    @available(iOS 13.0, *)
    public func distanceDays(to date: Date, isRoundUp: Bool = false) -> Int {
        // Date は Strideable に準拠しており、distance(to:) は秒差（Double, date - self）を返す
        let seconds = self.distance(to: date)
        let daySeconds: Double = 86_400

        // 絶対秒と符号を分離
        let sign: Int = seconds == 0 ? 0 : (seconds > 0 ? 1 : -1)
        let absSeconds = abs(seconds)

        // 端数の有無を厳密に判定（浮動小数点の誤差を最小化）
        let remainder = absSeconds.truncatingRemainder(dividingBy: daySeconds)
        let baseDays = Int(floor(absSeconds / daySeconds))

        // 切り上げ指定かつ端数ありなら +1（絶対値ベース）
        let magnitude = (isRoundUp && remainder > 0) ? (baseDays + 1) : baseDays

        // ゼロのときは符号も 0 に統一
        if magnitude == 0 { return 0 }
        return sign * magnitude
    }

    /// 当日から +1 日移動（DST を考慮）
    public var tomorrow: Date {
        return move(.day, value: 1)
    }

    /// 当日から -1 日移動（DST を考慮）
    public var yesterday: Date {
        return move(.day, value: -1)
    }

    // MARK: - Month names (localized)
    /// ロケールに基づく月名（veryShort, 文脈依存）
    public var veryShortMonthString: String {
        return DF.make().veryShortMonthSymbols[self.month - 1]
    }

    /// ロケールに基づく月名（short, 文脈依存）
    public var shortMonthString: String {
        return DF.make().shortMonthSymbols[self.month - 1]
    }

    /// ロケールに基づく月名（long, 文脈依存）
    public var monthString: String {
        return DF.make().monthSymbols[self.month - 1]
    }

    /// ロケールに基づく月名（veryShort, スタンドアロン）
    public var veryShortStandaloneMonthString: String {
        return DF.make().veryShortStandaloneMonthSymbols[self.month - 1]
    }

    /// ロケールに基づく月名（short, スタンドアロン）
    public var shortStandaloneMonthString: String {
        return DF.make().shortStandaloneMonthSymbols[self.month - 1]
    }

    /// ロケールに基づく月名（long, スタンドアロン）
    public var standaloneMonthString: String {
        return DF.make().standaloneMonthSymbols[self.month - 1]
    }

    // MARK: - Day/Week/Month boundaries
    /// その日の 00:00:00（`Calendar.startOfDay(for:)` 準拠）
    public var startOfDay: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self)
    }

    /// その日が属する「週（weekOfMonth）」の開始日の 00:00 を返す。
    /// - Note: 週の開始曜日はユーザーのカレンダー設定（`firstWeekday` / `minimumDaysInFirstWeek`）に依存する。
    public var startWeekOfMonth: Date {
        // `dateInterval(of:.weekOfMonth, for:)` の start は週の先頭（ロケール依存）
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfMonth, for: self)?.start ?? self
        return calendar.startOfDay(for: start)
    }

    /// その日が属する「週（weekOfMonth）」の最終日の 00:00 を返す。
    /// - Important: `dateInterval(of:.weekOfMonth, for:)` の `end` は **排他的（exclusive）** のため、1日戻した上で 00:00 に正規化する。
    public var endWeekOfMonth: Date {
        // `end` は翌週の先頭（exclusive）。前日に戻す
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfMonth, for: self)?.end ?? self
        return calendar.startOfDay(for: start.yesterday)
    }

    /// 月初（その月における最初の瞬間：`00:00:00`）。
    /// - Note: `Calendar.dateInterval(of: .month, for: self)?.start` を利用しており、
    ///   サマータイム（DST）やタイムゾーン変更が絡む日付でも安全に先頭境界を取得します。
    /// - Returns: 対象月の開始日時。失敗時は `self` を返します（極端な暦設定変更などのフェイルセーフ）。
    public var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: self)?.start ?? self
    }

    /// 年初（`Calendar.dateInterval(of:.year, for:)` の start）
    public var startOfYear: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .year, for: self)?.start ?? self
    }

    // MARK: - Formatting
    /// `DateFormatter` による日付文字列化。`style` は `dateStyle` に適用（time は省略）
    public func toDateString(_ style: DateFormatter.Style = .full) -> String {
        let dateFormatter = DF.make()
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: self)
    }

    /// iOS 15+ の `FormatStyle` 版（日付のみ）。曖昧さ回避のためデフォルト値は付けない
    @available(iOS 15.0, *)
    public func toDateString(_ style: Date.FormatStyle.DateStyle) -> String {
        self.formatted(date: style, time: .omitted)
    }

    /// `DateFormatter` による時刻文字列化。`style` は `timeStyle` に適用（date は省略）
    public func toTimeString(_ style: DateFormatter.Style = .short) -> String {
        let dateFormatter = DF.make()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = style
        return dateFormatter.string(from: self)
    }

    /// iOS 15+ の `FormatStyle` 版（時刻のみ）
    @available(iOS 15.0, *)
    public func toTimeString(_ style: Date.FormatStyle.TimeStyle) -> String {
        self.formatted(date: .omitted, time: style)
    }

    /// 年月（例: "2025年8月" / "August 2025"）をローカライズして返す。
    /// - Note: `setLocalizedDateFormatFromTemplate("yMMMM")` を使用し、言語・地域に応じた並び順・表記に自動適応する。
    public func toYearMonthString() -> String {
        let dateFormatter = DF.make()
        dateFormatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return dateFormatter.string(from: self)
    }

    @available(iOS 15.0, *)
    public func toYearMonthString(
        yearStyle: FormatStyle.Symbol.Year,
        monthStyle: FormatStyle.Symbol.Month
    ) -> String {
        return self.formatted(.dateTime.year(yearStyle).month(monthStyle))
    }

    public func toMonthDayString() -> String {
        let dateFormatter = DF.make()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
        return dateFormatter.string(from: self)
    }

    @available(iOS 15.0, *)
    public func toMonthDayString(
        monthStyle: Date.FormatStyle.Symbol.Month,
        dayStyle: Date.FormatStyle.Symbol.Day,
        weekStyle: Date.FormatStyle.Symbol.Week
    ) -> String {
        return self.formatted(
            .dateTime
                .month(monthStyle)
                .day(dayStyle)
                .week(weekStyle)
                .locale(.current)
        )
    }

    public func toYearString() -> String {
        let dateFormatter = DF.make()
        dateFormatter.setLocalizedDateFormatFromTemplate("y")
        return dateFormatter.string(from: self)
    }

    @available(iOS 15.0, *)
    public func toYearString(yearStyle: Date.FormatStyle.Symbol.Year) -> String {
        return self.formatted(.dateTime.year(yearStyle).locale(.current))
    }

    /// 指定コンポーネントで相対移動して新たな `Date` を返します（失敗時はフォールバックで `self`）。
    /// - Parameters:
    ///   - component: 追加・減算するカレンダーコンポーネント（例: `.day`, `.month`, `.year`）。
    ///   - value: 加算（正）/ 減算（負）する量。
    /// - Note: `Calendar.date(byAdding:value:to:)` を使用。DST などの不連続もカレンダー側で処理されます。
    public func move(_ component: Calendar.Component, value: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: component, value: value, to: self) ?? self
    }

    /// 指定したコンポーネント集合のみを残し、他の下位コンポーネントを正規化（ゼロ化）します。
    /// - Parameter components: 残したいコンポーネントの集合（例: `[.year, .month, .day]`）。
    /// - Returns: 正規化済み `Date`。生成に失敗した場合は `self` を返します。
    /// - UseCase: カレンダーの「日単位比較」や絞り込みで、時分秒を常に `00:00:00` に揃えたい場合。
    public func trimmed(to components: Set<Calendar.Component>) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents(components, from: self)
        return calendar.date(from: dateComponents) ?? self
    }

    /// 当日かどうか
    public var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }

    /// AM かどうか（0:00〜11:59）
    public var isAM: Bool {
        self.dayPeriod == .am
    }

    /// PM かどうか（12:00〜23:59）
    public var isPM: Bool {
        self.dayPeriod == .pm
    }

    /// 週末かどうか（ロケール・カレンダーに依存。例: 一部地域では金・土が週末）
    public var isWeekend: Bool {
        let calendar = Calendar.current
        return calendar.isDateInWeekend(self)
    }

    /// 曜日判定のショートカット群（`Calendar` の weekday に準拠）
    public var isSunday: Bool {
        self.weekday == .sunday
    }

    public var isMonday: Bool {
        self.weekday == .monday
    }

    public var isTuesday: Bool {
        self.weekday == .tuesday
    }

    public var isWednesday: Bool {
        self.weekday == .wednesday
    }

    public var isThursday: Bool {
        self.weekday == .thursday
    }

    public var isFriday: Bool {
        self.weekday == .friday
    }

    public var isSaturday: Bool {
        self.weekday == .saturday
    }

    // MARK: - Equality checks (granularity)
    /// 同一日かどうか（タイムゾーンに注意）
    public func isSameDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date)
    }

    /// 同一月かどうか（年も含めて比較）。
    /// - Important: タイムゾーンの影響を受けます。`Calendar.current` によるローカル基準での比較です。
    public func isSameMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .month)
    }

    /// 同一年かどうか。
    /// - Important: `Calendar.current` のタイムゾーン/ロケールに依存します。
    public func isSameYear(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .year)
    }

    /// 同一時間かどうか（分・秒は無視）。
    public func isSameHour(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .hour)
    }

    /// 同一分かどうか（秒は無視）。
    public func isSameMinute(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .minute)
    }

    /// 同一秒かどうか。
    public func isSameSecond(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .second)
    }

    // MARK: - Relative comparison helpers
    /// `self < date` のラッパー。同日の場合の戻り値を `ifSameDay` で上書き可能
    /// - Parameter ifSameDay: `true` なら同日を「前」として扱い、`false` なら「後」として扱う（`nil` なら通常比較）
    public func isBefore(_ date: Date, ifSameDay: Bool? = nil) -> Bool {
        if let ifSameDay {
            if self.isSameDay(date) {
                return ifSameDay
            }
        }
        return self < date
    }

    /// `self > date` のラッパー。同日の場合の戻り値を `ifSameDay` で上書き可能
    /// - Parameter ifSameDay: `true` なら同日を「後」として扱い、`false` なら「前」として扱う（`nil` なら通常比較）
    public func isAfter(_ date: Date, ifSameDay: Bool? = nil) -> Bool {
        if let ifSameDay {
            if self.isSameDay(date) {
                return ifSameDay
            }
        }
        return self > date
    }

}

/// `DateFormatter` 生成ヘルパ。`autoupdatingCurrent` によりロケール/タイムゾーン変更へ自動追従
private enum DF {

    /// `DateFormatter` を都度生成して返します。
    /// - Policy: 共有インスタンスは使用せず、スレッドセーフティと環境変更（ロケール/タイムゾーン）への追従漏れを避けます。
    /// - Performance: 大量処理が必要な箇所では呼び出し側でのキャッシュを検討してください。
    static func make() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }

}
