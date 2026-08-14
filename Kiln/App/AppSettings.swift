import Foundation
import SwiftUI

struct AppSettings: Sendable {
    var language: AppLanguage = .system
    var appearance: AppAppearance = .system
    var destination: DestinationPolicy = .sameFolder
    var notifyOnComplete: Bool = false
    var lastFolderBookmark: Data?
    var lastFormatByFamily: [String: String] = [:]
    var currencyAutoRefresh: Bool = true

    var locale: Locale { language.locale }
    var layoutDirection: LayoutDirection { language.layoutDirection }

    mutating func remember(formatID: String, family: FormatFamily) {
        lastFormatByFamily[family.rawValue] = formatID
    }

    func lastFormat(for family: FormatFamily) -> String? {
        lastFormatByFamily[family.rawValue]
    }
}

enum SettingsStore {
    private static let key = "kiln.settings.v1"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let raw = try? JSONDecoder().decode(Stored.self, from: data) else {
            return AppSettings()
        }
        var settings = AppSettings()
        settings.language = AppLanguage(rawValue: raw.language) ?? .system
        settings.appearance = AppAppearance(rawValue: raw.appearance) ?? .system
        settings.destination = DestinationPolicy(rawValue: raw.destination) ?? .sameFolder
        settings.notifyOnComplete = raw.notifyOnComplete
        settings.lastFolderBookmark = raw.lastFolderBookmark
        settings.lastFormatByFamily = raw.lastFormatByFamily
        settings.currencyAutoRefresh = raw.currencyAutoRefresh ?? true
        return settings
    }

    static func save(_ settings: AppSettings) {
        let raw = Stored(
            language: settings.language.rawValue,
            appearance: settings.appearance.rawValue,
            destination: settings.destination.rawValue,
            notifyOnComplete: settings.notifyOnComplete,
            lastFolderBookmark: settings.lastFolderBookmark,
            lastFormatByFamily: settings.lastFormatByFamily,
            currencyAutoRefresh: settings.currencyAutoRefresh
        )
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private struct Stored: Codable {
        var language: String
        var appearance: String
        var destination: String
        var notifyOnComplete: Bool
        var lastFolderBookmark: Data?
        var lastFormatByFamily: [String: String]
        var currencyAutoRefresh: Bool?
    }
}
