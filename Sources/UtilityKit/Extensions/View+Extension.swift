//
//  View+Extension.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/18.
//

public import SwiftUI

@available(iOS 13.0, *)
extension View {
    
    @ViewBuilder
    public func `if`<Content: View>(@ViewBuilder _ content: (Self) -> Content) -> some View {
        content(self)
    }
    
}
