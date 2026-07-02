//
//  HTTPResponse.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 30/03/26.
//

import Foundation

public struct HTTPResponse: Sendable {
    let headers: [String: String]
    let statusCode: Int
    let responseData: Data?
    let error: Error?
    let responseTime: Double
    let mimeType: MimeType
    
    public init(headers: [String : String],
                statusCode: Int, responseData: Data?,
                error: Error?,
                responseTime: Double = 0,
                mimeType: MimeType = .empty,
                textEncoding: String? = nil) {
        self.headers = headers
        self.statusCode = statusCode
        self.responseData = responseData
        self.error = error
        self.responseTime = responseTime
        self.mimeType = mimeType
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headers = try container.decode([String: String].self, forKey: .headers)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        responseData = try container.decodeIfPresent(Data.self, forKey: .responseData)
        responseTime = try container.decode(Double.self, forKey: .responseTime)
        mimeType = try container.decode(MimeType.self, forKey: .mimeType)
        self.error = nil
    }
}

extension HTTPResponse: Equatable {
    public static func == (lhs: HTTPResponse, rhs: HTTPResponse) -> Bool {
        lhs.mimeType == rhs.mimeType &&
        lhs.headers == rhs.headers &&
        lhs.statusCode == rhs.statusCode &&
        lhs.responseData == rhs.responseData &&
        lhs.responseTime == rhs.responseTime &&
        (lhs.error?.localizedDescription ?? "") == (rhs.error?.localizedDescription ?? "")
    }
}

extension HTTPResponse: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(mimeType)
        hasher.combine(headers)
        hasher.combine(statusCode)
        hasher.combine(responseData)
        hasher.combine(responseTime)
        hasher.combine(error?.localizedDescription ?? "")
    }
}

extension HTTPResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case headers, statusCode, responseData, responseTime, mimeType, textEncoding
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(headers, forKey: .headers)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(responseData, forKey: .responseData)
        try container.encode(responseTime, forKey: .responseTime)
        try container.encode(mimeType, forKey: .mimeType)
    }
}
