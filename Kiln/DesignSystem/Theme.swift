import SwiftUI

enum KilnTheme {
    /// Critically damped. Interruptible. No bounce on chrome that wasn't flicked.
    static let spring = Animation.spring(response: 0.32, dampingFraction: 1.0)
}
