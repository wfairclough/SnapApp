//
//  Logger.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import Foundation
import os.log

class AppLogger {
    static let shared = AppLogger()
    private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.snapapp", category: "SnapApp")
    
    private init() {}
    
    func info(_ message: String) {
        logger.info("\(message)")
    }
    
    func debug(_ message: String) {
        logger.debug("\(message)")
    }
    
    func error(_ message: String) {
        logger.error("\(message)")
    }
    
    func warning(_ message: String) {
        logger.warning("\(message)")
    }
}