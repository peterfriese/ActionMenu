// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ActionMenu",
  platforms: [
    .iOS(.v18),
  ],
  products: [
    .library(
      name: "ActionMenu",
      targets: ["ActionMenu"])
  ],
  targets: [
    .target(
      name: "ActionMenu"),
  ]
)
