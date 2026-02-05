//
//  Andernet_Weather_WidgetLiveActivity.swift
//  Andernet Weather Widget
//
//  Created by Matt on 2/5/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Andernet_Weather_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Andernet_Weather_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Andernet_Weather_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Andernet_Weather_WidgetAttributes {
    fileprivate static var preview: Andernet_Weather_WidgetAttributes {
        Andernet_Weather_WidgetAttributes(name: "World")
    }
}

extension Andernet_Weather_WidgetAttributes.ContentState {
    fileprivate static var smiley: Andernet_Weather_WidgetAttributes.ContentState {
        Andernet_Weather_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Andernet_Weather_WidgetAttributes.ContentState {
         Andernet_Weather_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Andernet_Weather_WidgetAttributes.preview) {
   Andernet_Weather_WidgetLiveActivity()
} contentStates: {
    Andernet_Weather_WidgetAttributes.ContentState.smiley
    Andernet_Weather_WidgetAttributes.ContentState.starEyes
}
