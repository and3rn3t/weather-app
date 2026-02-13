package com.andernet.weather

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.andernet.weather.ui.screen.FavoritesScreen
import com.andernet.weather.ui.screen.HomeScreen
import com.andernet.weather.ui.screen.SearchScreen
import com.andernet.weather.ui.screen.SettingsScreen

/**
 * Navigation destinations
 */
sealed class Screen(val route: String, val title: String) {
    data object Home : Screen("home", "Home")
    data object Search : Screen("search", "Search")
    data object Favorites : Screen("favorites", "Favorites")
    data object Settings : Screen("settings", "Settings")
}

/**
 * Main app composable with bottom navigation
 */
@Composable
fun WeatherApp() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    
    val navigationItems = listOf(
        Screen.Home to Icons.Default.Home,
        Screen.Search to Icons.Default.Search,
        Screen.Favorites to Icons.Default.Favorite,
        Screen.Settings to Icons.Default.Settings
    )
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                navigationItems.forEach { (screen, icon) ->
                    NavigationBarItem(
                        icon = { Icon(icon, contentDescription = screen.title) },
                        label = { Text(screen.title) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                        onClick = {
                            navController.navigate(screen.route) {
                                // Pop up to the start destination to avoid building up a back stack
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                // Avoid multiple copies of the same destination
                                launchSingleTop = true
                                // Restore state when reselecting a previously selected item
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Home.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Home.route) {
                HomeScreen(
                    onNavigateToSearch = {
                        navController.navigate(Screen.Search.route)
                    }
                )
            }
            composable(Screen.Search.route) {
                SearchScreen()
            }
            composable(Screen.Favorites.route) {
                FavoritesScreen()
            }
            composable(Screen.Settings.route) {
                SettingsScreen()
            }
        }
    }
}
