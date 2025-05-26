//
//  StealthIconPickerView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/24/25.
//

import SwiftUI

struct StealthIconPickerView: View {
    @AppStorage("selectedStealthIcon") private var persistedIcon: String?
    @AppStorage("isStealthModeEnabled") private var isStealthModeEnabled: Bool = false
    @State private var selectedIcon: String?

    private let availableIcons = [
        "AppIcon-Stealth1",
        "AppIcon-Stealth2",
        "AppIcon-Stealth3",
        "AppIcon-Stealth4",
        "AppIcon-Stealth5",
        "AppIcon-Stealth6"
    ]
    
    private func setAppIcon(to iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons not supported.")
            return
        }

        UIApplication.shared.setAlternateIconName(iconName == "AppIcon-Stealth1" ? nil : iconName) { error in
            if let error = error {
                print("❌ Failed to set icon: \(error.localizedDescription)")
            } else {
                selectedIcon = iconName
                persistedIcon = iconName
                isStealthModeEnabled = true
                print("✅ App icon changed to: \(iconName)")
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose Your Stealth Icon")
                .font(.headline)
                .padding(.bottom, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(availableIcons, id: \.self) { iconName in
                    let previewIndex = iconName.replacingOccurrences(of: "AppIcon-Stealth", with: "")
                    let previewName = "StealthIconPreview\(previewIndex)"

                    Button {
                        setAppIcon(to: iconName)
                    } label: {
                        Image(previewName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedIcon == iconName ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            selectedIcon = persistedIcon
        }
    }

    
}
#Preview {
    StealthIconPickerView()
}
