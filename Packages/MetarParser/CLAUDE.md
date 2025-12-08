# MetarParser

Парсер METAR и TAF сообщений с использованием JavaScriptCore.

## Build Commands

```bash
swift build --package-path Packages/MetarParser
swift test --package-path Packages/MetarParser
```

## Architecture

```
Sources/MetarParser/
├── MetarParser.swift       # публичный API (parseMetar, parseTaf, parseMetars, parseTafs)
├── Parser/
│   ├── JSEngine.swift      # обёртка JSContext с thread safety (NSLock)
│   └── MetarJSParser.swift # вызов JS парсера, декодирование результатов
├── Models/
│   ├── MetarData.swift     # Codable структура METAR с computed properties (flightCategory, temperatureF, ceilingFeet)
│   ├── TafData.swift       # Codable структура TAF с forecast и changes
│   ├── CloudLayer.swift    # слой облачности (coverage, heightFeet)
│   ├── WeatherPhenomenon.swift # погодное явление (intensity, descriptor, phenomenon)
│   ├── FlightCategory.swift # категория полёта (VFR, MVFR, IFR, LIFR)
│   └── ParserError.swift   # типы ошибок
└── Resources/
    └── metar-parser.js     # JavaScript парсер
```

## Usage

```swift
import MetarParser

// через глобальную функцию
let metar = try parseMetar("METAR LJMB 081300Z VRB01KT CAVOK 10/05 Q1021")
print(metar.station)       // "LJMB"
print(metar.isCavok)       // true

// через экземпляр парсера
let parser = try MetarJSParser()
let data = try parser.parseMetar("...")
let taf = try parser.parseTaf("TAF KJFK ...")
```

## Patterns

- **JavaScriptCore**: выполнение JS парсера без WKWebView
- **Thread Safety**: NSLock для синхронизации JSContext
- **Codable**: JSON декодирование результата JS в Swift структуры
- **Batch API**: parseMetars/parseTafs для обработки массивов сообщений

## Key Files

- **Parser/JSEngine.swift** — загрузка JS, вызов функций, сериализация
- **Parser/MetarJSParser.swift** — парсер с warmup при инициализации
- **Resources/metar-parser.js** — JavaScript парсер METAR/TAF
- **Models/MetarData.swift** — структура METAR с computed properties (flightCategory, temperatureF, ceilingFeet, visibilityStatuteMiles)
- **Models/FlightCategory.swift** — enum категорий полёта (VFR/MVFR/IFR/LIFR)
