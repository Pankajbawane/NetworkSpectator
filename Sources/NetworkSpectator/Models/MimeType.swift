//
//  MimeType.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 30/03/26.
//

import Foundation

public enum MimeType: Equatable, Codable, Hashable, Sendable {
    case json
    case xml
    case html
    case plainText
    case imageJpeg
    case imagePng
    case empty
    case custom(String)
    
    var raw: String {
        switch self {
        case .json: return "application/json"
        case .xml: return "application/xml"
        case .html: return "text/html"
        case .plainText: return "text/plain"
        case .imageJpeg: return "image/jpeg"
        case .imagePng: return "image/png"
        case .empty: return ""
        case .custom(let value): return value
        }
    }
}
