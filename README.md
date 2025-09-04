# AppUtilityKit

A modular collection of utilities for iOS app development.
Each component is available as an independent library and `AppUtilityKitCore` re-exports all modules.

Included modules:

- **AppInfoKit** – access `Info.plist` values such as app name or custom URLs
- **LoggerKit** – wrapper around `os.Logger`
- **CoreDataKit** – global actor and executor for Core Data
- **ProductPurchaseKit** – StoreKit 2 purchase flow utilities
- **UserDefaultKit** – typed `UserDefaults` wrappers
- **UtilityKit** – miscellaneous extensions (Color, Date, calendars, etc.)

> **Note**: Many modules depend on Apple-only frameworks (CoreData, StoreKit2, SwiftUI, os.Logger). Building on non-Apple platforms is not supported.

## Installation

Use Swift Package Manager and add the repository as a dependency:

```swift
dependencies: [
    .package(url: "https://github.com/iwacchi/AppUtilityKit.git", from: "1.0.0")
]
```

Add desired libraries to your target. `AppUtilityKitCore` re-exports every module so you can import everything at once:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "AppUtilityKitCore", package: "AppUtilityKit")
        // or use .product(name: "AppInfoKit", package: "AppUtilityKit") etc.
    ]
)
```

## Modules and Usage

### AppInfoKit

Access application metadata and custom URLs defined in `Info.plist`.
Define URLs using the following keys for example:

| Info.plist key | Purpose |
|---|---|
| `AppUtilityKit - App store URL` | Link to App Store page |
| `AppUtilityKit - Privacy policy URL` | Link to privacy policy |
| `AppUtilityKit - Terms of service URL` | Link to terms of service |

```swift
import AppInfoKit

let info = AppInfoKit.current
print(info.appName)          // App display name
print(info.appStoreURL)      // URL from Info.plist if provided
```

### LoggerKit

Structured logging using `os.Logger` (iOS 14+).

```swift
import LoggerKit

// Configure subsystem and log level if needed
LoggerKit.config.minimumLogLevel = .info

LoggerKit.app.debug("Application started")
LoggerKit.network.error("Request failed: \(error)")
```

`LoggerKit.config.minimumLogLevel` lets you filter out verbose logs in release builds.

### CoreDataKit

Provides a `SerialExecutor`, global actor and thin context wrapper for Core Data (iOS 17+).

```swift
import CoreDataKit
import CoreData

// Configure once on launch
let container = NSPersistentContainer(name: "Model")
container.loadPersistentStores { _, _ in }
CoreDataExecutor.configureShared(container: container)

// Perform database work
@CoreDataActor func insertItem() async throws {
    let context = CoreDataExecutor.shared.context
    let item: MyEntity = context.create()
    try context.save()
}
```

### ProductPurchaseKit

Simplifies StoreKit 2 purchase flow and entitlement handling (iOS 15+).

```swift
import ProductPurchaseKit
import StoreKit

@MainActor
struct PurchaseExecutor: ProductPurchaseExecutor {
    func upgradeExecute(transaction: Transaction) async {}
    func downgradeExecute() async {}
}

// Configure executor early
ProductPurchaseKit.shared.configure { PurchaseExecutor() }

// Purchase a product and start observing updates
let result = try await ProductPurchaseKit.shared.purchase(for: product)
ProductPurchaseKit.shared.startObservingTransactionUpdates { txn in
    print("Received: \(txn.id)")
}
```

### UserDefaultKit

Type-safe wrappers around `UserDefaults` with property wrappers.

```swift
import UserDefaultKit

enum SettingKey: UserDefaultKey {
    case hasOnboarded
    var key: String { "hasOnboarded" }
}

@UserDefaultKit(userDefaultKey: SettingKey.hasOnboarded, defaultValue: false)
var hasOnboarded: Bool

enum SortOrder: Int { case none, asc, desc }
@RawRepresentableUserDefaultKit(key: "sort", defaultValue: .none)
var sortOrder: SortOrder
```

### UtilityKit

General extensions and helpers such as:

- `Color` codable support (SwiftUI)
- `Date` convenience utilities
- Calendar value types like `YearMonthDay`
- `AppearanceMode` enum to switch between light/dark/system modes

```swift
import UtilityKit
import SwiftUI

let color = Color.red
let json = try color.jsonString          // Encode Color to JSON
let date = Date().isWeekend              // Check if date is weekend
let mode: AppearanceMode = .dark
```

## License

[MIT](LICENSE)
