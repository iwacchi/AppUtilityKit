//
//  LoggerKit.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

import Foundation
import os

// MARK: - LoggerKit
/// OS の `Logger` をラップし、統合ログへ出力するユーティリティ
/// - 位置情報（file/function/line/column）とカテゴリを自動付与
/// - しきい値（`minimumLogLevel`）未満のログは評価すらしない（文字列構築コストを抑制）

@available(iOS 14.0, *)
public struct LoggerKit: @unchecked Sendable {

    /// 共有設定（サブシステムと最小出力レベル）
    /// - Note: 実行時に `LoggerKit.config` を差し替え可能
    public struct Config {

        public var subsystem: String

        public var minimumLogLevel: Level

    }

    /// ログレベル（`OSLogType` へのマッピングと表示用シンボルを保持）
    public enum Level: Int {

        case debug, info, `default`, error, fault

        internal var osType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .default:
                return .default
            case .error:
                return .error
            case .fault:
                return .fault
            }
        }

        internal var symbol: String {
            switch self {
            case .debug:
                return "DEBUG"
            case .info:
                return "INFO"
            case .default:
                return "DEFAULT"
            case .error:
                return "ERROR"
            case .fault:
                return "FAULT"
            }
        }

    }

    /// ロガーのグローバル設定（並行環境での読み取りを想定し `nonisolated(unsafe)`）
    nonisolated(unsafe)
        public static var config = Config.default

    private let logger: Logger

    public let category: String

    /// カテゴリ別のロガーを生成（フィルタや可視性のためにカテゴリ名を付ける）
    public init(category: String = "Default") {
        self.category = category
        self.logger = Logger(subsystem: Self.config.subsystem, category: category)
    }

    /// 呼び出し元の位置情報を自動付与して出力
    @inlinable public func debug(
        _ message: @autoclosure () -> String,
        isPrivate: Bool = false,
        fileID: String = #fileID,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(
            .debug,
            isPrivate: isPrivate,
            message(),
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    /// 呼び出し元の位置情報を自動付与して出力
    @inlinable public func info(
        _ message: @autoclosure () -> String,
        isPrivate: Bool = false,
        fileID: String = #fileID,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(
            .info,
            isPrivate: isPrivate,
            message(),
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    /// 呼び出し元の位置情報を自動付与して出力
    @inlinable public func notice(
        _ message: @autoclosure () -> String,
        isPrivate: Bool = false,
        fileID: String = #fileID,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(
            .default,
            isPrivate: isPrivate,
            message(),
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    /// 呼び出し元の位置情報を自動付与して出力
    @inlinable public func error(
        _ message: @autoclosure () -> String,
        isPrivate: Bool = false,
        fileID: String = #fileID,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(
            .error,
            isPrivate: isPrivate,
            message(),
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    /// 呼び出し元の位置情報を自動付与して出力
    @inlinable public func fault(
        _ message: @autoclosure () -> String,
        isPrivate: Bool = false,
        fileID: String = #fileID,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        log(
            .fault,
            isPrivate: isPrivate,
            message(),
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    @usableFromInline
    internal func log(
        _ level: Level,
        isPrivate: Bool = false,
        _ message: @autoclosure () -> String,
        fileID: String,
        function: String,
        line: Int,
        column: Int
    ) {
        if level.rawValue < Self.config.minimumLogLevel.rawValue {
            return
        }
        let msg = message()
        if isPrivate {
            logger.log(
                level: level.osType,
                "[\(fileID)] [\(function)] [\(line):\(column)] \(level.symbol): \(msg, privacy: .private)"
            )
        } else {
            logger.log(
                level: level.osType,
                "[\(fileID)] [\(function)] [\(line):\(column)] \(level.symbol): \(msg, privacy: .public)"
            )
        }
    }

}

@available(iOS 14.0, *)
extension LoggerKit.Config {

    /// デフォルト設定（サブシステムは `Bundle.main.bundleIdentifier` または "AppUtilityKit"）
    public static var `default`: LoggerKit.Config {
        return LoggerKit.Config(
            subsystem: Bundle.main.bundleIdentifier ?? "AppUtilityKit",
            minimumLogLevel: .debug
        )
    }

}

@available(iOS 14.0, *)
extension LoggerKit {

    /// アプリ全般
    public static let app = LoggerKit(category: "App")

    /// ネットワーク層
    public static let network = LoggerKit(category: "Network")

    /// 課金（IAP）
    public static let inAppPurchase = LoggerKit(category: "InAppPurchase")

    /// 分析/トラッキング
    public static let analytics = LoggerKit(category: "Analytics")

}
