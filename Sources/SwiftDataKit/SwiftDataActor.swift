//
//  SwiftDataActor.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2026/06/13.
//

import Foundation
import SwiftData

/// SwiftData 用のグローバルアクター
/// - ライブラリ側の Source クラス。実アプリ側で `ModelContainer` を注入して使用する
/// - 直列実行: SwiftData 標準の `DefaultSerialModelExecutor` に委譲する
/// - 使い方:
///   1) アプリ起動時に `SwiftDataActor.configureShared(container:)` を呼ぶ
///   2) 以降は `SwiftDataActor.shared` 経由で `ModelActor` として利用
@available(iOS 17.0, *)
@globalActor
public actor SwiftDataActor: ModelActor {
    
    /// ライブラリ利用側で DI するための共有インスタンス保持
    nonisolated(unsafe)
    private static var _shared: SwiftDataActor?
    
    /// 共有の `SwiftDataActor`
    /// - Note: 未設定時は早期に気付けるよう `preconditionFailure` にする
    public static var shared: SwiftDataActor {
        guard let actor = _shared else {
            preconditionFailure(
                "SwiftDataActor is not configured. Call SwiftDataActor.configureShared(container:) at app launch."
            )
        }
        return actor
    }
    
    /// SwiftData の永続化コンテナ
    /// - Note: `ModelActor` 準拠に必要なプロパティ
    nonisolated public let modelContainer: ModelContainer
    
    /// SwiftData の直列実行を担う Executor
    /// - Note: `ModelActor` 準拠に必要なプロパティ
    nonisolated public let modelExecutor: any ModelExecutor
    
    /// DI 用の初期化子（テスト/別ストア差し替えも想定）
    /// - Parameter modelContainer: アプリ側で生成した `ModelContainer`
    private init(modelContainer: ModelContainer) {
        let modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
    }
    
    /// アプリ側で最初に呼び出し、SwiftData の `ModelContainer` を注入
    /// - Parameter container: アプリ側で生成した `ModelContainer`
    public static func configureShared(container: ModelContainer) {
        _shared = .init(modelContainer: container)
    }
    
    /// `ModelContext` を `SwiftDataActor` 配下で扱うための薄いラッパ
    /// - Note: 直接 `ModelContext` を外に出さず、専用ラッパ経由で操作する
    public var context: SwiftDataModelContext {
        .init(modelContext)
    }
    
}
