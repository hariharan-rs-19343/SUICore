# SUICore Project Knowledge Base

Single source of truth for understanding and working on the SUICore library.

---

## What is SUICore?

A foundational **SwiftUI utility library** providing reusable components, services, and extensions for iOS/Mac Catalyst apps. Single-module Swift Package — consumers just `import SUICore`.

---

## Tech Stack

- **Language:** Swift 6.2+
- **UI Framework:** SwiftUI + UIKit bridges
- **Platform:** iOS 26+ / Mac Catalyst 26+
- **Package Manager:** Swift Package Manager (swift-tools-version: 6.2)
- **Concurrency:** Swift 6 strict concurrency
- **Dependencies:** None (zero external deps)

---

## Project Structure

```
SUICore/
├── Package.swift
├── README.md
├── LICENSE (Apache 2.0)
├── Sources/SUICore/
│   ├── Services/
│   │   └── Keychain/              # KeychainService, KeychainError
│   ├── SUIToast/                  # Toast notification system
│   │   ├── Models/                # Toast, ToastAction, ToastStyle, etc.
│   │   ├── Protocols/            # ToastContentProviding, ToastStyleProviding
│   │   ├── Builders/             # ToastBuilder (fluent API)
│   │   ├── Manager/              # ToastManager (shared, queue-based)
│   │   ├── Views/                # DefaultToastView, ToastContainerView
│   │   └── Modifiers/           # ToastContainerModifier
│   ├── Utilities/
│   │   ├── Extensions/           # Array+, Color+, Date+, String+, UI*, View+
│   │   ├── FileManager/          # ZFFileManager
│   │   ├── ConnectionStatus.swift
│   │   ├── LetterAvatar.swift
│   │   ├── UIViewPreview.swift
│   │   └── ZOSLogs.swift
│   ├── ViewRepresentables/       # DocumentViewRepresentable
│   └── ZMenu/                    # Custom dropdown menu system
│       ├── Views/                # ZMenuContentView
│       ├── Utilities/            # FrameReader
│       ├── ZMenu.swift           # Public container view
│       ├── ZMenuStyle.swift      # Style protocol + GlassyZMenuStyle, DefaultZMenuStyle
│       ├── ZMenuItem.swift       # Menu item view
│       ├── ZMenuCoordinator.swift # Overlay window lifecycle
│       ├── ZMenuOverlayWindow.swift
│       ├── ZMenuHostingController.swift
│       ├── ZMenuPositioning.swift
│       └── ZMenuEnvironment.swift
└── Tests/SUICoreTests/
    ├── SUICoreTests.swift
    └── ZipTests.swift
```

---

## Organization Pattern

- **Single module:** everything is `import SUICore`
- **Feature-first:** top-level folders per feature (`SUIToast/`, `ZMenu/`, `Services/`)
- **Layered inside features:** Models / Protocols / Builders / Manager / Views / Modifiers
- **Naming:** `SUI` prefix for SwiftUI-facing features, `ZF` prefix for file utilities, `ZOS` for logging

---

## Feature: ZMenu

Custom dropdown menu for Mac Catalyst using a UIWindow overlay.

### Architecture

```
ZMenu (container view) → captures frame via readFrame → tap triggers ZMenuCoordinator
  → ZMenuCoordinator creates/reuses ZMenuOverlayWindow (UIWindow at .alert+1)
  → Hosts ZMenuOverlayContent in ZMenuHostingController
  → style.makeContent() applies visual decoration (glass, shadow)
  → Positioned via ZMenuPositioning (trailing-align + flip/clamp logic)
  → readFrame continuously updates coordinator.anchorFrame while presented
  → ZMenuLayoutChangeBehavior controls response: .dismiss (default) or .reposition
  → Auto-dismisses if label leaves screen regardless of behavior
```

### Style Protocol

```swift
protocol ZMenuStyle {
    func makeBody(configuration:) -> LabelBody     // label appearance
    func makeContent(configuration:) -> ContentBody // dropdown container appearance
}
```

- Default extension provides Liquid Glass fallback for `makeContent`
- `GlassyZMenuStyle` (default): `.glassEffect` + layered shadows + white border
- `DefaultZMenuStyle`: plain `.systemBackground` + single shadow + gray border
- Environment-propagated via `.zMenuStyle()`

### Key Types

| Type | Role |
|------|------|
| `ZMenu` | Public container view with internal/external state |
| `ZMenuCoordinator` | `@MainActor ObservableObject`, owns overlay window |
| `ZMenuOverlayWindow` | UIWindow at elevated level |
| `ZMenuHostingController` | UIHostingController + keyboard commands |
| `ZMenuPositioning` | Pure position calculation (trailing-align, flip, clamp) |
| `ZMenuFocusModel` | Keyboard arrow navigation state |
| `ZMenuItem` | Individual item with hover + auto-dismiss |

### Environment Keys

- `\.zMenuStyle` — propagates active style
- `\.zMenuDismiss` — closure called by items to dismiss menu
- `\.zMenuLayoutChangeBehavior` — `.dismiss` (default) or `.reposition`; set via `.zMenuLayoutChangeBehavior(_:)` modifier

---

## Feature: SUIToast

Queue-based toast system with global manager or local SwiftUI binding.

### Key Types

- `Toast` — model with title, message, style, duration, position, action
- `ToastManager` — singleton, manages queue, publishes current toast
- `ToastBuilder` — fluent builder pattern
- `ToastContainerView` — renders toasts with animation
- `.toastContainer()` modifier — installs renderer at scene root

---

## Feature: KeychainService

Type-safe Keychain CRUD for `Codable` values. Static methods, no singleton state.

---

## Feature: ConnectionStatus

`NWPathMonitor`-backed reachability. Singleton with Combine publisher + delegate observers.

---

## Feature: ZOSLogs

Thin wrapper on `os.Logger`. Levels: debug, info, warning, error. Includes file/line metadata.

---

## Build Commands

```bash
# Mac Catalyst
xcodebuild build -scheme SUICore -destination 'platform=macOS,variant=Mac Catalyst'

# iOS Simulator
xcodebuild build -scheme SUICore -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Tests
swift test
```

---

## Conventions

- All UI-bound types use `@MainActor`
- Environment keys use `nonisolated(unsafe)` for static defaults when needed
- `@preconcurrency EnvironmentKey` for keys with MainActor-isolated default values
- Public APIs use `@ViewBuilder` closures for content composition
- No external dependencies — keep the package self-contained
