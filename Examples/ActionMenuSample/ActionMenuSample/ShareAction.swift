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

@MainActor @preconcurrency
public struct ShareAction {
  private func presentActivityViewController(for items: [Any]) {
    let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
      var topController = rootViewController
      while let presentedViewController = topController.presentedViewController {
        topController = presentedViewController
      }
      topController.present(activityVC, animated: true, completion: nil)
    }
  }

  public func callAsFunction(_ item: URL, subject: Text? = nil, message: Text? = nil) {
    let items = [item]
    presentActivityViewController(for: items)
  }

  public func callAsFunction(_ item: String, subject: Text? = nil, message: Text? = nil) {
    let items = [item]
    presentActivityViewController(for: items)
  }
}

extension EnvironmentValues {
  @Entry public var share: ShareAction = .init()
}
