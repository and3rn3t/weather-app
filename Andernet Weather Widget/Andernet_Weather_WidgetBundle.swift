//
//  Andernet_Weather_WidgetBundle.swift
//  Andernet Weather Widget
//
//  Created by Matt on 2/5/26.
//

import WidgetKit
import SwiftUI

@main
struct Andernet_Weather_WidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        Andernet_Weather_Widget()
        LockScreenWeatherWidget()
        
        // Live Activity
        Andernet_Weather_WidgetLiveActivity()
        
        // Control Center Widgets (iOS 18+)
        if #available(iOS 18.0, *) {
            WeatherControlWidget()
            TemperatureControlWidget()
            ConditionsControlWidget()
            RainChanceControlWidget()
        }
    }
}
