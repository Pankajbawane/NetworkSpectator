//
//  HTTPInputConverter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import Foundation

struct HTTPInputConverter {
    enum ConversionError: Error, LocalizedError {
        case invalidStatusCode(String)
        case invalidJSON(String)
        case invalidHeaderLine(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidStatusCode(let s):
                return "Invalid status code: '\(s)'. Please enter a valid integer."
            case .invalidJSON(let s):
                return "Invalid JSON string. Error: \(s)"
            case .invalidHeaderLine(let line):
                return "Invalid header line: '\(line)'. Expected 'Key: Value'."
            }
        }
    }
    
    // Converts a string into JSON Data.
    // Accepts either a raw JSON string or something that can be coerced via JSONSerialization.
    static func jsonData(from string: String) throws -> Data {
        if string.isEmpty { return Data() }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        // If it already looks like JSON, try decoding directly to Data to validate
        if trimmed.first == "{" || trimmed.first == "[" || trimmed.first == "\"" || trimmed.first == "t" || trimmed.first == "f" || trimmed.first == "n" {
            guard let data = trimmed.data(using: .utf8) else {
                throw ConversionError.invalidJSON("Unable to encode string as UTF-8.")
            }
            // Validate that it's valid JSON
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
                return data
            } catch {
                throw ConversionError.invalidJSON(error.localizedDescription)
            }
        }
        // Otherwise, try to interpret as a plain string and wrap as JSON string
        guard let data = try? JSONSerialization.data(withJSONObject: trimmed, options: []) else {
            throw ConversionError.invalidJSON("String could not be serialized as JSON.")
        }
        return data
    }
    
    // Converts a status code string (e.g., "200") to Int
    static func statusCode(from string: String) throws -> Int {
        if string.isEmpty { return 200 }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let code = Int(trimmed) else {
            throw ConversionError.invalidStatusCode(string)
        }
        return code
    }
    
    // Converts headers entered as lines like:
    static func headers(from string: String) throws -> [String: String] {
        if string.isEmpty { return [:] }
        var result: [String: String] = [:]
        let lines = string
            .split(whereSeparator: \.isNewline)
            .map { String($0) }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        for line in lines {
            // Try ":" first, then "="
            if let range = line.range(of: ":") ?? line.range(of: "=") {
                let key = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if key.isEmpty {
                    throw ConversionError.invalidHeaderLine(line)
                }
                result[key] = value
            } else {
                throw ConversionError.invalidHeaderLine(line)
            }
        }
        return result
    }
}
