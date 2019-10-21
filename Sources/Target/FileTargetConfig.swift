//
//  FileTargetConfig.swift
//  Logr
//
//  Created by Paulius Gudonis on 27/08/2019.
//  Copyright © 2019 neqsoft. All rights reserved.
//

import Foundation

public struct FileTargetConfig {
    
    public static let defaultMaxFileSizeInBytes: UInt64 = 20 * 1024 * 1024
    
    public let fileExtension: String
    public let fileName: String
    
    public let maxArchivedFilesCount: UInt16
    public let archiveFrequency: TimeSpan
    public let maxFileSizeInBytes: UInt64
    public let levels: [LogLevel]
    public let style: Style
    
    public init(fileName: String? = nil, fileExtension: String? = nil, maxArchivedFilesCount: UInt16? = nil,
                archiveFrequency: TimeSpan? = nil, maxFileSizeInBytes: UInt64? = nil,
                levels: [LogLevel]? = nil, style: Style? = nil) {
        self.fileExtension = fileExtension ?? "log"
        self.fileName = fileName ?? "file"
        self.maxArchivedFilesCount = maxArchivedFilesCount ?? 1
        self.archiveFrequency = archiveFrequency ?? .day
        self.maxFileSizeInBytes = maxFileSizeInBytes ?? FileTargetConfig.defaultMaxFileSizeInBytes
        self.levels = levels ?? LogLevel.allCases
        self.style = style ?? .minimal
    }
    
    public var fullFileName: String {
        return "\(fileName).\(fileExtension)"
    }
    
    public var fullArchiveFileName: String {
        return "archive/\(fileName).0.\(fileExtension)"
    }
}
