// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let dependencies: [Package.Dependency] = [
  // inner
  .package(path: "../MetarParser"),
  .package(path: "../MapLibreJS"),
  // archive
  .package(url: "https://github.com/1024jp/GzipSwift", revision: "6.0.1"),  // https://github.com/search?q=gzip+language:Swift+&type=repositories
  .package(url: "https://github.com/weichsel/ZIPFoundation", revision: "0.9.20"),
  // database
  //  https://github.com/aaronpearce/Harmony
  .package(url: "https://github.com/groue/GRDB.swift", revision: "v7.8.0"),
  // other
  .package(url: "https://github.com/avia-briefing/KeyValue", from: "0.0.8"),
  .package(url: "https://github.com/apple/swift-protobuf", revision: "1.32.0"),
  //  .package(url: "https://github.com/apple/swift-log", revision: "1.6.2"),
  //  .package(url: "https://github.com/apple/swift-http-types", revision: "1.3.1"),
  //  .package(url: "https://github.com/apple/swift-algorithms", revision: "1.2.1"),
  //  .package(url: "https://github.com/apple/swift-async-algorithms", revision: "1.0.0"),
  //  .package(url: "https://github.com/apple/swift-collections", from: "1.1.4"),
  .package(url: "https://github.com/MobileNativeFoundation/Kronos", revision: "4.3.1"),
  .package(url: "https://github.com/mapbox/turf-swift", revision: "v4.0.0"),
  .package(url: "https://github.com/devicekit/DeviceKit", revision: "5.7.0"),
  // UI
  .package(url: "https://github.com/avia-briefing/Horizon", revision: "0.3.6"),
//  .package(url: "https://github.com/maplibre/maplibre-gl-native-distribution", revision: "6.19.2"),
  //  .package(url: "https://github.com/siteline/swiftui-introspect", revision: "26.0.0"),
  //  .package(url: "https://github.com/sparrowcode/SafeSFSymbols", revision: "2.0.1"),
]

private let commonTargets: [Target] = [
  .target(name: "Extensions", dependencies: [])  // только расширения к системным библиотекам, не добавлять внешние зависимости
]

private let srvTargets: [Target] = [
  .target(
    name: "SrvCore",
    dependencies: [
      .product(name: "DeviceKit", package: "DeviceKit"),
      .product(name: "Gzip", package: "GzipSwift"),
      .product(name: "KeyValue", package: "KeyValue"),
      .product(name: "Kronos", package: "Kronos"),
      "Extensions",
    ]),
  .target(
    name: "SrvData",
    dependencies: [
      "Extensions",
      "SrvCore",
      "SrvDatabase",
    ],
    resources: [
      .process("Resources")
    ]),
  .target(
    name: "SrvDatabase",
    dependencies: [
      .product(name: "GRDB", package: "GRDB.swift"),
      "Extensions",
    ]),
  .target(
    name: "SrvNotam",
    dependencies: [
      .product(name: "Gzip", package: "GzipSwift"),
      "SrvCore",
      "SrvDatabase",
      "Extensions",
    ]),
  .target(
    name: "SrvMBTiles",
    dependencies: [
      .product(name: "GRDB", package: "GRDB.swift"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
    ]),
  .target(
    name: "SrvMap",
    dependencies: [
      .product(name: "ZIPFoundation", package: "ZIPFoundation"),
      "Extensions",
    ],
    resources: [
      .copy("Resources")
    ]),
]

private let uiTargets: [Target] = [
  .target(
    name: "UIApp",
    dependencies: [
      .product(name: "MetarParser", package: "MetarParser"),
      .product(name: "MapLibreJS", package: "MapLibreJS"),
      .product(name: "Horizon", package: "Horizon"),
      "UIMap",
      "UINotam",
      "Extensions",
      "WxMap",
      "SrvMap",
    ],
    resources: [
      .copy("Resources")
    ]),
  .target(
    name: "UICore", dependencies: [],
    resources: [
      .process("Resources")
    ]),
  .target(
    name: "UIMap",
    dependencies: [      
      .product(name: "Horizon", package: "Horizon"),      
      "Extensions",
    ]),
  .target(
    name: "UIMeteo",
    dependencies: [
      .product(name: "Horizon", package: "Horizon"),
      "SrvNotam",
      "Extensions",
    ]),
  .target(
    name: "UINotam",
    dependencies: [
      .product(name: "Horizon", package: "Horizon"),
      "SrvNotam",
      "Extensions",
    ]
  ),
  .target(
    name: "WxMap",
    dependencies: [
      .product(name: "Turf", package: "turf-swift"),
      // .product(name: "Horizon", package: "Horizon"),
      // "SrvNotam",
      // "Extensions",
    ],
    resources: [
      .process("Resources")
    ],
    swiftSettings: [.swiftLanguageMode(.version("6.2"))]
  ),
]

private let package = Package(
  name: "SkyPackage",
  defaultLocalization: "en",
  platforms: [
    .iOS("26.0")
  ],
  products: [
    .library(name: "UIApp", targets: ["UIApp"])
  ],
  dependencies: dependencies,
  targets: [commonTargets, srvTargets, uiTargets].reduce(into: []) { $0 += $1 },
  swiftLanguageModes: [.version("6.1")],
  //  swiftLanguageModes: [.v5]
)
