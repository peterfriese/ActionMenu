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

struct ActionMenu<Content: View>: View {
  @Environment(\.dismiss) private var dismiss

  let title: String
  let content: () -> Content

  init(
    title: String = "Options", @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.content = content
  }

  var body: some View {
    NavigationStack {
      List {
        content()
      }
      .labelStyle(.menu)
      .buttonStyle(.action)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

struct ActionMenuModifier<MenuContent: View>: ViewModifier {
  let title: String
  @Binding var isPresented: Bool
  let menuContent: () -> MenuContent

  @Environment(\.dismiss) private var dismiss

  init(title: String, isPresented: Binding<Bool>, @ViewBuilder  menuContent: @escaping () -> MenuContent) {
    self.title = title
    self._isPresented = isPresented
    self.menuContent = menuContent
  }

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $isPresented) {
        ActionMenu(title: title) {
          menuContent()
        }
        .presentationDetents([.medium, .large])
      }
  }
}

extension View {
  public func actionMenu(
    title: String, isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> some View
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
