//
//  Date+Extension.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import Foundation

extension Date {
    /// Returns a formatted string that shows:
    /// - "X hours ago" for recent events (under 24h),
    /// - "Friday at 3:47 PM" for events within the last week,
    /// - "April 28, 2025 at 4:16 PM" for anything older.
    func smartRelativeDescription(referenceDate: Date = Date()) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: referenceDate)

        // 1. If it's within the last 24 hours, use relative style (e.g., "2 hours ago")
        if let hoursAgo = calendar.dateComponents([.hour], from: self, to: referenceDate).hour,
           hoursAgo < 24 {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: self, relativeTo: referenceDate)
        }

        // 2. If it's within the last 7 days, show weekday + time (e.g., "Friday at 3:47 PM")
        if let days = components.day, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a" // e.g., "Friday at 3:47 PM"
            return formatter.string(from: self)
        }

        // 3. Older than a week: full date and time
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
