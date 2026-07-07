//
//  HistoryItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 22/03/26.
//

import Foundation

package struct HistoryItem: Codable, Identifiable {
    package let key: String
    package let url: URL
    package let startTimestamp: String
    package let endTimestamp: String
    package let count: String
    package let size: Int
    package var isCurrentSession: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case key, url, startTimestamp, endTimestamp, count, size
    }
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    package var formattedTitle: String {
        let startTime = formatter.date(from: startTimestamp)?.formatted(date: .abbreviated, time: .shortened) ?? ""
        let endTime = formatter.date(from: endTimestamp)?.formatted(date: .omitted, time: .shortened) ?? ""
        return "\(startTime) - \(endTime)"
    }
    
    package var shortTitle: String {
        formatter.date(from: startTimestamp)?.formatted(date: .abbreviated, time: .shortened) ?? startTimestamp
    }
    
    package var id: String {
        key
    }

    package init(key: String,
                url: URL,
                startTimestamp: String,
                endTimestamp: String,
                count: String,
                size: Int,
                isCurrentSession: Bool = false) {
        self.key = key
        self.url = url
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.count = count
        self.size = size
        self.isCurrentSession = isCurrentSession
    }
}
