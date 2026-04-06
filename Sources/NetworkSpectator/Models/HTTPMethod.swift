//
//  HTTPMethod.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 06/04/26.
//

import Foundation

public enum HTTPMethod: String, Identifiable, Codable, Hashable, Sendable, CaseIterable {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, TRACE, CONNECT
    
    public var id: String {
        rawValue
    }
}
