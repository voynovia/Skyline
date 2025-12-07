# SkyPackage

Основной Swift пакет приложения Skyline — сервисы, UI-компоненты и расширения.

## Requirements

- Swift 6.1+ (WxMap модуль использует Swift 6.2)
- iOS 26.0+

## Build Commands

```bash
swift build
swift test
```

## Architecture

```
Sources/
├── Extensions/      # расширения системных типов (без внешних зависимостей)
├── SrvCore/         # базовые сервисы (дата, сеть, шифрование, приложение)
├── SrvData/         # работа с данными (метео, аэропорты)
├── SrvDatabase/     # GRDB-обёртки для SQLite
├── SrvMBTiles/      # работа с MBTiles (vector tiles, protobuf)
├── SrvNotam/        # сервис NOTAM
├── UIApp/           # главный UI модуль (ContentView, AppDelegate)
├── UICore/          # общие UI утилиты
├── UIMap/           # компоненты карты
├── UIMeteo/         # метео UI
├── UINotam/         # NOTAM UI
└── WxMap/           # погодные карты (WebP→GeoJSON, UVT декодирование, Swift 6.2)
```

## Dependencies

<!-- AUTO-MANAGED: dependencies -->
- DeviceKit 5.7.0 — информация об устройстве
- GRDB.swift 7.8.0 — база данных SQLite
- GzipSwift 6.0.1 — сжатие данных
- Horizon 0.3.6 — UI компоненты
- KeyValue 0.0.8+ — хранение настроек (UserDefaults wrapper)
- Kronos 4.3.1 — синхронизация времени NTP
- swift-protobuf 1.32.0 — Protocol Buffers
- turf-swift 4.0.0 — геопространственные вычисления
- ZIPFoundation 0.9.20 — работа с ZIP архивами
- MapLibreJS (локальный пакет) — карты
<!-- END AUTO-MANAGED: dependencies -->

## Patterns

<!-- AUTO-MANAGED: patterns -->
- **Layered Architecture**:
  - `Extensions` — чистые расширения без зависимостей
  - `Srv*` — сервисный слой (Core → Database → Data → Notam)
  - `UI*` — UI слой, зависит от сервисов
- **Concurrency**:
  - `@MainActor` для UI-связанных структур (AppController)
  - `async/await` для асинхронных операций
  - `Task {}` для отложенных операций (загрузка слоёв после инициализации карты)
- **Resource Management**:
  - Lazy download/extraction (ensureTopoMBTiles проверяет существование перед загрузкой)
  - Bundle resources для конфигураций (JSON слоёв из Bundle.module)
- **Dependency Injection**: передача зависимостей через инициализаторы
- **MVVM**: ViewModels для UI компонентов (NotamViewModel)
<!-- END AUTO-MANAGED: patterns -->

## Key Files

<!-- AUTO-MANAGED: key-files -->
- **Package.swift** — манифест пакета, все targets и зависимости
- **Sources/UIApp/ContentView.swift** — главный View (MapServer инициализация, MBTiles загрузка/распаковка из cdn.aeromap.app, MapView интеграция, загрузка слоёв из Bundle, progress tracking, theme-aware topoLayers выбор через colorScheme)
- **Sources/UIApp/AppDelegate.swift** — UIApplicationDelegate
- **Sources/SrvMap/MapLayer.swift** — enum слоёв карты (topographyLight, topographyDark, hypsometry), sourceId и layerConfigURL для каждого слоя
- **Sources/SrvMap/Resources/layers/** — JSON конфигурации слоёв карты:
  - **topo-light.json** — светлая тема топографии (land #F5F2EE, water #D0D8DC)
  - **topo-dark.json** — тёмная тема топографии (land #2A2A2A, water #1E2528)
  - **hypsometry.json** — слои рельефа (гипсометрия)
- **Sources/SrvCore/App/AppController.swift** — информация о приложении
- **Sources/SrvCore/Date/** — утилиты работы с датой/временем
- **Sources/SrvDatabase/DatabaseApp.swift** — GRDB database manager
- **Sources/SrvNotam/NotamService.swift** — сервис NOTAM
- **Sources/Extensions/** — расширения системных типов
<!-- END AUTO-MANAGED: key-files -->
