import AppKit
import Foundation
import SwiftUI

@MainActor
final class UnitsModel: ObservableObject {
    @Published var category: UnitCategory = .length
    @Published var fromID: String = "km"
    @Published var toID: String = "m"
    @Published var inputText: String = "1"
    @Published var snapshot: RateSnapshot?
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var autoRefreshEnabled = true
    @Published var sidebarVisible = true

    var fetcher: any RateFetching
    var cache: RateCache
    var now: () -> Date

    static let refreshInterval: TimeInterval = 3600

    init(
        fetcher: any RateFetching = FrankfurterClient(),
        cache: RateCache = RateCache(fileURL: RateCache.defaultFileURL),
        now: @escaping () -> Date = Date.init
    ) {
        self.fetcher = fetcher
        self.cache = cache
        self.now = now
        self.snapshot = cache.load()
    }

    var unitSpecs: [UnitSpec] {
        if category.isCurrency {
            return (snapshot?.currencies ?? ["EUR", "USD", "GBP"]).map { UnitSpec(id: $0, symbol: $0) }
        }
        return UnitsCatalog.specs(for: category)
    }

    var result: Double? {
        guard let value = parseInput else { return nil }
        if category.isCurrency {
            guard let snapshot else { return nil }
            return try? CurrencyEngine.convert(amount: value, from: fromID, to: toID, snapshot: snapshot)
        }
        return try? MeasurementEngine.convert(value: value, category: category, from: fromID, to: toID)
    }

    var parseInput: Double? {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if trimmed.isEmpty { return 0 }
        return Double(trimmed)
    }

    var isStale: Bool {
        guard let snapshot else { return category.isCurrency }
        return RateCache.isStale(snapshot, now: now(), maxAge: Self.refreshInterval)
    }

    var lastUpdatedLabel: String? {
        guard let snapshot else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let local = formatter.string(from: snapshot.fetchedAt)
        if snapshot.date.isEmpty { return local }
        return "\(local) · \(snapshot.date)"
    }

    func select(category: UnitCategory) {
        self.category = category
        let specs = unitSpecs
        if specs.isEmpty {
            fromID = "EUR"
            toID = "USD"
            return
        }
        fromID = specs[0].id
        toID = specs.count > 1 ? specs[1].id : specs[0].id
    }

    func swap() {
        let previous = fromID
        fromID = toID
        toID = previous
    }

    func copyResult() {
        guard let result else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(format(result), forType: .string)
    }

    func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = category == .temperature || category == .currency ? 4 : 8
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    func refreshIfNeeded() async {
        guard category.isCurrency else { return }
        if snapshot == nil || (autoRefreshEnabled && isStale) {
            await refresh()
        }
    }

    func refresh() async {
        isRefreshing = true
        errorMessage = nil
        do {
            let base = snapshot?.base ?? "USD"
            let next = try await fetcher.fetchRates(base: base)
            snapshot = next
            try cache.save(next)
            if category.isCurrency, !unitSpecs.contains(where: { $0.id == fromID }) {
                select(category: .currency)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isRefreshing = false
    }
}
