//
//  File.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/24.
//

extension StringProtocol where Self: RangeReplaceableCollection {
    
    public var removeWhitespaceAndNewLines: Self {
        filter { !$0.isWhitespace && !$0.isNewline }
    }
    
}
