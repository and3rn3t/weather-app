//
//  SimpleSettingsView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

struct SimpleSettingsView: View {
    @Environment(SimpleSettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Units Section
                Section {
                    Toggle("Use Celsius", isOn: $settings.useCelsius)
                } header: {
                    Label("Units", systemImage: "ruler")
                }
                
                // Appearance Section
                Section {
                    Toggle("Animated Backgrounds", isOn: $settings.showAnimatedBackgrounds)
                    Toggle("Weather Particles", isOn: $settings.showWeatherParticles)
                } header: {
                    Label("Appearance", systemImage: "paintbrush")
                } footer: {
                    Text("Weather particles include rain, snow, clouds, lightning, and fog effects.")
                }
                
                // Display Section
                Section {
                    Toggle("Show \"Feels Like\" Temperature", isOn: $settings.showFeelsLike)
                } header: {
                    Label("Display", systemImage: "eye")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("Open-Meteo")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SimpleSettingsView()
        .environment(SimpleSettingsManager())
}
