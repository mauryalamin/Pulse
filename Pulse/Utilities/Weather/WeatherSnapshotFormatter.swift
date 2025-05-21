//
//  WeatherSnapshotFormatter.swift
//  Pulse
//
//  Created by Maury Alamin on 5/21/25.
//

import Foundation


struct WeatherSnapshotFormatter {
    static func formatted(code: Int?, temp: Double?) -> String {
        let summary = WeatherSnapshot.codeDescription[code ?? -1] ?? "Unknown"
        if let temp = temp {
            return "\(Int(temp))°, \(summary)"
        } else {
            return summary
        }
    }
}
