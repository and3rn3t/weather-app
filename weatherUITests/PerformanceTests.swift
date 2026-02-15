//
//  PerformanceTests.swift
//  weatherUITests
//
//  Performance tests for measuring app launch time, memory usage, and UI responsiveness
//

import XCTest

nonisolated(unsafe)
final class PerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "PERFORMANCE_TESTING"]
    }
    
    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }
    
    // MARK: - Launch Performance Tests
    
    func testColdLaunchPerformance() throws {
        // Measure cold launch performance - most important metric for user experience
        measure(metrics: [
            XCTApplicationLaunchMetric(waitUntilResponsive: true),
            XCTMemoryMetric(),
            XCTCPUMetric()
        ]) {
            app.launch()
            
            // Wait for main weather view or welcome screen to appear
            let weatherDisplayed = app.staticTexts["Loading weather data..."].waitForExistence(timeout: 2) ||
                                 app.navigationBars.firstMatch.waitForExistence(timeout: 2) ||
                                 app.staticTexts["Welcome to Weather"].waitForExistence(timeout: 2)
            
            XCTAssertTrue(weatherDisplayed, "App should show weather, loading, or welcome screen within 2 seconds")
        }
    }
    
    func testWarmLaunchPerformance() throws {
        // Test performance when app is backgrounded and foregrounded
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        // Background the app
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Foreground and measure
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.activate()
            _ = app.wait(for: .runningForeground, timeout: 2)
        }
    }
    
    func testDataLoadingPerformance() throws {
        // Measure time from app launch to weather data display
        let startTime = Date()
        app.launch()
        
        // Wait for actual weather data (not just loading spinner)
        let weatherLoaded = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '°'")).firstMatch.waitForExistence(timeout: 10)
        
        let loadTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(weatherLoaded, "Weather data should load within 10 seconds")
        XCTAssertLessThan(loadTime, 8.0, "Weather data should load within 8 seconds for good UX")
        
        // Record measurement for CI/Analytics
        measure {
            // This records the baseline
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageDuringNormalUsage() throws {
        // Measure memory footprint during typical app usage
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Simulate typical user interactions that might cause memory pressure
            
            // Scroll through forecast
            let scrollView = app.scrollViews.firstMatch
            if scrollView.waitForExistence(timeout: 5) {
                for _ in 0..<5 {
                    scrollView.swipeUp(velocity: .slow)
                    usleep(100_000) // 0.1 second pause
                }
                for _ in 0..<5 {
                    scrollView.swipeDown(velocity: .slow)
                    usleep(100_000)
                }
            }
            
            // Navigate to settings
            let settingsButton = app.buttons["settingsButton"].firstMatch
            if settingsButton.waitForExistence(timeout: 3) {
                settingsButton.tap()
                sleep(1)
                
                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
            
            // Open favorites if available
            let favoritesButton = app.buttons["list.bullet"].firstMatch
            if favoritesButton.waitForExistence(timeout: 3) {
                favoritesButton.tap()
                sleep(1)
                
                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                    sleep(1)
                }
            }
        }
    }
    
    func testMemoryLeaksWithRepeatedOperations() throws {
        // Test for memory leaks by repeating operations
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        let initialMemoryMetric = XCTMemoryMetric()
        
        measure(metrics: [initialMemoryMetric]) {
            // Repeat operations that might cause memory leaks
            for _ in 0..<10 {
                // Open and close settings
                let settingsButton = app.buttons["settingsButton"].firstMatch
                if settingsButton.waitForExistence(timeout: 1) {
                    settingsButton.tap()
                    usleep(200_000) // 0.2s
                    
                    let backButton = app.navigationBars.buttons.firstMatch
                    if backButton.exists {
                        backButton.tap()
                        usleep(200_000)
                    }
                }
                
                // Trigger refresh if pull-to-refresh is available
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    // Simulate refresh gesture
                    scrollView.swipeDown(velocity: .fast)
                    usleep(500_000) // 0.5s for refresh to complete
                }
            }
        }
    }
    
    // MARK: - UI Responsiveness Tests
    
    func testScrollingPerformance() throws {
        // Test smooth scrolling performance
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10), "Scroll view should be available")
        
        measure(metrics: [
            XCTOSSignpostMetric.scrollingAndDecelerationMetric,
            XCTCPUMetric()
        ]) {
            // Test different scroll velocities
            scrollView.swipeUp(velocity: .fast)
            usleep(500_000) // Wait for deceleration
            
            scrollView.swipeUp(velocity: .slow)
            usleep(300_000)
            
            scrollView.swipeDown(velocity: .fast)
            usleep(500_000)
            
            scrollView.swipeDown(velocity: .slow)
            usleep(300_000)
        }
    }
    
    func testAnimationPerformance() throws {
        // Test performance of app animations and transitions
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        measure(metrics: [
            XCTOSSignpostMetric.applicationLaunch,
            XCTCPUMetric()
        ]) {
            // Test various UI animations
            
            // Navigation animations
            let settingsButton = app.buttons["settingsButton"].firstMatch
            if settingsButton.waitForExistence(timeout: 3) {
                settingsButton.tap()
                usleep(800_000) // Animation duration
                
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                    usleep(800_000)
                }
            }
            
            // Sheet presentations (if favorites is implemented as sheet)
            let favoritesButton = app.buttons["list.bullet"].firstMatch
            if favoritesButton.waitForExistence(timeout: 3) {
                favoritesButton.tap()
                usleep(600_000) // Sheet animation
                
                // Dismiss sheet
                let dismissArea = app.otherElements.firstMatch
                if dismissArea.exists {
                    dismissArea.tap()
                    usleep(600_000)
                }
            }
        }
    }
    
    // MARK: - Network Performance Tests
    
    func testNetworkLoadingPerformance() throws {
        // Test how network requests affect UI performance
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            // Trigger refresh multiple times to test network performance
            let scrollView = app.scrollViews.firstMatch
            if scrollView.waitForExistence(timeout: 5) {
                // Pull to refresh
                scrollView.swipeDown(velocity: .fast)
                sleep(2) // Wait for network request
                
                // Second refresh
                scrollView.swipeDown(velocity: .fast)
                sleep(2)
            }
        }
    }
    
    // MARK: - Battery Performance Tests
    
    func testCPUUsageEfficiency() throws {
        // Measure CPU efficiency during normal usage
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        measure(metrics: [XCTCPUMetric()]) {
            // Simulate 30 seconds of normal usage
            let endTime = Date().addingTimeInterval(5) // Shortened for test speed
            
            while Date() < endTime {
                // Scroll around
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    scrollView.swipeUp(velocity: .slow)
                    usleep(200_000)
                    scrollView.swipeDown(velocity: .slow)
                    usleep(200_000)
                }
                
                // Check current time to avoid infinite loop
                if Date() >= endTime { break }
            }
        }
    }
    
    // MARK: - Regression Prevention Tests
    
    func testPerformanceBaseline() throws {
        // Establishes performance baseline for regression detection
        let launchMetric = XCTApplicationLaunchMetric(waitUntilResponsive: true)
        
        measure(metrics: [launchMetric]) {
            app.launch()
            
            // Wait for app to be fully ready
            let isReady = app.navigationBars.firstMatch.waitForExistence(timeout: 10) ||
                         app.staticTexts["Welcome to Weather"].waitForExistence(timeout: 10)
            
            XCTAssertTrue(isReady, "App should be ready within 10 seconds")
        }
    }
    
    func testPerformanceUnderStress() throws {
        // Test performance when system is under memory pressure
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
        
        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            // Stress test by rapidly performing operations
            for i in 0..<20 {
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    if i % 2 == 0 {
                        scrollView.swipeUp(velocity: .fast)
                    } else {
                        scrollView.swipeDown(velocity: .fast)
                    }
                    usleep(50_000) // Very short pause to stress the system
                }
                
                // Periodically trigger navigation
                if i % 5 == 0 {
                    let settingsButton = app.buttons["settingsButton"].firstMatch
                    if settingsButton.exists {
                        settingsButton.tap()
                        usleep(100_000)
                        
                        let backButton = app.navigationBars.buttons.firstMatch
                        if backButton.exists {
                            backButton.tap()
                            usleep(100_000)
                        }
                    }
                }
            }
        }
    }
}