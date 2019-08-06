//
//  LogLevel.swift
//  loggy
//
//  Created by Paulius Gudonis on 28/06/2019.
//  Copyright © 2019 neqsoft. All rights reserved.
//

import Foundation

enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3
    case critical = 4
    
    var title: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warn: return "Warn"
        case .error: return "Error"
        case .critical: return "Critical"
        }
    }
}
