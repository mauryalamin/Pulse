//
//  WeatherEditSheet.swift
//  Pulse
//
//  Created by Codex on 3/3/26.
//

import SwiftUI

struct WeatherEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draftWeatherCode: Int
    @State private var draftTemperatureCelsius: Double

    let weatherConditionOptions: [(code: Int, label: String)]
    let onSave: (Int, Double) -> Void

    init(
        initialWeatherCode: Int,
        initialTemperatureCelsius: Double,
        weatherConditionOptions: [(code: Int, label: String)],
        onSave: @escaping (Int, Double) -> Void
    ) {
        _draftWeatherCode = State(initialValue: initialWeatherCode)
        _draftTemperatureCelsius = State(initialValue: initialTemperatureCelsius)
        self.weatherConditionOptions = weatherConditionOptions
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Condition", selection: $draftWeatherCode) {
                    ForEach(weatherConditionOptions, id: \.code) { option in
                        Text(option.label).tag(option.code)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Image(systemName: WeatherFormatting.symbolName(for: nil, code: draftWeatherCode))
                        .foregroundStyle(.secondary)
                    Text(WeatherFormatting.formattedTempCompact(celsius: draftTemperatureCelsius))
                        .font(.body)
                }

                Stepper("Temperature", value: $draftTemperatureCelsius, in: -50...60, step: 1)
            }
            .navigationTitle("Edit Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draftWeatherCode, draftTemperatureCelsius)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    WeatherEditSheet(
        initialWeatherCode: 2,
        initialTemperatureCelsius: 22,
        weatherConditionOptions: WeatherSnapshot.codeDescription
            .sorted { $0.key < $1.key }
            .map { (code: $0.key, label: $0.value) },
        onSave: { _, _ in }
    )
}
