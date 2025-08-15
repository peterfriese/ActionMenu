//
// Backport.swift
// ActionMenu
//
// Created by Peter Friese on 15.08.25.
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
//

import SwiftUI

struct ToolbarLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    if #available(iOS 26, *) {
      Label(configuration)
    } else {
      Label(configuration)
        .labelStyle(.titleOnly)
    }
  }
}

@available(iOS, introduced: 18, obsoleted: 26, message: "Remove this property in iOS 26")
extension LabelStyle where Self == ToolbarLabelStyle {
  static var toolbar: Self { .init() }
}

struct ToolbarProminentStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    if #available(iOS 26, *) {
      Button(configuration)
        .buttonStyle(.glassProminent)
    } else {
      Button(configuration)
    }
  }
}

@available(iOS, introduced: 18, obsoleted: 26, message: "Remove this property in iOS 26")
extension PrimitiveButtonStyle where Self == ToolbarProminentStyle {
  static var toolbarProminent: Self { .init() }
}