//
//  MomentResponse.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation

/// UI-friendly representation that maps to your existing `gaveIn` Bool.
public enum MomentResponse: String, Codable, CaseIterable {
    case stayedPresent = "Stayed Present"
    case followed = "Followed"

    var gaveIn: Bool { self == .followed }
}
