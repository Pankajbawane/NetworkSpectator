//
//  StatusCodeColor.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import SwiftUI

/// Provides consistent status code colors across the app.
struct StatusCodeColor {

    /// Returns the color for a given HTTP status code integer.
    static func color(for statusCode: Int) -> Color {
        switch statusCode {
        case 100..<200: return .brown
        case 200..<300: return .green
        case 300..<400: return .yellow
        case 400..<500: return .red
        case 500..<600: return .orange
        default: return .gray
        }
    }

    /// Returns the color for a status code category string (e.g. "200..<300").
    static func color(range: String) -> Color {
        switch range {
        case "100..<200": return .brown
        case "200..<300": return .green
        case "300..<400": return .yellow
        case "400..<500": return .red
        case "500..<600": return .orange
        default: return .gray
        }
    }
}
