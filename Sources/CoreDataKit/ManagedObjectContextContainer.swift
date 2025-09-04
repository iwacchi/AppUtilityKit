//
//  ManagedObjectContextContainer.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

/// `NSPersistentContainer` から派生したバックグラウンド `NSManagedObjectContext` を保持・直列実行するためのコンテナ
/// - ポリシー: `mergeByPropertyObjectTrump` / `automaticallyMergesChangesFromParent = true`

import Foundation
import CoreData

public final class ManagedObjectContextContainer: @unchecked Sendable {
    
    private let persistentContainer: NSPersistentContainer
    
    /// 呼び出し側からの投入順を保証するためのシリアルキュー
    internal let queue = DispatchQueue(label: "NSManagedObjectContextContainerQueue")
    
    /// バックグラウンド用 `NSManagedObjectContext`（必要時に初期化）
    internal lazy var context: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }()
    
    public init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    /// 直列キュー→MOC.perform の順に実行（投入順序を安定化）
    internal func perform(_ block: @escaping @Sendable () -> Void) {
        queue.async {
            self.context.perform(block)
        }
    }
    
}
