//
//  TextExporter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 11/07/25.
//

import Foundation

struct TextExporter: FileExportable {
    let fileExtension: String = "txt"
    let item: LogItem
    
    func export() -> URL? {
        let details: [String] = [
            "URL\n" + item.url,
            "Method\n" + item.method.uppercased(),
            "Status Code\n\(item.statusCode)",
            "Start Time\n\(item.startTime)",
            "Finish Time\n\(item.finishTime ?? Date())",
            "Response Time\n\(item.responseTime) s",
            "Headers\n" + item.headers,
            "Response\n" + item.responseBody,
            "Response Headers\n" + item.responseHeaders
        ]
        
        let text = details.joined(separator: "\n\n")
        return save(content: text)
    }
}
