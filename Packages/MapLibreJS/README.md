# MapLibreJS

Swift обёртка над [MapLibre GL JS](https://github.com/maplibre/maplibre-gl-js) для отображения интерактивных карт в SwiftUI приложениях через WKWebView.

## Требования

- iOS 16.0+
- macOS 13.0+
- Swift 6.2+

## Установка

### Swift Package Manager

Добавьте зависимость в `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/MapLibreJS", from: "1.0.0")
]
```

Или через Xcode: File → Add Package Dependencies → укажите URL репозитория.

## Быстрый старт

```swift
import SwiftUI
import MapLibreJS

struct ContentView: View {
    @State private var server: MapServer?

    var body: some View {
        Group {
            if let server {
                MapView(server: server)
            } else {
                ProgressView("Загрузка карты...")
            }
        }
        .task {
            do {
                let resourceManager = ResourceManager()
                try await resourceManager.prepareResources()
                let mapServer = MapServer(resourceManager: resourceManager)
                try await mapServer.start()
                self.server = mapServer
            } catch {
                print("Ошибка: \(error)")
            }
        }
    }
}
```

## API Reference

### ResourceManager

Менеджер ресурсов карты. Распаковывает ZIP архив с глифами, спрайтами и стилями в Application Support.

```swift
let resourceManager = ResourceManager()
try await resourceManager.prepareResources()

// пути к ресурсам
let wwwPath = await resourceManager.wwwPath          // HTML, JS, CSS
let resourcesPath = await resourceManager.resourcesPath  // glyphs, sprites
```

### MapServer

HTTP сервер для раздачи ресурсов карты. Использует динамический порт (8080-8180).

```swift
let server = MapServer(resourceManager: resourceManager)
try await server.start()

// URL сервера
let url = await server.baseURL  // http://localhost:8080

// регистрация источников
await server.register(mbTilesSource)
await server.register(pmTilesSource)
await server.register(geoJSONSource)

// удаление источника
await server.unregister(sourceId: "topo")

// остановка сервера
await server.stop()
```

### MapView

SwiftUI компонент для отображения карты.

```swift
MapView(
    server: server,
    onZoomChange: { zoom in
        print("Zoom: \(zoom)")
    },
    onClick: { event in
        print("Click: \(event.longitude), \(event.latitude)")
        for layer in event.layers {
            print("Layer: \(layer.layerId)")
        }
    }
)
```

#### Методы MapView

```swift
// добавление источника
await mapView.addSource(source)

// удаление источника
await mapView.removeSource("sourceId")

// перезагрузка источника (после изменения пути)
await mapView.reloadSource(source)

// добавление слоёв из JSON
await mapView.addLayer(from: layerURL)

// удаление слоя
await mapView.removeLayer("layerId")
```

### Источники данных

#### MBTilesSource

Источник векторных тайлов из MBTiles файла (SQLite).

```swift
let source = try MBTilesSource(id: "topo", path: topoURL)

// обновление пути к файлу
try source.updatePath(newURL)
```

#### PMTilesSource

Источник тайлов из PMTiles файла. Поддерживает локальные и удалённые URL.

```swift
// удалённый файл
let source = PMTilesSource(id: "terrain", url: remoteURL)

// локальный файл
let source = PMTilesSource(id: "local", url: localFileURL)

// растровые тайлы
let source = PMTilesSource(id: "satellite", url: url, isRaster: true)

// обновление URL
source.updateURL(newURL)
```

#### GeoJSONSource

Источник данных GeoJSON. Поддерживает URL, Data и словарь.

```swift
// из URL
let source = GeoJSONSource(id: "points", url: geojsonURL)

// из Data
let source = GeoJSONSource(id: "features", data: geojsonData)

// из словаря
let source = GeoJSONSource(id: "inline", dictionary: [
    "type": "FeatureCollection",
    "features": []
])

// обновление данных
source.updateData(.url(newURL))
source.updateData(.data(newData))
```

## Примеры использования

### Добавление MBTiles топографической карты

```swift
struct MapWithMBTiles: View {
    @State private var server: MapServer?
    @State private var coordinator: MapViewCoordinator?

    var body: some View {
        Group {
            if let server {
                MapView(server: server)
            }
        }
        .task {
            // инициализация сервера
            let resourceManager = ResourceManager()
            try? await resourceManager.prepareResources()
            let mapServer = MapServer(resourceManager: resourceManager)
            try? await mapServer.start()
            self.server = mapServer

            // добавление MBTiles источника
            if let url = Bundle.main.url(forResource: "topography", withExtension: "mbtiles") {
                let source = try? MBTilesSource(id: "topo", path: url)
                if let source {
                    await mapServer.register(source)
                }
            }
        }
    }
}
```

### Добавление PMTiles из сети

```swift
let terrainURL = URL(string: "https://example.com/terrain.pmtiles")!
let source = PMTilesSource(id: "terrain", url: terrainURL)
await server.register(source)
```

### Добавление GeoJSON точек

```swift
let geojson: [String: Any] = [
    "type": "FeatureCollection",
    "features": [
        [
            "type": "Feature",
            "geometry": [
                "type": "Point",
                "coordinates": [37.6173, 55.7558]
            ],
            "properties": [
                "name": "Москва"
            ]
        ]
    ]
]

let source = GeoJSONSource(id: "cities", dictionary: geojson)
await mapView.addSource(source)
```

### Добавление слоёв

Создайте JSON файл со слоями:

```json
[
    {
        "id": "topo-fill",
        "type": "fill",
        "source": "topo",
        "source-layer": "landcover",
        "paint": {
            "fill-color": "#228B22",
            "fill-opacity": 0.5
        }
    }
]
```

```swift
if let layerURL = Bundle.main.url(forResource: "layers", withExtension: "json") {
    await mapView.addLayer(from: layerURL)
}
```

### Обработка событий карты

```swift
MapView(
    server: server,
    onZoomChange: { zoom in
        print("Текущий зум: \(zoom)")
    },
    onClick: { event in
        print("Координаты: \(event.longitude), \(event.latitude)")

        // информация о слоях под курсором
        for layer in event.layers {
            print("Слой: \(layer.layerId)")
            print("Источник: \(layer.source)")
            print("Свойства: \(layer.properties)")
        }
    }
)
```

### Динамическое изменение источника

```swift
// изменение пути к MBTiles
try source.updatePath(newMBTilesURL)
await mapView.reloadSource(source)

// изменение URL PMTiles
source.updateURL(newPMTilesURL)
await mapView.reloadSource(source)
```

## Зависимости

- [FlyingFox](https://github.com/swhitty/FlyingFox) 0.26.0 — HTTP сервер
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) 0.9.20 — работа с ZIP архивами

## Лицензия

MIT License
