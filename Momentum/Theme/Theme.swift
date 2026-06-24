//
//  Theme.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI
import UIKit

extension Color {
    fileprivate init(light: UInt32, dark: UInt32) {
        self = Color(uiColor: UIColor { traits in
            UIColor(rgbHex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    fileprivate convenience init(rgbHex: UInt32) {
        let r = CGFloat((rgbHex >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgbHex >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgbHex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

enum AppColor {
    static let bg = Color(light: 0xF2F2F7, dark: 0x0E1116)
    static let surface = Color(light: 0xFFFFFF, dark: 0x171B22)
    static let surface2 = Color(light: 0xF5F5F7, dark: 0x1E232C)
    static let surface3 = Color(light: 0xE5E5EA, dark: 0x262C36)
    static let hairline = Color(light: 0xD1D1D6, dark: 0x2A313C)
    static let text = Color(light: 0x11151C, dark: 0xEEF2F6)
    static let text2 = Color(light: 0x545B66, dark: 0x9BA6B4)
    static let text3 = Color(light: 0x8A92A0, dark: 0x69707C)
    static let accent = Color(light: 0x2C6EE3, dark: 0x5B8DEF)
    static let danger = Color(light: 0xE03333, dark: 0xFF6B6B)
}

enum PulseColor {
    static let active = Color(light: 0x16A271, dark: 0x2FD4A7)
    static let cooling = Color(light: 0xC97A00, dark: 0xF6B23C)
    static let cold = Color(light: 0x8E939C, dark: 0x6B7686)

    static let activeHalo = active.opacity(0.16)
    static let coolingHalo = cooling.opacity(0.14)
    static let coldRowTint = cold.opacity(0.16)
}
