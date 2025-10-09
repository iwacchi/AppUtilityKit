//
//  UserDefaultKit.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

public import Foundation

#if canImport(Combine)
public import Combine
#endif
#if canImport(SwiftUI)
internal import SwiftUI
#endif

// MARK: - Typed Key Protocol
/// 型安全なキー定義用プロトコル（enum などで実装）
/// - 例:
///   ```
///   enum SettingKey: UserDefaultKey {
///       case hasOnboarded
///       var key: String { "hasOnboarded" }
///   }
///   ```
/// - Note: App Group を使う場合は `store:` に `UserDefaults(suiteName:)` を渡す
public protocol UserDefaultKey {

    /// 実際に保存に使用するキー文字列
    var key: String { get }

}

// MARK: - UserDefaultKit (Property List 型向け)

/// ⚠️ 注意: `enum`（`Int` などの RawValue ベース）をこのラッパーに直接保存すると、
/// UserDefaults が受け付けるのは Property List 型（`String/Int/Double/Bool/Data/Array/Dictionary/Date/NSNumber` 等）のみのため、
/// `set` 時に *non-property list object* でクラッシュします。`CodableUserDefaultKit` か、下の `RawRepresentableUserDefaultKit` を使ってください。
///
/// UserDefaults を型安全に扱うための Property Wrapper（Property List 準拠型向け）
/// - 例:
///   ```
///   @UserDefaultKit(key: "hasOnboarded", defaultValue: false) var hasOnboarded
///   @UserDefaultKit(key: "username", defaultValue: "") var username
///   ```
/// - 注意: `Codable` な独自型は `CodableUserDefaultKit` を使用
@propertyWrapper
public struct UserDefaultKit<Value> {

    /// 保存に使用するキー
    private let key: String

    /// 値が未登録の時に返すデフォルト値
    private let defaultValue: Value

    /// 対象の `UserDefaults`（既定は `.standard`）
    private let store: UserDefaults

    /// 初期化
    /// - Parameters:
    ///   - key: 保存キー
    ///   - defaultValue: 登録が無い時に返す値
    ///   - store: 対象の `UserDefaults`（App Group の場合は `UserDefaults(suiteName:)` を渡す）
    public init(key: String, defaultValue: Value, store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    /// 型安全キーによる初期化
    /// - Parameters:
    ///   - userDefaultKey: `UserDefaultKey` に準拠したキー（enum など）
    ///   - defaultValue: 登録が無い時に返す値
    ///   - store: 対象の `UserDefaults`
    public init(
        userDefaultKey: UserDefaultKey,
        defaultValue: Value,
        store: UserDefaults = .standard
    ) {
        self.key = userDefaultKey.key
        self.defaultValue = defaultValue
        self.store = store
    }

    /// 値の読み書き（未登録時は `defaultValue` を返す）
    public var wrappedValue: Value {
        get {
            store.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            store.set(newValue, forKey: key)
        }
    }

    /// 付随操作（削除/存在チェック/移行/監視）を提供
    public var projectedValue: Access {
        Access(key: key, defaultValue: defaultValue, store: store)
    }

    /// 付随操作用のアクセサ（`$variable` から利用）
    public struct Access {

        /// 対象キー
        private let key: String

        /// 未登録時のフォールバック値
        private let defaultValue: Value

        /// 対象ストア
        private let store: UserDefaults

        /// キーの存在有無
        public var exists: Bool {
            store.object(forKey: key) != nil
        }

        /// 初期化
        public init(key: String, defaultValue: Value, store: UserDefaults) {
            self.key = key
            self.defaultValue = defaultValue
            self.store = store
        }

        /// 値を削除（キーを除去）
        public func remove() {
            store.removeObject(forKey: key)
        }

        /// 別キーから値を移行（新キーが未設定の時のみ）。移行後に旧キーを削除するか選べる
        public func migrate(from oldKey: String, removeOld: Bool = true) {
            guard store.object(forKey: key) == nil,
                let object = store.object(forKey: oldKey)
            else {
                return
            }
            store.set(object, forKey: key)
            if removeOld {
                store.removeObject(forKey: oldKey)
            }
        }

        #if canImport(Combine)
        /// 値の変更を購読（`UserDefaults.didChangeNotification` を利用）
        @available(iOS 13.0, *)
        public var publisher: AnyPublisher<Value, Never> {
            NotificationCenter.default
                .publisher(for: UserDefaults.didChangeNotification, object: store)
                .map { _ in
                    (store.object(forKey: key) as? Value) ?? defaultValue
                }
                .eraseToAnyPublisher()
        }
        #endif

    }

}

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

// MARK: - CodableUserDefaultKit（Codable 型向け）

/// `Codable` 型を JSON で保存・復元する Property Wrapper
/// - 注意: デコード失敗時は `defaultValue` を返す
@propertyWrapper
public struct CodableUserDefaultKit<Value: Codable> {

    /// 保存キー
    private let key: String

    /// 未登録時に返す値
    private let defaultValue: Value

    /// 対象ストア
    private let store: UserDefaults

    /// JSON エンコーダ（差し替え可能）
    private let encoder: JSONEncoder

    /// JSON デコーダ（差し替え可能）
    private let decoder: JSONDecoder

    /// 初期化
    /// - Parameters:
    ///   - key: 保存キー
    ///   - defaultValue: 登録が無い時に返す値
    ///   - store: 対象の `UserDefaults`
    ///   - encoder: JSON エンコーダ（既定は `JSONEncoder()`）
    ///   - decoder: JSON デコーダ（既定は `JSONDecoder()`）
    public init(
        key: String,
        defaultValue: Value,
        store: UserDefaults = .standard,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
        self.encoder = encoder
        self.decoder = decoder
    }

    /// 型安全キーによる初期化（Codable）
    /// - Parameters:
    ///   - userDefaultKey: `UserDefaultKey` に準拠したキー
    ///   - defaultValue: 登録が無い時に返す値
    ///   - store: 対象の `UserDefaults`
    ///   - encoder: JSON エンコーダ
    ///   - decoder: JSON デコーダ
    public init(
        userDefaultKey: UserDefaultKey,
        defaultValue: Value,
        store: UserDefaults = .standard,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.key = userDefaultKey.key
        self.defaultValue = defaultValue
        self.store = store
        self.encoder = encoder
        self.decoder = decoder
    }

    /// 値の読み書き（失敗時は `defaultValue` を返す）
    public var wrappedValue: Value {
        get {
            guard let data = store.data(forKey: key) else {
                return defaultValue
            }
            do {
                return try decoder.decode(Value.self, from: data)
            } catch {
                return defaultValue
            }
        }
        set {
            do {
                let data = try encoder.encode(newValue)
                store.set(data, forKey: key)
            } catch {
                // エンコード失敗時は何もしない（呼び出し側で適宜ハンドリング）
            }
        }
    }

    /// 付随操作（削除/存在チェック/移行/監視）を提供
    public var projectedValue: Access {
        Access(key: key, defaultValue: defaultValue, store: store)
    }

    /// 付随操作用のアクセサ（`$variable` から利用）
    public struct Access {

        /// 対象キー
        private let key: String

        /// 未登録時のフォールバック値
        private let defaultValue: Value

        /// 対象ストア
        private let store: UserDefaults

        /// エンコード済みデータの存在有無
        public var exists: Bool {
            return store.data(forKey: key) != nil
        }

        /// 初期化
        public init(key: String, defaultValue: Value, store: UserDefaults) {
            self.key = key
            self.defaultValue = defaultValue
            self.store = store
        }

        /// 値を削除（キーを除去）
        public func remove() {
            store.removeObject(forKey: key)
        }

        /// 別キーから値を移行（新キーが未設定の時のみ）。移行後に旧キーを削除するか選べる
        public func migrate(from oldKey: String, removeOld: Bool = true) {
            guard store.data(forKey: key) == nil else {
                return
            }
            if let data = store.data(forKey: oldKey) {
                store.set(data, forKey: key)
                if removeOld {
                    store.removeObject(forKey: oldKey)
                }
            }
        }

        #if canImport(Combine)
        /// 値の変更を購読（`UserDefaults.didChangeNotification` を利用）。デコード失敗時は `defaultValue`
        @available(iOS 13.0, *)
        public var publisher: AnyPublisher<Value, Never> {
            NotificationCenter.default
                .publisher(for: UserDefaults.didChangeNotification, object: store)
                .compactMap { _ in store.data(forKey: key) }
                .map { data in
                    (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
                }
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
public struct RawRepresentableUserDefaultKit<Value: RawRepresentable> {
    public typealias Raw = Value.RawValue
    private let key: String
    private let defaultValue: Value
    private let store: UserDefaults

    public init(key: String, defaultValue: Value, store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    public init(
        userDefaultKey: UserDefaultKey,
        defaultValue: Value,
        store: UserDefaults = .standard
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
        private let store: UserDefaults

        public var exists: Bool { store.object(forKey: key) != nil }

        public init(key: String, defaultValue: Value, store: UserDefaults) {
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
extension RawRepresentableUserDefaultKit where Value.RawValue == String {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Int {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Int64 {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Int32 {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Int16 {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Bool {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Double {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Float {}

extension RawRepresentableUserDefaultKit where Value.RawValue == Data {}

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

public enum UbiquitousKeyValueKitValue {
    
    @discardableResult
    public static func synchronize(_ store: NSUbiquitousKeyValueStore = .default) -> Bool {
        store.synchronize()
    }
    
    @inlinable
    public static func value(for key: String, store: NSUbiquitousKeyValueStore = .default) -> Any? {
        store.object(forKey: key)
    }
    
    @inlinable
    public static func value(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Any? {
        store.object(forKey: userDefaultKey.key)
    }
    
    @inlinable
    public static func set(
        _ value: Any?,
        for key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) {
        store.set(value, forKey: key)
    }
    
    @inlinable
    public static func set(
        _ value: Any?,
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) {
        store.set(value, forKey: userDefaultKey.key)
    }
    
    @inlinable
    public static func longLong(
        for key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Int64 {
        store.longLong(forKey: key)
    }
    
    @inlinable
    public static func longLong(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Int64 {
        store.longLong(forKey: userDefaultKey.key)
    }
    
    @inlinable
    public static func bool(
        for key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Bool {
        store.bool(forKey: key)
    }
    
    @inlinable
    public static func bool(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Bool {
        store.bool(forKey: userDefaultKey.key)
    }
    
    @inlinable
    public static func double(
        for key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Double {
        store.double(forKey: key)
    }
    
    @inlinable
    public static func double(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Double {
        store.double(forKey: userDefaultKey.key)
    }
    
    @inlinable
    public static func string(
        for key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) -> String? {
        store.string(forKey: key)
    }
    
    @inlinable
    public static func string(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) -> String? {
        store.string(forKey: userDefaultKey.key)
    }
    
    @inlinable
    public static func array<T>(
        for key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) -> [T]? {
        store.array(forKey: key) as? [T]
    }
    
    @inlinable
    public static func array<T>(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) -> [T]? {
        store.array(forKey: userDefaultKey.key) as? [T]
    }
    
    @inlinable
    public static func data(
        for key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Data? {
        store.data(forKey: key)
    }
    
    @inlinable
    public static func data(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) -> Data? {
        store.data(forKey: userDefaultKey.key)
    }
    
    @inlinable
    public static func removeObject(for key: String, store: NSUbiquitousKeyValueStore = .default) {
        store.removeObject(forKey: key)
    }
    
    @inlinable
    public static func removeObject(
        for userDefaultKey: UserDefaultKey,
        store: NSUbiquitousKeyValueStore = .default
    ) {
        store.removeObject(forKey: userDefaultKey.key)
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
