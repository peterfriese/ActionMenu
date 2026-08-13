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

/// The sheet's top chrome: the grabber/rounded-top area that the presentation renders above the
/// `.height` detent value. Measured empirically (~21pt on iOS 26+ sheets); a fixed presentation
/// constant rather than a device or list style, so it is shared across all menus.
private let sheetTopChrome: CGFloat = 21

/// Aggregated bounds of the menu's rows in global coordinates.
///
/// The rows are measured via a `GeometryReader` in each row's background so the detent can balance
/// the sheet's bottom gap against the rows' own side margins, regardless of device or list style.
private struct RowBounds: Equatable {
  var minX: CGFloat = .infinity
  var maxY: CGFloat = 0
}

/// Collects the global bounds of every menu row into a single `RowBounds` value.
private struct RowBoundsKey: PreferenceKey {
  static let defaultValue = RowBounds()
  static func reduce(value: inout RowBounds, nextValue: () -> RowBounds) {
    value.minX = min(value.minX, nextValue().minX)
    value.maxY = max(value.maxY, nextValue().maxY)
  }
}

/// A view modifier that sizes a presentation sheet to the height of its scrollable content.
///
/// It measures the menu rows' geometry relative to the sheet's root and applies the measured height
/// as a `.height` presentation detent. Because the rows' position relative to the sheet root is
/// invariant under detent changes, the detent stays stable when the user drags the sheet or cycles
/// between detents. The detent places the bottom menu row at the same distance from the sheet's
/// bottom edge as its own side margins:
/// `target = rowsBottomInSheet + sideMargin - sheetTopChrome`. A `.medium` detent is used as a
/// fallback until the first measurement completes, preventing an invisible, zero-height sheet from
/// flashing.
struct SelfSizingSheetModifier: ViewModifier {
  /// The currently applied detent height.
  @State private var contentHeight: CGFloat = 0

  /// The bottom edge of the last menu row, in global coordinates.
  @Binding var rowsBottom: CGFloat

  /// The leading edge of the menu rows, in global coordinates (their side margin).
  @Binding var sideMargin: CGFloat

  /// The top edge of the sheet's root view, in global coordinates.
  @Binding var sheetTop: CGFloat

  func body(content: Content) -> some View {
    content
      .onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }, action: { _, newGeo in
        // Skip until the List has laid out its content: the zero-sized first callback must not
        // collapse the sheet below the `.medium` fallback.
        guard newGeo.contentSize.height > 0 else { return }
        guard rowsBottom > 0, sideMargin > 0, sheetTop > 0 else { return }
        // Detent-independent: the rows' position relative to the sheet root does not change when
        // the on-screen detent changes, so the target is stable across handle drags and detent
        // cycling (the global measurements shift together and cancel out).
        let rowsBottomInSheet = rowsBottom - sheetTop
        let target = rowsBottomInSheet + sideMargin - sheetTopChrome
        if contentHeight == 0 || abs(target - contentHeight) > 1 {
          contentHeight = target
        }
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
  @State private var rowsBottom: CGFloat = 0
  @State private var sideMargin: CGFloat = 0
  @State private var sheetTop: CGFloat = 0

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
          .listRowBackground(
            GeometryReader { proxy in
              let frame = proxy.frame(in: .global)
              Color(uiColor: .secondarySystemGroupedBackground)  // restore the grouped card look
                .preference(key: RowBoundsKey.self, value: RowBounds(minX: frame.minX, maxY: frame.maxY))
            }
          )
      }
      .onPreferenceChange(RowBoundsKey.self) { bounds in
        rowsBottom = bounds.maxY
        sideMargin = bounds.minX
      }
      .modifier(
        SelfSizingSheetModifier(rowsBottom: $rowsBottom, sideMargin: $sideMargin, sheetTop: $sheetTop)
      )
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
    .onGeometryChange(for: CGFloat.self, of: { $0.frame(in: .global).minY }) { top in
      sheetTop = top
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
  ///   - title: The title to display in the navigation bar of the action menu. Defaults to `"Options"`.
  ///   - isPresented: A binding to a Boolean value that determines whether to present the action menu.
  ///   - content: A `@ContentBuilder` closure that creates the content of the action menu. This is typically a list of `Button`s.
  public func actionMenu(
    title: String = "Options", isPresented: Binding<Bool>,
    @ContentBuilder content: () -> some View
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
