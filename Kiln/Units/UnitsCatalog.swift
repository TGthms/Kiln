import Foundation

enum UnitsCatalog {
    static func specs(for category: UnitCategory) -> [UnitSpec] {
        switch category {
        case .currency:
            return []
        case .angle:
            return [
                UnitSpec(id: "deg", symbol: "°"),
                UnitSpec(id: "rad", symbol: "rad"),
                UnitSpec(id: "arcmin", symbol: "′"),
                UnitSpec(id: "arcsec", symbol: "″"),
                UnitSpec(id: "grad", symbol: "grad"),
                UnitSpec(id: "rev", symbol: "rev"),
            ]
        case .area:
            return [
                UnitSpec(id: "m2", symbol: "m²"),
                UnitSpec(id: "km2", symbol: "km²"),
                UnitSpec(id: "cm2", symbol: "cm²"),
                UnitSpec(id: "mm2", symbol: "mm²"),
                UnitSpec(id: "ha", symbol: "ha"),
                UnitSpec(id: "acre", symbol: "ac"),
                UnitSpec(id: "ft2", symbol: "ft²"),
                UnitSpec(id: "in2", symbol: "in²"),
                UnitSpec(id: "yd2", symbol: "yd²"),
                UnitSpec(id: "mi2", symbol: "mi²"),
            ]
        case .data:
            return [
                UnitSpec(id: "B", symbol: "B"),
                UnitSpec(id: "bit", symbol: "bit"),
                UnitSpec(id: "kB", symbol: "kB"),
                UnitSpec(id: "MB", symbol: "MB"),
                UnitSpec(id: "GB", symbol: "GB"),
                UnitSpec(id: "TB", symbol: "TB"),
                UnitSpec(id: "KiB", symbol: "KiB"),
                UnitSpec(id: "MiB", symbol: "MiB"),
                UnitSpec(id: "GiB", symbol: "GiB"),
                UnitSpec(id: "TiB", symbol: "TiB"),
            ]
        case .energy:
            return [
                UnitSpec(id: "J", symbol: "J"),
                UnitSpec(id: "kJ", symbol: "kJ"),
                UnitSpec(id: "cal", symbol: "cal"),
                UnitSpec(id: "kcal", symbol: "kcal"),
                UnitSpec(id: "kWh", symbol: "kWh"),
            ]
        case .force:
            return [
                UnitSpec(id: "N", symbol: "N"),
                UnitSpec(id: "kN", symbol: "kN"),
                UnitSpec(id: "lbf", symbol: "lbf"),
                UnitSpec(id: "kgf", symbol: "kgf"),
            ]
        case .fuel:
            return [
                UnitSpec(id: "L100km", symbol: "L/100km"),
                UnitSpec(id: "mpg", symbol: "mpg"),
                UnitSpec(id: "mpgUK", symbol: "mpg (UK)"),
            ]
        case .length:
            return [
                UnitSpec(id: "m", symbol: "m"),
                UnitSpec(id: "km", symbol: "km"),
                UnitSpec(id: "cm", symbol: "cm"),
                UnitSpec(id: "mm", symbol: "mm"),
                UnitSpec(id: "mi", symbol: "mi"),
                UnitSpec(id: "yd", symbol: "yd"),
                UnitSpec(id: "ft", symbol: "ft"),
                UnitSpec(id: "in", symbol: "in"),
                UnitSpec(id: "nmi", symbol: "nmi"),
            ]
        case .power:
            return [
                UnitSpec(id: "W", symbol: "W"),
                UnitSpec(id: "kW", symbol: "kW"),
                UnitSpec(id: "MW", symbol: "MW"),
                UnitSpec(id: "hp", symbol: "hp"),
            ]
        case .pressure:
            return [
                UnitSpec(id: "Pa", symbol: "Pa"),
                UnitSpec(id: "kPa", symbol: "kPa"),
                UnitSpec(id: "bar", symbol: "bar"),
                UnitSpec(id: "mbar", symbol: "mbar"),
                UnitSpec(id: "psi", symbol: "psi"),
                UnitSpec(id: "atm", symbol: "atm"),
                UnitSpec(id: "mmHg", symbol: "mmHg"),
                UnitSpec(id: "inHg", symbol: "inHg"),
            ]
        case .speed:
            return [
                UnitSpec(id: "m_s", symbol: "m/s"),
                UnitSpec(id: "km_h", symbol: "km/h"),
                UnitSpec(id: "mph", symbol: "mph"),
                UnitSpec(id: "kn", symbol: "kn"),
            ]
        case .temperature:
            return [
                UnitSpec(id: "C", symbol: "°C"),
                UnitSpec(id: "F", symbol: "°F"),
                UnitSpec(id: "K", symbol: "K"),
            ]
        case .time:
            return [
                UnitSpec(id: "s", symbol: "s"),
                UnitSpec(id: "min", symbol: "min"),
                UnitSpec(id: "h", symbol: "h"),
                UnitSpec(id: "d", symbol: "d"),
            ]
        case .volume:
            return [
                UnitSpec(id: "L", symbol: "L"),
                UnitSpec(id: "mL", symbol: "mL"),
                UnitSpec(id: "m3", symbol: "m³"),
                UnitSpec(id: "gal", symbol: "gal"),
                UnitSpec(id: "galUK", symbol: "gal (UK)"),
                UnitSpec(id: "qt", symbol: "qt"),
                UnitSpec(id: "pt", symbol: "pt"),
                UnitSpec(id: "cup", symbol: "cup"),
                UnitSpec(id: "floz", symbol: "fl oz"),
            ]
        case .weight:
            return [
                UnitSpec(id: "g", symbol: "g"),
                UnitSpec(id: "kg", symbol: "kg"),
                UnitSpec(id: "mg", symbol: "mg"),
                UnitSpec(id: "t", symbol: "t"),
                UnitSpec(id: "lb", symbol: "lb"),
                UnitSpec(id: "oz", symbol: "oz"),
                UnitSpec(id: "st", symbol: "st"),
            ]
        case .frequency:
            return [
                UnitSpec(id: "Hz", symbol: "Hz"),
                UnitSpec(id: "kHz", symbol: "kHz"),
                UnitSpec(id: "MHz", symbol: "MHz"),
                UnitSpec(id: "GHz", symbol: "GHz"),
            ]
        case .acceleration:
            return [
                UnitSpec(id: "m_s2", symbol: "m/s²"),
                UnitSpec(id: "g0", symbol: "g"),
            ]
        case .illuminance:
            return [
                UnitSpec(id: "lx", symbol: "lx"),
                UnitSpec(id: "fc", symbol: "fc"),
            ]
        }
    }

    static func dimension(category: UnitCategory, id: String) -> Dimension? {
        switch category {
        case .currency:
            return nil
        case .angle:
            switch id {
            case "deg": return UnitAngle.degrees
            case "rad": return UnitAngle.radians
            case "arcmin": return UnitAngle.arcMinutes
            case "arcsec": return UnitAngle.arcSeconds
            case "grad": return UnitAngle.gradians
            case "rev": return UnitAngle.revolutions
            default: return nil
            }
        case .area:
            switch id {
            case "m2": return UnitArea.squareMeters
            case "km2": return UnitArea.squareKilometers
            case "cm2": return UnitArea.squareCentimeters
            case "mm2": return UnitArea.squareMillimeters
            case "ha": return UnitArea.hectares
            case "acre": return UnitArea.acres
            case "ft2": return UnitArea.squareFeet
            case "in2": return UnitArea.squareInches
            case "yd2": return UnitArea.squareYards
            case "mi2": return UnitArea.squareMiles
            default: return nil
            }
        case .data:
            switch id {
            case "B": return UnitInformationStorage.bytes
            case "bit": return UnitInformationStorage.bits
            case "kB": return UnitInformationStorage.kilobytes
            case "MB": return UnitInformationStorage.megabytes
            case "GB": return UnitInformationStorage.gigabytes
            case "TB": return UnitInformationStorage.terabytes
            case "KiB": return UnitInformationStorage.kibibytes
            case "MiB": return UnitInformationStorage.mebibytes
            case "GiB": return UnitInformationStorage.gibibytes
            case "TiB": return UnitInformationStorage.tebibytes
            default: return nil
            }
        case .energy:
            switch id {
            case "J": return UnitEnergy.joules
            case "kJ": return UnitEnergy.kilojoules
            case "cal": return UnitEnergy.calories
            case "kcal": return UnitEnergy.kilocalories
            case "kWh": return UnitEnergy.kilowattHours
            default: return nil
            }
        case .force:
            switch id {
            case "N": return KilnForce.newtons
            case "kN": return KilnForce.kilonewtons
            case "lbf": return KilnForce.poundsForce
            case "kgf": return KilnForce.kilogramsForce
            default: return nil
            }
        case .fuel:
            switch id {
            case "L100km": return UnitFuelEfficiency.litersPer100Kilometers
            case "mpg": return UnitFuelEfficiency.milesPerGallon
            case "mpgUK": return UnitFuelEfficiency.milesPerImperialGallon
            default: return nil
            }
        case .length:
            switch id {
            case "m": return UnitLength.meters
            case "km": return UnitLength.kilometers
            case "cm": return UnitLength.centimeters
            case "mm": return UnitLength.millimeters
            case "mi": return UnitLength.miles
            case "yd": return UnitLength.yards
            case "ft": return UnitLength.feet
            case "in": return UnitLength.inches
            case "nmi": return UnitLength.nauticalMiles
            default: return nil
            }
        case .power:
            switch id {
            case "W": return UnitPower.watts
            case "kW": return UnitPower.kilowatts
            case "MW": return UnitPower.megawatts
            case "hp": return UnitPower.horsepower
            default: return nil
            }
        case .pressure:
            switch id {
            case "Pa": return UnitPressure.newtonsPerMetersSquared
            case "kPa": return UnitPressure.kilopascals
            case "bar": return UnitPressure.bars
            case "mbar": return UnitPressure.millibars
            case "psi": return UnitPressure.poundsForcePerSquareInch
            case "atm": return UnitPressure(symbol: "atm", converter: UnitConverterLinear(coefficient: 101325))
            case "mmHg": return UnitPressure.millimetersOfMercury
            case "inHg": return UnitPressure.inchesOfMercury
            default: return nil
            }
        case .speed:
            switch id {
            case "m_s": return UnitSpeed.metersPerSecond
            case "km_h": return UnitSpeed.kilometersPerHour
            case "mph": return UnitSpeed.milesPerHour
            case "kn": return UnitSpeed.knots
            default: return nil
            }
        case .temperature:
            switch id {
            case "C": return UnitTemperature.celsius
            case "F": return UnitTemperature.fahrenheit
            case "K": return UnitTemperature.kelvin
            default: return nil
            }
        case .time:
            switch id {
            case "s": return UnitDuration.seconds
            case "min": return UnitDuration.minutes
            case "h": return UnitDuration.hours
            case "d": return Self.days
            default: return nil
            }
        case .volume:
            switch id {
            case "L": return UnitVolume.liters
            case "mL": return UnitVolume.milliliters
            case "m3": return UnitVolume.cubicMeters
            case "gal": return UnitVolume.gallons
            case "galUK": return UnitVolume.imperialGallons
            case "qt": return UnitVolume.quarts
            case "pt": return UnitVolume.pints
            case "cup": return UnitVolume.cups
            case "floz": return UnitVolume.fluidOunces
            default: return nil
            }
        case .weight:
            switch id {
            case "g": return UnitMass.grams
            case "kg": return UnitMass.kilograms
            case "mg": return UnitMass.milligrams
            case "t": return UnitMass.metricTons
            case "lb": return UnitMass.pounds
            case "oz": return UnitMass.ounces
            case "st": return UnitMass.stones
            default: return nil
            }
        case .frequency:
            switch id {
            case "Hz": return UnitFrequency.hertz
            case "kHz": return UnitFrequency.kilohertz
            case "MHz": return UnitFrequency.megahertz
            case "GHz": return UnitFrequency.gigahertz
            default: return nil
            }
        case .acceleration:
            switch id {
            case "m_s2": return UnitAcceleration.metersPerSecondSquared
            case "g0": return UnitAcceleration.gravity
            default: return nil
            }
        case .illuminance:
            switch id {
            case "lx": return UnitIlluminance.lux
            case "fc": return UnitIlluminance(symbol: "fc", converter: UnitConverterLinear(coefficient: 10.76391))
            default: return nil
            }
        }
    }

    private static let days = UnitDuration(symbol: "d", converter: UnitConverterLinear(coefficient: 86400))
}

final class KilnForce: Dimension, @unchecked Sendable {
    static let newtons = KilnForce(symbol: "N", converter: UnitConverterLinear(coefficient: 1))
    static let kilonewtons = KilnForce(symbol: "kN", converter: UnitConverterLinear(coefficient: 1000))
    static let poundsForce = KilnForce(symbol: "lbf", converter: UnitConverterLinear(coefficient: 4.4482216152605))
    static let kilogramsForce = KilnForce(symbol: "kgf", converter: UnitConverterLinear(coefficient: 9.80665))

    override class func baseUnit() -> Self {
        newtons as! Self
    }
}
