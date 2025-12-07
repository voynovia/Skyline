# MapLibreJS

Swift обёртка над MapLibre GL JS для отображения интерактивных карт в SwiftUI приложениях через WKWebView.

## Requirements

- Swift 6.2+
- iOS 16.0+
- macOS 13.0+

## Build Commands

```bash
swift build        # сборка
swift test         # тесты
```

## Architecture

- `Sources/MapLibreJS/` — основной код библиотеки
  - `Sources/` — источники данных карты (MBTiles, PMTiles, GeoJSON)
  - `Server/` — HTTP сервер (MapServer) и менеджер ресурсов
  - `Databases/` — SQLite менеджер для работы с MBTiles
  - `Views/` — SwiftUI компонент MapView
  - `Resources/` — статические ресурсы (HTML, JS, CSS, glyphs, sprites)
- `Tests/MapLibreJSTests/` — unit-тесты

## Dependencies

- **FlyingFox** 0.26.0 — HTTP сервер
- **ZIPFoundation** 0.9.20 — работа с ZIP архивами

## Platforms

- macOS 13+
- iOS 16+

## Patterns

<!-- AUTO-MANAGED: patterns -->
- **Concurrency**:
  - `actor` для изолированного состояния (MapServer, ResourceManager)
  - `@MainActor` для UI-координаторов (MapViewCoordinator, createWebView)
  - `nonisolated func` для protocol conformance (WKScriptMessageHandler)
  - `@unchecked Sendable` с `NSLock` для thread-safe мутабельных типов (MBTilesSource, PMTilesSource, GeoJSONSource, SQLiteManager)
  - `@unchecked Sendable` для immutable-after-init структур (MapClickEvent.ClickedLayer с [String: Any] properties)
  - `DispatchQueue` с барьерами для connection pool (SQLiteManager)
- **SwiftUI Integration**:
  - Platform-specific representables (`UIViewRepresentable`/`NSViewRepresentable`) с `#if os()`
  - `@State` для coordinator lifecycle management
  - `@Binding` для передачи coordinator между View и Representable
  - Coordinator pattern для WKWebView (makeCoordinator, WKScriptMessageHandler conformance)
  - Pending operations queue для буферизации JavaScript команд до загрузки карты (isMapLoaded flag, executePendingOperations)
- **JavaScript Bridge**:
  - MessageName enum с CaseIterable для type-safe message handling (console, zoom, click)
  - Message parsing через WKScriptMessage.body (dictionary/string casting)
  - Conditional JS execution через executeJS (immediate если loaded, queue если pending)
  - Task wrapping в nonisolated callbacks для MainActor isolation
- **Resource Management**:
  - Lazy initialization ресурсов (ResourceManager.prepareResources)
  - Connection pooling для SQLite (DBPool с max connections = CPU cores / 2)
  - NSCache для тайлов (100 MB limit)
- **Error Handling**:
  - Custom error types (MapSourceError, ResourceManagerError)
  - Optional returns для missing resources (getTile → Data?)
  - throws для validation (MapSource.init проверяет fileExists)
<!-- END AUTO-MANAGED: patterns -->

## Key Files

<!-- AUTO-MANAGED: key-files -->
- **Package.swift** — манифест пакета, зависимости (FlyingFox, ZIPFoundation)
- **MapLibreJS.swift** — публичный API, convenience initializers
- **Sources/**:
  - **MapSource.swift** — протокол источников данных, типы (vector/raster/geojson)
  - **MBTilesSource.swift** — источник из SQLite MBTiles файлов
  - **PMTilesSource.swift** — источник из PMTiles (pmtiles:// protocol)
  - **GeoJSONSource.swift** — источник из GeoJSON (URL/Data/dictionary)
- **Server/**:
  - **MapServer.swift** — HTTP сервер на FlyingFox, маршрутизация, управление источниками, обработчики запросов (tiles, glyphs, sprites, static files)
  - **ResourceManager.swift** — распаковка ZIP, пути к ресурсам
- **Databases/**:
  - **SQLiteManager.swift** — connection pool, кэш тайлов, TMS координаты
- **Views/**:
  - **MapView.swift** — SwiftUI view с WKWebView, MessageName enum (console/zoom/click), MapClickEvent с ClickedLayer (@unchecked Sendable для properties), platform-specific MapWebViewRepresentable (UIViewRepresentable/NSViewRepresentable с #if os()), createWebView helper (@MainActor, WKWebViewConfiguration setup, message handlers, isInspectable), MapViewCoordinator (@MainActor класс, WKScriptMessageHandler conformance через nonisolated func, pending operations queue с isMapLoaded flag), public API методы (addSource с автоматической регистрацией на сервере через type casting, removeSource с server.unregister, reloadSource, addLayer from URL, addLayers inline, removeLayer), event handling (console для map loaded detection, zoom callback, click с parseClickEvent), executeJS с conditional logic (evaluateJavaScript если loaded, queue если pending)
- **Resources/**:
  - **base.json** — базовый MapLibre GL стиль (background, land/island/water polygons/lines, sky atmosphere blend)
- **Resources/www/**:
  - **index.html** — HTML bootstrap (<!DOCTYPE html>), viewport meta (width=device-width, initial-scale=1.0), base href для относительных путей, подключение CSS (maplibre-gl.css), JS библиотек (maplibre-gl.js, pmtiles.js) и скриптов (functions.js, map.js), map container div с фоном #002266
  - **functions.js** — IIFE для перехвата console методов (log/error/warn/info/debug), перенаправление в Swift через window.webkit.messageHandlers.console с type и message полями
  - **map.js** — DOMContentLoaded handler, регистрация pmtiles:// protocol через maplibregl.addProtocol, создание maplibregl.Map (zoom 4, minZoom 2, maxZoom 18, style из base.json), window.mapAPI с методами (addSource с проверкой существования, removeSource с автоудалением связанных слоёв, addLayer с beforeId, addLayerFromURL с автоматическим добавлением source, addLayersInline), обработчики событий (map.on('move') для zoom, map.on('click') для queryRenderedFeatures)
<!-- END AUTO-MANAGED: key-files -->
