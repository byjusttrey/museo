import SwiftUI

/// Minimal shared components using the DS tokens.
/// Keep this file lean to avoid name collisions & missing symbols.

struct TopBar: View {
    var title: String

    var body: some View {
        Text(title)
            .font(DS.FontToken.x2)
            .foregroundStyle(DS.ColorToken.textPrimary)
    }
}
