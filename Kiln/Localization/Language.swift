import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case en
    case es
    case fr
    case de
    case it
    case ptBR = "pt-BR"
    case ptPT = "pt-PT"
    case nl
    case da
    case sv
    case nb
    case fi
    case pl
    case cs
    case hu
    case ro
    case el
    case tr
    case ru
    case uk
    case ar
    case he
    case hi
    case th
    case vi
    case id
    case ja
    case ko
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"

    var id: String { rawValue }

    static let shippedCodes: [String] = AppLanguage.allCases
        .filter { $0 != .system }
        .map(\.rawValue)

    var autonym: String {
        switch self {
        case .system: return ""
        case .en: return "English"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        case .ptBR: return "Português (Brasil)"
        case .ptPT: return "Português (Portugal)"
        case .nl: return "Nederlands"
        case .da: return "Dansk"
        case .sv: return "Svenska"
        case .nb: return "Norsk Bokmål"
        case .fi: return "Suomi"
        case .pl: return "Polski"
        case .cs: return "Čeština"
        case .hu: return "Magyar"
        case .ro: return "Română"
        case .el: return "Ελληνικά"
        case .tr: return "Türkçe"
        case .ru: return "Русский"
        case .uk: return "Українська"
        case .ar: return "العربية"
        case .he: return "עברית"
        case .hi: return "हिन्दी"
        case .th: return "ไทย"
        case .vi: return "Tiếng Việt"
        case .id: return "Bahasa Indonesia"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return .autoupdatingCurrent
        default: return Locale(identifier: rawValue)
        }
    }

    var isRTL: Bool {
        switch self {
        case .ar, .he: return true
        case .system:
            return Locale.autoupdatingCurrent.language.characterDirection == .rightToLeft
        default: return false
        }
    }

    var layoutDirection: LayoutDirection {
        isRTL ? .rightToLeft : .leftToRight
    }
}

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .system: return "settings.appearance.system"
        case .light: return "settings.appearance.light"
        case .dark: return "settings.appearance.dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
