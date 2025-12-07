// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "MapLibreJS",
  platforms: [
    .macOS(.v15),
    .iOS(.v18)
  ],
  products: [
    .library(
      name: "MapLibreJS",
      targets: ["MapLibreJS"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swhitty/FlyingFox", exact: "0.26.0"),
    .package(url: "https://github.com/weichsel/ZIPFoundation", exact: "0.9.20"),
  ],
  targets: [
    .target(
      name: "MapLibreJS",
      dependencies: [
        .product(name: "FlyingFox", package: "FlyingFox"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
      ],
      resources: [
        .copy("Resources/www"),
        .copy("Resources/base-light.json"),
        .copy("Resources/base-dark.json"),
      ]
    ),
    .testTarget(
      name: "MapLibreJSTests",
      dependencies: ["MapLibreJS"]
    ),
  ]
)
