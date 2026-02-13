package com.andernet.weather

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Application class for Weather app
 * Annotated with @HiltAndroidApp to trigger Hilt code generation
 */
@HiltAndroidApp
class WeatherApplication : Application()
