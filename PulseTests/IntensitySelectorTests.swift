//
//  IntensitySelectorTests.swift
//  PulseTests
//
//  Created by Maury Alamin on 10/27/25.
//

import Testing
import SwiftUI
@testable import Pulse

struct IntensitySelectorTests {

    // 1) Spec mapping is exact for levels 1...5
    @Test
    func gradient_pairs_match_spec() {
        // (brightness, saturation) spec we expect
        let expected: [(Double, Double)] = [
            (0.4, 0.6),
            (0.3, 0.7),
            (0.2, 0.8),
            (0.1, 0.9),
            (0.0, 1.0),
        ]

        for level in 1...5 {
            let pair = IntensityGradientSpec.pair(for: level)
            #expect(pair.brightness == expected[level-1].0)
            #expect(pair.saturation == expected[level-1].1)
        }
    }

    // Clamp behavior at edges (defensive)
    @Test
    func gradient_pairs_clamp_out_of_range_levels() {
        let lo = IntensityGradientSpec.pair(for: 0)   // clamp to 1
        let hi = IntensityGradientSpec.pair(for: 99)  // clamp to 5
        #expect(lo.brightness == 0.4 && lo.saturation == 0.6)
        #expect(hi.brightness == 0.0 && hi.saturation == 1.0)
    }

    // 2) Fill logic: first N are filled, others not
    @Test
    func fill_logic_marks_first_N_as_filled() {
        let N = 3
        for level in 1...5 {
            let filled = IntensityGradientSpec.isFilled(level: level, selected: N)
            if level <= N {
                #expect(filled == true)
            } else {
                #expect(filled == false)
            }
        }
    }

    @Test
    func fill_logic_with_nil_selection_marks_none_filled() {
        for level in 1...5 {
            #expect(IntensityGradientSpec.isFilled(level: level, selected: nil) == false)
        }
    }

    // 3) Base color fallback
    @Test
    func base_color_uses_fallback_when_hex_is_nil_or_invalid() {
        let fb: Color = .pulseBlue

        let c1 = IntensityGradientSpec.baseColor(from: nil, fallback: fb)
        let c2 = IntensityGradientSpec.baseColor(from: "INVALID", fallback: fb)

        // We can only check equality via description safely here.
        #expect(String(describing: c1) == String(describing: fb))
        #expect(String(describing: c2) == String(describing: fb))
    }

    @Test
    func base_color_uses_valid_hex() {
        // A real hex; equality is string-based to avoid internal style differences
        let chosen = IntensityGradientSpec.baseColor(from: "#8B3A3A", fallback: .pulseBlue)
        #expect(String(describing: chosen) != String(describing: Color.pulseBlue))
    }
}
