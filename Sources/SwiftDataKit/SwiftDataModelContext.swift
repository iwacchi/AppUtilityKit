//
//  SwiftDataModelContext.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2026/06/13.
//

import Foundation
import SwiftData

/// SwiftData の `ModelContext` を扱うための薄いラッパ
/// - `SwiftDataActor.context` から生成して使用する
/// - `fetch` / `insert` / `delete` / `save` など、永続化操作を集約する
@available(iOS 17.0, *)
public final class SwiftDataModelContext {
    
    /// SwiftData の実際の操作対象となる `ModelContext`
    private let context: ModelContext
    
    /// 既存の `ModelContext` をラップ
    /// - Parameter context: `SwiftDataActor` が保持する `ModelContext`
    public init(_ context: ModelContext) {
        self.context = context
    }
    
    /// 指定した条件でモデルを取得
    /// - Parameter descriptor: 取得条件・ソート条件を持つ `FetchDescriptor`
    /// - Returns: 条件に一致したモデル配列
    public func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        return try context.fetch(descriptor)
    }
    
    /// 新規モデルを挿入
    /// - Parameter model: 挿入対象の SwiftData モデル
    public func insert<T: PersistentModel>(_ model: T) {
        context.insert(model)
    }
    
    /// 指定モデルを削除マーク
    /// - Parameter model: 削除対象の SwiftData モデル
    public func delete<T: PersistentModel>(_ model: T) {
        context.delete(model)
    }
    
    /// 未保存の変更があるかを返す
    public func hasChanges() -> Bool {
        context.hasChanges
    }
    
    /// 変更を永続化
    public func save() throws {
        try context.save()
    }
    
}
