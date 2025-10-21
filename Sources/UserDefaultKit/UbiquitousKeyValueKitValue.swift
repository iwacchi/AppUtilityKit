//
//  UbiquitousKeyValueKitValue.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/10/21.
//

import Foundation

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
