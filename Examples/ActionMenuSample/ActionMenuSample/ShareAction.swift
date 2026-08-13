//
// ShareAction.swift
// ActionMenuSample
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
import UIKit

/// A SwiftUI wrapper that presents the system share sheet for the given items.
///
/// UIKit is required here: `ShareLink` is a view that only presents when tapped, so it cannot be
/// triggered from a button *action*. This is the project's documented UIKit exception (AGENTS.md) —
/// programmatic share presentation is impossible in pure SwiftUI.
struct ShareSheet: UIViewControllerRepresentable {
  let activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// The environment share action.
///
/// Calling it returns a `ShareSheet` view (not a presentation), so it must be placed in a
/// presentation — e.g. the content of a `.sheet` driven by a deferred flag — rather than called
/// from a button action, which would build and discard the view.
struct ShareAction: Sendable {
  nonisolated init() {}

  @MainActor
  func callAsFunction(_ item: String) -> some View {
    ShareSheet(activityItems: [item])
  }
}

extension EnvironmentValues {
  @Entry var share: ShareAction = ShareAction()
}
