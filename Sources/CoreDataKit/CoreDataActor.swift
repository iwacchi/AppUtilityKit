//
//  CoreDataActor.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

import Foundation

/// Core Data 用のグローバルアクター
/// - 直列実行: 実体は `CoreDataExecutor` に紐づくシリアルエグゼキュータ
/// - 使い方: `CoreDataExecutor.configureShared(container:)` をアプリ起動直後に呼び、その後このアクター配下でDB操作を行う
@available(iOS 17.0, *)
@globalActor
public actor CoreDataActor {
    
    public static let shared = CoreDataActor()
    
    /// このアクターが利用する `UnownedSerialExecutor`
    /// - Note: 未設定時は `CoreDataExecutor.sharedUnownedExecutor` の構築で `preconditionFailure`
    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        CoreDataExecutor.sharedUnownedExecutor
    }
    
}
