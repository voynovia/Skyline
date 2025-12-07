import SwiftUI
import WebKit

private enum MessageName: String, CaseIterable {
  case console
  case zoom
  case click
}

/// SwiftUI View для отображения карты MapLibre GL JS
public struct MapView: View {
  private let server: MapServer
  private let initialLayers: [[String: Any]]
  private let onZoomChange: ((Double) -> Void)?
  private let onClick: ((MapClickEvent) -> Void)?

  @Binding private var sourceEnabled: Bool
  private let toggleSourceId: String
  private let toggleSourceConfig: [String: Any]
  private let toggleLayerConfigs: [[String: Any]]

  @State private var coordinator: MapViewCoordinator?
  @Environment(\.colorScheme) private var colorScheme

  public init(
    server: MapServer,
    initialLayers: [[String: Any]] = [],
    sourceEnabled: Binding<Bool> = .constant(true),
    toggleSourceId: String = "",
    toggleSourceConfig: [String: Any] = [:],
    toggleLayerConfigs: [[String: Any]] = [],
    onZoomChange: ((Double) -> Void)? = nil,
    onClick: ((MapClickEvent) -> Void)? = nil
  ) {
    self.server = server
    self.initialLayers = initialLayers
    self._sourceEnabled = sourceEnabled
    self.toggleSourceId = toggleSourceId
    self.toggleSourceConfig = toggleSourceConfig
    self.toggleLayerConfigs = toggleLayerConfigs
    self.onZoomChange = onZoomChange
    self.onClick = onClick
  }

  public var body: some View {
    MapWebViewRepresentable(
      server: server,
      initialLayers: initialLayers,
      sourceEnabled: $sourceEnabled,
      toggleSourceId: toggleSourceId,
      toggleSourceConfig: toggleSourceConfig,
      toggleLayerConfigs: toggleLayerConfigs,
      coordinator: $coordinator,
      colorScheme: colorScheme,
      onZoomChange: onZoomChange,
      onClick: onClick
    )
  }

  // MARK: - Public API

  /// Добавление источника на карту
  public func addSource(_ source: any MapSource) async {
    guard let coordinator else { return }
    await coordinator.addSource(source)
  }

  /// Удаление источника с карты
  public func removeSource(_ sourceId: String) async {
    guard let coordinator else { return }
    await coordinator.removeSource(sourceId)
  }

  /// Перезагрузка источника
  public func reloadSource(_ source: any MapSource) async {
    guard let coordinator else { return }
    await coordinator.reloadSource(source)
  }

  /// Добавление слоя из JSON конфигурации
  public func addLayer(from url: URL) async {
    guard let coordinator else { return }
    await coordinator.addLayer(from: url)
  }

  /// Добавление слоёв из inline конфигурации
  public func addLayers(_ configs: [[String: Any]]) async {
    guard let coordinator else { return }
    await coordinator.addLayers(configs)
  }

  /// Удаление слоя
  public func removeLayer(_ layerId: String) async {
    guard let coordinator else { return }
    await coordinator.removeLayer(layerId)
  }
}

/// Событие клика на карте
public struct MapClickEvent: Sendable {
  public let longitude: Double
  public let latitude: Double
  public let layers: [ClickedLayer]

  public struct ClickedLayer: @unchecked Sendable {
    public let layerId: String
    public let source: String
    public let sourceLayer: String?
    public let properties: [String: Any]

    public init(layerId: String, source: String, sourceLayer: String?, properties: [String: Any]) {
      self.layerId = layerId
      self.source = source
      self.sourceLayer = sourceLayer
      self.properties = properties
    }
  }
}

// MARK: - Platform-specific WebView

#if os(iOS)
private struct MapWebViewRepresentable: UIViewRepresentable {
  let server: MapServer
  let initialLayers: [[String: Any]]
  @Binding var sourceEnabled: Bool
  let toggleSourceId: String
  let toggleSourceConfig: [String: Any]
  let toggleLayerConfigs: [[String: Any]]
  @Binding var coordinator: MapViewCoordinator?
  let colorScheme: ColorScheme
  let onZoomChange: ((Double) -> Void)?
  let onClick: ((MapClickEvent) -> Void)?

  func makeUIView(context: Context) -> WKWebView {
    let webView = createWebView(coordinator: context.coordinator)
    context.coordinator.webView = webView
    context.coordinator.colorScheme = colorScheme
    context.coordinator.initialLayers = initialLayers
    context.coordinator.sourceEnabled = sourceEnabled
    context.coordinator.toggleSourceId = toggleSourceId
    context.coordinator.toggleSourceConfig = toggleSourceConfig
    context.coordinator.toggleLayerConfigs = toggleLayerConfigs
    Task {
      await context.coordinator.loadMapURL()
    }
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    if context.coordinator.colorScheme != colorScheme {
      context.coordinator.colorScheme = colorScheme
      Task {
        await context.coordinator.reloadWithTheme()
      }
    }

    if context.coordinator.sourceEnabled != sourceEnabled {
      context.coordinator.sourceEnabled = sourceEnabled
      Task {
        if sourceEnabled {
          await context.coordinator.enableSource(toggleSourceId, sourceConfig: toggleSourceConfig, layerConfigs: toggleLayerConfigs)
        } else {
          await context.coordinator.disableSource(toggleSourceId)
        }
      }
    }
  }

  func makeCoordinator() -> MapViewCoordinator {
    let coord = MapViewCoordinator(server: server, onZoomChange: onZoomChange, onClick: onClick)
    Task { @MainActor in
      coordinator = coord
    }
    return coord
  }
}

#elseif os(macOS)
private struct MapWebViewRepresentable: NSViewRepresentable {
  let server: MapServer
  let initialLayers: [[String: Any]]
  @Binding var sourceEnabled: Bool
  let toggleSourceId: String
  let toggleSourceConfig: [String: Any]
  let toggleLayerConfigs: [[String: Any]]
  @Binding var coordinator: MapViewCoordinator?
  let colorScheme: ColorScheme
  let onZoomChange: ((Double) -> Void)?
  let onClick: ((MapClickEvent) -> Void)?

  func makeNSView(context: Context) -> WKWebView {
    let webView = createWebView(coordinator: context.coordinator)
    context.coordinator.webView = webView
    context.coordinator.colorScheme = colorScheme
    context.coordinator.initialLayers = initialLayers
    context.coordinator.sourceEnabled = sourceEnabled
    context.coordinator.toggleSourceId = toggleSourceId
    context.coordinator.toggleSourceConfig = toggleSourceConfig
    context.coordinator.toggleLayerConfigs = toggleLayerConfigs
    Task {
      await context.coordinator.loadMapURL()
    }
    return webView
  }

  func updateNSView(_ webView: WKWebView, context: Context) {
    if context.coordinator.colorScheme != colorScheme {
      context.coordinator.colorScheme = colorScheme
      Task {
        await context.coordinator.reloadWithTheme()
      }
    }

    if context.coordinator.sourceEnabled != sourceEnabled {
      context.coordinator.sourceEnabled = sourceEnabled
      Task {
        if sourceEnabled {
          await context.coordinator.enableSource(toggleSourceId, sourceConfig: toggleSourceConfig, layerConfigs: toggleLayerConfigs)
        } else {
          await context.coordinator.disableSource(toggleSourceId)
        }
      }
    }
  }

  func makeCoordinator() -> MapViewCoordinator {
    let coord = MapViewCoordinator(server: server, onZoomChange: onZoomChange, onClick: onClick)
    Task { @MainActor in
      coordinator = coord
    }
    return coord
  }
}
#endif

// MARK: - Common WebView setup

@MainActor
private func createWebView(coordinator: MapViewCoordinator) -> WKWebView {
  let config = WKWebViewConfiguration()
  let contentController = WKUserContentController()

  for name in MessageName.allCases {
    contentController.add(coordinator, name: name.rawValue)
  }

  config.userContentController = contentController
  config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

  let webView = WKWebView(frame: .zero, configuration: config)

  if #available(macOS 13.3, iOS 16.4, *) {
    webView.isInspectable = true
  }

  #if os(iOS)
  webView.scrollView.minimumZoomScale = 1.0
  webView.scrollView.maximumZoomScale = 1.0
  webView.scrollView.bouncesZoom = false
  #endif

  return webView
}


// MARK: - Coordinator

@MainActor
public final class MapViewCoordinator: NSObject, WKScriptMessageHandler {
  weak var webView: WKWebView?
  private let server: MapServer
  private let onZoomChange: ((Double) -> Void)?
  private let onClick: ((MapClickEvent) -> Void)?

  private var isMapLoaded = false
  private var jsQueue: [String] = []
  private var isExecutingJS = false
  var colorScheme: ColorScheme = .light
  var initialLayers: [[String: Any]] = []
  var sourceEnabled: Bool = true
  var toggleSourceId: String = ""
  var toggleSourceConfig: [String: Any] = [:]
  var toggleLayerConfigs: [[String: Any]] = []

  init(
    server: MapServer,
    onZoomChange: ((Double) -> Void)?,
    onClick: ((MapClickEvent) -> Void)?
  ) {
    self.server = server
    self.onZoomChange = onZoomChange
    self.onClick = onClick
    super.init()
  }

  public nonisolated func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    MainActor.assumeIsolated {
      handleMessage(message)
    }
  }

  private func handleMessage(_ message: WKScriptMessage) {
    guard let messageName = MessageName(rawValue: message.name) else {
      print("unknown message name: \(message.name)")
      return
    }
    switch messageName {
    case .console:
      if let bodyDict = message.body as? [String: Any] {
        let type = bodyDict["type"] as? String ?? "log"
        let msg = bodyDict["message"] as? String ?? ""
        print("JS Console \(type): \(msg)")
        if msg.contains("Map loaded successfully") {
          Task {
            self.isMapLoaded = true
            await self.addInitialLayers()
            await self.processJSQueue()
          }
        }
      }
    case .zoom:
      if let zoomString = message.body as? String,
         let zoom = Double(zoomString) {
        onZoomChange?(zoom)
      }
    case .click:
      if let dict = message.body as? [String: Any] {
        let event = parseClickEvent(dict)
        onClick?(event)
      }
    }
  }

  private func parseClickEvent(_ dict: [String: Any]) -> MapClickEvent {
    let longitude = dict["longitude"] as? Double ?? 0
    let latitude = dict["latitude"] as? Double ?? 0
    let layersData = dict["layers"] as? [[String: Any]] ?? []

    let layers = layersData.map { layerDict -> MapClickEvent.ClickedLayer in
      MapClickEvent.ClickedLayer(
        layerId: layerDict["layer"] as? String ?? "",
        source: layerDict["source"] as? String ?? "",
        sourceLayer: layerDict["sourceLayer"] as? String,
        properties: layerDict["properties"] as? [String: Any] ?? [:]
      )
    }

    return MapClickEvent(longitude: longitude, latitude: latitude, layers: layers)
  }

  // MARK: - Map Operations

  func loadMapURL() async {
    guard let port = await server.port else { return }
    let theme = colorScheme == .dark ? "dark" : "light"
    let url = URL(string: "http://localhost:\(port)/index.html?theme=\(theme)")!
    webView?.load(URLRequest(url: url))
  }

  func reloadWithTheme() async {
    isMapLoaded = false
    jsQueue.removeAll()
    isExecutingJS = false
    await loadMapURL()
  }

  func addSource(_ source: any MapSource) async {
    guard let port = await server.port else { return }

    // регистрируем источник на сервере
    if let mbtiles = source as? MBTilesSource {
      await server.register(mbtiles)
    } else if let pmtiles = source as? PMTilesSource {
      await server.register(pmtiles)
    } else if let geojson = source as? GeoJSONSource {
      await server.register(geojson)
    }

    let config: [String: Any]
    if let mbtiles = source as? MBTilesSource {
      config = mbtiles.configuration(port: port)
    } else if let pmtiles = source as? PMTilesSource {
      config = pmtiles.configuration(serverPort: port)
    } else if let geojson = source as? GeoJSONSource {
      config = geojson.configuration(serverPort: port)
    } else {
      config = source.configuration
    }

    guard let configJSON = try? JSONSerialization.data(withJSONObject: config),
          let configString = String(data: configJSON, encoding: .utf8) else {
      return
    }

    let js = "window.mapAPI?.addSource('\(source.id)', \(configString))"
    await executeJS(js)
  }

  func removeSource(_ sourceId: String) async {
    await server.unregister(sourceId: sourceId)
    let js = "window.mapAPI?.removeSource('\(sourceId)')"
    await executeJS(js)
  }

  func reloadSource(_ source: any MapSource) async {
    await removeSource(source.id)
    await addSource(source)
  }

  func addLayer(from url: URL) async {
    guard let port = await server.port else { return }
    let urlString: String
    if url.isFileURL {
      urlString = "http://localhost:\(port)/layers/\(url.lastPathComponent)"
    } else {
      urlString = url.absoluteString
    }
    let js = "window.mapAPI?.addLayerFromURL('\(urlString)')"
    await executeJS(js)
  }

  func removeLayer(_ layerId: String) async {
    let js = "window.mapAPI?.removeLayer('\(layerId)')"
    await executeJS(js)
  }

  func addLayers(_ configs: [[String: Any]]) async {
    guard let configJSON = try? JSONSerialization.data(withJSONObject: configs),
          let configString = String(data: configJSON, encoding: .utf8) else { return }

    let js = "window.mapAPI?.addLayersInline(\(configString))"
    await executeJS(js)
  }

  private func addInitialLayers() async {
    guard !initialLayers.isEmpty else { return }
    await addLayers(initialLayers)
  }

  func disableSource(_ sourceId: String) async {
    let js = "window.mapAPI?.disableSource('\(sourceId)')"
    await executeJS(js)
  }

  func enableSource(_ sourceId: String, sourceConfig: [String: Any], layerConfigs: [[String: Any]]) async {
    guard let sourceJSON = try? JSONSerialization.data(withJSONObject: sourceConfig),
          let sourceString = String(data: sourceJSON, encoding: .utf8),
          let layersJSON = try? JSONSerialization.data(withJSONObject: layerConfigs),
          let layersString = String(data: layersJSON, encoding: .utf8) else { return }
    let js = "window.mapAPI?.enableSource('\(sourceId)', \(sourceString), \(layersString))"
    await executeJS(js)
  }

  // MARK: - Helpers

  private func executeJS(_ js: String) async {
    jsQueue.append(js)
    guard isMapLoaded, !isExecutingJS else { return }
    await processJSQueue()
  }

  private func processJSQueue() async {
    guard !isExecutingJS else { return }
    isExecutingJS = true

    while !jsQueue.isEmpty {
      let command = jsQueue.removeFirst()
      do {
        _ = try await webView?.evaluateJavaScript(command)
      } catch {
        print("JS Error: \(error)")
      }
    }

    isExecutingJS = false
  }
}
