//
//  Dictionary+Extension.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/11/25.
//

import Foundation

extension Dictionary {
    var prettyPrintedJSON: String {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "\(self)"
    }
    
    var prettyPrintedHeaders: String {
        var headers = ""
        for (key, value) in self {
            headers += "\(key): \(value)\n"
        }
        return headers
    }
}
