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
/// StoreKitの購入トランザクション結果に応じて、アプリ内の権利（非消耗/サブスクリプション等）を付与・更新・剥奪する実装ポイント。
/// - Important: UI更新や状態反映を行うため、メインアクター上で実行されます。
@MainActor public protocol ProductPurchaseExecutor {

    /// 権利の付与・更新処理（非消耗/サブスクリプション等の有効化）。
    /// - Parameter transactions: 検証済みのトランザクション配列（複数件を想定）。
    func upgradeExecute(transactions: [Transaction]) async

    /// 権利の無効化処理（返金・失効・ダウングレードなどで権利が使えなくなった場合）。
    func downgradeExecute() async

}
#endif
