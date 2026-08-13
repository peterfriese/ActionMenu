//
// FruitDemoView.swift
// ActionMenuSample
//
// Created by Peter Friese on 13.08.26.
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
import ActionMenu

/// The demo menu sizes: how many items the pinned sheet shows.
enum MenuSize: String, CaseIterable, Identifiable {
  case small, medium, large

  var id: String { rawValue }

  /// The picker label for this size.
  var label: String {
    switch self {
    case .small: "Small"
    case .medium: "Medium"
    case .large: "Large"
    }
  }

  /// The nav bar title of the demo menu for this size.
  var title: String { "\(label) Menu" }

  /// A short description of how many items this size shows.
  var itemCountDescription: String {
    switch self {
    case .small: "2 items"
    case .medium: "6 items"
    case .large: "18 items"
    }
  }
}

struct FruitDemoView: View {
  @State private var store = FruitStore()
  @State private var isMoreActionTapped = false
  @State private var isSecondarySheetPresented = false
  @State private var isSharePresented = false
  @State private var menuSize: MenuSize = .medium
  @State private var isDemoMenuPresented = false

  @Environment(\.share) private var share

  var body: some View {
    NavigationStack {
      List {
        Section {
          Picker("Menu size", selection: $menuSize) {
            ForEach(MenuSize.allCases) { size in
              Text(size.label).tag(size)
            }
          }
          .pickerStyle(.segmented)

          Button("Show \(menuSize.label) menu") {
            if store.selectedFruit == nil {
              store.select(store.fruits.first ?? "")
            }
            isDemoMenuPresented = true
          }
        } header: {
          Text("Menu Size Demo")
        } footer: {
          Text("\(menuSize.label) menu: \(menuSize.itemCountDescription) — the pinned sheet sizes to its content.")
        }

        Section {
          ForEach(store.fruits, id: \.self) { fruit in
            Text(fruit)
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                  store.delete(fruit)
                }
                Button("More", systemImage: "ellipsis.circle") {
                  store.select(fruit)
                  isMoreActionTapped.toggle()
                }
                .tint(.gray)
              }
          }
        }
      }
      .navigationTitle("Fruits")
      .actionMenu(title: "Actions", isPresented: $isMoreActionTapped) {
        Section("Text Options") {
          Button("Uppercase", systemImage: "characters.uppercase") { store.uppercaseSelected() }
          Button("Lowercase", systemImage: "characters.lowercase") { store.lowercaseSelected() }
          Button("Say hello", systemImage: "quote.bubble.fill") { isSecondarySheetPresented.toggle() }
          Button("Share", systemImage: "square.and.arrow.up") { isSharePresented = true }
          Button("Duplicate", systemImage: "doc.on.doc") { store.duplicateSelected() }
        }
        Section {
          Button("Delete Item", systemImage: "trash", role: .destructive) {
            withAnimation { store.deleteSelected() }
          }
        }
      }
      .sheet(isPresented: $isSecondarySheetPresented) {
        Text("Hello, World! Here is a \(store.selectedFruit ?? "no fruit")")
      }
    }
    .actionMenu(title: menuSize.title, isPresented: $isDemoMenuPresented) {
      demoMenuContent(for: menuSize)
    }
    .sheet(isPresented: $isSharePresented) {
      share("Some test")
    }
  }

  /// The demo menu's content for the given size.
  @ViewBuilder
  private func demoMenuContent(for size: MenuSize) -> some View {
    switch size {
    case .small:
      Section {
        Button("Uppercase", systemImage: "characters.uppercase") { store.uppercaseSelected() }
        Button("Say hello", systemImage: "quote.bubble.fill") { isSecondarySheetPresented.toggle() }
      }
    case .medium:
      Section("Text Options") {
        Button("Uppercase", systemImage: "characters.uppercase") { store.uppercaseSelected() }
        Button("Lowercase", systemImage: "characters.lowercase") { store.lowercaseSelected() }
        Button("Say hello", systemImage: "quote.bubble.fill") { isSecondarySheetPresented.toggle() }
        Button("Share", systemImage: "square.and.arrow.up") { isSharePresented = true }
        Button("Duplicate", systemImage: "doc.on.doc") { store.duplicateSelected() }
      }
      Section {
        Button("Delete Item", systemImage: "trash", role: .destructive) {
          withAnimation { store.deleteSelected() }
        }
      }
    case .large:
      Section("Text Options") {
        Button("Uppercase", systemImage: "characters.uppercase") { store.uppercaseSelected() }
        Button("Lowercase", systemImage: "characters.lowercase") { store.lowercaseSelected() }
        Button("Say hello", systemImage: "quote.bubble.fill") { isSecondarySheetPresented.toggle() }
        Button("Share", systemImage: "square.and.arrow.up") { isSharePresented = true }
        Button("Duplicate", systemImage: "doc.on.doc") { store.duplicateSelected() }
      }
      Section("Organize") {
        Button("Flag", systemImage: "flag") {}
        Button("Archive", systemImage: "archivebox") {}
        Button("Mark as Read", systemImage: "envelope.open") {}
        Button("Move to Folder", systemImage: "folder") {}
        Button("Copy Link", systemImage: "link") {}
      }
      Section("More Actions") {
        Button("Print", systemImage: "printer") {}
        Button("Translate", systemImage: "character.bubble") {}
        Button("Rotate", systemImage: "rotate.right") {}
        Button("Star", systemImage: "star") {}
        Button("Pin", systemImage: "pin") {}
        Button("Hide", systemImage: "eye.slash") {}
        Button("Mute", systemImage: "speaker.slash") {}
      }
      Section {
        Button("Delete Item", systemImage: "trash", role: .destructive) {
          withAnimation { store.deleteSelected() }
        }
      }
    }
  }
}

#Preview {
  FruitDemoView()
}
