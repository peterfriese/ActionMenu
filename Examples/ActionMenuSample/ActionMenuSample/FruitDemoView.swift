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

struct FruitDemoView: View {
  @State private var store = FruitStore()
  @State private var isMoreActionTapped = false
  @State private var isSecondarySheetPresented = false

  @Environment(\.share) private var share

  var body: some View {
    NavigationStack {
      List(store.fruits, id: \.self) { fruit in
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
      .navigationTitle("Fruits")
      .actionMenu(title: "Actions", isPresented: $isMoreActionTapped) {
        Section("Text Options") {
          Button("Uppercase", systemImage: "characters.uppercase") { store.uppercaseSelected() }
          Button("Lowercase", systemImage: "characters.lowercase") { store.lowercaseSelected() }
          Button("Say hello", systemImage: "quote.bubble.fill") { isSecondarySheetPresented.toggle() }
          Button("Share", systemImage: "square.and.arrow.up") { share("Some test") }
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
  }
}

#Preview {
  FruitDemoView()
}
