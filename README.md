# NetworkSpectator

A lightweight Swift utility to observe and inspect your app's network traffic during development and testing. NetworkSpectator captures requests and responses, lets you browse them in a simple UI, and export your logs for analysis.

## Features

- **Monitor network requests and responses in real time**
  - URL, method, status code, duration, request/response headers, and body (when available)
  - Simple list and detail views for quick inspection
  - Analytics dashboard with charts for HTTP methods, status codes, and host distribution

- **Export logs in multiple formats**
  - CSV export for spreadsheets and data analysis
  - Plain text export for quick sharing

- **Mock response**
  - Mock response by applying rules to match the request
  - Helpful to check behaviours without needing API deployment
  - Helps to write unit tests for HTTP requests without adding complex stubbing logic
 
- **Skip logging**
  - Supports skipping to log a particular request using rules

- **Lightweight and easy to integrate**
  - No external dependencies
  - Works with SwiftUI and UIKit/AppKit
  - Configurable logging

- **Cross-platform SwiftUI support**
  - iOS 17.0+
  - macOS 13.0+

## Installation

### Swift Package Manager

Add NetworkSpectator to your project using Swift Package Manager:

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the package repository URL - https://github.com/Pankajbawane/NetworkSpectator.git

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pankajbawane/NetworkSpectator.git", branch: "main")
]
```

## Usage

### Example App
NetworkSpectatorExample app demostrates basic usage of the library - https://github.com/Pankajbawane/NetworkSpectatorExample

### Basic Setup

1. **Enable NetworkSpectator** in your app's entry point (AppDelegate or App struct):
Call NetworkSpectator.start() to start listening HTTP requests. This will automatically log HTTP requests.
```swift
import NetworkSpectator

@main
struct MyApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                    .task {
                        #if DEBUG
                        NetworkSpectator.start()
                        #endif
                      }
        }
    }
}
```

2. **Present the NetworkSpectator UI**:

#### SwiftUI
```swift
import NetworkSpectator

ContentView() {
}
  .sheet(isPresented: $showLogs) {
      NetworkSpectator.rootView
  }

```

#### UIKit (iOS)
```swift
import NetworkSpectator

let networkVC = NetworkSpectator.rootViewController
present(networkVC, animated: true)
```

#### AppKit (macOS)
```swift
import NetworkSpectator

let networkVC = NetworkSpectator.rootViewController
presentAsSheet(networkVC)
```

### Configuration

Customize NetworkSpectator behavior with the configuration methods:

```swift
// Printing logs on Debug console
NetworkSpectator.debugLogsPrint(isEnabled: Bool)

// Register for mock response
NetworkSpectator.registerMock(for mock: Mock)

// Skip logging a request
NetworkSpectator.ignoreLogging(for rule: MatchRule)
```

### Disabling NetworkSpectator

You can stop network monitoring:

```swift
NetworkSpectator.stop()
```

## Safety and Release Builds

Because NetworkSpectator captures and displays sensitive network information, you should **limit it to debug builds only**. Wrap your integration points with `#if DEBUG` so nothing leaks into release builds.

### Recommendations:

- Avoid shipping any debug-only menu items, overlays, or UI that reveals network logs in production
- Consider guarding runtime toggles with `#if DEBUG` and/or internal feature flags
- Ensure exported files (CSV/text) aren't created in release builds
- Avoid NetworkSpectator initialization in release configurations

### Example:

```swift
#if DEBUG
NetworkSpectator.start()
#endif
```

## Export Options

NetworkSpectator supports multiple export formats:

- **CSV**: Perfect for importing into spreadsheet applications or data analysis tools
- **Text**: Human-readable format for quick sharing or viewing in text editors

Access export options from the UI by tapping the export button in the network logs view.

## Notes and Tips

- For macOS, the share/export UI uses the system sharing picker for a native experience
- The UI is intentionally minimal. You can embed the `rootView` into your own debug tooling screens
- The analytics dashboard provides visual insights into your app's network patterns, making it easy to spot issues or unusual activity

## Requirements

- Swift 6.2+
- iOS 17.0+ / macOS 13.0+
- Xcode 16.0+
