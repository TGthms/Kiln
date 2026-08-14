import Foundation

enum MeasurementEngine {
    static func convert(value: Double, category: UnitCategory, from fromID: String, to toID: String) throws -> Double {
        if fromID == toID { return value }
        guard let from = UnitsCatalog.dimension(category: category, id: fromID),
              let to = UnitsCatalog.dimension(category: category, id: toID) else {
            throw KilnError.unsupported
        }
        let measurement = Measurement(value: value, unit: from)
        return measurement.converted(to: to).value
    }
}
