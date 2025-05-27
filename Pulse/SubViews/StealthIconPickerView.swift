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
        "AppIcon-StealthAlt1",
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

        UIApplication.shared.setAlternateIconName(iconName == "AppIcon" ? nil : iconName) { error in
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
                    let previewIndex = iconName
                        .replacingOccurrences(of: "AppIcon-StealthAlt", with: "")
                        .replacingOccurrences(of: "AppIcon-Stealth", with: "")
                    let previewName = "StealthIconPreview\(previewIndex)"

                    Button {
                        setAppIcon(to: iconName)
                    } label: {
                        if let uiImage = UIImage(named: previewName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIcon == iconName ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        } else {
                            Color.gray
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("?")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                        }
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
