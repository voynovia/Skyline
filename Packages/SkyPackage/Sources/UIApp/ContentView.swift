import SwiftUI
import MapLibreJS
import SrvMap

public struct ContentView: View {
  @State private var server: MapServer?
  @State private var loadingStatus = "Инициализация..."
  @State private var isLoading = true
  @State private var topoLayers: [[String: Any]] = []
  @State private var hypsometryLayers: [[String: Any]] = []
  @State private var hypsometrySourceConfig: [String: Any] = [:]
  @State private var isHypsometryEnabled = true
  @Environment(\.colorScheme) private var colorScheme

  public init() {}

  public var body: some View {
    Group {
      if let server, !isLoading {
        ZStack(alignment: .bottomLeading) {
          MapView(
            server: server,
            initialLayers: topoLayers + hypsometryLayers,
            sourceEnabled: $isHypsometryEnabled,
            toggleSourceId: "hypsometry",
            toggleSourceConfig: hypsometrySourceConfig,
            toggleLayerConfigs: hypsometryLayers
          )

          Button {
            isHypsometryEnabled.toggle()
          } label: {
            Image(systemName: isHypsometryEnabled ? "mountain.2.fill" : "mountain.2")
              .font(.title2)
              .padding(12)
              .background(.ultraThinMaterial)
              .clipShape(Circle())
          }
          .padding()
        }
      } else {
        VStack {
          ProgressView()
          Text(loadingStatus)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .task {
      await initializeMap()
    }
  }

  private func initializeMap() async {
    do {
      let mapDataService = MapDataService.shared
      await mapDataService.setStatusHandler { status in
        Task { @MainActor in
          loadingStatus = status
        }
      }

      // 1. проверить/скачать topo.mbtiles и hypsometry.mbtiles
      loadingStatus = "Проверка карты..."
      let topoPath = try await mapDataService.ensureTopography()
      let hypsometryPath = try await mapDataService.ensureHypsometry()

      // 2. инициализировать сервер
      loadingStatus = "Запуск сервера..."
      let resourceManager = ResourceManager()
      try await resourceManager.prepareResources()
      let mapServer = MapServer(resourceManager: resourceManager)
      try await mapServer.start()

      // 3. зарегистрировать MBTiles источники
      loadingStatus = "Загрузка карты..."
      let topoSource = try MBTilesSource(id: "topo", path: topoPath)
      let hypsometrySource = try MBTilesSource(id: "hypsometry", path: hypsometryPath)
      await mapServer.register(topoSource)
      await mapServer.register(hypsometrySource)

      // 4. загрузить конфигурацию слоёв topo в зависимости от темы
      let topoLayer: MapLayer = colorScheme == .dark ? .topographyDark : .topographyLight
      if let topoURL = topoLayer.layerConfigURL,
         let data = try? Data(contentsOf: topoURL),
         let layers = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
        topoLayers = layers
      }

      // 5. загрузить конфигурацию слоёв рельефа
      if let hypsometryURL = MapLayer.hypsometry.layerConfigURL,
         let data = try? Data(contentsOf: hypsometryURL),
         let layers = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
        hypsometryLayers = layers
      }

      // 6. сохранить конфигурацию source для toggle
      if let data = await mapServer.sourceConfigurationData(for: "hypsometry"),
         let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        hypsometrySourceConfig = config
      }

      self.server = mapServer
      self.isLoading = false

    } catch {
      loadingStatus = "Ошибка: \(error.localizedDescription)"
      print("Ошибка инициализации: \(error)")
    }
  }
}
