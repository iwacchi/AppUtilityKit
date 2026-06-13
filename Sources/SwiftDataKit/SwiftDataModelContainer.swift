//
//  SwiftDataModelContainer.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2026/06/13.
//

import Foundation
import SwiftData

/// SwiftData の `ModelContainer` を保持するための薄いコンテナ
/// - ライブラリ側で `ModelContainer` を保持・受け渡しするために使用する
/// - Note: SwiftData 側の直列実行は `SwiftDataActor` が保持する `DefaultSerialModelExecutor` に委譲する
@available(iOS 17.0, *)
public final class SwiftDataModelContainer: @unchecked Sendable {
    
    /// SwiftData の永続化コンテナ
    internal let modelContainer: ModelContainer
    
    /// DI 用の初期化子
    /// - Parameter modelContainer: アプリ側で生成した `ModelContainer`
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
}
