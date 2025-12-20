# NetworkSpectator

A lightweight Swift utility for observing and inspecting your app's network traffic during development and testing. NetworkSpectator captures requests and responses, provides a simple UI for browsing and mocking them, and allows you to export logs for sharing.

## Features

- **Monitor network requests and responses in real time**
  - URL, method, status code, duration, request/response headers, and response body
  - Simple list and detail views for quick inspection
  - Analytics dashboard with charts for HTTP methods, status codes, and host distribution
 
- **Filters and Search**
  - Filter requests by status codes and HTTP methods
  - Locate specific requests by URL using search
  - Combine filters for precise request searching

- **Export logs in multiple formats**

  NetworkSpectator supports multiple export formats:
  - **CSV export** - Perfect for importing into spreadsheet applications or data analysis tools
  - **Plain text export** - Human-readable format for quick sharing or viewing in text editors
  - **Postman Collection format** - Import directly into Postman for API testing and collaboration

- **Mock responses**
  - Define custom mock responses using flexible rule-based matching
  - Test different scenarios and edge cases without backend API deployment
  - **Programmatic mocking** - Add mocks via code for reliable unit tests without complex stubbing setups
  - **UI-based mocking** - Enable QA testers to validate business logic in test builds independently, without developer intervention or Xcode
  - Perfect for offline development

- **Skip logging**
  - Exclude specific or sensitive requests from logging using matching rules
  - Reduce noise by filtering out irrelevant requests
  - Configure skip rules both programmatically (in code) and dynamically (via UI)

- **Lightweight and easy to integrate**
  - One-line setup to start monitoring and logging
  - No external dependencies
  - Works with SwiftUI and UIKit/AppKit
  - Configurable logging on Xcode debug console

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
The NetworkSpectatorExample app demonstrates basic usage of the library: https://github.com/Pankajbawane/NetworkSpectatorExample

### Basic Setup

1. **Enable NetworkSpectator** in your app's entry point (AppDelegate or App struct):

Call `NetworkSpectator.start()` to begin listening to HTTP requests. This will automatically log all HTTP traffic.
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
// Enable or disable printing logs to the debug console
NetworkSpectator.debugLogsPrint(isEnabled: Bool)

// Register a mock response
NetworkSpectator.registerMock(for mock: Mock)

// Skip logging for specific requests
NetworkSpectator.ignoreLogging(for rule: MatchRule)
```

### Disabling NetworkSpectator

If enabled, then, to stop network monitoring:

```swift
NetworkSpectator.stop()
```

## NetworkSpectator UI on iOS
The following screenshots demonstrate NetworkSpectator running on iOS in light mode.

| List of Requests | Filters | URL Search | Details |
|---------|---------|------------|------------|
| <img width="300" height="652" alt="landing" src="https://github.com/user-attachments/assets/e58d675a-1ab7-4a8f-8232-f45323b61b20" /> | <img width="300" height="652" alt="filters_ios" src="https://github.com/user-attachments/assets/32087e71-0c66-4204-aa4e-873a1a28cf67" /> | <img width="300" height="652" alt="url_search_ios" src="https://github.com/user-attachments/assets/5db9d07e-d311-49e6-b1c1-3bf8a2da0a2d" /> | <img width="300" height="652" alt="basic_ios" src="https://github.com/user-attachments/assets/d6d86fc3-eece-4bae-b557-519966040815" /> |

| Headers | Response | Settings | Export & Share |
|---------|----------|----------|-------|
| <img width="300" height="652" alt="headers_ios" src="https://github.com/user-attachments/assets/1fc211e9-382e-4491-af7d-0f590dad5a9d" /> | <img width="300" height="652" alt="response_response" src="https://github.com/user-attachments/assets/9623b659-a0b5-4414-bf59-cd91c600047d" /> | <img width="300" height="652" alt="settings_ios" src="https://github.com/user-attachments/assets/c3f4e364-aa95-4d65-955d-4a35c8a94d68" /> | <img width="300" height="652" alt="share_ios" src="https://github.com/user-attachments/assets/96b0fc82-dcfe-4159-8458-00b815466802" /> |

## NetworkSpectator UI on macOS
The following screenshots demonstrate NetworkSpectator running on macOS in dark mode.

| List of Requests | Filters | Details |
|------------------|---------|---------------|
| <img width="1169" height="620" alt="landing_mac" src="https://github.com/user-attachments/assets/2006355b-7a6a-47f4-89e2-14f7cf76e8df" /> | <img width="1152" height="609" alt="filters_mac" src="https://github.com/user-attachments/assets/2007cc11-672e-420d-9f13-7110e8b95a2d" /> | <img width="1152" height="833" alt="basic_details_mac" src="https://github.com/user-attachments/assets/65f946ff-90da-4815-b27f-8d02c8bd06f2" /> |

| Headers | Response | Analytics |
|---------|----------|-----------|
| <img width="1152" height="833" alt="headers_mac" src="https://github.com/user-attachments/assets/72a63e17-de57-4218-ab90-5fd2935e0468" /> | <img width="1152" height="833" alt="response_mac" src="https://github.com/user-attachments/assets/0507e4a5-4c24-4a70-838c-4a2802620218" /> | <img width="1152" height="949" alt="analytics_mac" src="https://github.com/user-attachments/assets/152e8e49-7dbb-41f4-9bf8-2e5d3ce6c1af" /> |

| Settings | Add Mock | Skip Logging |
|----------|----------|--------------|
| <img width="1169" height="620" alt="settings_mac" src="https://github.com/user-attachments/assets/e6a7ebee-cd44-415a-910d-ef0273d57495" /> | <img width="1169" height="632" alt="add_mock_mac" src="https://github.com/user-attachments/assets/8353ae97-69b1-46ec-bc32-273463f2c95c" /> | <img width="1169" height="632" alt="skip_logging_mac" src="https://github.com/user-attachments/assets/04400e4b-0e59-4dd1-827f-257c9eda131f" /> |

## Safety and Release Builds

Because NetworkSpectator captures and displays network information, you should **limit it to debug builds only**. Wrap your integration points with `#if DEBUG` to ensure nothing leaks into release builds.

### Recommendations:

- Never ship NetworkSpectator in production builds
- Always guard with `#if DEBUG` and/or internal feature flags
- Ensure NetworkSpectator is not initialized in release configurations

### Example:

```swift
#if DEBUG
NetworkSpectator.start()
#endif
```

## Requirements

- Swift 6+
- iOS 17.0+ / macOS 13.0+
- Xcode 16.0+
