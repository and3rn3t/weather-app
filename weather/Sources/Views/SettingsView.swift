//
//  SettingsView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsManager
    @Bindable var notifications: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @State private var showingThemePicker = false
    @State private var showingResetConfirmation = false
    @State private var showingAPIKeyInput = false
    
    init(settings: SettingsManager, notifications: NotificationManager) {
        self.settings = settings
        self.notifications = notifications
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Units Section
                Section {
                    Picker("Temperature", selection: $settings.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    
                    Picker("Wind Speed", selection: $settings.windSpeedUnit) {
                        ForEach(WindSpeedUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    
                    Picker("Precipitation", selection: $settings.precipitationUnit) {
                        ForEach(PrecipitationUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                } header: {
                    Label("Units", systemImage: "ruler")
                }
                
                // Appearance Section
                Section {
                    Toggle(isOn: $settings.useSystemAppearance) {
                        Label("Use System Appearance", systemImage: "circle.righthalf.filled")
                    }
                    
                    if !settings.useSystemAppearance {
                        Picker("Appearance", selection: Binding(
                            get: { settings.preferredColorScheme ?? .light },
                            set: { settings.preferredColorScheme = $0 }
                        )) {
                            Text("Light").tag(ColorScheme.light)
                            Text("Dark").tag(ColorScheme.dark)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Toggle(isOn: $settings.showAnimatedBackgrounds) {
                        Label("Animated Backgrounds", systemImage: "sparkles")
                    }
                    
                    Toggle(isOn: $settings.showWeatherParticles) {
                        Label("Weather Particles", systemImage: "snow")
                    }
                    
                    // Theme Picker
                    Button {
                        showingThemePicker = true
                    } label: {
                        HStack {
                            Label("Color Theme", systemImage: "paintpalette")
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(themeManager.currentTheme.previewColors.prefix(3), id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                
                // Display Options Section
                Section {
                    Toggle(isOn: $settings.showFeelsLike) {
                        Label("Show \"Feels Like\" Temperature", systemImage: "thermometer.medium")
                    }
                    
                    Toggle(isOn: $settings.show24HourFormat) {
                        Label("24-Hour Time Format", systemImage: "clock")
                    }
                } header: {
                    Label("Display", systemImage: "eye")
                }
                
                // Live Activities Section
                Section {
                    Toggle(isOn: $settings.liveActivitiesEnabled) {
                        Label("Live Activities", systemImage: "figure.walk.motion")
                    }
                } header: {
                    Label("Lock Screen", systemImage: "lock.iphone")
                } footer: {
                    Text("Show live weather updates on your Lock Screen and Dynamic Island.")
                }
                
                // Notifications Section
                Section {
                    if !notifications.hasPermission {
                        Button {
                            Task {
                                _ = await notifications.requestAuthorization()
                            }
                        } label: {
                            Label("Enable Notifications", systemImage: "bell.badge")
                        }
                    } else {
                        Toggle(isOn: $settings.dailyForecastEnabled) {
                            Label("Daily Forecast", systemImage: "calendar")
                        }
                        .onChange(of: settings.dailyForecastEnabled) { _, enabled in
                            if !enabled {
                                notifications.cancelDailyForecast()
                            }
                        }
                        
                        if settings.dailyForecastEnabled {
                            DatePicker(
                                "Notification Time",
                                selection: $settings.notificationTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        
                        Toggle(isOn: $settings.severeWeatherAlertsEnabled) {
                            Label("Severe Weather Alerts", systemImage: "exclamationmark.triangle")
                        }
                        
                        Toggle(isOn: $settings.rainAlertsEnabled) {
                            Label("Rain Alerts", systemImage: "cloud.rain")
                        }
                    }
                } header: {
                    Label("Notifications", systemImage: "bell")
                } footer: {
                    if notifications.hasPermission {
                        Text("Receive weather updates and alerts based on your preferences.")
                    } else {
                        Text("Enable notifications to receive weather updates and alerts.")
                    }
                }
                
                // Data Section
                Section {
                    Picker("Auto Refresh", selection: $settings.autoRefreshInterval) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("Manual only").tag(0)
                    }
                } header: {
                    Label("Data", systemImage: "arrow.clockwise")
                } footer: {
                    Text("Weather data will automatically refresh at the selected interval when the app is active.")
                }
                
                // API Keys Section
                Section {
                    HStack {
                        Text("Tomorrow.io API Key")
                        Spacer()
                        if settings.tomorrowIOAPIKey.isEmpty {
                            Text("Not Set")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("••••••")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingAPIKeyInput = true
                    }
                } header: {
                    Label("API Keys", systemImage: "key.fill")
                } footer: {
                    Text("Required for pollen forecasts in the United States. Get your free API key at tomorrow.io/weather-api")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("Open-Meteo")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://open-meteo.com")!) {
                        HStack {
                            Text("Visit Open-Meteo")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }
                
                // Reset Section
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                    .confirmationDialog(
                        "Reset all settings to their default values?",
                        isPresented: $showingResetConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            HapticFeedback.warning()
                            settings.resetToDefaults()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will reset all units, appearance, notification, and display settings. This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
                    .environment(themeManager)
            }
            .sheet(isPresented: $showingAPIKeyInput) {
                APIKeyInputView(apiKey: $settings.tomorrowIOAPIKey)
            }
        }
    }
}

// MARK: - API Key Input View

struct APIKeyInputView: View {
    @Binding var apiKey: String
    @Environment(\.dismiss) private var dismiss
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Enter API Key", text: $inputText)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isFocused)
                } header: {
                    Text("Tomorrow.io API Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Get a free API key at:")
                        Link("tomorrow.io/weather-api", destination: URL(string: "https://www.tomorrow.io/weather-api/")!)
                            .font(.footnote.weight(.medium))
                        
                        Text("\nFree tier includes:")
                            .padding(.top, 4)
                        Text("• 500 calls per day")
                        Text("• Pollen forecasts for US locations")
                        Text("• No credit card required")
                    }
                    .font(.caption)
                }
                
                if !inputText.isEmpty {
                    Section {
                        Button("Save API Key") {
                            apiKey = inputText
                            HapticFeedback.success()
                            dismiss()
                        }
                        .buttonStyle(.glass)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                if !apiKey.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            apiKey = ""
                            inputText = ""
                            HapticFeedback.warning()
                            dismiss()
                        } label: {
                            Text("Remove API Key")
                        }
                    }
                }
            }
            .navigationTitle("API Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                inputText = apiKey
                isFocused = true
            }
        }
    }
}

#Preview {
    SettingsView(settings: SettingsManager(), notifications: NotificationManager())
        .environment(ThemeManager())
}
