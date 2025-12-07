# Skyline

iOS-приложение для авиационного брифинга с интерактивными картами и метеоданными.

## Requirements

- Swift 6.1+ / 6.2
- iOS 26.0+
- Xcode 16+

## Build Commands

```bash
# Xcode build
xcodebuild -project Skyline.xcodeproj -scheme Skyline -destination 'platform=iOS Simulator,name=iPhone 16' build

# Swift Package build (для отдельных пакетов)
swift build --package-path Packages/SkyPackage
swift build --package-path Packages/MapLibreJS
```

## Architecture

```
Skyline/
├── Skyline/                 # главное iOS приложение
│   └── SkylineApp.swift     # @main, импортирует UIApp
├── Packages/
│   ├── SkyPackage/          # основной пакет (см. Packages/SkyPackage/CLAUDE.md)
│   └── MapLibreJS/          # карты (см. Packages/MapLibreJS/CLAUDE.md)
└── Skyline.xcodeproj        # Xcode проект
```

## Dependencies

<!-- AUTO-MANAGED: dependencies -->
**SkyPackage:**
- DeviceKit 5.7.0 — информация об устройстве
- GRDB.swift 7.8.0 — база данных SQLite
- GzipSwift 6.0.1 — сжатие данных
- Horizon 0.3.6 — UI компоненты
- KeyValue 0.0.8+ — хранение настроек
- Kronos 4.3.1 — синхронизация времени NTP
- swift-protobuf 1.32.0 — Protocol Buffers
- turf-swift 4.0.0 — геопространственные вычисления
- ZIPFoundation 0.9.20 — работа с ZIP архивами

**MapLibreJS:**
- FlyingFox 0.26.0 — HTTP сервер
- ZIPFoundation 0.9.20 — работа с ZIP
<!-- END AUTO-MANAGED: dependencies -->

## Patterns

<!-- AUTO-MANAGED: patterns -->
- **Structured Concurrency**: async/await, actors для изолированного состояния
- **@MainActor**: для UI-компонентов и контроллеров
- **SwiftUI**: декларативный UI с MVVM паттерном
- **Swift Package Manager**: модульная архитектура через локальные пакеты
- **Тёмная тема**: постоянно активна (.preferredColorScheme(.dark))
<!-- END AUTO-MANAGED: patterns -->

## Key Files

<!-- AUTO-MANAGED: key-files -->
- **Skyline/SkylineApp.swift** — точка входа приложения
- **Packages/SkyPackage/Package.swift** — манифест основного пакета
- **Packages/MapLibreJS/Package.swift** — манифест пакета карт
<!-- END AUTO-MANAGED: key-files -->
