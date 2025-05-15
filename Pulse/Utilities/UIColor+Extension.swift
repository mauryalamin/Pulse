//
//  UIColor+Extension.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import Foundation
import UIKit

extension UIColor {
    var toHex: String? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }

        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
