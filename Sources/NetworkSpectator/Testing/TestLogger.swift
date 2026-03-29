//
//  TestLogger.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

import Foundation

actor TestLogStore {
    
    static let shared = TestLogStore()
    
    /// Track requests tested.
    private var items: [UUID: LogItem] = [:]
    
    /// To be  exported to Ci.
    private var debugLog = [String]()
    private var testLog: [LogItem] = []
    private var testCount: [String: Int] = [:]
    
    func add(_ item: LogItem) {
        if items[item.id] == nil {
            debugLog.append("Initiated testing for " + item.url)
        } else {
            testLog.append(item)
            testCount[item.url, default: 0] += 1
            debugLog.append("Finished testing for " + item.url)
        }
    }
}
