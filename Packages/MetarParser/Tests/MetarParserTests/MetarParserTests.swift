import Foundation
import Testing

@testable import MetarParser

@Suite("METAR Parser Tests")
struct MetarParserTests {

  let parser = try! MetarJSParser()

  @Test("Parse basic METAR with CAVOK")
  func testBasicMetarCavok() throws {
    let raw = "METAR LJMB 081300Z VRB01KT CAVOK 10/05 Q1021"
    let result = try parser.parseMetar(raw)

    #expect(result.station == "LJMB")
    #expect(result.rawTimestamp == "081300Z")
    #expect(result.isWindVariable == true)
    #expect(result.windSpeedKt == 1)
    #expect(result.isCavok == true)
    #expect(result.visibilityMeters == 10000)
    #expect(result.temperatureC == 10)
    #expect(result.dewpointC == 5)
    #expect(result.altimeterHpa == 1021)
  }

  @Test("Parse METAR with clouds and gusts")
  func testMetarWithClouds() throws {
    let raw = "METAR KJFK 081256Z 32010G18KT 10SM FEW020 SCT045 BKN100 22/16 A3012"
    let result = try parser.parseMetar(raw)

    #expect(result.station == "KJFK")
    #expect(result.windDirection == 320)
    #expect(result.windSpeedKt == 10)
    #expect(result.windGustKt == 18)
    #expect(result.visibilityMiles == 10)
    #expect(result.clouds.count == 3)
    #expect(result.clouds[0].coverage == .few)
    #expect(result.clouds[0].heightFeet == 2000)
    #expect(result.clouds[1].coverage == .scattered)
    #expect(result.clouds[1].heightFeet == 4500)
    #expect(result.clouds[2].coverage == .broken)
    #expect(result.clouds[2].heightFeet == 10000)
    #expect(result.altimeterInHg == 30.12)
  }

  @Test("Parse METAR with weather phenomena")
  func testMetarWithWeather() throws {
    let raw = "METAR EGLL 081250Z 27008KT 3000 -RA BR SCT010 BKN020 15/14 Q1008"
    let result = try parser.parseMetar(raw)

    #expect(result.station == "EGLL")
    #expect(result.visibilityMeters == 3000)
    #expect(result.weather.count >= 1)
    #expect(result.altimeterHpa == 1008)
  }

  @Test("Parse METAR with negative temperature")
  func testMetarNegativeTemp() throws {
    let raw = "METAR UUEE 081300Z 09003MPS 9999 BKN033 M05/M09 Q1024"
    let result = try parser.parseMetar(raw)

    #expect(result.temperatureC == -5)
    #expect(result.dewpointC == -9)
    #expect(result.windSpeedKt == 6)
  }

  @Test("Empty input throws error")
  func testEmptyInput() {
    #expect(throws: ParserError.self) {
      _ = try parser.parseMetar("")
    }
  }

  @Test("Calculate relative humidity")
  func testRelativeHumidity() throws {
    let raw = "METAR LJMB 081300Z VRB01KT CAVOK 10/05 Q1021"
    let result = try parser.parseMetar(raw)

    let rh = result.relativeHumidity
    #expect(rh != nil)
    #expect(rh! > 65 && rh! < 80)
  }

  @Test("Global parseMetar function")
  func testGlobalFunction() throws {
    let result = try parseMetar("METAR LJMB 081300Z VRB01KT CAVOK 10/05 Q1021")
    #expect(result.station == "LJMB")
  }
}

@Suite("Batch Parser Tests")
struct BatchParserTests {

  let parser = try! MetarJSParser()

  @Test("Parse multiple METARs in batch")
  func testBatchMetars() throws {
    let metars = [
      "METAR LJMB 081300Z VRB01KT CAVOK 10/05 Q1021",
      "METAR KJFK 081256Z 32010G18KT 10SM FEW020 SCT045 BKN100 22/16 A3012",
      "METAR EGLL 081250Z 27008KT 3000 -RA BR SCT010 BKN020 15/14 Q1008",
    ]

    let results = try parser.parseMetars(metars)

    #expect(results.count == 3)
    #expect(results[0].station == "LJMB")
    #expect(results[1].station == "KJFK")
    #expect(results[2].station == "EGLL")
  }

  @Test("Parse large batch of METARs")
  func testLargeBatch() throws {
    let baseMetar = "METAR KJFK 081256Z 32010KT 10SM FEW020 22/16 A3012"
    let metars = Array(repeating: baseMetar, count: 1000)

    let results = try parser.parseMetars(metars)

    #expect(results.count == 1000)
  }

  @Test("Global parseMetars function")
  func testGlobalBatchFunction() throws {
    let metars = [
      "METAR LJMB 081300Z VRB01KT CAVOK 10/05 Q1021",
      "METAR KJFK 081256Z 32010KT 10SM FEW020 22/16 A3012",
    ]

    let results = try parseMetars(metars)
    #expect(results.count == 2)
  }
}

@Suite("TAF Parser Tests")
struct TafParserTests {

  let parser = try! MetarJSParser()

  @Test("Parse basic TAF")
  func testBasicTaf() throws {
    let raw = "TAF KJFK 081130Z 0812/0918 32015KT 9999 SKC"
    let result = try parser.parseTaf(raw)

    #expect(result.station == "KJFK")
    #expect(result.isAmended == false)
    #expect(result.forecast.windDirection == 320)
    #expect(result.forecast.windSpeedKt == 15)
  }

  @Test("Parse amended TAF")
  func testAmendedTaf() throws {
    let raw = "TAF AMD EGLL 081200Z 0812/0912 27010KT 9999 SCT040"
    let result = try parser.parseTaf(raw)

    #expect(result.station == "EGLL")
    #expect(result.isAmended == true)
  }

  @Test("Global parseTaf function")
  func testGlobalFunction() throws {
    let result = try parseTaf("TAF KJFK 081130Z 0812/0918 32015KT 9999 SKC")
    #expect(result.station == "KJFK")
  }
}

@Suite("Batch TAF Parser Tests")
struct BatchTafParserTests {

  let parser = try! MetarJSParser()

  @Test("Parse multiple TAFs in batch")
  func testBatchTafs() throws {
    let tafs = [
      "TAF KJFK 081130Z 0812/0918 32015KT 9999 SKC",
      "TAF EGLL 081200Z 0812/0912 27010KT 9999 SCT040",
      "TAF AMD UUEE 081300Z 0813/0919 09005MPS 9999 BKN030",
    ]

    let results = try parser.parseTafs(tafs)

    #expect(results.count == 3)
    #expect(results[0].station == "KJFK")
    #expect(results[1].station == "EGLL")
    #expect(results[2].station == "UUEE")
    #expect(results[2].isAmended == true)
  }

  @Test("Global parseTafs function")
  func testGlobalBatchTafsFunction() throws {
    let tafs = [
      "TAF KJFK 081130Z 0812/0918 32015KT 9999 SKC",
      "TAF EGLL 081200Z 0812/0912 27010KT 9999 SCT040",
    ]

    let results = try parseTafs(tafs)
    #expect(results.count == 2)
    #expect(results[0].station == "KJFK")
    #expect(results[1].station == "EGLL")
  }
}

@Suite("Flight Category Tests")
struct FlightCategoryTests {

  let parser = try! MetarJSParser()

  @Test("VFR - CAVOK conditions")
  func testVfrCavok() throws {
    let raw = "METAR LJMB 081300Z VRB01KT CAVOK 10/05 Q1021"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .vfr)
    #expect(result.ceilingFeet == nil)
  }

  @Test("VFR - high ceiling and good visibility")
  func testVfrHighCeiling() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM FEW050 BKN120 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .vfr)
    #expect(result.ceilingFeet == 12000)
  }

  @Test("MVFR - ceiling 2500 ft")
  func testMvfrCeiling() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM BKN025 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .mvfr)
    #expect(result.ceilingFeet == 2500)
  }

  @Test("MVFR - visibility 4 SM")
  func testMvfrVisibility() throws {
    let raw = "METAR KJFK 081300Z 27010KT 4SM FEW100 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .mvfr)
  }

  @Test("IFR - ceiling 800 ft")
  func testIfrCeiling() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM OVC008 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .ifr)
    #expect(result.ceilingFeet == 800)
  }

  @Test("IFR - visibility 2 SM")
  func testIfrVisibility() throws {
    let raw = "METAR KJFK 081300Z 27010KT 2SM FEW100 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .ifr)
  }

  @Test("LIFR - ceiling 400 ft")
  func testLifrCeiling() throws {
    let raw = "METAR KJFK 081300Z 27010KT 5SM BKN004 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .lifr)
    #expect(result.ceilingFeet == 400)
  }

  @Test("LIFR - visibility 1/2 SM")
  func testLifrVisibility() throws {
    let raw = "METAR KJFK 081300Z 27010KT 1/2SM FEW100 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.flightCategory == .lifr)
  }
}

@Suite("MetarData Computed Properties Tests")
struct MetarDataComputedPropertiesTests {

  let parser = try! MetarJSParser()

  // MARK: - Temperature

  @Test("Temperature F - positive celsius")
  func testTemperatureFPositive() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM SKC 20/10 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.temperatureC == 20)
    #expect(result.temperatureF == 68)
  }

  @Test("Temperature F - negative celsius")
  func testTemperatureFNegative() throws {
    let raw = "METAR UUEE 081300Z 09003MPS 9999 BKN033 M10/M15 Q1024"
    let result = try parser.parseMetar(raw)
    #expect(result.temperatureC == -10)
    #expect(result.temperatureF == 14)
  }

  @Test("Temperature F - freezing point")
  func testTemperatureFZero() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM SKC 00/M02 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.temperatureC == 0)
    #expect(result.temperatureF == 32)
  }

  @Test("Dewpoint F conversion")
  func testDewpointF() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM SKC 25/15 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.dewpointC == 15)
    #expect(result.dewpointF == 59)
  }

  // MARK: - Cloud Heights

  @Test("Lowest cloud layer - multiple layers")
  func testLowestCloudMultiple() throws {
    let raw = "METAR KJFK 081256Z 32010KT 10SM FEW020 SCT045 BKN100 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.lowestCloudLayerFeet == 2000)
    #expect(result.ceilingFeet == 10000)
  }

  @Test("Ceiling - broken is ceiling layer")
  func testCeilingBroken() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM FEW010 SCT020 BKN030 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.lowestCloudLayerFeet == 1000)
    #expect(result.ceilingFeet == 3000)
  }

  @Test("Ceiling - overcast layer")
  func testCeilingOvercast() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM SCT020 OVC050 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.ceilingFeet == 5000)
  }

  @Test("No ceiling - only FEW and SCT")
  func testNoCeiling() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM FEW020 SCT045 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.lowestCloudLayerFeet == 2000)
    #expect(result.ceilingFeet == nil)
  }

  // MARK: - Visibility

  @Test("Visibility statute miles - from meters")
  func testVisibilityFromMeters() throws {
    let raw = "METAR EGLL 081250Z 27008KT 5000 SCT020 15/14 Q1008"
    let result = try parser.parseMetar(raw)
    #expect(result.visibilityMeters == 5000)
    let visSm = result.visibilityStatuteMiles!
    #expect(visSm > 3.0 && visSm < 3.2)
  }

  @Test("Visibility statute miles - direct US format")
  func testVisibilityDirectMiles() throws {
    let raw = "METAR KJFK 081300Z 27010KT 10SM SKC 22/16 A3012"
    let result = try parser.parseMetar(raw)
    #expect(result.visibilityMiles == 10)
    #expect(result.visibilityStatuteMiles == 10)
  }
}
