//
//  View+Extension.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

#if canImport(SwiftUI)
public import SwiftUI

@available(iOS 13.0, *)
extension View {

    /// 条件が `true` の場合に指定した変換を適用します。
    /// - Parameters:
    ///   - condition: 変換を適用するかどうかの判定。
    ///   - transform: 条件が成立した場合に適用するビュー変換クロージャ。
    /// - Returns: `condition` が `true` のとき `transform(self)`、それ以外は元のビュー (`self`)。
    @ViewBuilder
    public func `if`<Content: View>(
        _ condition: Bool,
        @ViewBuilder transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// 常に指定した変換を適用します（条件付け無し）。
    /// このオーバーロードは、引数なしで `transform` を直接適用したい場合に便利です。
    /// - Parameter transform: ビューに対して適用する変換クロージャ。
    /// - Returns: `transform(self)` を適用したビュー。
    @ViewBuilder
    public func `if`<Content: View>(@ViewBuilder transform: (Self) -> Content) -> some View {
        transform(self)
    }

}
#endif
