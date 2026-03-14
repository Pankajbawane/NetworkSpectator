import SwiftUI

/// Provides consistent HTTP method colors across the app.
struct HTTPMethodColor {

    /// Returns the color for a given HTTP method string.
    static func color(for method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .indigo
        case "PUT": return .orange
        case "PATCH": return .purple
        case "DELETE": return .red
        case "HEAD": return .mint
        case "OPTIONS": return .brown
        case "TRACE": return .pink
        case "CONNECT": return .yellow
        default: return .gray
        }
    }
}
