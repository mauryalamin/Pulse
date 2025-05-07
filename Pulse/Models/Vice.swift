//
//  Vice.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import Foundation
import SwiftData

@Model
class Vice {
    var name: String
    var colorHex: String  // e.g. "#FF6B6B"
    
    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
    }
}
