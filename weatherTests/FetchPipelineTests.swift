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

    /// The shared sample forecast (65.0 degrees, what the cache tests expect) with `latitude` replaced,
    /// so a response identifies which request produced it and concurrent tests agree on the data.
    static func forecastJSON(latitude: Double) -> Data {
        guard var object = (try? JSONSerialization.jsonObject(with: Data(MockWeatherData.sampleJSON.utf8))) as? [String: Any],
              let data = {
                  object["latitude"] = latitude
                  return try? JSONSerialization.data(withJSONObject: object)
              }() else {
            return Data()
        }
        return data
    }

    private var pending: DispatchWorkItem?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let latitude = items?.first(where: { $0.name == "latitude" })?.value
            ?? items?.first(where: { $0.name == "location" })?.value?.split(separator: ",").first.map(String.init)
            ?? "0"
        // Like the real APIs: Tomorrow.io rejects our test keys, Open-Meteo rejects impossible coordinates.
        let status: Int
        if url.host?.contains("tomorrow.io") == true {
            status = 401
        } else if let lat = Double(latitude), abs(lat) > 90 {
            status = 400
        } else {
            status = 200
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
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: status == 200 ? Self.forecastJSON(latitude: Double(latitude) ?? 0) : Data("{}".utf8))
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
@Suite(.serialized, .sharedGlobalState)
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

    // #103: background refresh needs to know whether the fetch worked.
    @Test func fetchReportsSuccessAndFailure() async {
        let service = makeService()
        StubURLProtocol.stub(latitude: 12.5)
        StubURLProtocol.stub(latitude: -12.5, .init(failure: .notConnectedToInternet))

        let ok = await service.fetchWeatherData(latitude: 12.5, longitude: 0, locationName: "A")
        let failed = await service.fetchWeatherData(latitude: -12.5, longitude: 0, locationName: "B")

        #expect(ok == true)
        #expect(failed == false)
    }

    // #99: previews/comparison/widgets use a stateless fetch that leaves the service untouched.
    @Test func statelessForecastFetchDoesNotChangeServiceState() async throws {
        // Start with nothing persisted, so a new service has no forecast to begin with.
        for key in ["lastWeatherLatitude", "lastWeatherLongitude", "lastWeatherLocationName"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        if let file = SharedDataManager.cachedWeatherFilePrimaryURL {
            try? FileManager.default.removeItem(at: file)
        }
        let service = makeService()
        StubURLProtocol.stub(latitude: 13.5)

        let forecast = try await WeatherService.fetchForecast(latitude: 13.5, longitude: 0, session: StubURLProtocol.makeSession())

        #expect(forecast.latitude == 13.5)
        #expect(service.weatherData == nil)
        #expect(service.currentLocationName == nil)
    }
}

// MARK: - Background task completion

struct BackgroundTaskCompletionTests {
    // #103: expiry and the finishing work can race; the task must be completed exactly once.
    @Test func completesOnlyOnce() {
        let results = ResultsBox()
        let completion = BackgroundTaskCompletion { results.append($0) }

        completion.complete(success: false) // expiration handler
        completion.complete(success: true) // work finishing afterwards

        #expect(results.values == [false])
    }
}

private nonisolated final class ResultsBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Bool] = []
    func append(_ value: Bool) { lock.withLock { stored.append(value) } }
    var values: [Bool] { lock.withLock { stored } }
}

// MARK: - Offline service for tests

/// A WeatherService wired to the stub network, so tests never reach the live APIs. Use this
/// instead of `WeatherService()` in any test that fetches.
@MainActor
enum StubbedWeather {
    static func service() -> WeatherService {
        let session = StubURLProtocol.makeSession()
        return WeatherService(session: session, forceRefreshSession: session, fetchesSecondaryData: false)
    }
}
