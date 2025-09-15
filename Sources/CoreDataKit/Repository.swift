//
//  Repository.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

import Foundation

@available(iOS 17.0, *)
@CoreDataActor
public protocol Repository {

    var context: ManagedObjectContext { get }

}
