//
// FruitStore.swift
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

import Observation

@MainActor
@Observable
final class FruitStore {
  var fruits = ["Apple", "Banana", "Orange", "Mango", "Pear", "Grape", "Pineapple", "Strawberry"]
  var selectedFruit: String?

  func select(_ fruit: String) { selectedFruit = fruit }

  func delete(_ fruit: String) {
    guard let index = fruits.firstIndex(of: fruit) else { return }
    fruits.remove(at: index)
  }

  func uppercaseSelected() {
    guard let selectedFruit, let index = fruits.firstIndex(of: selectedFruit) else { return }
    fruits[index] = selectedFruit.uppercased()
  }

  func lowercaseSelected() {
    guard let selectedFruit, let index = fruits.firstIndex(of: selectedFruit) else { return }
    fruits[index] = selectedFruit.lowercased()
  }

  func duplicateSelected() {
    guard let selectedFruit, let index = fruits.firstIndex(of: selectedFruit) else { return }
    fruits.insert(selectedFruit, at: index + 1)
  }

  func deleteSelected() {
    guard let selectedFruit, let index = fruits.firstIndex(of: selectedFruit) else { return }
    fruits.remove(at: index)
  }
}
