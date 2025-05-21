//
//  WeatherSnapshotFormatter.swift
//  Pulse
//
//  Created by Maury Alamin on 5/21/25.
//

import Foundation


struct WeatherSnapshotFormatter {
    static func formatted(_ snapshot: WeatherSnapshot) -> String {
        if let temp = snapshot.temperature {
            return "\(snapshot.summary), \(Int(temp))°"
        } else {
            return snapshot.summary
        }
    }
}
