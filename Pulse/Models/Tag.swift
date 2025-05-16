//
//  Tag.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import Foundation
import SwiftData

@Model
class Tag: Identifiable {
    var name: String
    var usageCount: Int = 0
    
    var moments: [Moment] = []
    
    init(name: String) {
        self.name = name
    }
}
