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
    ///   - transform: 条件が成立した場合に適用するビュー変換。
    /// - Returns: `condition` が `true` の場合は変換後のビュー、それ以外は元のビュー。
    @ViewBuilder
    public func `if`<Content: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

}
#endif
