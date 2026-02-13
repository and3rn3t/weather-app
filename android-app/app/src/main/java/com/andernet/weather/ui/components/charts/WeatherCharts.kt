package com.andernet.weather.ui.components.charts

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.andernet.weather.data.model.HourlyWeatherData
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WindSpeedUnit
import com.github.mikephil.charting.charts.BarChart
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.data.*

/**
 * Temperature chart showing 24-hour temperature trend
 */
@Composable
fun TemperatureChart(
    hourlyData: List<HourlyWeatherData>,
    temperatureUnit: TemperatureUnit,
    modifier: Modifier = Modifier
) {
    AndroidView(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp),
        factory = { context ->
            LineChart(context).apply {
                ChartFactory.styleLineChart(this)
                xAxis.valueFormatter = ChartFactory.HourFormatter()
                axisLeft.valueFormatter = ChartFactory.TemperatureFormatter(
                    when (temperatureUnit) {
                        TemperatureUnit.FAHRENHEIT -> "°F"
                        TemperatureUnit.CELSIUS -> "°C"
                    }
                )
            }
        },
        update = { chart ->
            val entries = hourlyData.mapIndexed { index, data ->
                Entry(index.toFloat(), data.temperature.toFloat())
            }
            
            val dataSet = ChartFactory.createLineDataSet(
                entries = entries,
                label = "Temperature",
                color = ChartFactory.TEMPERATURE_COLOR,
                fillEnabled = true
            )
            
            chart.data = LineData(dataSet)
            chart.invalidate()
        }
    )
}

/**
 * Precipitation chart showing rain/snow probability
 */
@Composable
fun PrecipitationChart(
    hourlyData: List<HourlyWeatherData>,
    modifier: Modifier = Modifier
) {
    AndroidView(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp),
        factory = { context ->
            BarChart(context).apply {
                ChartFactory.styleBarChart(this)
                xAxis.valueFormatter = ChartFactory.HourFormatter()
                axisLeft.valueFormatter = ChartFactory.PercentageFormatter()
                axisLeft.axisMaximum = 100f
            }
        },
        update = { chart ->
            val entries = hourlyData.mapIndexed { index, data ->
                BarEntry(index.toFloat(), data.precipitationProbability.toFloat())
            }
            
            // Color bars based on precipitation type (simplified)
            val colors = hourlyData.map { data ->
                if (data.temperature < 32) ChartFactory.SNOW_COLOR
                else ChartFactory.PRECIPITATION_COLOR
            }
            
            val dataSet = ChartFactory.createMultiColorBarDataSet(
                entries = entries,
                label = "Precipitation",
                colors = colors
            )
            
            chart.data = BarData(dataSet)
            chart.invalidate()
        }
    )
}

/**
 * UV Index chart with color-coded levels
 */
@Composable
fun UVIndexChart(
    hourlyData: List<HourlyWeatherData>,
    modifier: Modifier = Modifier
) {
    AndroidView(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp),
        factory = { context ->
            BarChart(context).apply {
                ChartFactory.styleBarChart(this)
                xAxis.valueFormatter = ChartFactory.HourFormatter()
                axisLeft.axisMaximum = 12f
            }
        },
        update = { chart ->
            val entries = hourlyData.mapIndexed { index, data ->
                BarEntry(index.toFloat(), (data.uvIndex ?: 0.0).toFloat())
            }
            
            // Color code by UV level
            val colors = hourlyData.map { data ->
                val uv = data.uvIndex ?: 0.0
                when {
                    uv < 3 -> ChartFactory.UV_LOW_COLOR
                    uv < 6 -> ChartFactory.UV_MODERATE_COLOR
                    uv < 8 -> ChartFactory.UV_HIGH_COLOR
                    uv < 11 -> ChartFactory.UV_VERY_HIGH_COLOR
                    else -> ChartFactory.UV_EXTREME_COLOR
                }
            }
            
            val dataSet = ChartFactory.createMultiColorBarDataSet(
                entries = entries,
                label = "UV Index",
                colors = colors
            )
            
            chart.data = BarData(dataSet)
            chart.invalidate()
        }
    )
}

/**
 * Wind speed chart with gust indicators
 */
@Composable
fun WindSpeedChart(
    hourlyData: List<HourlyWeatherData>,
    windSpeedUnit: WindSpeedUnit,
    modifier: Modifier = Modifier
) {
    AndroidView(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp),
        factory = { context ->
            LineChart(context).apply {
                ChartFactory.styleLineChart(this)
                xAxis.valueFormatter = ChartFactory.HourFormatter()
                axisLeft.valueFormatter = ChartFactory.WindSpeedFormatter(
                    when (windSpeedUnit) {
                        WindSpeedUnit.MPH -> "mph"
                        WindSpeedUnit.KMH -> "km/h"
                        WindSpeedUnit.MS -> "m/s"
                        WindSpeedUnit.KNOTS -> "kn"
                    }
                )
            }
        },
        update = { chart ->
            val entries = hourlyData.mapIndexed { index, data ->
                Entry(index.toFloat(), data.windSpeed.toFloat())
            }
            
            val dataSet = ChartFactory.createLineDataSet(
                entries = entries,
                label = "Wind Speed",
                color = ChartFactory.WIND_COLOR,
                fillEnabled = false
            )
            
            chart.data = LineData(dataSet)
            chart.invalidate()
        }
    )
}

/**
 * Humidity chart with area fill
 */
@Composable
fun HumidityChart(
    hourlyData: List<HourlyWeatherData>,
    modifier: Modifier = Modifier
) {
    AndroidView(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp),
        factory = { context ->
            LineChart(context).apply {
                ChartFactory.styleLineChart(this)
                xAxis.valueFormatter = ChartFactory.HourFormatter()
                axisLeft.valueFormatter = ChartFactory.PercentageFormatter()
                axisLeft.axisMinimum = 0f
                axisLeft.axisMaximum = 100f
            }
        },
        update = { chart ->
            val entries = hourlyData.mapIndexed { index, data ->
                Entry(index.toFloat(), data.humidity.toFloat())
            }
            
            val dataSet = ChartFactory.createLineDataSet(
                entries = entries,
                label = "Humidity",
                color = ChartFactory.HUMIDITY_COLOR,
                fillEnabled = true
            )
            
            chart.data = LineData(dataSet)
            chart.invalidate()
        }
    )
}
