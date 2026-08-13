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
  /// A button style that dismisses the current view when the button is tapped.
  ///
  /// When used inside an action menu sheet, tapping a button with this style records the button's
  /// action and dismisses the sheet. The sheet executes the recorded action once it has disappeared,
  /// ensuring the menu is gone before the action is performed.
  ///
  /// This standalone accessor is intended for previews and standalone use. It wires the style to a
  /// constant, inert pending-action binding, so a tapped action is not executed outside of a sheet.
  static var action: ActionMenuButtonStyle {
    .init(pendingAction: .constant(nil))
  }
}

/// The key used to propagate whether the enclosing menu row is a destructive action.
private struct IsDestructiveActionKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  /// Whether the enclosing menu row represents a destructive action.
  var isDestructiveAction: Bool {
    get { self[IsDestructiveActionKey.self] }
    set { self[IsDestructiveActionKey.self] = newValue }
  }
}

struct ActionMenuButtonStyle: PrimitiveButtonStyle {
  @Environment(\.dismiss) private var dismiss
  @Binding var pendingAction: (() -> Void)?

  func makeBody(configuration: Configuration) -> some View {
    Button {
      pendingAction = { configuration.trigger() }
      dismiss()
    } label: {
      if configuration.role == .destructive {
        configuration.label
          .foregroundStyle(Color(uiColor: .systemRed))
          .environment(\.isDestructiveAction, true)
      } else {
        configuration.label
      }
    }
  }
}

extension LabelStyle where Self == MenuLabelStyle {
  /// A label style that displays the title on the left and the icon on the right.
  ///
  /// This style is used for the labels within the action menu. It places the label's title on the leading edge
  /// and its icon on the trailing edge, with a spacer in between to push them to the opposite sides.
  static var menu: MenuLabelStyle { .init() }
}

struct MenuLabelStyle: LabelStyle {
  @Environment(\.isDestructiveAction) private var isDestructiveAction
  @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22.0

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 22) {
      configuration.title
      Spacer()
      configuration.icon
        .foregroundStyle(isDestructiveAction ? Color(uiColor: .systemRed) : Color.primary)
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
