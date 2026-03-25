# NetworkSpectator: Monitor and Inspect HTTP Traffic on iOS and macOS apps

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-orange?logo=swift)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2016.0%2B%20%7C%20macOS%2013.0%2B-blue)
![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen?logo=swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/pankajbawane/NetworkSpectator/blob/main/LICENSE)
[![Build](https://github.com/Pankajbawane/NetworkSpectator/actions/workflows/ci.yml/badge.svg)](https://github.com/Pankajbawane/NetworkSpectator/actions/workflows/ci.yml)

NetworkSpectator is a Swift network debugging library that intercepts, inspects, and logs HTTP/HTTPS request and response in your iOS or macOS app in real time.
Browse captured API traffic in a native SwiftUI interface, export logs and create mock API responses programmatically or through a built-in UI.
Designed for developers debugging network calls during development and QA teams validating app behavior without backend dependencies or developer intervention.

## Features

- **Real-time network monitoring**
  - Capture URL, method, status code, response time, headers, request body, and response body
  - Live updates with in-progress indicators for pending requests
  - Start immediately or use **on-demand mode** to enable monitoring from the UI when needed
  - Color-coded list view with method badges, status indicators, and response metrics
 
- **Filtering and search**
  - Filter by status code ranges and HTTP methods
  - Combine multiple filters with visual filter chips
  - Full-text URL search across all captured requests

- **Detailed request inspection**
  - Tabbed detail view: Overview, Request, Headers, and Response
  - Smart response rendering — pretty-printed JSON, inline image previews, and plain text
  - Copy any request or response data to clipboard
  - Create a mock or skip rule directly from a captured request

- **Export in multiple formats**
  - **CSV** — bulk or single request export for spreadsheets and analysis
  - **Plain text** — human-readable format for quick sharing
  - **Postman Collection** — import directly into Postman for API testing

- **Mock responses**
  - Intercept requests and return custom responses without a backend
  - Flexible matching: hostname, URL, path, endPath, subPath
  - Configure status codes, headers, JSON/raw body, and response delay
  - **Programmatic mocking** — register mocks via code for unit tests and development
  - **UI-based mocking** — let QA testers create and manage mocks on the fly without Xcode
  - **Persist mocks** across app sessions with local storage

- **Skip request logging**
  - Exclude noisy or sensitive requests using the same flexible matching rules
  - Configure skip rules programmatically or from the UI
  - Persist rules across app launches

- **Insights dashboard**
  - Summary cards: total requests, success rate, and unique hosts
  - Interactive charts for status code distribution, HTTP methods, host traffic, and request timeline

- **Log history**
  - Automatically save session logs to disk for later review
  - Browse past sessions from Tools
  - Enable or disable history persistence from settings

- **Lightweight and easy to integrate**
  - One-line setup to start monitoring
  - No XIB/Storyboards, no external dependencies
  - Works with SwiftUI, UIKit, and AppKit
  - Toggle debug console logging on or off
  - Supports both light and dark mode

- **Cross-platform**
  - iOS 16.0+ / macOS 13.0+


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

// Remove all registered mocks
NetworkSpectator.stopMocking()

// Skip logging for specific requests
NetworkSpectator.ignoreLogging(for rule: MatchRule)

// Remove all skip logging rules
NetworkSpectator.stopIgnoringLog()
```

### On-Demand Monitoring

Start NetworkSpectator in on-demand mode to let users enable monitoring from the UI:

```swift
NetworkSpectator.start(onDemand: true)
```

### Disabling NetworkSpectator

If enabled, then, to stop network monitoring:

```swift
NetworkSpectator.stop()
```

## NetworkSpectator on iOS
The following screenshots demonstrate NetworkSpectator running on iOS.

| List of Requests | Filters | URL Search | Details |
|---------|---------|------------|------------|
| <img width="300" height="652" alt="landing" src="https://github.com/user-attachments/assets/5da584f2-1c41-4234-8202-a77708a2a3c9" /> | <img width="300" height="652" alt="filters_ios" src="https://github.com/user-attachments/assets/043395c8-e0e7-4d2a-ab91-61ff89c4268d" /> | <img width="300" height="652" alt="url_search_ios" src="https://github.com/user-attachments/assets/43106dd4-e6a9-4cd6-933e-86519c0002ba" /> | <img width="300" height="652" alt="basic_ios" src="https://github.com/user-attachments/assets/e0eefc13-c54a-4d7a-8fdd-1a9d675e8ead" /> |

| Headers | Response | Tools | History |
|---------|----------|----------|-------|
| <img width="300" height="652" alt="headers_ios" src="https://github.com/user-attachments/assets/e4b512d2-efc2-4d9b-bc10-e57991f6755e" /> | <img width="300" height="652" alt="response_response" src="https://github.com/user-attachments/assets/bdebe73d-5f5c-4d02-8eea-d6793f499313" /> | <img width="300" height="652" alt="settings_ios" src="https://github.com/user-attachments/assets/6dd6f018-6f6c-4ce9-86e5-b073f81d1085" /> | <img width="300" height="652" alt="share_ios" src="https://github.com/user-attachments/assets/bf1be17f-9955-41da-9022-efff604388ba" /> |

| Insights | Insights - Timeline | Insights - Status code | Insights - Performance |
|---------|---------|----------|-----------|
| <img width="300" height="652" alt="insights_ios" src="https://github.com/user-attachments/assets/70cba56d-49b4-4245-a32d-96697231cdaf" /> | <img width="300" height="652" alt="timeline_ios" src="https://github.com/user-attachments/assets/8c63883f-431f-4992-bc85-6b4545d4d767" /> | <img width="300" height="652" alt="status_code_ios" src="https://github.com/user-attachments/assets/d42d4cb3-e664-40db-bad1-3ca9b68a791f" /> | <img width="300" height="652" alt="perf_ios" src="https://github.com/user-attachments/assets/1a6141cd-657c-4f5b-b5b8-82dee2fa8742" /> |

## NetworkSpectator on macOS
The following screenshots demonstrate NetworkSpectator running on macOS.

| List of Requests | Filters | Details |
|------------------|---------|---------------|
| <img width="1169" height="620" alt="landing_mac" src="https://github.com/user-attachments/assets/a79edd45-337d-4890-ae7a-5b8de137c196" /> | <img width="1152" height="609" alt="filters_mac" src="https://github.com/user-attachments/assets/eab654ea-624b-4d9c-b8db-4eeaf275bbd1" /> | <img width="1152" height="833" alt="basic_details_mac" src="https://github.com/user-attachments/assets/8cf2a025-060d-43ba-931c-b84a18dc0a6e" /> |

| Headers | Response | Tools |
|---------|----------|-----------|
| <img width="1152" height="833" alt="headers_mac" src="https://github.com/user-attachments/assets/8846eec1-11f4-4b39-beb3-5b99d2eaee5c" /> | <img width="1152" height="833" alt="response_mac" src="https://github.com/user-attachments/assets/83435e3c-3839-4fe6-974d-34c84ede8e86" /> | <img width="1152" height="949" alt="analytics_mac" src="https://github.com/user-attachments/assets/433a04ec-2ff7-412d-98a6-fdb1a68264a4" /> |

| Insights | Timeline | Performance |
|----------|----------|--------------|
| <img width="1169" height="620" alt="settings_mac" src="https://github.com/user-attachments/assets/5f10bd2a-aeb9-42eb-83f8-47fbc6493e9f" /> | <img width="1169" height="632" alt="add_mock_mac" src="https://github.com/user-attachments/assets/36ec6643-1159-41b8-9f57-76919f8315d0" /> | <img width="1169" height="632" alt="skip_logging_mac" src="https://github.com/user-attachments/assets/508c99b7-192d-46cf-8596-890a806c5119" /> |

## Safety and Release Builds

Because NetworkSpectator captures and displays network information, you should **limit it to debug/test builds only**. Wrap your integration points with `#if DEBUG` to ensure nothing leaks into release builds.

### Recommendations:

- Always guard with `#if DEBUG` and/or internal feature flags
- Ensure NetworkSpectator is not initialized in release configurations

### Example:

```swift
// Monitoring will start only for a debug build.
#if DEBUG
NetworkSpectator.start()
#endif
```

## Requirements

- Swift 6+
- iOS 16.0+ / macOS 13.0+
- Xcode 16.0+

## LICENSE
MIT license. View LICENSE for more details.
