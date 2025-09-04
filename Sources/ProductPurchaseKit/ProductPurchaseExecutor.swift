//
//  ProductPurchaseExecutor.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

#if canImport(StoreKit)
import Foundation
import StoreKit

@available(iOS 15.0, *)
// MARK: - Protocol
/// 課金トランザクションの結果に応じてアプリ側の権利を適用/解除する実装ポイント
/// - Note: UI更新や状態反映を伴うためメインアクターで実行する
@MainActor public protocol ProductPurchaseExecutor {
    
    /// 課金の付与処理（非消耗/サブスクなどの権利反映）
    /// - Parameter transaction: 検証済みトランザクション
    func upgradeExecute(transaction: Transaction) async
    
    /// 権利の剥奪処理（返金/失効/ダウングレード時）
    func downgradeExecute() async

}
#endif
