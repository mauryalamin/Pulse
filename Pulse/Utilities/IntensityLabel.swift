//
//  IntensityLabel.swift
//  Pulse
//
//  Created by Maury Alamin on 5/14/25.
//
import Foundation

enum IntensityLabel: Int {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    
    var label: String {
        switch self {
        case .one: return "Fleeting"
        case .two: return "Noticeable"
        case .three: return "Strong"
        case .four: return "Disruptive"
        case .five: return "Overwhelming"
        }
    }
    
    var symbolName: String {
        switch self {
        case .one: return "1.circle"
        case .two: return "2.circle"
        case .three: return "3.circle"
        case .four: return "4.circle"
        case .five: return "5.circle"
        }
    }
    
    static func from(_ value: Int) -> IntensityLabel? {
        return IntensityLabel(rawValue: value)
    }
}
