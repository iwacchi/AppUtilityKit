//
//  File.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

import CoreData
import Foundation

@available(iOS 13.0, *)
/// 永続化レイヤの注入ポイント
/// - Note: ライブラリ側は `any PersistenceProtocol`（existential）を受け取るため、関連型や `Self` 要件は持たせない
public protocol PersistenceProtocol {

    associatedtype PersistentContainer: NSPersistentContainer

    static var shared: Self { get }

    /// Core Data の `NSPersistentContainer` 実体
    var container: PersistentContainer { get }

}
