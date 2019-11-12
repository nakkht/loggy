//
//  FileTarget.swift
//  Logr
//
//  Created by Paulius Gudonis on 22/08/2019.
//  Copyright © 2019 neqsoft. All rights reserved.
//

import Foundation

/// Target class for logging to a file.
open class FileTarget: Target {
    
    lazy var fileManager = FileManager.default
    
    /// Base directory URL for logged files.
    public lazy var baseLogDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    
    /// URL of main log file.
    public lazy var fullLogFileUrl = baseLogDirectory.appendingPathComponent(self.config.fullFileName)
    
    /// URL or archive folder.
    public lazy var archiveUrl = baseLogDirectory.appendingPathComponent("archive")
    
    /// Config struct assigned during initialization
    public let config: FileTargetConfig
    
    /// File handle of a current log file being written to.
    public var fileHandle: FileHandle?

    let dispatchQueue = DispatchQueue(label: "com.neqsoft.file_target", qos: .background)
    
   /**
    Initializes FileTarget instance with provided FileTargetConfig struct. Prepares file for receiving and persisting log messages.
    
    - Parameters:
       - config: struct encapsulating logging preferences. Defaults to struct instance with defaults values.
    */
    public init(_ config: FileTargetConfig? = nil) {
        self.config = config ?? FileTargetConfig()
        initFile()
    }
    
    open func send(_ message: Message) {
        guard self.config.levels.contains(message.level) else { return }
        let metaText = self.config.style == .verbose ? "\(message.meta.text) " : ""
        self.write("\(metaText)\(message.level.title): \(message.text)\n")
    }
    
    func write(_ log: String) {
        guard !log.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        dispatchQueue.async {
            guard let data = log.data(using: .utf8), data.count > 0 else { return }
            self.fileHandle?.seekToEndOfFile()
            self.fileHandle?.write(data)
            self.fileHandle?.synchronizeFile()
        }
    }
    
    /// Forces archive process of the current log file regardless of the preconditions set in config files. Non-blocking. Thread-safe.
    public func archive() {
        dispatchQueue.async {
            self.shiftArchivedFiles()
            self.closeFile()
            self.moveFile()
            self.initFile()
            self.deleteObsoletFiles(at: self.archiveUrl)
        }
    }
    
    func initFile() {
        let fullFilePath = self.baseLogDirectory.appendingPathComponent(self.config.fullFileName)
        self.createFileIfNeeded(fullLogFileUrl)
        self.fileHandle = FileHandle(forWritingAtPath: fullFilePath.path)
    }
    
    func createFileIfNeeded(_ url: URL) {
        guard !self.doesLogFileExists else { return }
        try? self.fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        self.fileManager.createFile(atPath: url.path,
                                    contents: nil,
                                    attributes: [.creationDate: Date()])
    }
    
    func closeFile() {
        self.fileHandle?.synchronizeFile()
        self.fileHandle?.closeFile()
    }
    
    func moveFile() {
        try? self.fileManager.moveItem(atPath: fullLogFileUrl.path, toPath: archiveUrl.path)
    }
    
    func deleteObsoletFiles(at url: URL) {
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return }
        let filesForDeletion = contents.sorted {
            $0.path.compare($1.path, options: .numeric) == .orderedAscending
        }.dropFirst(Int(self.config.maxArchivedFilesCount))
        guard filesForDeletion.count > 0 else { return }
        filesForDeletion.forEach {
            try? self.fileManager.removeItem(at: $0)
        }
    }
    
    func shiftArchivedFiles() {
        guard let contents = try? fileManager.contentsOfDirectory(at: self.archiveUrl, includingPropertiesForKeys: nil) else { return }
        let archivedFiles = contents.sorted {
            $0.path.compare($1.path, options: .numeric) == .orderedAscending
        }
        archivedFiles.enumerated().reversed().forEach { (offset: Int, url: URL) in
            let newFileUrl = archiveUrl.appendingPathComponent("\(self.config.fileName).\(offset + 1).\(self.config.fileExtension)")
            try? self.fileManager.moveItem(at: url, to: newFileUrl)
        }
    }
    
    func archiveIfNeeded() {
        guard self.shouldArchive else { return }
        self.archive()
    }
    
    var shouldArchive: Bool {
        guard let logFileAge = self.logFileAge else {
            return shouldArchiveBasedOnSize
        }
        return logFileAge.rawValue >= config.archiveFrequency.rawValue || shouldArchiveBasedOnSize
    }
    
    var shouldArchiveBasedOnSize: Bool {
        return logFileSizeInBytes > config.maxFileSizeInBytes
    }
    
    var logFileAge: TimeSpan? {
        guard let creationDate = try? fileManager.attributesOfItem(atPath: fullLogFileUrl.path)[.creationDate] as? Date,
            let modificationDate = try? fileManager.attributesOfItem(atPath: fullLogFileUrl.path)[.modificationDate] as? Date else {
                return nil
        }
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month], from: creationDate, to: modificationDate)
        switch components {
        case _ where components.month ?? 0 >= 1: return .month
        case _ where components.weekOfYear ?? 0 >= 1: return .week
        case _ where components.day ?? 0 >= 1: return .day
        case _ where components.hour ?? 0 >= 1: return .hour
        case _ where components.minute ?? 0 >= 1: return .minute
        default: return nil
        }
    }
    
    var logFileSizeInBytes: UInt64 {
        let size = try? fileManager.attributesOfItem(atPath: fullLogFileUrl.path)[.size] as? UInt64
        return size ?? 0
    }
    
    var doesLogFileExists: Bool {
        return fileManager.fileExists(atPath: self.fullLogFileUrl.path)
    }
}
