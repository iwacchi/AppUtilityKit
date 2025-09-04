//
//  CoreDataExecutor.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

import Foundation
import CoreData

/// CoreData 用の `SerialExecutor`
/// - ライブラリ側の Source クラス。実アプリ側で `PersistenceProtocol` 実装を注入して使用する
/// - 使い方:
///   1) アプリ起動時に `CoreDataExecutor.configureShared(persistence:)` を呼ぶ
///   2) 以降は `CoreDataExecutor.shared` / `sharedUnownedExecutor` を利用
@available(iOS 17.0, *)
final public class CoreDataExecutor: SerialExecutor {
    
    /// 直列実行対象となる Core Data コンテキストを保持するラッパ
    private let container: ManagedObjectContextContainer
    
    /// `NSManagedObjectContext` を `CoreDataActor` 配下で扱うための薄いラッパ
    @CoreDataActor
    public var context: ManagedObjectContext {
        .init(container.context)
    }
    
    /// DI 用の初期化子（テスト/別ストア差し替えも想定）
    internal init(container: ManagedObjectContextContainer) {
        self.container = container
    }
    
    /// `SerialExecutor` 準拠: 受け取ったジョブを直列キューに投入して実行
    /// - 実行順序は `ManagedObjectContextContainer.queue` → `NSManagedObjectContext.perform(_:)` の二段直列
    public func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)
        container.perform {
            unownedJob.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }
    
}

@available(iOS 17.0, *)
extension CoreDataExecutor{
    
    // MARK: - Shared (DI required)
    /// ライブラリ利用側で DI するための共有インスタンス保持
    nonisolated(unsafe)
    private static var _shared: CoreDataExecutor?
    
    /// アプリ側で最初に呼び出し、ユーザー実装の `PersistenceProtocol` を注入
    public static func configureShared(container: NSPersistentContainer) {
        _shared = CoreDataExecutor(container: ManagedObjectContextContainer(persistentContainer: container))
    }
    
    /// 共有の `CoreDataExecutor`
    /// - Note: 未設定時は早期に気付けるよう `preconditionFailure` にする
    public static var shared: CoreDataExecutor {
        guard let s = _shared else {
            preconditionFailure("CoreDataExecutor is not configured. Call CoreDataExecutor.configureShared(container:) at app launch.")
        }
        return s
    }
    
    /// 共有の `UnownedSerialExecutor`（`SerialExecutor` 準拠 API が要求する場合に使用）
    public static var sharedUnownedExecutor: UnownedSerialExecutor {
        shared.asUnownedSerialExecutor()
    }
}
