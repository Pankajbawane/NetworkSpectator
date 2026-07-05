//
//  NetworkLogMetrics.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/07/26.
//

import Foundation

package struct NetworkLogMetrics: Codable, Equatable, Hashable, Sendable {
    package let redirectCount: Int
    package let responseInterval: DateInterval
    package let transactions: [NetworkTransaction]

    package init(redirectCount: Int, responseInterval: DateInterval, transactions: [NetworkTransaction]) {
        self.redirectCount = redirectCount
        self.responseInterval = responseInterval
        self.transactions = transactions
    }
}

package struct NetworkTransaction: Codable, Equatable, Hashable, Sendable {
    
    package let fetchStartDate: Date?
    package let domainLookupStartDate: Date?
    package let domainLookupEndDate: Date?
    package let connectStartDate: Date?
    package let secureConnectionStartDate: Date?
    package let secureConnectionEndDate: Date?
    package let connectEndDate: Date?
    package let requestStartDate: Date?
    package let requestEndDate: Date?
    package let responseStartDate: Date?
    package let responseEndDate: Date?
    package let networkProtocolName: String?
    package let isProxyConnection: Bool?
    package let isReusedConnection: Bool?
    package let resourceFetchType: ResourceFetchType?
    package let countOfRequestHeaderBytesSent: Int64?
    package let countOfRequestBodyBytesSent: Int64?
    package let countOfRequestBodyBytesBeforeEncoding: Int64?
    package let countOfResponseHeaderBytesReceived: Int64?
    package let countOfResponseBodyBytesReceived: Int64?
    package let countOfResponseBodyBytesAfterDecoding: Int64?
    package let localAddress: String?
    package let remoteAddress: String?
    package let isCellular: Bool?
    package let isExpensive: Bool?
    package let isConstrained: Bool?
    package let isMultipath: Bool?
    package let domainResolutionProtocol: DomainResolution?
    package let localPort: Int?
    package let remotePort: Int?
    package let negotiatedTLSProtocolVersion: TLSVersion?
    package let negotiatedTLSCipherSuite: TLSCipherSuite?
}

package extension NetworkTransaction {
    init(_ metric: URLSessionTaskTransactionMetrics) {
        fetchStartDate = metric.fetchStartDate
        domainLookupStartDate = metric.domainLookupStartDate
        domainLookupEndDate = metric.domainLookupEndDate
        connectStartDate = metric.connectStartDate
        secureConnectionStartDate = metric.secureConnectionStartDate
        secureConnectionEndDate = metric.secureConnectionEndDate
        connectEndDate = metric.connectEndDate
        requestStartDate = metric.requestStartDate
        requestEndDate = metric.requestEndDate
        responseStartDate = metric.responseStartDate
        responseEndDate = metric.responseEndDate
        networkProtocolName = metric.networkProtocolName
        isProxyConnection = metric.isProxyConnection
        isReusedConnection = metric.isReusedConnection
        resourceFetchType = ResourceFetchType(rawValue: metric.resourceFetchType.rawValue)
        countOfRequestHeaderBytesSent = metric.countOfRequestHeaderBytesSent
        countOfRequestBodyBytesSent = metric.countOfRequestBodyBytesSent
        countOfRequestBodyBytesBeforeEncoding = metric.countOfRequestBodyBytesBeforeEncoding
        countOfResponseHeaderBytesReceived = metric.countOfResponseHeaderBytesReceived
        countOfResponseBodyBytesReceived = metric.countOfResponseBodyBytesReceived
        countOfResponseBodyBytesAfterDecoding = metric.countOfResponseBodyBytesAfterDecoding
        localAddress = metric.localAddress
        remoteAddress = metric.remoteAddress
        isCellular = metric.isCellular
        isExpensive = metric.isExpensive
        isConstrained = metric.isConstrained
        isMultipath = metric.isMultipath
        domainResolutionProtocol = DomainResolution(rawValue: metric.domainResolutionProtocol.rawValue)
        localPort = metric.localPort
        remotePort = metric.remotePort
        negotiatedTLSProtocolVersion = metric.negotiatedTLSProtocolVersion.flatMap { TLSVersion(rawValue: $0.rawValue) }
        negotiatedTLSCipherSuite = metric.negotiatedTLSCipherSuite.flatMap { TLSCipherSuite(rawValue: $0.rawValue) }
    }
}

package enum ResourceFetchType: Int, Codable, Sendable {
    case unknown = 0
    case networkLoad = 1
    case serverPush = 2
    case localCache = 3
    
    package var formatted: String {
        switch self {
        case .networkLoad: return "Network"
        case .serverPush: return "Server Push"
        case .localCache: return "Cache"
        case .unknown: return "Unknown"
        }
    }
    
    package var icon: String {
        switch self {
        case .networkLoad: return "network"
        case .serverPush: return "arrow.down.forward.and.arrow.up.backward"
        case .localCache: return "externaldrive"
        case .unknown: return "questionmark.circle"
        }
    }
}

package enum TLSVersion: UInt16, Codable, Sendable {
    case TLSv10 = 769
    case TLSv11 = 770
    case TLSv12 = 771
    case TLSv13 = 772
    case DTLSv10 = 65279
    case DTLSv12 = 65277
    
    package var formatted: String {
        switch self {
        case .TLSv10: return "TLS 1.0"
        case .TLSv11: return "TLS 1.1"
        case .TLSv12: return "TLS 1.2"
        case .TLSv13: return "TLS 1.3"
        case .DTLSv10: return "DTLS 1.0"
        case .DTLSv12: return "DTLS 1.2"
        }
    }
}

package enum DomainResolution: Int, Codable, Sendable {
    case unknown = 0
    case udp = 1
    case tcp = 2
    case tls = 3
    case https = 4
    
    package var formatted: String {
        switch self {
        case .udp: return "UDP"
        case .tcp: return "TCP"
        case .tls: return "TLS"
        case .https: return "HTTPS"
        case .unknown: return "Unknown"
        }
    }
}

package enum TLSCipherSuite: UInt16, Codable, Sendable {
    case RSA_WITH_3DES_EDE_CBC_SHA = 10
    case RSA_WITH_AES_128_CBC_SHA = 47
    case RSA_WITH_AES_256_CBC_SHA = 53
    case RSA_WITH_AES_128_GCM_SHA256 = 156
    case RSA_WITH_AES_256_GCM_SHA384 = 157
    case RSA_WITH_AES_128_CBC_SHA256 = 60
    case RSA_WITH_AES_256_CBC_SHA256 = 61
    case ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA = 49160
    case ECDHE_ECDSA_WITH_AES_128_CBC_SHA = 49161
    case ECDHE_ECDSA_WITH_AES_256_CBC_SHA = 49162
    case ECDHE_RSA_WITH_3DES_EDE_CBC_SHA = 49170
    case ECDHE_RSA_WITH_AES_128_CBC_SHA = 49171
    case ECDHE_RSA_WITH_AES_256_CBC_SHA = 49172
    case ECDHE_ECDSA_WITH_AES_128_CBC_SHA256 = 49187
    case ECDHE_ECDSA_WITH_AES_256_CBC_SHA384 = 49188
    case ECDHE_RSA_WITH_AES_128_CBC_SHA256 = 49191
    case ECDHE_RSA_WITH_AES_256_CBC_SHA384 = 49192
    case ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 = 49195
    case ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 = 49196
    case ECDHE_RSA_WITH_AES_128_GCM_SHA256 = 49199
    case ECDHE_RSA_WITH_AES_256_GCM_SHA384 = 49200
    case ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 = 52392
    case ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 = 52393
    case AES_128_GCM_SHA256 = 4865
    case AES_256_GCM_SHA384 = 4866
    case CHACHA20_POLY1305_SHA256 = 4867
}
