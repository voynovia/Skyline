// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "MetarParser",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
  ],
  products: [
    .library(
      name: "MetarParser",
      targets: ["MetarParser"]
    ),
  ],
  targets: [
    .target(
      name: "MetarParser",
      resources: [
        .copy("Resources/metar-parser.js"),
      ]
    ),
    .testTarget(
      name: "MetarParserTests",
      dependencies: ["MetarParser"]
    ),
  ]
)
