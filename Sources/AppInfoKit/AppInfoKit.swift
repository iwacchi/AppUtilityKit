//
//  AppInfoKit.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/17.
//

import Foundation

/// アプリのバンドル情報を集約して提供するユーティリティ
/// - 取得元: `Bundle.main` の Info.plist（URL等はカスタムキー）
/// - 方針: フォールバックを用意して「落ちない/空にならない」を優先
public final class AppInfoKit: @unchecked Sendable {
// Concurrency: 参照型だが保持状態なしのため @unchecked Sendable とする（共有可変状態は持たない方針）
    
    // MARK: - Info.plist カスタムキー
    /// Info.plist に定義するURL関連のキーを型安全に管理
    public enum AppInfoKey: String, CaseIterable {
        
        /// App Store 製品ページ
        case appStoreURL = "AppUtilityKit - App store URL"
        
        /// プライバシーポリシー
        case privacyPolicyURL = "AppUtilityKit - Privacy policy URL"
        
        /// 利用規約
        case termsOfServiceURL = "AppUtilityKit - Terms of service URL"
        
        /// レビュー依頼用URL（アプリ外誘導の予備）
        case requestReviewURL = "AppUtilityKit - Request review URL"
        
        /// 開発者への連絡
        case contactWithDeveloperURL = "AppUtilityKit - Contact with developer URL"
        
        /// Info.plist から文字列を取得し、前後空白を除去して `URL` に変換
        fileprivate static func url(for key: AppInfoKey) -> URL? {
            guard let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String else {
                return nil
            }
            let urlString = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !urlString.isEmpty, let url = URL(string: urlString) else {
                return nil
            }
            return url
        }
        
    }
    
    // MARK: - Singleton
    /// 共有インスタンス（ステートレスのためスレッド制約なし）
    public static let current = AppInfoKit()
    
    /// 外部生成禁止（Singleton）
    private init() {}
    
    // MARK: - Basic Info
    /// アプリ名（ローカライズ → DisplayName → Name → 最後に processName でフォールバック）
    public var appName: String {
        let b = Bundle.main
        if let s = b.localizedInfoDictionary?["CFBundleDisplayName"] as? String, !s.isEmpty { return s }
        if let s = b.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !s.isEmpty { return s }
        if let s = b.object(forInfoDictionaryKey: "CFBundleName") as? String, !s.isEmpty { return s }
        return ProcessInfo.processInfo.processName
    }
    
    /// バンドルID（存在しない場合は空文字）
    public var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? ""
    }

    /// マーケティング版番号（CFBundleShortVersionString）
    public var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    /// ビルド番号（CFBundleVersion）
    public var buildCode: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    // MARK: - URLs (from Info.plist)
    /// App Store の製品ページURL
    public var appStoreURL: URL? {
        return AppInfoKey.url(for: .appStoreURL)
    }

    /// プライバシーポリシーURL
    public var privacyPolicyURL: URL? {
        return AppInfoKey.url(for: .privacyPolicyURL)
    }

    /// 利用規約URL
    public var termsOfServiceURL: URL? {
        return AppInfoKey.url(for: .termsOfServiceURL)
    }

    /// レビュー依頼用URL（`SKStoreReviewController` の代替/補助として使用）
    public var requestReviewURL: URL? {
        return AppInfoKey.url(for: .requestReviewURL)
    }

    /// 開発者への連絡用URL
    public var contactWithDeveloperURL: URL? {
        return AppInfoKey.url(for: .contactWithDeveloperURL)
    }
}
