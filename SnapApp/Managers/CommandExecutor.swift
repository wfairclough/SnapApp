//
//  CommandExecutor.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-28.
//

import Foundation
import AppKit

struct CommandResult {
    let exitCode: Int32
    let output: String
    let error: String
    let executionTime: TimeInterval
}

class CommandExecutor {
    static let shared = CommandExecutor()
    
    private init() {}
    
    private let dangerousCommands = [
        "rm", "rmdir", "del", "delete", "format", "fdisk", "mkfs",
        "dd", "sudo", "su", "chmod", "chown", "kill", "killall",
        "reboot", "shutdown", "halt", "init", "systemctl", "service"
    ]
    
    func executeCommand(_ command: String, timeout: TimeInterval = 30.0) async -> CommandResult {
        let startTime = Date()
        
        AppLogger.shared.info("Executing command: \(command)")
        
        // Check for potentially dangerous commands
        if isDangerousCommand(command) {
            AppLogger.shared.warning("Potentially dangerous command detected: \(command)")
            
            let shouldProceed = await confirmDangerousCommand(command)
            if !shouldProceed {
                AppLogger.shared.info("Command execution cancelled by user")
                return CommandResult(
                    exitCode: -1,
                    output: "",
                    error: "Command execution cancelled by user due to security warning",
                    executionTime: Date().timeIntervalSince(startTime)
                )
            }
        }
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        // Set up the process
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Set up environment variables
        var environment = ProcessInfo.processInfo.environment
        
        // Add common paths to ensure commands are found
        let commonPaths = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "/opt/homebrew/bin",
            "/opt/local/bin"
        ]
        
        if let existingPath = environment["PATH"] {
            environment["PATH"] = commonPaths.joined(separator: ":") + ":" + existingPath
        } else {
            environment["PATH"] = commonPaths.joined(separator: ":")
        }
        
        process.environment = environment
        
        let outputData = NSMutableData()
        let errorData = NSMutableData()
        
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty {
                outputData.append(data)
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty {
                errorData.append(data)
            }
        }
        
        do {
            try process.run()
            
            // Wait for process to complete with timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if process.isRunning {
                    AppLogger.shared.warning("Command timed out after \(timeout) seconds, terminating")
                    process.terminate()
                }
            }
            
            process.waitUntilExit()
            timeoutTask.cancel()
            
            // Close file handles
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            try outputPipe.fileHandleForReading.close()
            try errorPipe.fileHandleForReading.close()
            
            let output = String(data: outputData as Data, encoding: .utf8) ?? ""
            let error = String(data: errorData as Data, encoding: .utf8) ?? ""
            let executionTime = Date().timeIntervalSince(startTime)
            
            let result = CommandResult(
                exitCode: process.terminationStatus,
                output: output,
                error: error,
                executionTime: executionTime
            )
            
            AppLogger.shared.info("Command completed with exit code: \(result.exitCode), execution time: \(String(format: "%.2f", executionTime))s")
            
            if !result.output.isEmpty {
                AppLogger.shared.debug("Command output: \(result.output)")
            }
            
            if !result.error.isEmpty {
                AppLogger.shared.debug("Command error: \(result.error)")
            }
            
            return result
            
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            AppLogger.shared.error("Failed to execute command: \(error)")
            
            return CommandResult(
                exitCode: -1,
                output: "",
                error: "Failed to execute command: \(error.localizedDescription)",
                executionTime: executionTime
            )
        }
    }
    
    private func isDangerousCommand(_ command: String) -> Bool {
        let lowercaseCommand = command.lowercased().trimmingCharacters(in: .whitespaces)
        
        return dangerousCommands.contains { dangerous in
            lowercaseCommand.hasPrefix(dangerous + " ") || lowercaseCommand == dangerous
        }
    }
    
    private func confirmDangerousCommand(_ command: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Potentially Dangerous Command"
                alert.informativeText = "The command '\(command)' may modify your system or delete files. Are you sure you want to execute it?"
                alert.addButton(withTitle: "Execute")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .warning
                
                let response = alert.runModal()
                continuation.resume(returning: response == .alertFirstButtonReturn)
            }
        }
    }
}