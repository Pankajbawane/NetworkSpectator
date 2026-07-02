//
//  HistoryItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 22/03/26.
//

import Foundation

struct HistoryItem: Codable, Identifiable {
    let key: String
    let url: URL
    let startTimestamp: String
    let endTimestamp: String
    let count: String
    let size: Int
    var isCurrentSession: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case key, url, startTimestamp, endTimestamp, count, size
    }
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    var formattedTitle: String {
        let startTime = formatter.date(from: startTimestamp)?.formatted(date: .abbreviated, time: .shortened) ?? ""
        let endTime = formatter.date(from: endTimestamp)?.formatted(date: .omitted, time: .shortened) ?? ""
        return "\(startTime) - \(endTime)"
    }
    
    var shortTitle: String {
        formatter.date(from: startTimestamp)?.formatted(date: .abbreviated, time: .shortened) ?? startTimestamp
    }
    
    var id: String {
        key
    }
}
