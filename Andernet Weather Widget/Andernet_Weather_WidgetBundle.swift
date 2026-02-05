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
        Andernet_Weather_Widget()
        Andernet_Weather_WidgetControl()
        Andernet_Weather_WidgetLiveActivity()
    }
}
