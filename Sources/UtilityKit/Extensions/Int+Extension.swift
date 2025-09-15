//
//  Int+Extension.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/23.
//

public import Foundation

/// `Int` を **西暦年（proleptic Gregorian）** とみなしてローカライズ済みの年文字列へ変換する拡張。
/// - Note: `Calendar.current` / `.autoupdatingCurrent` を用いるため、ユーザーのロケールやタイムゾーン変更に追従します。
///         厳密にグレゴリオ暦固定にしたい場合は、呼び出し側で `Calendar(identifier: .gregorian)` を使う実装に差し替えてください。
extension Int {

    /// `DateFormatter` を用いて年だけをローカライズ表示する。
    /// - Returns: ローカライズ済みの年文字列（例: `"2025年"`）。無効な年が与えられた場合は空文字を返す。
    /// - Important: `Calendar.current` を使用するため、ユーザー設定に依存します。厳密な暦やタイムゾーンが必要な場合は調整してください。
    public func toYearString() -> String {
        let calendar = Calendar.current
        // Int はグレゴリオ暦の「年」として解釈する（他のフィールドは未設定 = 1月1日 00:00 相当）
        let components = DateComponents(year: self)
        guard let date = calendar.date(from: components) else {
            return ""
        }
        // スレッドセーフティのため、共有せず都度生成（DF.make() を利用）
        let dateFormatter = DF.make()
        // "y" テンプレートをロケールに展開（例: ja_JP -> 2025年 / en_US -> 2025）
        dateFormatter.setLocalizedDateFormatFromTemplate("y")
        return dateFormatter.string(from: date)
    }

    /// iOS 15+ の `Date.FormatStyle` による年のローカライズ表示。
    /// - Parameter yearStyle: `Date.FormatStyle.Symbol.Year`（例: `.defaultDigits`, `.twoDigits` など）。
    /// - Returns: ローカライズ済みの年文字列。無効な年が与えられた場合は空文字を返す。
    /// - Tip: `FormatStyle` は `DateFormatter` より軽量なことが多く、頻繁な呼び出しに向きます。
    @available(iOS 15.0, *)
    public func toYearString(yearStyle: Date.FormatStyle.Symbol.Year) -> String {
        let calendar = Calendar.current
        let components = DateComponents(year: self)
        guard let date = calendar.date(from: components) else {
            return ""
        }
        // `FormatStyle` で年のみを指定し、ロケールは .current を明示
        return date.formatted(.dateTime.year(yearStyle).locale(.current))
    }

}

// MARK: - DateFormatter helper
/// `DateFormatter` 生成ヘルパ。`autoupdatingCurrent` によりロケール/タイムゾーン変更へ自動追従
private enum DF {

    /// 軽量な `DateFormatter` を都度生成（スレッドセーフティの観点から共有はしない）
    static func make() -> DateFormatter {
        let formatter = DateFormatter()
        // ロケール/タイムゾーン変更に追従させる（常に最新設定を参照）
        formatter.calendar = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        // NOTE: 高頻度で呼び出す場合は、呼び出し側でスレッドセーフなキャッシュやプール化も検討
        return formatter
    }

}
