import Foundation

struct RateSnapshot: Codable, Equatable, Sendable {
    var base: String
    var date: String
    var rates: [String: Double]
    var fetchedAt: Date

    var currencies: [String] {
        var set = Set(rates.keys)
        set.insert(base)
        return set.sorted()
    }
}

enum CurrencyEngine {
    static func convert(amount: Double, from: String, to: String, snapshot: RateSnapshot) throws -> Double {
        let src = from.uppercased()
        let dst = to.uppercased()
        if src == dst { return amount }
        let base = snapshot.base.uppercased()
        let sourceInBase: Double
        if src == base {
            sourceInBase = amount
        } else if let rate = snapshot.rates[src], rate != 0 {
            sourceInBase = amount / rate
        } else {
            throw KilnError.unsupported
        }
        if dst == base { return sourceInBase }
        guard let destRate = snapshot.rates[dst] else { throw KilnError.unsupported }
        return sourceInBase * destRate
    }
}

struct RateCache: Sendable {
    var fileURL: URL

    static var defaultFileURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = root.appendingPathComponent("Kiln", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("frankfurter-rates.json")
    }

    func load() -> RateSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(RateSnapshot.self, from: data)
    }

    func save(_ snapshot: RateSnapshot) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    static func isStale(_ snapshot: RateSnapshot, now: Date = Date(), maxAge: TimeInterval = 3600) -> Bool {
        now.timeIntervalSince(snapshot.fetchedAt) > maxAge
    }
}

protocol RateFetching: Sendable {
    func fetchRates(base: String) async throws -> RateSnapshot
}

struct FrankfurterClient: RateFetching {
    var session: URLSession = .shared
    var endpointRoot = "https://api.frankfurter.dev"

    func fetchRates(base: String) async throws -> RateSnapshot {
        guard var components = URLComponents(string: "\(endpointRoot)/v2/rates") else {
            throw KilnError.conversionFailed("Bad Frankfurter URL")
        }
        components.queryItems = [URLQueryItem(name: "base", value: base.uppercased())]
        guard let url = components.url else { throw KilnError.conversionFailed("Bad Frankfurter URL") }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw KilnError.conversionFailed("Frankfurter HTTP \(http.statusCode)")
        }
        return try Self.decodeRates(data, fetchedAt: Date(), fallbackBase: base.uppercased())
    }

    static func decodeRates(_ data: Data, fetchedAt: Date, fallbackBase: String) throws -> RateSnapshot {
        let json = try JSONSerialization.jsonObject(with: data)
        if let rows = json as? [[String: Any]] {
            return try decodeV2Rows(rows, fetchedAt: fetchedAt, fallbackBase: fallbackBase)
        }
        if let object = json as? [String: Any] {
            return try decodeLegacyObject(object, fetchedAt: fetchedAt, fallbackBase: fallbackBase)
        }
        throw KilnError.conversionFailed("Bad rates JSON")
    }

    /// Live `GET /v2/rates` body: `[{date, base, quote, rate}, ...]`.
    private static func decodeV2Rows(_ rows: [[String: Any]], fetchedAt: Date, fallbackBase: String) throws -> RateSnapshot {
        let wanted = fallbackBase.uppercased()
        var rates: [String: Double] = [:]
        var date = ""
        var resolvedBase = wanted
        for row in rows {
            let rowBase = (row["base"] as? String)?.uppercased() ?? wanted
            if rowBase != wanted, !rates.isEmpty, resolvedBase == wanted {
                continue
            }
            if rates.isEmpty { resolvedBase = rowBase }
            if rowBase != resolvedBase { continue }
            guard let quote = (row["quote"] as? String)?.uppercased() else { continue }
            let rate: Double?
            if let n = row["rate"] as? Double { rate = n }
            else if let n = row["rate"] as? NSNumber { rate = n.doubleValue }
            else { rate = nil }
            guard let rate else { continue }
            rates[quote] = rate
            if let rowDate = row["date"] as? String, rowDate > date {
                date = rowDate
            }
        }
        rates[resolvedBase] = 1
        if rates.count <= 1 { throw KilnError.conversionFailed("No rates in payload") }
        return RateSnapshot(base: resolvedBase, date: date, rates: rates, fetchedAt: fetchedAt)
    }

    private static func decodeLegacyObject(_ object: [String: Any], fetchedAt: Date, fallbackBase: String) throws -> RateSnapshot {
        let base = (object["base"] as? String)?.uppercased() ?? fallbackBase
        let date = object["date"] as? String ?? ""
        var rates: [String: Double] = [:]
        if let dict = object["rates"] as? [String: Any] {
            for (code, raw) in dict {
                if let n = raw as? Double {
                    rates[code.uppercased()] = n
                } else if let n = raw as? NSNumber {
                    rates[code.uppercased()] = n.doubleValue
                }
            }
        }
        rates[base] = 1
        if rates.count <= 1 { throw KilnError.conversionFailed("No rates in payload") }
        return RateSnapshot(base: base, date: date, rates: rates, fetchedAt: fetchedAt)
    }
}
