//
//  TagsReadOnlySectionViewTests.swift
//  PulseTests
//
//  Created by Maury Alamin on 11/10/25.
//

import Testing
import SwiftUI
@testable import Pulse


@MainActor
struct TagsReadOnlySectionViewTests {
    
    @Test
    func summary_no_tags() {
        let summary = TagsA11y.summary(for: [])
        #expect(summary == "No tags added")
    }
    
    @Test
    func summary_lists_tag_names_comma_separated() {
        let tags = [AppTag(name: "After Work"), AppTag(name: "Stress")]
        let summary = TagsA11y.summary(for: tags)
        #expect(summary.contains("After Work"))
        #expect(summary.contains("Stress"))
        #expect(summary == "After Work, Stress")
    }
}

// MARK: - Lightweight helpers

extension View {
    /// Extracts the `accessibilityValue` string description from a View,
    /// when available via reflection. This is crude but fine for snapshot-like tests.
    var accessibilityValueDescription: String {
        Mirror(reflecting: self).children
            .first(where: { "\($0.label ?? "")".contains("accessibilityValue") })?
            .value as? String ?? ""
    }
}
