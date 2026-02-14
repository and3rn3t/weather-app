//
//  WeatherAlertsCard.swift
//  weather
//
//  Created by GitHub Copilot on 2/14/26.
//
//  Displays severe weather alerts with priority coloring and details
//

import SwiftUI

struct WeatherAlertsCard: View {
    let alerts: [WeatherAlert]
    @State private var expandedAlertId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if alerts.isEmpty {
                // No alerts - show all clear
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Active Alerts")
                            .font(.headline)
                        Text("No severe weather warnings for this area")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
            } else {
                // Show alerts
                ForEach(Array(alerts.enumerated()), id: \.element.id) { index, alert in
                    alertRow(alert, isExpanded: expandedAlertId == alert.id)
                    
                    if index < alerts.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private func alertRow(_ alert: WeatherAlert, isExpanded: Bool) -> some View {
        Button {
            HapticFeedback.impact()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if expandedAlertId == alert.id {
                    expandedAlertId = nil
                } else {
                    expandedAlertId = alert.id
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    // Alert icon with severity color
                    Image(systemName: alert.icon)
                        .font(.title2)
                        .foregroundStyle(alertSeverityColor(alert.severity))
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Alert title
                        Text(alert.event)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        // Headline
                        if !alert.headline.isEmpty && alert.headline != alert.event {
                            Text(alert.headline)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Time info
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(timeRangeText(alert))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        
                        // Severity badge
                        HStack(spacing: 8) {
                            severityBadge(alert.severity)
                            urgencyBadge(alert.urgency)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand chevron
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                
                // Expanded details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                        
                        // Areas affected
                        if !alert.areas.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Affected Areas", systemImage: "mappin.circle")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                
                                Text(alert.areas)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // Description
                        if !alert.description.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Details", systemImage: "info.circle")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                
                                Text(alert.description)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // Source
                        HStack {
                            Spacer()
                            Text("Issued by \(alert.senderName)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .italic()
                        }
                    }
                    .padding(.leading, 44)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
    
    private func timeRangeText(_ alert: WeatherAlert) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let now = Date()
        
        if alert.effective > now {
            return "Starts \(formatter.string(from: alert.effective))"
        } else if alert.expires < now {
            return "Expired \(formatter.string(from: alert.expires))"
        } else {
            return "Until \(formatter.string(from: alert.expires))"
        }
    }
    
    private func severityBadge(_ severity: String) -> some View {
        Text(severity.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(alertSeverityColor(severity).opacity(0.2), in: Capsule())
            .foregroundStyle(alertSeverityColor(severity))
    }
    
    private func urgencyBadge(_ urgency: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: urgencyIcon(urgency))
                .font(.caption2)
            Text(urgency.capitalized)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.2), in: Capsule())
        .foregroundStyle(.secondary)
    }
    
    private func alertSeverityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "extreme":
            return .red
        case "severe":
            return .orange
        case "moderate":
            return .yellow
        case "minor":
            return .blue
        default:
            return .gray
        }
    }
    
    private func urgencyIcon(_ urgency: String) -> String {
        switch urgency.lowercased() {
        case "immediate":
            return "hare"
        case "expected":
            return "clock"
        case "future":
            return "calendar"
        default:
            return "questionmark"
        }
    }
}

// MARK: - Preview

#Preview("With Alerts") {
    let sampleAlerts = [
        WeatherAlert(
            event: "Severe Thunderstorm Warning",
            headline: "Severe thunderstorms capable of producing damaging winds and large hail",
            description: "At 3:45 PM local time, a severe thunderstorm was located near Downtown, moving northeast at 25 mph. Hazards include 60 mph wind gusts and quarter size hail. Expect damage to roofs, siding, and trees.",
            severity: "Severe",
            urgency: "Immediate",
            areas: "Downtown, North Side, East End",
            effective: Date().addingTimeInterval(-1800),
            expires: Date().addingTimeInterval(3600),
            senderName: "National Weather Service"
        ),
        WeatherAlert(
            event: "Heat Advisory",
            headline: "Dangerously hot conditions with heat index values up to 105",
            description: "Heat index values up to 105 expected. Drink plenty of fluids, stay in an air-conditioned room, stay out of the sun, and check up on relatives and neighbors.",
            severity: "Moderate",
            urgency: "Expected",
            areas: "Entire metro area",
            effective: Date(),
            expires: Date().addingTimeInterval(86400),
            senderName: "National Weather Service"
        )
    ]
    
    return ScrollView {
        VStack(spacing: 16) {
            WeatherAlertsCard(alerts: sampleAlerts)
        }
        .padding()
    }
    .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
}

#Preview("No Alerts") {
    ScrollView {
        VStack(spacing: 16) {
            WeatherAlertsCard(alerts: [])
        }
        .padding()
    }
    .background(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
}
