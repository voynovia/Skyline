import SwiftUI
import Horizon

@Equatable
struct ArpCardView: View {
  
  struct ArpValue: Identifiable {
    let id: UUID = UUID()
    let title: String
    let value: String
  }
  
  @State private var isExpanded: Bool = false
  @Namespace private var animation
  
  let arp: Arp
//  @State private var weatherService: WeatherService
  @State private var currentGradient: GradientColors = .init([])
  
  init(arp: Arp) {
    self.arp = arp
//    _weatherService = State(initialValue: WeatherService(coordinate: arp.location))
  }
  
  var body: some View {
    ZStack {
      
      RoundedRectangle(cornerRadius: 20)
        .fill(
          LinearGradient(
            colors: currentGradient.colors.isEmpty ? [] : Array(repeating: currentGradient.colors[0], count: 2), //Array(currentGradient.colors.prefix(2)),
            startPoint: currentGradient.startPoint,
            endPoint: currentGradient.endPoint
          )
        )
        .animation(.easeInOut(duration: 1.0), value: currentGradient.colors)
      
      // большая иконка справа
      HStack {
        Spacer()
        Image(systemName: arp.weatherIcon)
          .font(.system(size: 80))
          .symbolRenderingMode(.multicolor)
          .opacity(0.3)
          .padding(.trailing, 8)
      }
      
      HStack {
        //left
        WindRoseView(degrees: 0, direction: arp.windDirection, speed: arp.windSpeed)
          .padding(.horizontal, 8)
        // middle
        VStack {
          HStack {
            Text(arp.icao)
              .foregroundStyle(.primary)
            if let iata = arp.iata {
              Text(iata)
                .foregroundStyle(.secondary)
            }
          }
          Grid(alignment: .center, horizontalSpacing: 4) {
            GridRow {
              Image(systemName: "arrow.down.to.line").foregroundStyle(.secondary)
              Text(String(arp.qnh)+" hPa").font(.caption)
              Image(systemName: arp.category.icon).foregroundStyle(.secondary) // arp.category.icon
              Text(arp.category.rawValue).font(.caption)
            }
            GridRow {
              Image(systemName: "icloud.and.arrow.up").foregroundStyle(.secondary)
              Text("8000 ft").font(.caption)
              Image(systemName: "thermometer.variable").foregroundStyle(.secondary)
              Text("17 ℃").font(.caption)
            }
            GridRow {
              Image(systemName: "eye").foregroundStyle(.secondary)
              Text("10 km+").font(.caption)
              Image(systemName: "humidity").foregroundStyle(.secondary)
              Text("14 ℃").font(.caption)
            }
          }
        }
        Spacer()
        // right
        
      }
      
    }
    .frame(height: 100)
    .task {
      do {
//        currentGradient = try await LocationGradient()//.getGradient(for: arp.location)
      } catch {
        print(error.localizedDescription)
      }
    }
  }
  
}
