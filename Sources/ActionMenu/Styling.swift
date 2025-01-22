//
// Styling.swift
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

extension PrimitiveButtonStyle where Self == ActionMenuButtonStyle {
  static var action: ActionMenuButtonStyle {
    ActionMenuButtonStyle()
  }
}

struct ActionMenuButtonStyle: PrimitiveButtonStyle {
  @Environment(\.dismiss) private var dismiss
  @State private var shouldExecuteAction = false

  func makeBody(configuration: Configuration) -> some View {
    Button {
      shouldExecuteAction = true
      dismiss()
    } label: {
      if configuration.role == .destructive {
        configuration.label
          .foregroundStyle(Color(.systemRed))
      } else {
        configuration.label
      }
    }
    .onDisappear {
      if shouldExecuteAction {
        configuration.trigger()
      }
    }
  }
}

extension LabelStyle where Self == MenuLabelStyle {
  static var menu: MenuLabelStyle { .init() }
}

struct MenuLabelStyle: LabelStyle {
  @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22.0

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 22) {
      configuration.title
      Spacer()
      configuration.icon
        .foregroundStyle(Color.accentColor)
        .font(.system(size: iconSize, weight: .light))
    }
  }
}

#Preview {
  List {
    Section {
      Button("Uppercase", systemImage: "characters.uppercase") {
      }
      .buttonStyle(.action)
    }
    Section {
      Button("Delete item", role: .destructive) {
      }
      .buttonStyle(.action)
    }
  }
  .labelStyle(.menu)
}
