# SUICore

**SUICore** is a foundational SwiftUI package providing common utilities, helpers, and reusable components used to accelerate the development of SwiftUI-based SDKs and apps. It bundles a toast presentation system, a Keychain service, network connectivity monitoring, structured logging, file management, and a rich set of Swift / SwiftUI / UIKit extensions — all in a single, lightweight library.

## Requirements

- Swift **6.2+**
- iOS **26+** / macOS **26+**
- Xcode 26 or later

## Modules

### 🔔 SUIToast

A flexible, queue-based toast notification system for SwiftUI with a fluent builder API, custom styles, animations, haptics, and per-toast actions. Runs on iOS and macOS from the same call site — haptics, hover-to-pause, the close button and Escape-to-dismiss each resolve to whatever the platform supports.

`Toast` is `Sendable`, so you can build one off the main actor and `await` the show.

**Install the renderer near the root of your scene:**

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

The modifier also injects the manager into the environment, so any child view can reach it without the singleton:

```swift
@Environment(ToastManager.self) private var toasts
```

**Show a toast — quick API:**

```swift
ToastManager.shared.show(
    title: "Saved",
    message: "Your changes are safe.",
    configuration: ToastConfiguration(
        style: ToastStyle.success,
        duration: .short,
        position: .top
    )
)
```

**Show a toast — fluent builder:**

```swift
let toast = ToastBuilder(title: "Saved")
    .message("Your changes are safe.")
    .style(ToastStyle.success)
    .duration(.short)
    .position(.bottom)
    .animation(.spring)
    .haptic(.success)
    .action("Undo") { undo() }
    .build()

ToastManager.shared.show(toast) // returns the toast's UUID
```

**Custom content** — the framework keeps the queue, animation, gestures and safe-area handling; you own the body:

```swift
struct SyncProgress: ToastContentProviding {
    let percent: Double

    func makeBody(dismiss: @escaping @MainActor @Sendable () -> Void) -> some View {
        HStack {
            ProgressView(value: percent)
            Button("Stop", action: dismiss)
        }
        .padding()
    }
}

let toast = ToastBuilder(title: "Syncing")
    .content(SyncProgress(percent: 0.4))
    .duration(.persistent)
    .build()
```

**Queue behaviour** — one toast is visible at a time and the rest wait their turn:

```swift
let manager = ToastManager(
    maxQueueDepth: 3,           // oldest pending toast is dropped past this
    queuePolicy: .dropIfDuplicate  // or .enqueue (default) / .replaceCurrent
)
```

`.dropIfDuplicate` compares title and message, which keeps a retry loop from queueing the same failure fifty times.

**Sheets, covers and multiple windows** — install a container in every presentation layer that needs one:

```swift
ContentView()
    .toastContainer()
    .sheet(isPresented: $editing) {
        EditorView().toastContainer()   // wins while the sheet is up
    }
```

This is not redundant. SwiftUI presents a sheet above the presenting view's hierarchy, so the root container's overlay cannot draw over it — without a container inside the sheet, a toast raised from sheet code renders behind the sheet and is never seen.

When several containers observe the same manager, the frontmost one draws and the rest stand down, so a toast still appears exactly once. Dismiss the sheet mid-toast and the parent container picks it up; the countdown never stopped. Containers in a window that isn't active stand down too, and `.toastContainer(isActive:)` overrides the election by hand when the automatic answer is wrong.

For genuinely separate windows that should each keep their own queue:

```swift
WindowGroup {
    ContentView().windowScopedToastContainer()
}
```

Code inside such a window must reach the manager through `@Environment(ToastManager.self)` — `ToastManager.shared` is a different instance and its toasts will not render there.

**Local, SwiftUI-style presentation (no global manager required):**

```swift
struct DemoView: View {
    @State private var isPresented = false

    var body: some View {
        Button("Show toast") { isPresented = true }
            .toast(isPresented: $isPresented) {
                ToastBuilder(title: "Hello").style(ToastStyle.info).build()
            }
    }
}
```

**Accessibility** — toasts are announced to VoiceOver on appear, auto-dismiss durations stretch while VoiceOver runs, action and close buttons stay individually focusable, and Reduce Motion collapses every transition to a cross-fade.

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

**Positioning** — the dropdown trailing-aligns to the label when wider, or left-aligns when narrower. The menu automatically flips above the label when there isn't enough space below, and clamps to screen edges.

**Layout change behavior** — controls what happens when the label moves while the dropdown is open (e.g. sidebar collapse):

```swift
// Default: dismisses the dropdown when the label moves
ZMenu { /* items */ } label: { Text("Options") }

// Opt-in: dropdown slides to follow the label
ZMenu { /* items */ } label: { Text("Options") }
    .zMenuLayoutChangeBehavior(.reposition)
```

If the label leaves the screen entirely (hidden or removed), the dropdown auto-dismisses regardless of the chosen behavior.

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

