//
//  Product+Extension.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

#if canImport(StoreKit)
import Foundation
import StoreKit

@available(iOS 15.0, *)
extension Product {
    
    /// 条件を満たす無料トライアルの導入オファーを返す（なければ nil）
    private func qualifyingFreeTrialOffer() async -> Product.SubscriptionOffer? {
        guard
            let sub = self.subscription,
            let offer = sub.introductoryOffer
        else { return nil }
        
        // 導入割引が「無料トライアル」であることを確認
        guard offer.paymentMode == .freeTrial else { return nil }
        
        // ユーザーが導入割引の適格であること
        guard await sub.isEligibleForIntroOffer else { return nil }
        
        return offer
    }
    
    /// 無料トライアルが“利用可能”か（導入割引が freeTrial かつ適格）
    func hasFreeTrialOfferAvailable() async -> Bool {
        await qualifyingFreeTrialOffer() != nil
    }
    
    /// 無料トライアルの期間（値+単位）を返す。なければ nil
    func freeTrialPeriod() async -> Product.SubscriptionPeriod? {
        await qualifyingFreeTrialOffer()?.period
    }

    // MARK: - プロモーションオファー（復帰ユーザー等）
    /// プロモーションオファーのうち、無料トライアル（paymentMode == .freeTrial）のみを返す
    /// - Note: 利用可否はサーバー署名やコード引き換え等の条件に依存。ここでは「製品に設定されているか」を判定するのみ
    func freeTrialPromotionalOffers() -> [Product.SubscriptionOffer] {
        guard let offers = self.subscription?.promotionalOffers else { return [] }
        return offers.filter { $0.paymentMode == .freeTrial }
    }
    
    /// プロモーションオファーとして「無料トライアルが設定されている」か（ユーザー適格性は未判定）
    func hasFreeTrialPromotionalOfferConfigured() -> Bool {
        !freeTrialPromotionalOffers().isEmpty
    }
    
    /// 導入割引（intro）優先で無料トライアル期間を取得。無ければプロモーションオファーから取得
    /// - Returns: 最初に見つかった無料トライアルの期間（値+単位）
    func freeTrialPeriodFromIntroOrPromo() async -> Product.SubscriptionPeriod? {
        if let intro = await qualifyingFreeTrialOffer()?.period {
            return intro
        }
        return freeTrialPromotionalOffers().first?.period
    }
    
    /// すべての無料トライアル期間候補（intro + promo）を返す（重複を含む可能性あり）
    func allFreeTrialPeriods() async -> [Product.SubscriptionPeriod] {
        var periods: [Product.SubscriptionPeriod] = []
        if let intro = await qualifyingFreeTrialOffer()?.period {
            periods.append(intro)
        }
        periods.append(contentsOf: freeTrialPromotionalOffers().map { $0.period })
        return periods
    }
    
    /// intro/promo を通して最も長い無料トライアル期間を返す（概算日数で比較）
    func bestFreeTrialPeriod(calendar: Calendar = .autoupdatingCurrent) async -> Product.SubscriptionPeriod? {
        let periods = await allFreeTrialPeriods()
        return periods.max(by: { $0.approximateDays(calendar: calendar) < $1.approximateDays(calendar: calendar) })
    }

    /// 指定開始日から、無料トライアル終了日時を返す（最長の期間で計算）
    func freeTrialEndDate(from start: Date, calendar: Calendar = .autoupdatingCurrent) async -> Date? {
        guard let period = await bestFreeTrialPeriod(calendar: calendar) else { return nil }
        return period.endDate(from: start, calendar: calendar)
    }

    /// UI向けの無料トライアルバッジ文字列（例: ja → "7日 無料", en → "Free for 7 days"）
    func localizedFreeTrialBadge(
        unitsStyle: DateComponentsFormatter.UnitsStyle = .short,
        locale: Locale = .autoupdatingCurrent
    ) async -> String? {
        guard let period = await bestFreeTrialPeriod() else { return nil }
        let span = period.localizedDescription(unitsStyle: unitsStyle, locale: locale)
        if let code = locale.languageCode, code == "ja" {
            return "\(span) 無料"
        } else {
            return "Free for \(span)"
        }
    }
    
}

// MARK: - SubscriptionPeriod Utilities
@available(iOS 15.0, *)
extension Product.SubscriptionPeriod {
    
    /// `SubscriptionPeriod` を `DateComponents` へ変換（UI表示やフォーマットに便利）
    public func toDateComponents() -> DateComponents {
        switch unit {
        case .day:   return DateComponents(day: value)
        case .week:  return DateComponents(weekOfYear: value)
        case .month: return DateComponents(month: value)
        case .year:  return DateComponents(year: value)
        @unknown default:
            return DateComponents()
        }
    }
    
    /// 期間の概算日数（表示のソート等に利用）。カレンダー計算で近似
    public func approximateDays(calendar: Calendar = .autoupdatingCurrent) -> Int {
        let start = Date()
        guard let end = calendar.date(byAdding: toDateComponents(), to: start) else { return value }
        let diff = calendar.dateComponents([.day], from: start, to: end)
        return diff.day ?? value
    }
    
    /// ローカライズされた期間文字列（例: "7日", "1週間", "3か月", "1年"）
    /// - Parameters:
    ///   - unitsStyle: `.short` / `.full` など
    ///   - locale: 明示しなければ `autoupdatingCurrent`
    public func localizedDescription(
        unitsStyle: DateComponentsFormatter.UnitsStyle = .short,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let comps = toDateComponents()
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = unitsStyle
        formatter.collapsesLargestUnit = false
        formatter.maximumUnitCount = 1
        var cal = Calendar.autoupdatingCurrent
        cal.locale = locale
        formatter.calendar = cal
        formatter.allowedUnits = {
            switch unit {
            case .day:   return [.day]
            case .week:  return [.weekOfMonth, .weekOfYear]
            case .month: return [.month]
            case .year:  return [.year]
            @unknown default: return []
            }
        }()
        if let s = formatter.string(from: comps) {
            return s
        }
        // Fallback when DateComponentsFormatter cannot produce output
        return fallbackLocalizedDescription(locale: locale)
    }
    
    /// フォーマッタが生成できない場合の簡易ローカライズ文字列
    private func fallbackLocalizedDescription(locale: Locale) -> String {
        let lang = locale.languageCode ?? Locale.autoupdatingCurrent.languageCode ?? "en"
        switch lang {
        case "ja":
            switch unit {
            case .day:   return "\(value)日"
            case .week:  return "\(value)週"
            case .month: return "\(value)か月"
            case .year:  return "\(value)年"
            @unknown default: return "\(value)"
            }
        default:
            let unitEn: String = {
                switch unit {
                case .day:   return value == 1 ? "day"   : "days"
                case .week:  return value == 1 ? "week"  : "weeks"
                case .month: return value == 1 ? "month" : "months"
                case .year:  return value == 1 ? "year"  : "years"
                @unknown default: return ""
                }
            }()
            return "\(value) \(unitEn)"
        }
    }

    /// 期間の終了日時（`start` にこの期間を加算した日時）
    public func endDate(from start: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        calendar.date(byAdding: toDateComponents(), to: start)
    }

    /// この期間に対応する `DateInterval` を返す
    public func interval(from start: Date, calendar: Calendar = .autoupdatingCurrent) -> DateInterval? {
        guard let end = endDate(from: start, calendar: calendar) else { return nil }
        return DateInterval(start: start, end: end)
    }
}
#endif
