# SUICore

**SUICore** is a foundational SwiftUI package providing common utilities, helpers, and reusable components used to accelerate the development of SwiftUI-based SDKs and apps. It bundles a toast presentation system, a Keychain service, network connectivity monitoring, structured logging, file management, and a rich set of Swift / SwiftUI / UIKit extensions — all in a single, lightweight library.

## Requirements

- Swift **6.2+**
- iOS **26+** / Mac Catalyst **26+**
- Xcode 26 or later

## Modules

### 🔔 SUIToast

A flexible, queue-based toast notification system for SwiftUI with a fluent builder API, custom styles, animations, haptics, and per-toast actions.

**Install the renderer once near the root of your scene:**

```swift
import SwiftUI
import SUICore

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .toastContainer() // installs the shared ToastManager renderer
        }
    }
}
```

**Show a toast — quick API:**

```swift
ToastManager.shared.show(
    title: "Saved",
    message: "Your changes are safe.",
    style: ToastStyle.success,
    duration: .short,
    position: .top
)
```

**Show a toast — fluent builder:**

```swift
let toast = ToastBuilder(title: "Saved")
    .message("Your changes are safe.")
    .style(.success)
    .duration(.short)
    .position(.bottom)
    .animation(.spring)
    .haptic(.success)
    .action("Undo") { undo() }
    .build()

ToastManager.shared.show(toast)
```

**Local, SwiftUI-style presentation (no global manager required):**

```swift
struct DemoView: View {
    @State private var isPresented = false

    var body: some View {
        Button("Show toast") { isPresented = true }
            .toast(isPresented: $isPresented) {
                ToastBuilder(title: "Hello").style(.info).build()
            }
    }
}
```

---

### 🔐 KeychainService

Type-safe Keychain wrapper for storing any `Codable` value with configurable accessibility.

```swift
struct AuthToken: Codable { let value: String }

// Save
try KeychainService.save(
    value: AuthToken(value: "abc123"),
    forKey: "auth.token",
    accessibility: .afterFirstUnlockThisDeviceOnly
)

// Retrieve
let token: AuthToken? = try KeychainService.retrieve(forKey: "auth.token")

// Delete
try KeychainService.delete(forKey: "auth.token")
```

See [KeychainService](Sources/SUICore/Services/Keychain/KeychainService.swift) and [KeychainError](Sources/SUICore/Services/Keychain/KeychainError.swift).

---

### 📡 ConnectionStatus

Network reachability monitor backed by `NWPathMonitor`, exposed as both a Combine publisher and a delegate-style observer.

```swift
import Combine
import SUICore

let cancellable = ConnectionStatus.shared.isNetworkAvailablePublisher
    .sink { isOnline in
        print("Online: \(isOnline)")
    }

// Or via delegate
ConnectionStatus.shared.addObserver(self)
```

See [ConnectionStatus](Sources/SUICore/Utilities/ConnectionStatus.swift).

---

### 📝 ZOSLogs

Lightweight wrapper around Apple's `OSLog` `Logger` API with leveled, file/line-aware logging.

```swift
ZOSLogs.shared.debug("Loaded \(items.count) items")
ZOSLogs.shared.info("User signed in")
ZOSLogs.shared.warning("Cache miss")
ZOSLogs.shared.error("Network failed: \(error)")
```

See [ZOSLogs](Sources/SUICore/Utilities/ZOSLogs.swift).

---

### 📁 ZFFileManager

App-scoped cache management built on `FileManager` — write, read, list, size, and clear files inside a per-bundle cache directory.

See [ZFFileManager](Sources/SUICore/Utilities/FileManager/ZFFileManager.swift).

---

### 🅰️ LetterAvatar

A `UIImageView` subclass that renders deterministic letter-based avatars from a name (initials over a name-derived background color).

```swift
let avatar = LetterAvatar(name: "John Doe", size: 80)
avatar.configure(with: "Jane Smith") // update later
```

See [LetterAvatar](Sources/SUICore/Utilities/LetterAvatar.swift).

---

### 📄 DocumentViewRepresentable

SwiftUI wrapper around `UIDocumentPickerViewController` for exporting files.

```swift
.sheet(isPresented: $showPicker) {
    DocumentViewRepresentable(fileURL: fileURL) { success, error in
        // handle export result
    }
}
```

See [DocumentViewRepresentable](Sources/SUICore/ViewRepresentables/DocumentViewRepresentable.swift).

---

### ZMenu

A fully customizable dropdown menu component for Mac Catalyst. Renders the dropdown in a dedicated `UIWindow` overlay, solving layout collapse and zIndex issues with native SwiftUI `Menu`.

```swift
import SUICore

ZMenu {
    ZMenuItem("Edit", icon: "pencil") { }
    ZMenuItem("Delete", icon: "trash", role: .destructive) { }
    Divider()
    ZMenuItem("Settings", icon: "gear") { }
} label: {
    Text("Options")
}
.zMenuStyle(GlassyZMenuStyle())
```

**Style protocol** — full control over label and dropdown appearance:

```swift
struct MyStyle: ZMenuStyle {
    func makeBody(configuration: ZMenuStyleConfiguration) -> some View {
        configuration.label
    }

    func makeContent(configuration: ZMenuStyleConfiguration) -> some View {
        configuration.content
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}
```

Built-in styles: `GlassyZMenuStyle` (default, Liquid Glass) and `DefaultZMenuStyle` (plain background).

See [ZMenu](Sources/SUICore/ZMenu/).

---

### 🧰 Extensions

Curated set of Foundation / SwiftUI / UIKit extensions:

- [Array+](Sources/SUICore/Utilities/Extensions/Array+.swift)
- [Color+](Sources/SUICore/Utilities/Extensions/Color+.swift)
- [Date+](Sources/SUICore/Utilities/Extensions/Date+.swift)
- [ProcessInfo+](Sources/SUICore/Utilities/Extensions/ProcessInfo+.swift)
- [String+](Sources/SUICore/Utilities/Extensions/String+.swift)
- [UIColor+](Sources/SUICore/Utilities/Extensions/UIColor+.swift)
- [UIImage+](Sources/SUICore/Utilities/Extensions/UIImage+.swift)
- [UIScreen+](Sources/SUICore/Utilities/Extensions/UIScreen+.swift)
- [UIWindow+](Sources/SUICore/Utilities/Extensions/UIWindow+.swift)
- [View+](Sources/SUICore/Utilities/Extensions/View+.swift) — `customShadow`, `snapshot`, and more.

Plus [UIViewPreview](Sources/SUICore/Utilities/UIViewPreview.swift) for previewing UIKit views in SwiftUI canvases.

## Project Structure

```
Sources/SUICore/
├── Services/
│   └── Keychain/             # KeychainService + errors
├── SUIToast/                 # Toast system (Models, Builder, Manager, Views, Modifiers)
├── Utilities/
│   ├── Extensions/           # Foundation / SwiftUI / UIKit extensions
│   ├── FileManager/          # ZFFileManager
│   ├── ConnectionStatus.swift
│   ├── LetterAvatar.swift
│   ├── UIViewPreview.swift
│   └── ZOSLogs.swift
├── ViewRepresentables/       # UIKit ↔ SwiftUI bridges
└── ZMenu/                    # Custom dropdown menu (overlay window-based)
    ├── Views/                # ZMenuContentView
    ├── Utilities/            # FrameReader
    ├── ZMenu.swift           # Public container view API
    ├── ZMenuStyle.swift      # Style protocol + built-in styles
    ├── ZMenuItem.swift       # Menu item view
    ├── ZMenuCoordinator.swift
    ├── ZMenuOverlayWindow.swift
    ├── ZMenuHostingController.swift
    ├── ZMenuPositioning.swift
    └── ZMenuEnvironment.swift
```

## Testing

Run the test suite from the package root:

```bash
swift test
```

## License

SUICore is released under the **Apache License 2.0**. See [LICENSE](LICENSE) for details.

