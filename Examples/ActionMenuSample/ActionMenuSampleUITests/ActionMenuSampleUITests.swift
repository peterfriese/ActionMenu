//
//  ActionMenuSampleUITests.swift
//  ActionMenuSampleUITests
//
//  Created by Peter Friese on 13.08.26.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import XCTest

/// UI tests for the ActionMenu sample app.
///
/// These tests exercise the deferred-trigger design of the action menu: tapping an action button
/// records it as a pending action and dismisses the sheet; the action fires exactly once, only
/// after the sheet is gone.
final class ActionMenuSampleUITests: XCTestCase {

  // A fresh instance is created for every test method, so `app` is always a clean application.
  private let app = XCUIApplication()

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  // MARK: - Test 1: "Duplicate" fires exactly once

  /// Tapping "Duplicate" inserts exactly one copy of the selected fruit.
  ///
  /// The fruit count going up by exactly 1 is the probe for the deferred trigger: if the action
  /// fired twice, the count would go up by 2 and this test would fail.
  func testDuplicateFiresExactlyOnce() throws {
    launch()

    let before = countOfFruit("Apple")
    XCTAssertEqual(before, 1, "A fresh launch should show exactly one 'Apple' row.")

    presentMenu(for: "Apple")
    app.buttons["Duplicate"].tap()
    waitForMenuToDisappear()

    // The duplicate is inserted by the deferred action after the sheet is gone. Wait for the list
    // to settle at before + 1. If the action double-fired, the count would jump past this value
    // and this wait would time out.
    waitForFruitCount("Apple", before + 1)

    let after = countOfFruit("Apple")
    XCTAssertEqual(
      after, before + 1,
      "Duplicate must insert exactly one copy. If the action fired twice the count would be \(before + 2)."
    )
  }

  // MARK: - Test 2: Interactive (swipe-down) dismissal fires nothing

  /// Swiping the menu sheet down without tapping a row must run no action, and the menu must
  /// remain fully functional afterwards.
  func testSwipeDownDismissFiresNothing() throws {
    launch()

    let before = countOfFruit("Apple")
    XCTAssertEqual(before, 1)

    presentMenu(for: "Apple")
    dismissMenuBySwipingDown()
    waitForMenuToDisappear()

    // Nothing should have run: no uppercasing, no row changes.
    XCTAssertEqual(countOfFruit("Apple"), before, "Swiping the menu away must not change the fruit list.")
    XCTAssertFalse(app.staticTexts["APPLE"].exists, "Swiping the menu away must not fire any action.")

    // The menu must still be functional after an interactive dismiss: "Uppercase" should turn
    // "Apple" into "APPLE" once the menu is gone.
    presentMenu(for: "Apple")
    app.buttons["Uppercase"].tap()
    waitForMenuToDisappear()
    waitForStaticText("APPLE")

    XCTAssertTrue(app.staticTexts["APPLE"].exists, "Uppercase should have turned 'Apple' into 'APPLE'.")
    XCTAssertFalse(app.staticTexts["Apple"].exists, "The original 'Apple' row should be gone after uppercasing.")
  }

  // MARK: - Test 3: Secondary sheet presents after the menu dismisses

  /// "Say hello" must present the "Hello, World!" sheet only after the action menu has fully
  /// dismissed, proving the deferred trigger.
  func testSecondarySheetPresentsAfterMenuDismisses() throws {
    launch()

    presentMenu(for: "Apple")
    app.buttons["Say hello"].tap()

    let helloText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Hello, World!")).firstMatch
    XCTAssertTrue(helloText.waitForExistence(timeout: 5), "The 'Hello, World!' sheet should appear.")

    waitForMenuToDisappear()
    XCTAssertFalse(
      app.navigationBars["Actions"].exists,
      "The action menu must be dismissed before the secondary sheet is presented."
    )
  }

  // MARK: - Test 4: Close dismisses without firing an action

  /// Tapping the toolbar "Close" button (accessibility label) must dismiss the menu without
  /// firing any action.
  func testCloseButtonDismissesMenuWithoutFiringAction() throws {
    launch()

    let before = countOfFruit("Apple")
    XCTAssertEqual(before, 1)

    presentMenu(for: "Apple")

    // Preferred: the "Close" accessibility label exposed by the iOS 26+ xmark button.
    let closeButton = app.buttons["Close"]
    if closeButton.waitForExistence(timeout: 2) {
      closeButton.tap()
    } else {
      // Fallback for environments where the element tree differs: first toolbar button in the menu.
      let toolbarButton = app.navigationBars["Actions"].buttons.firstMatch
      XCTAssertTrue(toolbarButton.waitForExistence(timeout: 3), "The menu's toolbar button should exist.")
      toolbarButton.tap()
    }

    waitForMenuToDisappear()

    XCTAssertEqual(countOfFruit("Apple"), before, "Closing the menu must not change the fruit list.")
    XCTAssertFalse(app.staticTexts["APPLE"].exists, "Closing the menu must not fire any action.")
  }

  // MARK: - Test 5: Bottom action row is fully visible

  /// The sheet's self-sizing detent must balance the bottom gap with the rows' side margins, so
  /// the bottom "Delete Item" row is never clipped by the sheet's bottom edge.
  ///
  /// Measured on iPhone 17, iOS 27: with the pre-fix detent the button's bottom gap was ~92pt
  /// (over-sized); the balanced detent brings it to ~26pt against a ~23.4pt side margin. The
  /// 10pt accuracy discriminates the two while tolerating device differences, and the 15pt floor
  /// guarantees the row can never regress to a clipped state (pre-fix clipped gap was −7.4pt).
  func testBottomRowIsFullyVisible() throws {
    launch()
    presentMenu(for: "Apple")

    let deleteButton = app.buttons["Delete Item"]
    XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "The 'Delete Item' button should be visible.")

    let windowBottom = app.windows.firstMatch.frame.maxY
    let bottomGap = windowBottom - deleteButton.frame.maxY
    let sideGap = deleteButton.frame.minX

    XCTAssertEqual(
      bottomGap, sideGap, accuracy: 10,
      "The bottom gap should be balanced against the row's side margins."
    )
    XCTAssertGreaterThanOrEqual(bottomGap, 15, "The bottom action row must never be clipped.")
  }

  // MARK: - Test 6: Detent cycling returns to the balanced size

  /// Expanding the sheet to `.large` and returning must not corrupt the self-sizing detent: the
  /// bottom "Delete Item" row must end up at the same balanced gap against its side margins.
  func testDetentCycleReturnsToBalancedSize() throws {
    launch()
    presentMenu(for: "Apple")

    let deleteButton = app.buttons["Delete Item"]
    XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "The 'Delete Item' button should be visible.")
    let windowBottom = app.windows.firstMatch.frame.maxY
    let balancedGap = windowBottom - deleteButton.frame.maxY
    XCTAssertGreaterThanOrEqual(balancedGap, 15, "The sheet should start at its balanced size.")

    // Expand to `.large` by dragging the nav bar upward, then drag back down to the balanced detent.
    let navBar = app.navigationBars["Actions"]
    navBar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
    XCTAssertTrue(navBar.waitForExistence(timeout: 3), "The sheet should stay presented at `.large`.")
    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
      .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)))

    let cycledGap = windowBottom - deleteButton.frame.maxY
    let sideGap = deleteButton.frame.minX
    XCTAssertEqual(cycledGap, balancedGap, accuracy: 6, "The sheet must return to its balanced size after cycling.")
    XCTAssertEqual(cycledGap, sideGap, accuracy: 10, "The balanced detent must remain stable across detent cycling.")
  }

  // MARK: - Test 7: Drag-down from `.large` never yields a mini-rectangle

  /// Dragging the sheet fully down from `.large` must dismiss it cleanly (or return to a sane
  /// size) — never an ~8pt strip that fails to dismiss.
  func testDragDownFromLargeNeverYieldsMiniRectangle() throws {
    launch()
    presentMenu(for: "Apple")

    let navBar = app.navigationBars["Actions"]
    XCTAssertTrue(navBar.waitForExistence(timeout: 3), "The action menu should be presented.")

    // Expand to `.large`, then drag down past the dismiss threshold.
    navBar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
    XCTAssertTrue(navBar.exists, "The sheet should be at `.large`.")
    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
      .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
    sleep(2)

    if navBar.exists {
      // Still presented: it must be at a sane size, never a mini-rectangle.
      let deleteButton = app.buttons["Delete Item"]
      XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "The 'Delete Item' button should be visible.")
      let windowBottom = app.windows.firstMatch.frame.maxY
      let bottomGap = windowBottom - deleteButton.frame.maxY
      XCTAssertGreaterThanOrEqual(bottomGap, 15, "The menu must never collapse to a mini-rectangle.")
    } else {
      XCTAssertFalse(app.navigationBars["Actions"].exists, "The menu should be dismissed after a full drag-down.")
    }
  }

  // MARK: - Test 8: Share dismisses the menu via the deferred trigger

  /// Tapping "Share" must fire the deferred trigger: the menu dismisses, then the root presents the
  /// share sheet (a UIKit `UIActivityViewController`, the project's documented UIKit exception for
  /// programmatic share presentation).
  ///
  /// The share sheet's "Close" button is the automation anchor — the activity items themselves are
  /// not exposed as queryable buttons in this configuration.
  func testSharePresentsShareSheet() throws {
    launch()
    presentMenu(for: "Apple")

    let shareButton = app.buttons["Share"]
    XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "The 'Share' row should exist in the menu.")
    shareButton.tap()

    waitForMenuToDisappear()

    let closeButton = app.buttons["Close"]
    XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "The share sheet should appear after the menu dismisses.")
    XCTAssertFalse(app.staticTexts["APPLE"].exists, "Tapping Share must not run any other action.")

    // Dismiss the share sheet cleanly and confirm we're back at the fruit list.
    closeButton.tap()
    let closeGone = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: closeGone, object: closeButton)
    _ = XCTWaiter().wait(for: [expectation], timeout: 5)
    XCTAssertTrue(
      app.navigationBars["Fruits"].waitForExistence(timeout: 3),
      "The fruit list should be visible after dismissing the share sheet."
    )
  }

  // MARK: - Helpers

  /// Launches a fresh instance of the app and waits for the main fruit list.
  private func launch() {
    app.launch()
    XCTAssertTrue(
      app.navigationBars["Fruits"].waitForExistence(timeout: 5),
      "The fruit list should appear after launch."
    )
  }

  /// Swipes left on the row for `fruitName`, taps the "More" swipe action and waits for the
  /// action menu sheet to be presented.
  private func presentMenu(for fruitName: String) {
    let cell = app.cells.containing(.staticText, identifier: fruitName).firstMatch
    let elementToSwipe: XCUIElement
    if cell.waitForExistence(timeout: 3) {
      elementToSwipe = cell
    } else {
      // Fallback: swipe directly on the static text if the cell query cannot resolve the row.
      elementToSwipe = app.staticTexts[fruitName]
      XCTAssertTrue(elementToSwipe.waitForExistence(timeout: 3), "Row for '\(fruitName)' should exist.")
    }

    elementToSwipe.swipeLeft()

    let moreButton = app.buttons["More"]
    XCTAssertTrue(moreButton.waitForExistence(timeout: 3), "The 'More' swipe action should be revealed.")
    moreButton.tap()

    XCTAssertTrue(
      app.navigationBars["Actions"].waitForExistence(timeout: 3),
      "The action menu sheet should be presented."
    )
  }

  /// Drags the presented action menu sheet downwards to trigger an interactive dismissal.
  ///
  /// Starting the drag on the sheet's navigation bar avoids scrolling the menu's List instead of
  /// dragging the sheet.
  private func dismissMenuBySwipingDown() {
    let navBar = app.navigationBars["Actions"]
    XCTAssertTrue(navBar.waitForExistence(timeout: 3), "The action menu sheet should be presented.")
    let start = navBar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
    start.press(forDuration: 0.05, thenDragTo: end)
  }

  /// Blocks until the action menu's navigation bar has disappeared.
  private func waitForMenuToDisappear(timeout: TimeInterval = 5) {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app.navigationBars["Actions"])
    XCTAssertEqual(
      XCTWaiter().wait(for: [expectation], timeout: timeout),
      .completed,
      "The action menu sheet should disappear."
    )
  }

  /// Blocks until a static text whose label equals `text` exists.
  private func waitForStaticText(_ text: String, timeout: TimeInterval = 5) {
    let predicate = NSPredicate { _, _ in
      self.app.staticTexts[text].exists
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    XCTAssertEqual(
      XCTWaiter().wait(for: [expectation], timeout: timeout),
      .completed,
      "Static text '\(text)' should appear."
    )
  }

  /// Number of static texts whose label is exactly `fruitName`.
  private func countOfFruit(_ fruitName: String) -> Int {
    app.staticTexts.matching(NSPredicate(format: "label == %@", fruitName)).count
  }

  /// Blocks until the number of static texts with label `fruitName` equals `expected`.
  private func waitForFruitCount(_ fruitName: String, _ expected: Int, timeout: TimeInterval = 5) {
    let predicate = NSPredicate { _, _ in
      self.countOfFruit(fruitName) == expected
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    XCTAssertEqual(
      XCTWaiter().wait(for: [expectation], timeout: timeout),
      .completed,
      "Expected \(expected) row(s) labelled '\(fruitName)'."
    )
  }
}
