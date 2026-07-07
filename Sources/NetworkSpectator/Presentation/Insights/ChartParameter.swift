//
//  ChartParameter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 11/07/25.
//

import Foundation
import NetworkSpectatorCore

struct ChartParameter<T: Hashable & Sendable>: Identifiable, Sendable {
    let value: T
    let count: Int
    var id: T { value }
    var stringValue: String { "\(value)" }
}

extension ChartParameter {
    static func build(items: [LogItem], key: (LogItem) -> T) -> [ChartParameter<T>] {
        let grouped = Dictionary(grouping: items, by: key)
        
        let parameters = grouped.map { (code, group) in
            ChartParameter(value: code, count: group.count)
        }
        
        return parameters.sorted { $0.stringValue < $1.stringValue }
    }
}
