//
//  ManagedObjectContext.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

import CoreData
import Foundation

/// Core Data の `NSManagedObjectContext` を `@CoreDataActor` 配下で安全に扱うための薄いラッパ
@available(iOS 17.0, *)
@CoreDataActor
public final class ManagedObjectContext {

    private let context: NSManagedObjectContext

    /// 既存の `NSManagedObjectContext` をラップ
    public init(_ context: NSManagedObjectContext) {
        self.context = context
    }

    /// フェッチを実行
    public func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        try context.fetch(request)
    }

    /// 新規 `NSManagedObject` を挿入して返す
    public func create<T: NSManagedObject>() -> T {
        T.init(context: context)
    }

    /// 指定オブジェクトを削除マーク
    public func delete(_ object: NSManagedObject) {
        context.delete(object)
    }

    /// 変更の有無
    public func hasChanges() -> Bool {
        context.hasChanges
    }

    /// 変更を永続化
    public func save() throws {
        try context.save()
    }

}
