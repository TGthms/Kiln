import SwiftUI

enum KilnTheme {
    static let amber = Color(red: 0.89, green: 0.45, blue: 0.18)
    static let ember = Color(red: 0.72, green: 0.28, blue: 0.10)
    static let graphite = Color(red: 0.13, green: 0.13, blue: 0.14)
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let spring = Animation.spring(response: 0.36, dampingFraction: 1.0)
    static let press: CGFloat = 0.97
    static let radius: CGFloat = 16
}

struct KilnPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? KilnTheme.press : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct KilnCard: ViewModifier {
    var material: Material = .ultraThinMaterial

    func body(content: Content) -> some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: KilnTheme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KilnTheme.radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
    }
}

extension View {
    func kilnCard(_ material: Material = .ultraThinMaterial) -> some View {
        modifier(KilnCard(material: material))
    }
}
