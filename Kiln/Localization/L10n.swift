import Foundation
import SwiftUI

enum L10n {
    static func string(_ key: String, locale: Locale) -> String {
        String(localized: String.LocalizationValue(key), locale: locale)
    }

    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}

struct KilnText: View {
    var key: String

    var body: some View {
        Text(LocalizedStringKey(key))
    }
}
