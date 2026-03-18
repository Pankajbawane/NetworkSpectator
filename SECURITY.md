# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x  | :white_check_mark: |

## Important Security Considerations

NetworkSpectator is a **debug-only** network inspection library. By design, it captures and stores complete HTTP traffic, including potentially sensitive data such as:

- Authorization headers and bearer tokens
- Cookies and session identifiers
- API keys (in URLs, headers, or request bodies)
- Personal or confidential data in request/response bodies
- Query parameters containing sensitive values

### Data Storage

Captured network logs may be persisted to disk as **unencrypted JSON files** in the app's directory, and mock/skip rules are stored in `UserDefaults`. None of this data is encrypted at rest.

### Recommendations for Integrators

1. **Never include NetworkSpectator in release/production builds.** Always guard initialization with `#if DEBUG`:

   ```swift
   #if DEBUG
   NetworkSpectator.start()
   #endif

2. **Use skip rules** to exclude endpoints that handle highly sensitive data (e.g., authentication, payment processing) from being logged, even in debug builds.

3. **Do not commit exported logs** (CSV, text, or Postman collections) to version control, as they may contain sensitive request/response data.

4. **Clear log history** regularly during development to minimize the window of sensitive data exposure on disk.

5. **Be cautious with mock rules saved locally**, as they persist in User​Defaults and could contain sensitive endpoint patterns or response data.

## Reporting a Vulnerability

If you discover a security vulnerability in NetworkSpectator, please do not open a public issue.

Instead, report it via GitHub's reporting tool - **Settings > Security > Private vulnerability reporting** with the following details:

- A description of the vulnerability
- Steps to reproduce the issue
- The potential impact
- Any suggested fix (optional)

### What to Expect
- **Assessment**: We will assess the severity and impact of the vulnerability and communicate our findings.
- **Resolution**: For confirmed vulnerabilities, we aim to release a patch or mitigation guidance promptly.
- **Credit**: With your permission, we will credit you in the release notes for the fix.

### Scope

**The following are considered in scope for security reports:**

- Data leakage from NetworkSpectator into production builds
- Unintended data exposure through storage mechanisms (file system, UserDefaults)
- Vulnerabilities in the mock server that could be exploited (e.g., request interception beyond intended scope)
- Export functionality producing outputs that inadvertently expose data
- Issues in Network​URLProtocol that could cause unexpected behavior in host apps

**The following are considered out of scope:**

- Sensitive data being captured in debug builds (this is by design)
- Security issues in the host application unrelated to NetworkSpectator
- Issues that require physical access to an unlocked device with a debug build

### Security Best Practices for Contributors

When contributing to NetworkSpectator:

1. Do not add external dependencies. The zero-dependency policy minimizes the supply chain attack surface.
2. Do not introduce network calls from the library itself. NetworkSpectator should only observe traffic, never generate its own.
3. Do not log or print captured data to the system console in ways that could leak into device logs.
4. Ensure all test fixtures use synthetic/fake data and never contain real credentials, tokens, or personal information.
5. Review mock server changes carefully to ensure mocks cannot escape their intended scope or affect non-debug traffic.
