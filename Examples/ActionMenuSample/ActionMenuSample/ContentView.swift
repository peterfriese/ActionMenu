//
// ContentView.swift
// ActionMenuSample
//
// Created by Peter Friese on 17.01.25.
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

struct ContentView: View {
  @State private var fruits = ["Apple", "Banana", "Orange", "Mango", "Pear", "Grape", "Pineapple", "Strawberry"]
  @State private var isMoreActionTapped = false
  @State private var selectedFruit: String? = nil

  var body: some View {
    NavigationStack {
      List(fruits, id: \.self) { fruit in
        Text(fruit)
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", systemImage: "trash", role: .destructive) {
              if let index = fruits.firstIndex(of: fruit) {
                fruits.remove(at: index)
              }
            }

            Button("More", systemImage: "ellipsis.circle") {
              selectedFruit = fruit
              isMoreActionTapped.toggle()
            }
            .tint(.gray)
          }
      }
      .navigationTitle("Fruits")
      .actionMenu(title: "Actions", isPresented: $isMoreActionTapped) {
        Section("Text Options") {
          Button("Uppercase", systemImage: "characters.uppercase") {
            if let selectedFruit = selectedFruit,
               let index = fruits.firstIndex(of: selectedFruit) {
              fruits[index] = selectedFruit.uppercased()
            }
          }

          Button("Lowercase", systemImage: "characters.lowercase") {
            if let selectedFruit = selectedFruit,
               let index = fruits.firstIndex(of: selectedFruit) {
              fruits[index] = selectedFruit.lowercased()
            }
          }
        }

        Section {
          Button("Delete Item", systemImage: "trash", role: .destructive) {
            if let selectedFruit = selectedFruit,
               let index = fruits.firstIndex(of: selectedFruit) {
              _ = withAnimation {
                fruits.remove(at: index)
              }
            }
          }
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
