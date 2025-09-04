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
        case verificationError(StoreKit.Transaction, VerificationResult<Transaction>.VerificationError)
        
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
        for product: Product, isExecute: Bool = true
    ) async throws -> Result<StoreKit.Transaction, ProductPurchaseError> {
        let purchaseResult = try await product.purchase()
        switch purchaseResult {
        case .success(let verificationResult):
            switch verificationResult {
            case .unverified(let transaction, let verificationError):
                return .failure(.verificationError(transaction, verificationError))
            case .verified(let transaction):
                if isExecute {
                    await executor?.upgradeExecute(transaction: transaction)
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
                if isExecute {
                    await executor?.upgradeExecute(transaction: transaction)
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
        var purchasedTransactions: Set<Transaction> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                purchasedTransactions.insert(transaction)
            }
        }
        if isExecute {
            if purchasedTransactions.isEmpty {
                await executor?.downgradeExecute()
            } else {
                for transaction in purchasedTransactions {
                    await executor?.upgradeExecute(transaction: transaction)
                }
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
    @discardableResult
    public func processUnfinishedTransactions() async -> [Transaction] {
        var processed: [Transaction] = []
        for await result in StoreKit.Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            if let revoked = transaction.revocationDate, revoked <= Date() {
                await executor?.downgradeExecute()
            } else if let exp = transaction.expirationDate, exp <= Date() {
                await executor?.downgradeExecute()
            } else {
                await executor?.upgradeExecute(transaction: transaction)
            }
            await transaction.finish()
            processed.append(transaction)
        }
        return processed
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
        onUpdates: @escaping @Sendable (Transaction) async -> Void,
        isExecute: Bool = true
    ) -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }
                await onUpdates(transaction)
                if isExecute {
                    if let revoked = transaction.revocationDate, revoked <= Date() {
                        await executor?.downgradeExecute()
                    } else if let exp = transaction.expirationDate, exp <= Date() {
                        await executor?.downgradeExecute()
                    } else {
                        await executor?.upgradeExecute(transaction: transaction)
                    }
                    await transaction.finish()
                }
            }
        }
    }

}
#endif
