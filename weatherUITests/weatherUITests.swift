//
//  weatherUITests.swift
//  weatherUITests
//
//  Created by Matt on 2/4/26.
//

import XCTest

final class weatherUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    @MainActor
    func testWelcomeScreenOrWeatherDisplays() throws {
        let welcomeText = app.staticTexts["Welcome to Weather"]
        let loadingExists = app.staticTexts["Loading weather data..."].exists
        let navigationBar = app.navigationBars.firstMatch
        
        let exists = welcomeText.waitForExistence(timeout: 5) || loadingExists || navigationBar.exists
        XCTAssertTrue(exists, "Either welcome screen, loading, or weather should be visible")
    }
    
    // MARK: - Settings Tests
    
    @MainActor
    func testOpenSettings() throws {
        let settingsButton = app.buttons["gear"].firstMatch
        
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            
            let settingsTitle = app.staticTexts["Settings"].firstMatch
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3), "Settings title should appear")
        }
    }
    
    @MainActor
    func testSettingsContainsUnitsSection() throws {
        let settingsButton = app.buttons["gear"].firstMatch
        
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            
            let unitsHeader = app.staticTexts["Units"].firstMatch
            XCTAssertTrue(unitsHeader.waitForExistence(timeout: 3), "Units section should exist")
        }
    }
    
    // MARK: - Favorites Tests
    
    @MainActor
    func testOpenFavorites() throws {
        let favoritesButton = app.buttons["list.bullet"].firstMatch
        
        if favoritesButton.waitForExistence(timeout: 5) {
            favoritesButton.tap()
            
            let favoritesTitle = app.staticTexts["Favorites"].firstMatch
            XCTAssertTrue(favoritesTitle.waitForExistence(timeout: 3), "Favorites title should appear")
        }
    }
    
    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
