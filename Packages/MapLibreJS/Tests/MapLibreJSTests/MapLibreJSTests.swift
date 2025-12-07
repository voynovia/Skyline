import Testing
import Foundation
@testable import MapLibreJS

@Suite("MapSource Tests")
struct MapSourceTests {

  @Test("MBTilesSource создаётся с валидным путём")
  func testMBTilesSourceCreation() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let testFile = tempDir.appendingPathComponent("test.mbtiles")

    // создаём пустой файл для теста
    FileManager.default.createFile(atPath: testFile.path, contents: Data())
    defer { try? FileManager.default.removeItem(at: testFile) }

    let source = try MBTilesSource(id: "test", path: testFile)

    #expect(source.id == "test")
    #expect(source.sourceType == .vector)
    #expect(source.path == testFile)
  }

  @Test("MBTilesSource выбрасывает ошибку для несуществующего файла")
  func testMBTilesSourceInvalidPath() {
    let invalidPath = URL(fileURLWithPath: "/nonexistent/file.mbtiles")

    #expect(throws: MapSourceError.self) {
      _ = try MBTilesSource(id: "test", path: invalidPath)
    }
  }

  @Test("MBTilesSource обновляет путь")
  func testMBTilesSourceUpdatePath() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let testFile1 = tempDir.appendingPathComponent("test1.mbtiles")
    let testFile2 = tempDir.appendingPathComponent("test2.mbtiles")

    FileManager.default.createFile(atPath: testFile1.path, contents: Data())
    FileManager.default.createFile(atPath: testFile2.path, contents: Data())
    defer {
      try? FileManager.default.removeItem(at: testFile1)
      try? FileManager.default.removeItem(at: testFile2)
    }

    let source = try MBTilesSource(id: "test", path: testFile1)
    #expect(source.path == testFile1)

    try source.updatePath(testFile2)
    #expect(source.path == testFile2)
  }

  @Test("PMTilesSource создаётся с URL")
  func testPMTilesSourceCreation() {
    let url = URL(string: "https://example.com/tiles.pmtiles")!
    let source = PMTilesSource(id: "terrain", url: url)

    #expect(source.id == "terrain")
    #expect(source.sourceType == .vector)
    #expect(source.url == url)
  }

  @Test("PMTilesSource создаётся как растровый")
  func testPMTilesSourceRaster() {
    let url = URL(string: "https://example.com/satellite.pmtiles")!
    let source = PMTilesSource(id: "satellite", url: url, isRaster: true)

    #expect(source.sourceType == .raster)
  }

  @Test("PMTilesSource обновляет URL")
  func testPMTilesSourceUpdateURL() {
    let url1 = URL(string: "https://example.com/tiles1.pmtiles")!
    let url2 = URL(string: "https://example.com/tiles2.pmtiles")!

    let source = PMTilesSource(id: "test", url: url1)
    #expect(source.url == url1)

    source.updateURL(url2)
    #expect(source.url == url2)
  }

  @Test("GeoJSONSource создаётся из URL")
  func testGeoJSONSourceFromURL() {
    let url = URL(string: "https://example.com/data.geojson")!
    let source = GeoJSONSource(id: "points", url: url)

    #expect(source.id == "points")
    #expect(source.sourceType == .geojson)
  }

  @Test("GeoJSONSource создаётся из Data")
  func testGeoJSONSourceFromData() {
    let geojson = """
    {"type": "FeatureCollection", "features": []}
    """
    let data = geojson.data(using: .utf8)!
    let source = GeoJSONSource(id: "features", data: data)

    #expect(source.id == "features")
    #expect(source.sourceType == .geojson)
  }

  @Test("GeoJSONSource создаётся из словаря")
  func testGeoJSONSourceFromDictionary() throws {
    let dict: [String: Any] = [
      "type": "FeatureCollection",
      "features": []
    ]
    let source = try GeoJSONSource(id: "collection", dictionary: dict)

    #expect(source.id == "collection")
  }

  @Test("GeoJSONSource возвращает данные")
  func testGeoJSONSourceGetData() throws {
    let geojson = """
    {"type": "FeatureCollection", "features": []}
    """
    let data = geojson.data(using: .utf8)!
    let source = GeoJSONSource(id: "test", data: data)

    let result = try source.getDataBytes()
    #expect(result == data)
  }
}

@Suite("MapServer Tests")
struct MapServerTests {

  @Test("ResourceManager инициализируется")
  func testResourceManagerInit() async {
    let manager = ResourceManager()
    let path = await manager.resourcesPath
    #expect(path.path.contains("MapLibreJS") || path.path.contains("resources"))
  }
}

@Suite("Configuration Tests")
struct ConfigurationTests {

  @Test("MBTilesSource генерирует конфигурацию с портом")
  func testMBTilesSourceConfiguration() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let testFile = tempDir.appendingPathComponent("config_test.mbtiles")
    FileManager.default.createFile(atPath: testFile.path, contents: Data())
    defer { try? FileManager.default.removeItem(at: testFile) }

    let source = try MBTilesSource(id: "topo", path: testFile)
    let config = source.configuration(port: 8080)

    #expect(config["type"] as? String == "vector")

    let tiles = config["tiles"] as? [String]
    #expect(tiles?.first?.contains("8080") == true)
    #expect(tiles?.first?.contains("topo") == true)
  }

  @Test("PMTilesSource генерирует конфигурацию для удалённого URL")
  func testPMTilesSourceRemoteConfiguration() {
    let url = URL(string: "https://example.com/tiles.pmtiles")!
    let source = PMTilesSource(id: "remote", url: url)
    let config = source.configuration(serverPort: 8080)

    let pmtilesURL = config["url"] as? String
    #expect(pmtilesURL?.contains("pmtiles://https://example.com") == true)
  }

  @Test("PMTilesSource генерирует конфигурацию для локального файла")
  func testPMTilesSourceLocalConfiguration() {
    let url = URL(fileURLWithPath: "/path/to/tiles.pmtiles")
    let source = PMTilesSource(id: "local", url: url)
    let config = source.configuration(serverPort: 9000)

    let pmtilesURL = config["url"] as? String
    #expect(pmtilesURL?.contains("localhost:9000") == true)
    #expect(pmtilesURL?.contains("local.pmtiles") == true)
  }

  @Test("GeoJSONSource генерирует конфигурацию с inline данными")
  func testGeoJSONSourceInlineConfiguration() throws {
    let dict: [String: Any] = [
      "type": "FeatureCollection",
      "features": []
    ]
    let source = try GeoJSONSource(id: "inline", dictionary: dict)
    let config = source.configuration(serverPort: nil)

    #expect(config["type"] as? String == "geojson")
    // теперь возвращает пустой dict если нет serverPort для Data варианта
    #expect(config["data"] as? [String: Any] != nil)
  }
}
