import XCTest
import Foundation
@testable import Kiln

final class KilnUnitsTests: XCTestCase {
    func testLengthKilometersToMeters() throws {
        let meters = try MeasurementEngine.convert(value: 1, category: .length, from: "km", to: "m")
        XCTAssertEqual(meters, 1000, accuracy: 0.0001)
    }

    func testTemperatureFahrenheitToCelsius() throws {
        let celsius = try MeasurementEngine.convert(value: 32, category: .temperature, from: "F", to: "C")
        XCTAssertEqual(celsius, 0, accuracy: 0.0001)
    }

    func testDataMebibytesToKibibytes() throws {
        let kib = try MeasurementEngine.convert(value: 1, category: .data, from: "MiB", to: "KiB")
        XCTAssertEqual(kib, 1024, accuracy: 0.0001)
    }

    func testAllNamedCategoriesHaveConvertibleUnits() {
        let required: [UnitCategory] = [
            .angle, .area, .data, .energy, .force, .fuel, .length, .power,
            .pressure, .speed, .temperature, .time, .volume, .weight,
        ]
        for category in required {
            let specs = UnitsCatalog.specs(for: category)
            XCTAssertGreaterThanOrEqual(specs.count, 2, "\(category.rawValue)")
            let from = specs[0].id
            let to = specs[1].id
            do {
                _ = try MeasurementEngine.convert(value: 1, category: category, from: from, to: to)
            } catch {
                XCTFail("\(category.rawValue) \(from)->\(to): \(error)")
            }
        }
        XCTAssertTrue(UnitCategory.allCases.contains(.currency))
        XCTAssertTrue(UnitCategory.allCases.contains(.frequency))
        XCTAssertTrue(UnitCategory.allCases.contains(.acceleration))
        XCTAssertTrue(UnitCategory.allCases.contains(.illuminance))
    }

    func testCurrencyUsesFixtureRate() throws {
        let data = try Data(contentsOf: fixtureJSON())
        let root = try JSONSerialization.jsonObject(with: data)
        XCTAssertTrue(root is [[String: Any]], "fixture must be the live v2 row array")
        let snapshot = try FrankfurterClient.decodeRates(data, fetchedAt: Date(timeIntervalSince1970: 1_700_000_000), fallbackBase: "EUR")
        XCTAssertEqual(snapshot.base, "EUR")
        XCTAssertEqual(snapshot.date, "2026-08-13")
        let usdRate = try XCTUnwrap(snapshot.rates["USD"])
        let gbpRate = try XCTUnwrap(snapshot.rates["GBP"])
        XCTAssertGreaterThan(usdRate, 0)
        let usd = try CurrencyEngine.convert(amount: 10, from: "EUR", to: "USD", snapshot: snapshot)
        XCTAssertEqual(usd, 10 * usdRate, accuracy: 0.0001)
        let back = try CurrencyEngine.convert(amount: usd, from: "USD", to: "EUR", snapshot: snapshot)
        XCTAssertEqual(back, 10.0, accuracy: 0.0001)
        let gbp = try CurrencyEngine.convert(amount: 10, from: "USD", to: "GBP", snapshot: snapshot)
        XCTAssertEqual(gbp, 10 / usdRate * gbpRate, accuracy: 0.0001)
    }

    func testDecodeRatesAcceptsLiveV2RowArray() throws {
        let liveShaped = """
        [{"date":"2026-08-14","base":"USD","quote":"EUR","rate":0.8661},{"date":"2026-08-14","base":"USD","quote":"GBP","rate":0.74084},{"date":"2026-08-14","base":"USD","quote":"USD","rate":1.0}]
        """.data(using: .utf8)!
        let snapshot = try FrankfurterClient.decodeRates(liveShaped, fetchedAt: Date(), fallbackBase: "USD")
        XCTAssertEqual(snapshot.base, "USD")
        XCTAssertEqual(snapshot.date, "2026-08-14")
        XCTAssertEqual(try XCTUnwrap(snapshot.rates["EUR"]), 0.8661, accuracy: 0.00001)
        let euros = try CurrencyEngine.convert(amount: 100, from: "USD", to: "EUR", snapshot: snapshot)
        XCTAssertEqual(euros, 86.61, accuracy: 0.0001)
    }

    func testRateCacheRoundTripAndStale() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("kiln-fx-\(UUID().uuidString)")
        let cache = RateCache(fileURL: dir.appendingPathComponent("rates.json"))
        let fetched = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = RateSnapshot(base: "EUR", date: "2026-08-13", rates: ["USD": 1.1], fetchedAt: fetched)
        try cache.save(snapshot)
        let loaded = try XCTUnwrap(cache.load())
        XCTAssertEqual(loaded, snapshot)
        XCTAssertFalse(RateCache.isStale(snapshot, now: fetched.addingTimeInterval(60), maxAge: 3600))
        XCTAssertTrue(RateCache.isStale(snapshot, now: fetched.addingTimeInterval(3601), maxAge: 3600))
    }

    func testRefreshUpdatesFetchedAt() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("kiln-fx-\(UUID().uuidString)")
        let cache = RateCache(fileURL: dir.appendingPathComponent("rates.json"))
        let first = Date(timeIntervalSince1970: 100)
        let second = Date(timeIntervalSince1970: 200)
        let fetcher = FixtureFetcher(data: try Data(contentsOf: fixtureJSON()), fetchedAt: second)
        let model = await MainActor.run {
            UnitsModel(fetcher: fetcher, cache: cache, now: { second })
        }
        await MainActor.run {
            model.snapshot = RateSnapshot(base: "EUR", date: "old", rates: ["USD": 1], fetchedAt: first)
            model.category = .currency
        }
        await model.refresh()
        let after = await MainActor.run { model.snapshot }
        XCTAssertEqual(after?.fetchedAt, second)
        XCTAssertEqual(after?.date, "2026-08-13")
        XCTAssertEqual(cache.load()?.fetchedAt, second)
    }

    func testJPEGStillNotAConvertEdge() throws {
        let jpeg = try XCTUnwrap(FormatCatalog.shared.format(id: "jpeg"))
        let dests = ConversionGraph().destinations(from: jpeg, mode: .convert)
        XCTAssertFalse(dests.contains(where: { $0.id == "jpeg" }))
    }

    func testUnitCodesStaySymbols() {
        XCTAssertEqual(UnitsCatalog.specs(for: .length).first(where: { $0.id == "km" })?.symbol, "km")
        XCTAssertEqual(UnitsCatalog.specs(for: .temperature).first(where: { $0.id == "C" })?.symbol, "°C")
    }

    private func fixtureJSON() -> URL {
        if let url = Bundle(for: KilnUnitsTests.self).url(forResource: "frankfurter-fixture", withExtension: "json") {
            return url
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("frankfurter-fixture.json")
    }
}

private struct FixtureFetcher: RateFetching {
    var data: Data
    var fetchedAt: Date

    func fetchRates(base: String) async throws -> RateSnapshot {
        try FrankfurterClient.decodeRates(data, fetchedAt: fetchedAt, fallbackBase: base)
    }
}
