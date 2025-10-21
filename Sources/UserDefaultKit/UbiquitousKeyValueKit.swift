//
//  UbiquitousKeyValueKit.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/10/21.
//

import Foundation
import Combine

@propertyWrapper
public struct UbiquitousKeyValueKit<Value> {
    
    private let key: String
    
    private let defaultValue: Value
    
    private let store: NSUbiquitousKeyValueStore
    
    public init(key: String, defaultValue: Value, store: NSUbiquitousKeyValueStore = .default) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }
    
    public init(
        userDefaultKey: UserDefaultKey,
        defaultValue: Value,
        store: NSUbiquitousKeyValueStore = .default
    ) {
        self.key = userDefaultKey.key
        self.defaultValue = defaultValue
        self.store = store
    }
    
    public var wrappedValue: Value {
        get { store.object(forKey: key) as? Value ?? defaultValue }
        set { store.set(newValue, forKey: key) }
    }
    
    // public var projectedValue:
    
    public struct Access {
        
        private let key: String
        
        private let defaultValue: Value
        
        private let store: NSUbiquitousKeyValueStore
        
        public init(key: String, defaultValue: Value, store: NSUbiquitousKeyValueStore) {
            self.key = key
            self.defaultValue = defaultValue
            self.store = store
        }
        
        public var exists: Bool { store.object(forKey: key) != nil }
        
        public func remove() { store.removeObject(forKey: key) }
        
        public func migrateFromUserDefaults(
            _ oldKey: String,
            local: UserDefaults = .standard,
            removeOld: Bool = true
        ) {
            guard store.object(forKey: key) == nil, let object = local.object(forKey: key) else {
                return
            }
            store.set(object, forKey: key)
            if removeOld { local.removeObject(forKey: oldKey) }
        }
        
        #if canImport(Combine)
        
        @available(iOS 13.0, *)
        public var publisher: AnyPublisher<Value, Never> {
            NotificationCenter.default
                .publisher(
                    for: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                    object: store
                )
                .map { _ in (store.object(forKey: key) as? Value) ?? defaultValue }
                .eraseToAnyPublisher()
        }
        
        #endif
        
    }
    
}

// MARK: - RawRepresentableUserDefaultKit（RawValue を保存）

/// `RawRepresentable`（例: `enum MyFlag: Int`）を **RawValue** として保存・復元する Property Wrapper
/// - 対応 RawValue: `String`, `Int`, `Bool`, `Double`, `Float`, `Data`
/// - 例:
///   ```swift
///   enum SortOrder: Int { case none, asc, desc }
///   @RawRepresentableUserDefaultKit(key: "sort", defaultValue: .none) var sort
///   ```
@propertyWrapper
public struct RawRepresentableUbiquitousKeyValueKit<Value: RawRepresentable> {
    public typealias Raw = Value.RawValue
    private let key: String
    private let defaultValue: Value
    private let store: NSUbiquitousKeyValueStore

    public init(key: String, defaultValue: Value, store: NSUbiquitousKeyValueStore = .default) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    public init(
        userDefaultKey: UserDefaultKey,
        defaultValue: Value,
        store: NSUbiquitousKeyValueStore = .default
    ) {
        self.key = userDefaultKey.key
        self.defaultValue = defaultValue
        self.store = store
    }

    public var wrappedValue: Value {
        get {
            if let raw = store.object(forKey: key) as? Raw,
                let value = Value(rawValue: raw)
            {
                return value
            }
            return defaultValue
        }
        set {
            store.set(newValue.rawValue, forKey: key)
        }
    }

    public var projectedValue: Access { Access(key: key, defaultValue: defaultValue, store: store) }

    public struct Access {
        private let key: String
        private let defaultValue: Value
        private let store: NSUbiquitousKeyValueStore

        public var exists: Bool { store.object(forKey: key) != nil }

        public init(key: String, defaultValue: Value, store: NSUbiquitousKeyValueStore) {
            self.key = key
            self.defaultValue = defaultValue
            self.store = store
        }

        public func remove() { store.removeObject(forKey: key) }

        public func migrate(from oldKey: String, removeOld: Bool = true) {
            guard store.object(forKey: key) == nil,
                let object = store.object(forKey: oldKey)
            else { return }
            store.set(object, forKey: key)
            if removeOld { store.removeObject(forKey: oldKey) }
        }

        #if canImport(Combine)
        @available(iOS 13.0, *)
        public var publisher: AnyPublisher<Value, Never> {
            NotificationCenter.default
                .publisher(for: UserDefaults.didChangeNotification, object: store)
                .map { _ in store.object(forKey: key) as? Raw }
                .map { raw in raw.flatMap(Value.init(rawValue:)) ?? defaultValue }
                .eraseToAnyPublisher()
        }
        #endif
    }
}

// 制約: `Raw` が Property List として保存できる代表型に限定（コンパイル時に安全性を担保）
extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == String {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Int {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Int64 {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Int32 {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Int16 {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Bool {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Double {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Float {}

extension RawRepresentableUbiquitousKeyValueKit where Value.RawValue == Data {}

// MARK: - CodableUbiquitousKeyValueKit
/// `NSUbiquitousKeyValueStore` に `Codable` 対応のデータを保存・復元できる Property Wrapper
/// iCloud KVS 同期を前提とした軽量データの永続化に向いている。
///
/// - 保存形式: JSON（`JSONEncoder` / `JSONDecoder`）
/// - 主な用途: 軽量な構造体・設定情報の共有（例: 設定やユーザープロファイルなど）
///
/// ⚠️ 注意事項
/// - iCloud KVS は容量制限（全体で約1MB）があるため、大きなデータを保存しないこと。
/// - 端末間での同期は即時ではなく非同期で行われる。
@propertyWrapper
public struct CodableUbiquitousKeyValueKit<Value: Codable> {
    
    // 保存キー
    private let key: String
    
    // デフォルト値（未保存時の初期値）
    private let defaultValue: Value
    
    // 保存先の iCloud Key-Value ストア
    private let store: NSUbiquitousKeyValueStore
    
    // エンコード・デコード用
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - 初期化（直接キー指定）
    public init(
        key: String,
        defaultValue: Value,
        store: NSUbiquitousKeyValueStore = .default,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - 初期化（UserDefaultKey でキー指定）
    public init(
        userDefaultKey: UserDefaultKey,
        defaultValue: Value,
        store: NSUbiquitousKeyValueStore = .default,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.init(
            key: userDefaultKey.key,
            defaultValue: defaultValue,
            store: store,
            encoder: encoder,
            decoder: decoder
        )
    }

    // MARK: - 値アクセス
    public var wrappedValue: Value {
        get {
            // iCloud KVS からデータを取得し、Codable 型にデコード
            guard let data = store.data(forKey: key),
                  let value = try? decoder.decode(Value.self, from: data)
            else {
                // データが存在しない or デコード失敗時はデフォルト値を返す
                return defaultValue
            }
            return value
        }
        set {
            // Codable 値を Data に変換して保存
            if let data = try? encoder.encode(newValue) {
                store.set(data, forKey: key)
            }
        }
    }

    // MARK: - $アクセス用プロパティ
    /// `$`付きでアクセスした際に利用できる補助機能（削除・存在確認など）
    public var projectedValue: Access {
        Access(key: key, defaultValue: defaultValue, store: store)
    }

    // MARK: - Access 構造体
    /// `remove()` や `exists` チェック、Combine Publisher を提供する補助構造体
    public struct Access {
        private let key: String
        private let defaultValue: Value
        private let store: NSUbiquitousKeyValueStore

        public init(key: String, defaultValue: Value, store: NSUbiquitousKeyValueStore) {
            self.key = key
            self.defaultValue = defaultValue
            self.store = store
        }

        /// 値が保存済みかどうかを判定
        public var exists: Bool { store.data(forKey: key) != nil }
        
        /// 保存済みデータを削除
        public func remove() { store.removeObject(forKey: key) }

        #if canImport(Combine)
        // MARK: - Combine Publisher
        /// iCloud KVS の変更を監視し、対応するキーの値を更新として受け取る Publisher
        @available(iOS 13.0, *)
        public var publisher: AnyPublisher<Value, Never> {
            NotificationCenter.default
                .publisher(
                    for: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                    object: store
                )
                .map { _ in
                    // 最新の値をデコードしてストリームで返す
                    guard let data = store.data(forKey: key),
                          let value = try? JSONDecoder().decode(Value.self, from: data)
                    else {
                        // データがない場合はデフォルト値を返す
                        return defaultValue
                    }
                    return value
                }
                .eraseToAnyPublisher()
        }
        #endif
    }
}
