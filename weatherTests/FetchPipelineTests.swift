//
//  FetchPipelineTests.swift
//  weatherTests
//
//  WeatherService.fetchWeatherData against a stubbed network (no live requests).
//

import Foundation
import Testing
@testable import weather

// MARK: - Stub network

/// Serves canned Open-Meteo forecasts keyed by the request's `latitude`, optionally delayed or failing.
nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub {
        var delay: TimeInterval = 0
        var failure: URLError.Code?
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var stubs: [String: Stub] = [:]
    nonisolated(unsafe) private static var requests: [String] = []

    static func reset() {
        lock.withLock {
            stubs = [:]
            requests = []
        }
    }

    static func stub(latitude: Double, _ stub: Stub = Stub()) {
        lock.withLock { stubs[String(latitude)] = stub }
    }

    static func requestCount(latitude: Double) -> Int {
        lock.withLock { requests.filter { $0 == String(latitude) }.count }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// A forecast whose `latitude` identifies which stub produced it.
    static func forecastJSON(latitude: Double) -> Data {
        Data("""
        {
            "latitude": \(latitude),
            "longitude": 0.0,
            "timezone": "UTC",
            "current": {
                "time": "2026-02-14T12:00",
                "temperature_2m": 50.0,
                "apparent_temperature": 50.0,
                "weather_code": 0,
                "is_day": 1,
                "precipitation": 0.0,
                "wind_speed_10m": 0.0,
                "wind_direction_10m": 0,
                "wind_gusts_10m": 0.0,
                "relative_humidity_2m": 0,
                "dew_point_2m": 0.0,
                "surface_pressure": 1000.0,
                "visibility": 10000,
                "uv_index": 0.0,
                "cloud_cover": 0
            },
            "hourly": {
                "time": ["2026-02-14T12:00"],
                "temperature_2m": [50.0],
                "weather_code": [0],
                "precipitation_probability": [0]
            },
            "daily": {
                "time": ["2026-02-14"],
                "weather_code": [0],
                "temperature_2m_max": [50.0],
                "temperature_2m_min": [40.0],
                "sunrise": ["2026-02-14T07:00"],
                "sunset": ["2026-02-14T17:00"],
                "precipitation_probability_max": [0],
                "uv_index_max": [0.0],
                "wind_speed_10m_max": [0.0],
                "wind_gusts_10m_max": [0.0]
            }
        }
        """.utf8)
    }

    private var pending: DispatchWorkItem?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let latitude = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == "latitude" })?.value else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let stub = Self.lock.withLock { () -> Stub in
            Self.requests.append(latitude)
            return Self.stubs[latitude] ?? Stub()
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if let failure = stub.failure {
                self.client?.urlProtocol(self, didFailWithError: URLError(failure))
                return
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: Self.forecastJSON(latitude: Double(latitude) ?? 0))
            self.client?.urlProtocolDidFinishLoading(self)
        }
        pending = work
        DispatchQueue.global().asyncAfter(deadline: .now() + stub.delay, execute: work)
    }

    override func stopLoading() {
        pending?.cancel()
    }
}

// MARK: - Tests

/// Serialized: the stub registry is shared. Each test uses its own latitudes so cached results
/// from one test can't satisfy another.
@Suite(.serialized)
@MainActor
struct FetchPipelineTests {

    private func makeService() -> WeatherService {
        StubURLProtocol.reset()
        let session = StubURLProtocol.makeSession()
        return WeatherService(session: session, forceRefreshSession: session, fetchesSecondaryData: false)
    }

    @Test func stubbedForecastDecodes() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 10.5)

        await service.fetchWeatherData(latitude: 10.5, longitude: 0, locationName: "Ten")

        #expect(service.weatherData?.latitude == 10.5)
        #expect(service.currentLocationName == "Ten")
        #expect(service.errorMessage == nil)
    }

    // #96: a different place inside the 60 s window must still fetch.
    @Test func differentLocationWithinDebounceWindowFetches() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 20.5)
        StubURLProtocol.stub(latitude: 30.5)

        await service.fetchWeatherData(latitude: 20.5, longitude: 0, locationName: "A")
        await service.fetchWeatherData(latitude: 30.5, longitude: 0, locationName: "B")

        #expect(service.weatherData?.latitude == 30.5)
        #expect(service.currentLocationName == "B")
    }

    @Test func sameLocationWithinDebounceWindowIsSkipped() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 40.5)

        await service.fetchWeatherData(latitude: 40.5, longitude: 0, locationName: "A")
        await service.fetchWeatherData(latitude: 40.5, longitude: 0, locationName: "A")

        #expect(StubURLProtocol.requestCount(latitude: 40.5) == 1)
    }

    // #107: an explicit refresh is honored once the short floor has passed, but not instantly.
    @Test func forceRefreshRightAfterFetchIsSkippedByFloor() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 50.5)

        await service.fetchWeatherData(latitude: 50.5, longitude: 0, locationName: "A")
        await service.fetchWeatherData(latitude: 50.5, longitude: 0, locationName: "A", forceRefresh: true)

        #expect(StubURLProtocol.requestCount(latitude: 50.5) == 1)
    }

    // #97: a slow response for the previous location must not overwrite the newer one.
    @Test func slowEarlierResponseDoesNotOverwriteNewerLocation() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 60.5, .init(delay: 0.6))
        StubURLProtocol.stub(latitude: 70.5)

        let slow = Task { await service.fetchWeatherData(latitude: 60.5, longitude: 0, locationName: "Slow") }
        try? await Task.sleep(for: .milliseconds(100))
        await service.fetchWeatherData(latitude: 70.5, longitude: 0, locationName: "Fast")
        await slow.value

        #expect(service.weatherData?.latitude == 70.5)
        #expect(service.currentLocationName == "Fast")
        #expect(service.isLoading == false)
    }

    // #98: when the new place fails offline, don't show the old place's data under the new name.
    @Test func offlineFailureKeepsPreviousLocationAndName() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 80.5)
        StubURLProtocol.stub(latitude: -80.5, .init(failure: .notConnectedToInternet))

        await service.fetchWeatherData(latitude: 80.5, longitude: 0, locationName: "Old")
        await service.fetchWeatherData(latitude: -80.5, longitude: 0, locationName: "New")

        #expect(service.weatherData?.latitude == 80.5)
        #expect(service.currentLocationName == "Old")
        #expect(service.errorMessage != nil)
    }

    // #108: cancelling is not an error.
    @Test func cancelledFetchShowsNoError() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 15.5, .init(delay: 5))

        let task = Task { await service.fetchWeatherData(latitude: 15.5, longitude: 0, locationName: "A") }
        try? await Task.sleep(for: .milliseconds(150))
        task.cancel()
        await task.value

        #expect(service.errorMessage == nil)
        #expect(service.lastError == nil)
        #expect(service.isLoading == false)
    }
}
