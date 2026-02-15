//
//  PerformanceModule.kt
//  weather
//
//  Hilt module for providing PerformanceMonitor dependency
//

package com.andernet.weather.di

import android.content.Context
import com.andernet.weather.utils.PerformanceMonitor
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object PerformanceModule {
    
    @Provides
    @Singleton
    fun providePerformanceMonitor(
        @ApplicationContext context: Context
    ): PerformanceMonitor {
        return PerformanceMonitor(context)
    }
}