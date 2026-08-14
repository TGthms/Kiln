import Foundation

enum UnitCategory: String, CaseIterable, Identifiable, Sendable {
    case angle
    case area
    case currency
    case data
    case energy
    case force
    case fuel
    case length
    case power
    case pressure
    case speed
    case temperature
    case time
    case volume
    case weight
    case frequency
    case acceleration
    case illuminance

    var id: String { rawValue }

    var localizationKey: String { "category.\(rawValue)" }

    var isCurrency: Bool { self == .currency }
}

struct UnitSpec: Identifiable, Hashable, Sendable {
    var id: String
    var symbol: String
}
