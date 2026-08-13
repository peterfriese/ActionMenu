//
// ActionMenu.swift
// ActionMenu
//
// Created by Peter Friese on 22.01.25.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

/// A view modifier that sizes a presentation sheet to the height of its scrollable content.
///
/// It measures the scroll content size of the modified view (typically a `List`) and applies
/// the measured height as a `.height` presentation detent. The scroll content size is measured
/// instead of the view's own frame to avoid a feedback loop between the detent height and the
/// measured size. A `.medium` detent is used as a fallback until the first measurement
/// completes, preventing an invisible, zero-height sheet from flashing.
struct SelfSizingSheetModifier: ViewModifier {
  @State private var contentHeight: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .onScrollGeometryChange(for: CGSize.self, of: { proxy in
        proxy.contentSize
      }, action: { _, newSize in
        contentHeight = newSize.height
      })
      .presentationDetents(
        contentHeight == 0
        ? [.medium, .large]
        : [.height(contentHeight), .large]
      )
  }
}

struct ActionMenu<Content: View>: View {
  @Environment(\.dismiss) private var dismiss
  @State private var pendingAction: (() -> Void)? = nil

  let title: String
  let content: Content

  init(
    title: String = "Options",
    @ContentBuilder content: () -> Content
  ) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    NavigationStack {
      List {
        content
      }
      .modifier(SelfSizingSheetModifier())
      .labelStyle(.menu)
      .buttonStyle(ActionMenuButtonStyle(pendingAction: $pendingAction))
      .tint(.primary)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if #available(iOS 26, *) {
            Button("", systemImage: "xmark") {
              dismiss()
            }
            .accessibilityLabel("Close")
          } else {
            Button("Done") {
              dismiss()
            }
          }
        }
      }
    }
    .onDisappear {
      pendingAction?()
      pendingAction = nil
    }
    .onAppear {
      pendingAction = nil
    }
  }
}

struct ActionMenuModifier<MenuContent: View>: ViewModifier {
  let title: String
  @Binding var isPresented: Bool
  let menuContent: MenuContent

  init(title: String, isPresented: Binding<Bool>, @ContentBuilder menuContent: () -> MenuContent) {
    self.title = title
    self._isPresented = isPresented
    self.menuContent = menuContent()
  }

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $isPresented) {
        ActionMenu(title: title) {
          menuContent
        }
      }
  }
}

extension View {
  /// Presents an action menu sheet when a binding to a Boolean value that you provide is true.
  ///
  /// Use this modifier to present a menu of actions to the user, similar to the menu in Apple's Mail app.
  /// The menu is presented as a sheet from the bottom of the screen.
  ///
  /// In the example below, a list of fruits is displayed. When the user swipes left on a row, a "More" button
  /// is revealed. Tapping this button sets the `isMoreActionTapped` state variable to `true`, which
  /// triggers the presentation of the action menu.
  ///
  /// ```swift
  /// struct ContentView: View {
  ///   @State private var fruits = ["Apple", "Banana", "Orange"]
  ///   @State private var isMoreActionTapped = false
  ///   @State private var selectedFruit: String? = nil
  ///
  ///   var body: some View {
  ///     List(fruits, id: \.self) { fruit in
  ///       Text(fruit)
  ///         .swipeActions {
  ///           Button("More", systemImage: "ellipsis.circle") {
  ///             selectedFruit = fruit
  ///             isMoreActionTapped.toggle()
  ///           }
  ///         }
  ///     }
  ///     .actionMenu(title: "Actions", isPresented: $isMoreActionTapped) {
  ///       Button("Uppercase", systemImage: "characters.uppercase") {
  ///         // action for uppercasing the selected fruit
  ///       }
  ///       Button("Delete", role: .destructive) {
  ///         // action for deleting the selected fruit
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - title: The title to display in the navigation bar of the action menu.
  ///   - isPresented: A binding to a Boolean value that determines whether to present the action menu.
  ///   - content: A `@ContentBuilder` closure that creates the content of the action menu. This is typically a list of `Button`s.
  public func actionMenu(
    title: String, isPresented: Binding<Bool>,
    @ContentBuilder content: @escaping () -> some View
  ) -> some View {
    modifier(
      ActionMenuModifier(
        title: title,
        isPresented: isPresented,
        menuContent: content
      )
    )
  }
}

#Preview {
  @Previewable @State var fruits = [
    "Apple", "Banana", "Orange", "Mango", "Pear", "Grape", "Pineapple",
    "Strawberry",
  ]
  @Previewable @State var isMoreActionTapped = false
  @Previewable @State var selectedFruit: String? = nil

  Button(action: { isMoreActionTapped.toggle() }) {
    Text("Show Action Menu")
  }
  .actionMenu(title: "Actions", isPresented: $isMoreActionTapped) {
    Section("Text Operations") {
      Button("Uppercase", systemImage: "characters.uppercase") {
        if let selectedFruit = selectedFruit,
           let index = fruits.firstIndex(of: selectedFruit)
        {
          fruits[index] = selectedFruit.uppercased()
        }
      }
      .labelStyle(.menu)

      Button("Lowercase", systemImage: "characters.lowercase") {
        if let selectedFruit = selectedFruit,
           let index = fruits.firstIndex(of: selectedFruit)
        {
          fruits[index] = selectedFruit.lowercased()
        }
      }
    }

    Section {
      Button("Delete Item", systemImage: "trash", role: .destructive) {
        if let selectedFruit = selectedFruit,
           let index = fruits.firstIndex(of: selectedFruit)
        {
          fruits.remove(at: index)
        }
      }
    }
  }

}

#Preview {
  @Previewable @State var fruits = [
    "Apple", "Banana", "Orange", "Mango", "Pear", "Grape", "Pineapple",
    "Strawberry",
  ]
  @Previewable @State var selectedFruit: String? = nil

  ActionMenu(title: "Actions") {
    Section("Text Operations") {
      Button("Uppercase", systemImage: "characters.uppercase") {
        if let selectedFruit = selectedFruit,
           let index = fruits.firstIndex(of: selectedFruit)
        {
          fruits[index] = selectedFruit.uppercased()
        }
      }
      .labelStyle(.menu)

      Button("Lowercase", systemImage: "characters.lowercase") {
        if let selectedFruit = selectedFruit,
           let index = fruits.firstIndex(of: selectedFruit)
        {
          fruits[index] = selectedFruit.lowercased()
        }
      }
    }

    Section {
      Button("Delete Item", systemImage: "trash", role: .destructive) {
        if let selectedFruit = selectedFruit,
           let index = fruits.firstIndex(of: selectedFruit)
        {
          fruits.remove(at: index)
        }
      }
    }
  }
}
