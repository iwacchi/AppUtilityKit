//
//  UserDefaultKitValue.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/10/21.
//

import Foundation

public enum UserDefaultKitValue {
    
    /// 任意キーの生値を取得（Property Wrapper に依存しないユーティリティ）
    /// - Parameters:
    ///   - key: 保存キー文字列
    ///   - store: 参照先 `UserDefaults`（既定は `.standard`）
    /// - Returns: 保存された値（Property List 準拠型）。未登録は `nil`
    @inlinable
    public static func value(for key: String, store: UserDefaults = .standard) -> Any? {
        return store.object(forKey: key)
    }

    /// 型安全キーで生値を取得。
    /// - Parameters:
    ///   - userDefaultKey: `UserDefaultKey` に準拠したキー
    ///   - store: 参照先 `UserDefaults`
    /// - Returns: 保存された値。未登録は `nil`
    @inlinable
    public static func value(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard) -> Any? {
        return store.object(forKey: userDefaultKey.key)
    }

    /// 任意キーに値を保存（Property List 準拠型のみ）
    /// - Parameters:
    ///   - value: 保存する値（`String/Int/Double/Bool/Data/Array/Dictionary/Date/NSNumber` 等）
    ///   - key: 保存キー文字列
    ///   - store: 保存先 `UserDefaults`
    @inlinable
    public static func set(_ value: Any?, for key: String, store: UserDefaults = .standard) {
        store.set(value, forKey: key)
    }

    /// 型安全キーを用いて値を保存。
    /// - Parameters:
    ///   - value: 保存する値
    ///   - userDefaultKey: `UserDefaultKey` に準拠したキー
    ///   - store: 保存先 `UserDefaults`
    @inlinable
    public static func set(
        _ value: Any?,
        for userDefaultKey: UserDefaultKey,
        store: UserDefaults = .standard
    ) {
        store.set(value, forKey: userDefaultKey.key)
    }

    /// `Int` を取得（未登録時は `0` を返す、`UserDefaults` と同挙動）
    @inlinable
    public static func integer(for key: String, store: UserDefaults = .standard) -> Int {
        return store.integer(forKey: key)
    }

    /// 型安全キーで `Int` を取得（未登録時は `0`）
    @inlinable
    public static func integer(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard) -> Int
    {
        return store.integer(forKey: userDefaultKey.key)
    }

    /// `Double` を取得（未登録時は `0.0`）
    @inlinable
    public static func double(for key: String, store: UserDefaults = .standard) -> Double {
        return store.double(forKey: key)
    }

    /// 型安全キーで `Double` を取得（未登録時は `0.0`）
    @inlinable
    public static func double(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard)
        -> Double
    {
        return store.double(forKey: userDefaultKey.key)
    }

    /// `Bool` を取得（未登録時は `false`）
    @inlinable
    public static func bool(for key: String, store: UserDefaults = .standard) -> Bool {
        return store.bool(forKey: key)
    }

    /// 型安全キーで `Bool` を取得（未登録時は `false`）
    @inlinable
    public static func bool(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard) -> Bool {
        return store.bool(forKey: userDefaultKey.key)
    }

    /// `String` を取得（未登録は `nil`）
    @inlinable
    public static func string(for key: String, store: UserDefaults = .standard) -> String? {
        return store.string(forKey: key)
    }

    /// 型安全キーで `String` を取得（未登録は `nil`）
    @inlinable
    public static func string(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard)
        -> String?
    {
        return store.string(forKey: userDefaultKey.key)
    }

    /// 配列を取得してジェネリクスにキャスト（未登録/キャスト失敗は `nil`）
    /// - Warning: ランタイムキャストに失敗する可能性があります。保存時の型と整合させてください。
    @inlinable
    public static func array<T>(for key: String, store: UserDefaults = .standard) -> [T]? {
        return store.array(forKey: key) as? [T]
    }

    /// 型安全キーで配列を取得してキャスト（未登録/キャスト失敗は `nil`）
    @inlinable
    public static func array<T>(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard)
        -> [T]?
    {
        return store.array(forKey: userDefaultKey.key) as? [T]
    }

    /// `Data` を取得（未登録は `nil`）
    @inlinable
    public static func data(for key: String, store: UserDefaults = .standard) -> Data? {
        return store.data(forKey: key)
    }

    /// 型安全キーで `Data` を取得（未登録は `nil`）
    @inlinable
    public static func data(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard) -> Data? {
        return store.data(forKey: userDefaultKey.key)
    }

    /// `Codable` を JSON からデコードして取得。
    /// - Returns: デコード成功時は `T`、失敗/未登録は `nil`
    /// - Note: 保存側は `JSONEncoder` でエンコードされている前提。
    @inlinable
    public static func codable<T: Codable>(for key: String, store: UserDefaults = .standard) -> T? {
        if let data = store.data(forKey: key) {
            do {
                return try JSONDecoder().decode(T.self, from: data)  // デコード失敗時は catch 節でログ出力し、最終的に nil を返す
            } catch {
                print("CodableUserDefaultKit Error: \(error)")
            }
        }
        return nil
    }

    /// 型安全キーで `Codable` を取得（JSON デコード）。失敗時は `nil`
    @inlinable
    public static func codable<T: Codable>(
        for userDefaultKey: UserDefaultKey,
        store: UserDefaults = .standard
    ) -> T? {
        if let data = store.data(forKey: userDefaultKey.key) {
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("CodableUserDefaultKit Error: \(error)")
            }
        }
        return nil
    }

    /// 任意キーを削除（キーごと除去）
    @inlinable
    public static func removeObject(for key: String, store: UserDefaults = .standard) {
        store.removeObject(forKey: key)
    }

    /// 型安全キーで削除
    @inlinable
    public static func removeObject(for userDefaultKey: UserDefaultKey, store: UserDefaults = .standard) {
        store.removeObject(forKey: userDefaultKey.key)
    }
    
}

