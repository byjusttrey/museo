import SwiftUI

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if h.hasPrefix("#") { h.removeFirst() }
        var a, r, g, b: UInt64
        a = 255; r = 0; g = 0; b = 0

        func hexPair(_ s: Substring) -> UInt64 {
            UInt64(s, radix: 16) ?? 0
        }

        switch h.count {
        case 3: // RGB (12-bit)
            r = hexPair(h.prefix(1)) * 17
            g = hexPair(h.dropFirst().prefix(1)) * 17
            b = hexPair(h.dropFirst(2).prefix(1)) * 17
        case 4: // ARGB (16-bit) or RGBA (rare)
            // Assume RGBA (#RGBA)
            r = hexPair(h.prefix(1)) * 17
            g = hexPair(h.dropFirst().prefix(1)) * 17
            b = hexPair(h.dropFirst(2).prefix(1)) * 17
            a = hexPair(h.dropFirst(3).prefix(1)) * 17
        case 6: // RRGGBB
            r = hexPair(h.prefix(2))
            g = hexPair(h.dropFirst(2).prefix(2))
            b = hexPair(h.dropFirst(4).prefix(2))
        case 8: // RRGGBBAA
            r = hexPair(h.prefix(2))
            g = hexPair(h.dropFirst(2).prefix(2))
            b = hexPair(h.dropFirst(4).prefix(2))
            a = hexPair(h.dropFirst(6).prefix(2))
        default:
            r = 0; g = 0; b = 0; a = 255
        }

        self = Color(.sRGB,
                     red: Double(r) / 255.0,
                     green: Double(g) / 255.0,
                     blue: Double(b) / 255.0,
                     opacity: Double(a) / 255.0)
    }
}

// MARK: - Design Tokens (from your zip palette & utility classes)
enum DS {
    enum ColorToken {
        // Core text & surfaces
        static let textPrimary   = Color(hex: "#030213")
        static let textSecondary = Color(hex: "#717182")
        static let bg            = Color(hex: "#F3F3F5")
        static let surface       = Color(hex: "#FFFFFF")
        static let surfaceMuted  = Color(hex: "#ECECF0")

        // Accents (Tailwind-y)
        static let blue          = Color(hex: "#2563EB") // Tailwind blue-600
        static let amber         = Color(hex: "#F59E0B") // Tailwind amber-500

        // Borders/lines
        static let divider       = Color.black.opacity(0.1) // similar to #0000001a
        static let subtleShadow  = Color.black.opacity(0.06) // like #0000000F
    }

    enum Radius {
        static let sm: CGFloat  = 6
        static let md: CGFloat  = 10
        static let lg: CGFloat  = 14
        static let xl: CGFloat  = 18
        static let x2: CGFloat  = 24 // 2xl
        static let full: CGFloat = 999
    }

    enum Space {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 20
        static let x2: CGFloat  = 24
        static let x3: CGFloat  = 32
    }

    enum FontToken {
        // Tailwind-like sizing
        static let xs   = Font.system(size: 12, weight: .regular, design: .rounded)
        static let sm   = Font.system(size: 14, weight: .regular, design: .rounded)
        static let base = Font.system(size: 16, weight: .regular, design: .rounded)
        static let lg   = Font.system(size: 18, weight: .medium,  design: .rounded)
        static let xl   = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let x2   = Font.system(size: 24, weight: .semibold, design: .rounded) // 2xl
    }

    // Card shadow (subtle like Tailwind shadow-sm/md)
    static func cardShadow() -> some View {
        // 2-layer soft shadow
        EmptyView()
            .shadow(color: ColorToken.subtleShadow, radius: 6, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.03), radius: 16, x: 0, y: 8)
    }

    // Chip style helper
    struct Chip: ViewModifier {
        let bg: Color
        let fg: Color
        func body(content: Content) -> some View {
            content
                .font(FontToken.sm)
                .foregroundStyle(fg)
                .padding(.horizontal, Space.md)
                .padding(.vertical, 6)
                .background(bg)
                .clipShape(Capsule())
        }
    }
}
