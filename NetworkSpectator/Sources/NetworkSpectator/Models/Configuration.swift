//
//  Configuration.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 13/12/25.
//

public final class Configuration {
    
    internal var debugPrintEnabled: Bool = true
    internal var storeLogsEnabled: Bool = false
    internal var mockEnabled: Bool = false
    
    public init() {}
    
    public func enableDebugPrint(_ enable: Bool) -> Self {
        debugPrintEnabled = enable
        return self
    }
    
    public func enableStoringLogs(_ enable: Bool) -> Self {
        storeLogsEnabled = enable
        return self
    }
    
    public func enableMocking(_ enable: Bool) -> Self {
        mockEnabled = enable
        return self
    }
}
