# macOS Menubar Shortcut Manager - Product Requirements Document

## Executive Summary

A native macOS application that runs as a menubar utility, allowing users to configure global keyboard shortcuts that execute terminal bash commands. The application provides an intuitive interface for managing shortcuts while remaining lightweight and unobtrusive.

## Product Overview

### Vision
Create a powerful yet simple tool that bridges the gap between keyboard shortcuts and terminal automation, enabling power users to streamline their workflows without leaving their current applications.

### Core Value Proposition
- **Global Access**: System-wide keyboard shortcuts work from any application
- **Seamless Integration**: Lives quietly in the menubar until needed
- **Terminal Power**: Full bash command execution capabilities
- **User-Friendly**: Visual interface for managing complex shortcuts

## Development Phases

### Phase 1: Foundation & Core Infrastructure (Weeks 1-3)

#### Objectives
Establish the basic application architecture and menubar presence.

#### Technical Requirements
- **Swift/SwiftUI Application**: Native macOS app using Swift and SwiftUI with AppKit integration where needed
- **Menubar Integration**: NSStatusItem with custom icon and menu (requires AppKit NSStatusBar)
- **Application Lifecycle**: Proper background running with Launch Agent support
- **Basic UI Framework**: SwiftUI preferences window with NavigationStack

#### Deliverables
- Basic menubar app that launches and stays in background
- Simple preferences window (empty for now)
- Proper app bundle structure and Info.plist configuration
- Basic logging and error handling framework

#### Technical Considerations
- Use NSStatusBar (AppKit) for menubar integration
- Implement SwiftUI views wrapped in NSHostingController for modern UI
- Use AppKit for global hotkey detection (Carbon/CGEventTap)
- Proper memory management for background operation
- Set up build configuration for distribution (code signing, etc.)

### Phase 2: Shortcut Detection & Management (Weeks 4-6)

#### Objectives
Implement global hotkey detection and shortcut management system.

#### Technical Requirements
- **Global Hotkey Registration**: Carbon/Cocoa hotkey APIs
- **Key Combination Parser**: Support for modifier keys (⌘, ⌥, ⌃, ⇧) + standard keys
- **Shortcut Conflict Detection**: Warn users about system shortcut conflicts
- **Shortcut Storage**: Core Data or UserDefaults for persistence

#### Deliverables
- Global hotkey registration system
- Basic shortcut creation interface
- Shortcut storage and retrieval
- Conflict detection system

#### Technical Considerations
- Use CGEventTap or Carbon Event Manager for global key detection
- Handle accessibility permissions properly
- Implement proper key combination validation

### Phase 3: Command Execution Engine (Weeks 7-8)

#### Objectives
Build the bash command execution system with proper security and error handling.

#### Technical Requirements
- **Process Execution**: NSTask/Process for running bash commands
- **Environment Handling**: Proper PATH and environment variable setup
- **Output Capture**: STDOUT/STDERR capture and logging
- **Security Model**: Sandboxing considerations and user confirmation for dangerous commands

#### Deliverables
- Reliable command execution system
- Output logging and display
- Error handling and user feedback
- Basic security warnings for potentially dangerous commands

#### Technical Considerations
- Use Process class for command execution
- Implement timeout handling for long-running commands
- Consider shell escaping for command arguments

### Phase 4: User Interface & Configuration (Weeks 9-11)

#### Objectives
Create an intuitive interface for managing shortcuts and commands.

#### Technical Requirements
- **Preferences Window**: SwiftUI interface with NavigationStack and modern design
- **Shortcut Editor**: Custom SwiftUI view for key combination input and validation
- **Command Editor**: SwiftUI TextEditor with Lua syntax highlighting and validation
- **Import/Export**: JSON or plist format for backup/sharing

#### UI Components Needed
- Custom shortcut recorder SwiftUI view (wrapping AppKit functionality)
- Lua code editor with syntax highlighting (CodeEditor or custom)
- List management with SwiftUI List and NavigationStack
- Test/preview functionality with async result display

#### Deliverables
- Complete preferences interface
- Shortcut creation and editing workflow
- Command testing and validation
- Import/export functionality

### Phase 5: Advanced Features & Polish (Weeks 12-14)

#### Objectives
Add advanced functionality and polish the user experience.

#### Advanced Features
- **Command Variables**: Support for clipboard content, selected text, current app
- **Command Chaining**: Sequential command execution
- **Conditional Execution**: Simple if/then logic based on system state
- **Output Handling**: Display results in notifications, menubar, or popup

#### Polish Items
- **Menubar Menu**: Quick access to recent commands and settings
- **Status Indicators**: Visual feedback for running commands
- **Performance Optimization**: Minimize CPU/memory usage
- **Accessibility**: VoiceOver support and keyboard navigation

#### Deliverables
- Variable substitution system
- Enhanced menubar menu
- Notification system integration
- Performance optimizations

### Phase 6: Testing & Distribution (Weeks 15-16)

#### Objectives
Comprehensive testing and preparation for distribution.

#### Testing Requirements
- **Unit Tests**: Core functionality testing
- **Integration Tests**: End-to-end workflow testing
- **Manual Testing**: Real-world usage scenarios
- **Security Testing**: Permission handling and command safety

#### Distribution Preparation
- **Code Signing**: Apple Developer certificate setup
- **Notarization**: Apple notarization process
- **Installer Creation**: DMG or PKG installer
- **Documentation**: User guide and troubleshooting

#### Deliverables
- Comprehensive test suite
- Signed and notarized application
- Distribution package
- User documentation

## Technical Architecture

### Core Components

1. **AppDelegate**: Main application lifecycle management
2. **MenubarManager**: NSStatusItem management and menu creation
3. **ShortcutManager**: Global hotkey registration and detection
4. **CommandExecutor**: Bash command execution and output handling
5. **PreferencesController**: UI for shortcut and command management
6. **DataManager**: Persistence layer for shortcuts and settings

### Data Models

```swift
struct Shortcut {
    let id: UUID
    let name: String
    let keyCode: Int
    let modifierFlags: NSEvent.ModifierFlags
    let command: String
    let isEnabled: Bool
    let createdDate: Date
}
```

### Key Technologies
- **Swift 5.9+**: Modern Swift with SwiftUI and async/await support
- **SwiftUI**: Primary UI framework for preferences and configuration
- **AppKit Integration**: NSStatusBar, global hotkeys, and system integration
- **Core Data**: Data persistence (alternative: UserDefaults for simple storage)
- **Carbon/CGEventTap**: Global hotkey registration
- **NSTask/Process**: Command execution
- **NSHostingController**: Bridge between SwiftUI and AppKit

## Security & Privacy Considerations

### Required Permissions
- **Accessibility Access**: For global hotkey detection
- **Automation**: For controlling other applications (if needed)

### Security Measures
- Warn users about potentially dangerous commands
- Sandbox-friendly architecture where possible
- Clear permission request explanations
- Optional command confirmation prompts

## Success Metrics

### Phase Completion Criteria
- Each phase must pass basic functionality tests
- Memory usage under 50MB during normal operation
- Hotkey response time under 100ms
- Zero crashes during 24-hour continuous operation

### User Experience Goals
- Setup time under 5 minutes for first shortcut
- Intuitive interface requiring no documentation for basic use
- Reliable shortcut execution (99.9% success rate)

## Risk Assessment

### Technical Risks
- **Accessibility Permission Denial**: Users may deny required permissions
- **System Compatibility**: macOS version compatibility issues
- **Performance Impact**: Background operation affecting system performance

### Mitigation Strategies
- Clear permission request messaging with benefits explanation
- Support for macOS 11+ with version-specific code paths
- Efficient event handling and memory management
- Comprehensive testing on different macOS versions

## Future Enhancements (Post-Launch)

### Potential Features
- **AppleScript Integration**: Execute AppleScript commands
- **Network Commands**: HTTP requests and API calls
- **Scheduled Commands**: Time-based command execution
- **Team Collaboration**: Shared shortcut libraries
- **Plugin System**: Third-party command extensions

### Scalability Considerations
- Plugin architecture for extensibility
- Cloud sync for shortcut libraries
- Advanced scripting language support
- Integration with popular developer tools

## Conclusion

This PRD outlines a comprehensive 16-week development cycle for creating a professional-grade macOS menubar shortcut manager. The phased approach ensures steady progress while maintaining code quality and user experience standards. Each phase builds upon the previous one, creating a solid foundation for both current functionality and future enhancements.
