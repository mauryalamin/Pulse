//
//  VisualEffectBlur.swift
//  Pulse
//
//  Created by Maury Alamin on 5/28/25.
//

import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIVisualEffectView to apply blur effects.
struct VisualEffectBlur<Content: View>: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var vibrancyStyle: UIVibrancyEffectStyle? = nil
    var content: Content

    init(blurStyle: UIBlurEffect.Style,
         vibrancyStyle: UIVibrancyEffectStyle? = nil,
         @ViewBuilder content: () -> Content) {
        self.blurStyle = blurStyle
        self.vibrancyStyle = vibrancyStyle
        self.content = content()
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)

        if let vibrancyStyle = vibrancyStyle {
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancyStyle)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyView.translatesAutoresizingMaskIntoConstraints = false
            blurView.contentView.addSubview(vibrancyView)

            NSLayoutConstraint.activate([
                vibrancyView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
                vibrancyView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
                vibrancyView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
                vibrancyView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor)
            ])

            let hostingController = UIHostingController(rootView: content)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.backgroundColor = .clear
            vibrancyView.contentView.addSubview(hostingController.view)

            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: vibrancyView.contentView.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: vibrancyView.contentView.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: vibrancyView.contentView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: vibrancyView.contentView.trailingAnchor)
            ])
        } else {
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.backgroundColor = .clear
            blurView.contentView.addSubview(hostingController.view)

            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor)
            ])
        }

        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No dynamic updates needed for static blur content.
    }
}
