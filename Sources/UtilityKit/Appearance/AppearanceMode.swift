//
//  AppearanceMode.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

#if canImport(SwiftUI)
public import SwiftUI
public import UIKit

// MARK: - Appearance Mode
/// アプリの外観モード（システム／ライト／ダーク）を表す共通型。永続化のため `Int` RawValue を採用
public enum AppearanceMode: Int, CaseIterable, Codable, @unchecked Sendable {
    
    /// システム設定に追従（App設定＝未指定）
    case system = 0
    
    /// 常にライト表示
    case light = 1
    
    /// 常にダーク表示
    case dark = 2
    
    /// ローカライズ済み名称（例: "システム" / "ライト" / "ダーク"）
    /// - Note: iOS 15+ では `String(localized:)`。フレームワーク/SPM の場合は `bundle:` を明示する実装に差し替えると安全
    public var name: String {
        switch self {
        case .system:
            if #available(iOS 15, *) {
                String(localized: "appearanceModeSystem", bundle: Bundle.main)
            } else {
                NSLocalizedString("appearanceModeSystem", bundle: Bundle.main, comment: "appearanceModeSystem")
            }
        case .light:
            if #available(iOS 15, *) {
                String(localized: "appearanceModeLight", bundle: Bundle.main)
            } else {
                NSLocalizedString("appearanceModeLight", bundle: Bundle.main, comment: "appearanceModeLight")
            }
        case .dark:
            if #available(iOS 15, *) {
                String(localized: "appearanceModeDark", bundle: Bundle.main)
            } else {
                NSLocalizedString("appearanceModeDark", bundle: .main, comment: "appearanceModeDark")
            }
        }
    }
    
    /// SwiftUI の `ColorScheme` へのマッピング（`.system` は `nil` を返し、環境依存の解決に委ねる）
    @available(iOS 13.0, *)
    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
                .light
        case .dark:
                .dark
        }
    }
    
    /// UIKit の `UIUserInterfaceStyle` へのマッピング（ウィンドウ/ビュー単位の override に利用）
    public var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }
    
}
#endif
