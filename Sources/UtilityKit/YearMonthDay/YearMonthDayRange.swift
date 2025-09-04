//
//  YearMonthDayRange.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/22.
//

internal import Foundation

// MARK: - Info.plist カスタムキー
/// Info.plist に定義する西暦年の範囲（最小年・最大年）を型安全に管理
public enum YearMonthDayRange: String, CaseIterable {
    
    /// 許容する最大の西暦年（Info.plist の String または Number ）
    case maxYear = "UtilityKit - Max year"
    
    /// 許容する最小の西暦年（Info.plist の String または Number ）
    case minYear = "UtilityKit - Min year"
    
    /// Info.plist から最小/最大の西暦年を読み取って返します。
    /// - 文字列（前後空白は除去）または数値（NSNumber）をサポートします。
    public static var range: (minYear: Int?, maxYear: Int?) {
        func parse(_ any: Any?) -> Int? {
            switch any {
            case let s as String:
                return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
            case let n as NSNumber:
                return n.intValue
            default:
                return nil
            }
        }
        let minAny = Bundle.main.object(forInfoDictionaryKey: YearMonthDayRange.minYear.rawValue)
        let maxAny = Bundle.main.object(forInfoDictionaryKey: YearMonthDayRange.maxYear.rawValue)
        return (parse(minAny), parse(maxAny))
    }
    
}
