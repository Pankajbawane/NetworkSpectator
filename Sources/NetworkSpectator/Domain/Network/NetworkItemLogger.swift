//
//  NetworkItemLogger.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

import Foundation

package protocol Mockable: Sendable {
    func urlResponse(_ request: URLRequest) -> HTTPURLResponse?
    var response: HTTPResponse { get }
    var id: UUID { get }
}

package struct DefaultMock: Mockable {
    package func urlResponse(_ request: URLRequest) -> HTTPURLResponse? {
        nil
    }
    package let response: HTTPResponse
    package let id: UUID
}

package protocol NetworkItemLogger: Sendable {
    var isEnabled: Bool { get }
    func shouldIgnore(_ request: URLRequest) -> Bool
    func logging(_ item: LogItem)
}

package struct DefaultItemLogger: NetworkItemLogger {
    package let isEnabled = false

    package init() { }

    package func shouldIgnore(_ request: URLRequest) -> Bool { false }

    package func logging(_ item: LogItem) { }
}

package protocol MockServerProvider: Sendable {
    associatedtype T: Mockable
    func responseIfMocked(_ urlRequest: URLRequest) -> T?
}

package struct DefaultMockServer: MockServerProvider {
    package typealias T = DefaultMock

    package init() { }

    package func responseIfMocked(_ urlRequest: URLRequest) -> T? {
        nil
    }
}
