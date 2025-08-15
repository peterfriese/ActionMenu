## About ActionMenu

ActionMenu is a SwiftUI library that provides a flexible and easy-to-use menu component for iOS applications, similar to the one in Apple's built-in mail app.

![Video showing an iOS UI with a list of fruits. As the user selects the "More" action from the swipe action bar, a bottom sheet with a number of actions appears. The user selects several of the listed actions to manipulate the fruit list items.](Resources/demo.gif)

## Requirements

- iOS 18.0+
- Swift 6.0+

## Installation

### Xcode

1. In Xcode, open your project and navigate to File > Add Packages...
2. In the search field, enter the package repository URL: `https://github.com/peterfriese/ActionMenu`
3. Select the package when it appears in the search results
4. Choose your target application in the "Add to Project" field
5. Click "Add Package"


### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
  .package(url: "https://github.com/peterfriese/ActionMenu", from: "1.0.0")
]
```

Then, include "ActionMenu" as a dependency for your target:

```swift
targets: [
  .target(
    name: "YourTarget",
    dependencies: ["ActionMenu"])
]
```

## Quick Start

1. Import the package in your SwiftUI file:

```swift
import SwiftUI
import ActionMenu
```

2. Use the `.actionMenu` modifier on any view:

```swift
.actionMenu(title: "Actions", isPresented: $isShowingMenu) {
  Button("Option 1") {
    // Handle option 1
  }
  Button("Option 2") {
    // Handle option 2
  }
}
```

## Example

Here's a complete example showing how to use ActionMenu with a list:

```swift
struct ContentView: View {
  @State private var isMoreActionTapped = false
  @State private var selectedItem: String? = nil
    
  var body: some View {
    List(items, id: \.self) { item in
      Text(item)
        .swipeActions {
          Button("More", systemImage: "ellipsis.circle") {
            selectedItem = item
            isMoreActionTapped.toggle()
          }
        }
    }
    .actionMenu(title: "Actions", isPresented: $isMoreActionTapped) {
      Button("Flag", systemImage: "flag") {
        // Handle edit action
      }
      Button("Delete", role: .destructive) {
        // Handle delete action
      }
    }
  }
}
```

## Styling

The `ActionMenu` can be styled using standard SwiftUI techniques. The default appearance is designed to mimic the look and feel of the menu in Apple's Mail app.

### Backported Styles

To ensure the menu looks "at home" on different iOS versions, `ActionMenu` uses a backporting pattern for some of its styles. For example, the toolbar button on the sheet will use the `.glassProminent` button style on iOS 26 and newer, while falling back to a standard button style on older versions.

## Contributing

Contributions are welcome! Please feel free to submit a PR.

## License

ActionMenu is licensed under the Apache 2 license. See the [LICENSE](LICENSE) file for details.

## Author

Peter Friese

