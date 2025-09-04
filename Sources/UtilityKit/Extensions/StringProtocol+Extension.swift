//
//  File.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/24.
//

extension StringProtocol where Self: RangeReplaceableCollection {

    /// 空白および改行文字を取り除いた新しい文字列を返します。
    /// 元の文字列は変更されません。
    public var removingWhitespacesAndNewlines: Self {
        filter { !$0.isWhitespace && !$0.isNewline }
    }

    /// `removingWhitespacesAndNewlines` への後方互換用プロパティ。
    @available(*, deprecated, renamed: "removingWhitespacesAndNewlines")
    public var removeWhitespaceAndNewLines: Self {
        removingWhitespacesAndNewlines
    }

}
