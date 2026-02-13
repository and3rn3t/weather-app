package com.andernet.weather.ui.widget

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.repository.SettingsRepository
import com.andernet.weather.data.repository.WeatherRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import javax.inject.Inject

/**
 * Small Weather Widget (2x2)
 */
class SmallWeatherWidget : GlanceAppWidget() {
    
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val widgetData = WeatherWidgetData.load(context)
            SmallWidgetContent(
                locationName = widgetData.locationName,
                currentWeather = widgetData.currentWeather,
                temperatureUnit = widgetData.temperatureUnit
            )
        }
    }
    
    companion object {
        const val TAG = "SmallWeatherWidget"
    }
}

/**
 * Small Weather Widget Receiver
 */
@AndroidEntryPoint
class SmallWeatherWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SmallWeatherWidget()
    
    @Inject
    lateinit var weatherRepository: WeatherRepository
    
    @Inject
    lateinit var settingsRepository: SettingsRepository
}

/**
 * Medium Weather Widget (4x2)
 */
class MediumWeatherWidget : GlanceAppWidget() {
    
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val widgetData = WeatherWidgetData.load(context)
            MediumWidgetContent(
                locationName = widgetData.locationName,
                currentWeather = widgetData.currentWeather,
                temperatureUnit = widgetData.temperatureUnit
            )
        }
    }
    
    companion object {
        const val TAG = "MediumWeatherWidget"
    }
}

/**
 * Medium Weather Widget Receiver
 */
@AndroidEntryPoint
class MediumWeatherWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MediumWeatherWidget()
    
    @Inject
    lateinit var weatherRepository: WeatherRepository
    
    @Inject
    lateinit var settingsRepository: SettingsRepository
}

/**
 * Large Weather Widget (4x3)
 */
class LargeWeatherWidget : GlanceAppWidget() {
    
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val widgetData = WeatherWidgetData.load(context)
            LargeWidgetContent(
                locationName = widgetData.locationName,
                currentWeather = widgetData.currentWeather,
                hourlyForecast = widgetData.hourlyForecast,
                temperatureUnit = widgetData.temperatureUnit
            )
        }
    }
    
    companion object {
        const val TAG = "LargeWeatherWidget"
    }
}

/**
 * Large Weather Widget Receiver
 */
@AndroidEntryPoint
class LargeWeatherWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = LargeWeatherWidget()
    
    @Inject
    lateinit var weatherRepository: WeatherRepository
    
    @Inject
    lateinit var settingsRepository: SettingsRepository
}
