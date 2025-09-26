//
//  Color+Extension.swift
//  AppUtilityKit
//
//  Created by iwacchi on 2025/08/17.
//

#if canImport(SwiftUI)
internal import Foundation
public import SwiftUI
internal import UIKit

// MARK: - Helpers
/// 0...1 にクランプするユーティリティ。
@inline(__always)
private func clamp01(_ x: Double) -> Double { min(max(x, 0), 1) }

// MARK: - Color の Codable 化
/// SwiftUI の `Color` に `Codable` を付与します。
///
/// - エンコード/デコードは sRGB の RGBA 各成分（0...1）で表現します。
/// - エンコード時は **ライト** 外観でダイナミックカラーを解決し、テーマ差による JSON の揺れを防ぎます。
/// - `getRed` が失敗した場合は、`CGColor` を sRGB に変換してから成分を取得します（グレースケールにも対応）。
@available(iOS 14.0, *)
extension Color: @retroactive Decodable, @retroactive Encodable {

    public enum CodingKeys: String, CodingKey {
        /// 赤成分（0...1）
        case red
        /// 緑成分（0...1）
        case green
        /// 青成分（0...1）
        case blue
        /// 透過度（0...1）
        case opacity
    }

    /// 色を sRGB の RGBA 値としてエンコードします。
    /// - Note: 出力の安定化のため、ダイナミックカラーは **ライト外観** で解決します。
    /// - Fallback: `getRed` が失敗した場合は `CGColor` を sRGB に変換し、必要に応じてグレースケールを RGB に展開します。
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        // ライト外観でダイナミックカラーを解決してから成分を取得
        let resolved = UIColor(self)
            .resolvedColor(
                with: UITraitCollection(userInterfaceStyle: .light)
            )

        if resolved.getRed(&r, green: &g, blue: &b, alpha: &a) == false {
            // sRGB に変換してから成分を取得（グレースケール含む）
            if let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
                let converted = resolved.cgColor.converted(
                    to: sRGB,
                    intent: .defaultIntent,
                    options: nil
                ),
                let comps = converted.components
            {
                switch converted.numberOfComponents {
                case 4:  // RGBA
                    r = comps[0]
                    g = comps[1]
                    b = comps[2]
                    a = comps[3]
                case 2:  // Grayscale + Alpha
                    r = comps[0]
                    g = comps[0]
                    b = comps[0]
                    a = comps[1]
                default:
                    break  // 期待外は 0 のまま（安全側）
                }
            }
        }

        try container.encode(Double(r), forKey: .red)
        try container.encode(Double(g), forKey: .green)
        try container.encode(Double(b), forKey: .blue)
        try container.encode(Double(a), forKey: .opacity)
    }

    /// RGBA 各成分をデコードし、外れ値は `0...1` にクランプします。
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = clamp01(try container.decode(Double.self, forKey: .red))
        let green = clamp01(try container.decode(Double.self, forKey: .green))
        let blue = clamp01(try container.decode(Double.self, forKey: .blue))
        let opacity = clamp01(try container.decode(Double.self, forKey: .opacity))
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }

    /// この型が出力した JSON 文字列から初期化します。
    /// - Parameter jsonString: { red, green, blue, opacity } を含む UTF-8 の JSON 文字列。
    /// - Note: 失敗時は `nil` にフォールバックします。
    public init?(jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        if let color = try? decoder.decode(Color.self, from: jsonData) {
            self = color
        } else {
            return nil
        }
    }

    /// カラーを表す整形済み JSON 文字列。
    /// - Throws: エンコードや UTF-8 変換に失敗した場合にエラーを投げます。
    public var jsonString: String {
        get throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let jsonData = try encoder.encode(self)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "Color+Extension", code: -1)
            }
            return jsonString
        }
    }
    
    /// RGBA値をタプルで取得（sRGBに解決）
    internal func rgbaComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        let uiColor = UIColor(self)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r, g, b, a)
        } else if let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
                  let converted = uiColor.cgColor.converted(
                    to: sRGB,
                    intent: .defaultIntent,
                    options: nil
                  ),
                  let components = converted.components {
            switch converted.numberOfComponents {
                case 4: // RGBA
                    return (components[0], components[1], components[2], components[3])
                case 2: // Grayscale + Alpha
                    return (components[0], components[0], components[0], components[1])
                default:
                    return nil
            }
        }
        return nil
    }
    
    /// RGBAが一致しているかどうかを判定（誤差許容あり）
    public func isEqualRGBA(to color: Color, tolerance: CGFloat = 0.0001) -> Bool {
        guard let color1 = self.rgbaComponents(),
              let color2 = color.rgbaComponents() else {
            return false
        }
        return abs(color1.r - color2.r) <= tolerance && abs(color1.g - color2.g) <= tolerance &&
        abs(color1.b - color2.b) <= tolerance && abs(color1.a - color2.a) <= tolerance
    }
    
}
#endif
