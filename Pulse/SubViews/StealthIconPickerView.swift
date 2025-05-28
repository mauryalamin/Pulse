//
//  StealthIconPickerView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/24/25.
//

import SwiftUI
import UIKit

struct StealthIconPickerView: View {
    // @Binding var isPresented: Bool
    @AppStorage("selectedStealthIcon") private var selectedStealthIcon: String?
    @AppStorage("isStealthModeEnabled") private var isStealthModeEnabled: Bool = false

    @State private var tempSelection: String?

    private let availableIcons = [
        "AppIcon-StealthAlt1",
        "AppIcon-Stealth2",
        "AppIcon-Stealth3",
        "AppIcon-Stealth4",
        "AppIcon-Stealth5",
        "AppIcon-Stealth6"
    ]
    
    @MainActor
    private func setAppIcon(to iconName: String?) async {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons not supported.")
            return
        }

        do {
            try await UIApplication.shared.setAlternateIconName(iconName)
            selectedStealthIcon = iconName
            isStealthModeEnabled = true
            print("✅ App icon changed to: \(iconName ?? "Primary")")
        } catch {
            print("❌ Failed to set icon: \(error.localizedDescription)")
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Choose a Stealth Icon")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(availableIcons, id: \.self) { iconName in
                    let previewIndex = iconName
                        .replacingOccurrences(of: "AppIcon-StealthAlt", with: "")
                        .replacingOccurrences(of: "AppIcon-Stealth", with: "")
                    let previewName = "StealthIconPreview\(previewIndex)"

                    Button {
                        tempSelection = iconName
                    } label: {
                        Image(previewName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(tempSelection == iconName ? Color.blue : Color.clear, lineWidth: 3)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // MARK: - Preview
            VStack {
                if let tempSelection = tempSelection {
                    Text("How it will look")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ZStack  (alignment: .center) {
                        Image(.stealthPreview)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 292, height: 101)
                        
                        let previewIndex = tempSelection
                            .replacingOccurrences(of: "AppIcon-StealthAlt", with: "")
                            .replacingOccurrences(of: "AppIcon-Stealth", with: "")
                        Image("StealthIconPreview\(previewIndex)")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .offset(y: -6)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    tempSelection = selectedStealthIcon
                }
                .foregroundStyle(.red)

                Spacer()

                Button("Enable Stealth Mode") {
                    Task {
                        await setAppIcon(to: tempSelection)
                    }
                }
                .disabled(tempSelection == nil)
            }
            .padding(.top)
        }
        .padding()
        .onAppear {
            tempSelection = selectedStealthIcon
        }
    }
}

#Preview {
    StealthIconPickerView()
}
