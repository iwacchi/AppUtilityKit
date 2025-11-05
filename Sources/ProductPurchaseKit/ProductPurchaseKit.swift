//
//  ProductPurchaseKit.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/17.
//

#if canImport(StoreKit)
import Foundation
import StoreKit

/// StoreKit2 の購買フロー統合。検証済みトランザクションの受領→付与→finish までを管理
@available(iOS 15.0, *)
public final class ProductPurchaseKit: @unchecked Sendable {

    /// アプリ側の権利適用ロジック（@MainActor）。呼び出し時にメインへ自動ホップ
    internal var executor: ProductPurchaseExecutor?

    public enum ProductPurchaseError: Error {

        /// 署名検証に失敗（`Transaction` が未検証）
        case verificationError(
            StoreKit.Transaction,
            VerificationResult<Transaction>.VerificationError
        )

        /// ユーザーが購入フローをキャンセル
        case userCancelled

        /// Ask to Buy 等で保留。後で `Transaction.updates` に到着
        case pending

        /// ドキュメント外の将来拡張など
        case unknown

    }

    public static let shared = ProductPurchaseKit()

    private init() {}

    /// 権利適用/解除ロジックの実装を注入
    /// - Important: できるだけ早期（起動直後）に呼び出すこと
    public func configure(_ setExecutor: @escaping () -> ProductPurchaseExecutor) {
        self.executor = setExecutor()
    }

    /// 単一プロダクトの購入を実行
    /// - Parameters:
    ///   - product: 対象の `Product`
    ///   - isExecute: `true` の場合、付与処理（`executor.upgradeExecute`）と `finish()` まで実行
    public func purchase(
        for product: Product,
        isExecute: Bool = true
    ) async throws -> Result<StoreKit.Transaction, ProductPurchaseError> {
        let purchaseResult = try await product.purchase()
        switch purchaseResult {
        case .success(let verificationResult):
            switch verificationResult {
            case .unverified(let transaction, let verificationError):
                return .failure(.verificationError(transaction, verificationError))
            case .verified(let transaction):
                // isExecute=true の場合は、購入直後に権利適用と finish() をまとめて行う
                // ※ executor は @MainActor のため、自動的にメインアクターへホップして実行される
                if isExecute {
                    await executor?.upgradeExecute(transactions: [transaction])
                    await transaction.finish()
                }
                return .success(transaction)
            }
        case .userCancelled:
            return .failure(.userCancelled)
        case .pending:
            return .failure(.pending)
        @unknown default:
            return .failure(.unknown)
        }
    }

    /// 購入をオプション付きで実行（AppAccountToken/プロモーション/PresentedOn 等）
    public func purchase(
        product: Product,
        options: Set<Product.PurchaseOption>,
        isExecute: Bool = true
    ) async throws -> Result<StoreKit.Transaction, ProductPurchaseError> {
        let purchaseResult = try await product.purchase(options: options)
        switch purchaseResult {
        case .success(let verificationResult):
            switch verificationResult {
            case .unverified(let transaction, let verificationError):
                return .failure(.verificationError(transaction, verificationError))
            case .verified(let transaction):
                // オプション付き購入でもロジックは同一。検証済みトランザクションを権利適用し、すぐ finish()
                if isExecute {
                    await executor?.upgradeExecute(transactions: [transaction])
                    await transaction.finish()
                }
                return .success(transaction)
            }
        case .userCancelled:
            return .failure(.userCancelled)
        case .pending:
            return .failure(.pending)
        @unknown default:
            return .failure(.unknown)
        }
    }

    /// 現在のエンタイトルメントを走査し、必要に応じて付与/剥奪を実行
    public func currentPurchasedTransaction(isExecute: Bool = true) async -> Set<Transaction> {
        // 現在有効なエンタイトルメントを App Store から走査（返金/失効を除外）
        var purchasedTransactions: Set<Transaction> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            // 返金(Revocation) or 失効(Expiration) が無いものだけを「有効」と判定
            // ※ revocationDate/expirationDate は将来日時の可能性もあるため現在時刻と比較
            if transaction.revocationDate == nil {
                purchasedTransactions.insert(transaction)
            }
        }
        // 実行オプションに応じて、権利の付与/無効化を適用
        if isExecute {
            if purchasedTransactions.isEmpty {
                // 付与対象が無い場合は、権利を無効化（返金/期限切れ等を反映）
                await executor?.downgradeExecute()
            } else {
                // まとめて付与/更新を適用
                await executor?.upgradeExecute(transactions: Array(purchasedTransactions))
            }
        }
        return purchasedTransactions
    }

    // MARK: - Utilities

    /// このデバイス/アカウントで支払いが許可されているか
    public var canMakePayments: Bool {
        AppStore.canMakePayments
    }

    /// 未完了トランザクションを回収して処理（起動直後など）
    public func processUnfinishedTransactions(isExecute: Bool = true) async {
        // 未完了(unfinished) のトランザクションを全回収して、必要に応じて付与→finish まで行う
        var purchasedTransactions: [Transaction] = []
        for await result in StoreKit.Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            // 返金済み(Revocation) は付与対象から除外
            if let revoked = transaction.revocationDate, revoked <= Date() {
                
            // 期限切れ(Expiration) も除外
            } else if let exp = transaction.expirationDate, exp <= Date() {
                
            // それ以外は付与対象として確保
            } else {
                purchasedTransactions.append(transaction)
            }
            // 収集したら必ず finish() して重複処理を防ぐ
            await transaction.finish()
        }
        // 収集結果に応じて権利を反映
        if isExecute {
            if purchasedTransactions.isEmpty {
                await executor?.downgradeExecute()
            } else {
                await executor?.upgradeExecute(transactions: purchasedTransactions)
            }
        }
    }

    /// 指定 productID の購入状態を簡易判定（返金/失効も考慮）
    public func isPurchased(productID: String) async -> Bool {
        if let result = await StoreKit.Transaction.latest(for: productID) {
            if case .verified(let txn) = result {
                if let revoked = txn.revocationDate, revoked <= Date() { return false }
                if let exp = txn.expirationDate, exp <= Date() { return false }
                return true
            }
        }
        return false
    }

    /// 「購入を復元」。App Store と同期し、現在のエンタイトルメントを適用
    public func restorePurchases() async throws {
        try await AppStore.sync()
        let _ = await currentPurchasedTransaction()
    }

    // MARK: - Observation
    /// `Transaction.updates` を監視開始
    /// - Parameters:
    ///   - onUpdates: 受領した検証済みトランザクションをコールバック（ログ/トラッキング等）
    ///   - isExecute: true の場合、`executor` に付与/剥奪させた上で `finish()` まで行う
    /// - Returns: 中断用の `Task`。破棄時は `cancel()` を呼ぶ
    @discardableResult
    public func startObservingTransactionUpdates(
        onUpdates: @escaping @Sendable ([Transaction]) async -> Void,
        isExecute: Bool = true
    ) -> Task<Void, Never> {
        Task(priority: .background) {
            // Transaction.updates を常時監視し、検証済みの新着をバッファして finish()
            var purchasedTransactions: Set<Transaction> = []
            for await result in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }
                // 返金済みは除外
                if let revoked = transaction.revocationDate, revoked <= Date() {
                    
                // 有効期限切れも除外
                } else if let exp = transaction.expirationDate, exp <= Date() {
                    
                // それ以外は有効購入として保持
                } else {
                    purchasedTransactions.insert(transaction)
                }
                // 受領したら必ず finish() して二重処理を回避
                await transaction.finish()
            }
            // コールバック（ログ送出・分析用途など）
            await onUpdates(Array(purchasedTransactions))
            // 実行フラグに応じてエンタイトルメントを反映
            if isExecute {
                if purchasedTransactions.isEmpty {
                    await executor?.downgradeExecute()
                } else {
                    await executor?.upgradeExecute(transactions: Array(purchasedTransactions))
                }
            }
        }
    }

}
#endif
