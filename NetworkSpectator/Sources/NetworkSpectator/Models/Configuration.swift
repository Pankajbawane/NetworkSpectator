//
//  Configuration.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 13/12/25.
//

public struct Configuration {
    
    internal var debugPrintEnabled: Bool = false
    
    public mutating func enableDebugPrint(_ enable: Bool) -> Self {
        self.debugPrintEnabled = enable
        return self
    }
}
