//
//  PulseDateFormatting.swift
//  Pulse
//
//  Created by Maury Alamin on 10/20/25.
//

import Foundation

enum PulseDateFormatting {
    /// Example: "January 1, 2025 at 1:13 pm"
    static func contextTimestamp(_ date: Date) -> String {
        let datePart = date.formatted(
            .dateTime
                .month(.wide)
                .day()      // default digits -> "1"
                .year()
        )

        // Force 12h with lowercase am/pm
        let timePart = date.formatted(
            .dateTime
                .hour(.defaultDigits(amPM: .abbreviated)) // "1 PM" by default locale
                .minute(.twoDigits)
        )
        // Make am/pm lowercase to match spec
        let lowercasedTime = timePart.replacingOccurrences(of: "AM", with: "am")
                                     .replacingOccurrences(of: "PM", with: "pm")

        return "\(datePart) at \(lowercasedTime)"
    }
}
