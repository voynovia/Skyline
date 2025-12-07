import SwiftUI

// https://youtu.be/0yJqYzWQUj8 - notification button

struct ArpDetailView: View {
  
//  @Binding var isExpanded: Bool
  
  @Environment(\.dismiss) private var dismiss
  
  let arp: Arp
//  @State private var weatherService: WeatherService
  @State private var currentGradient: GradientColors = .init([])
  
  init(arp: Arp) {
    self.arp = arp
//    _weatherService = State(initialValue: WeatherService(coordinate: arp.location))
  }
  
  var body: some View {
    ZStack {
      // динамический градиентный фон
      LinearGradient(
        colors: currentGradient.colors,
        startPoint: currentGradient.startPoint,
        endPoint: currentGradient.endPoint
      )
      .ignoresSafeArea()
//      .animation(.easeInOut(duration: 1.0), value: currentGradient.colors)
      
      ScrollView {
        VStack(spacing: 0) {
          VStack(spacing: 8) {
            Text(arp.icao)
              .font(.system(size: 34, weight: .regular))
              .foregroundStyle(.white)
            
            Text("\(arp.temperature)°")
              .font(.system(size: 96, weight: .thin))
              .foregroundStyle(.white)
            
            Text(arp.condition.description)
              .font(.system(size: 20))
              .foregroundStyle(.white.opacity(0.8))
            
//            HStack(spacing: 8) {
//              Text("Макс.: \(city.maxTemp)°")
//              Text("Мин.: \(city.minTemp)°")
//            }
//            .font(.system(size: 17))
//            .foregroundStyle(.white)
//            .padding(.top, 4)
          }
          .padding(.top, 60)
          
          VStack(spacing: 20) {
            HourlyForecastView()
              .padding(.top, 40)
            
            DailyForecastView()
            
            WeatherDetailsView()
            
            WeatherMapView()
            
            AirQualityView()
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 40)
        }
      }
    }
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
        }
      }
      
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          // menu action
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 22))
            .foregroundStyle(.white)
        }
      }
    }
    .toolbarBackground(.hidden, for: .navigationBar)
    .task {
      do {
//        try await weatherService.loadWeatherData()
//        currentGradient = try await LocationGradient().getGradient(for: arp.location)
      } catch {
        print(error.localizedDescription)
      }
    }
//    .onAppear {
//      isExpanded = true
//    }
  }
}

struct HourlyForecastView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "clock")
          .font(.system(size: 14))
        Text("ПОЧАСОВОЙ ПРОГНОЗ")
          .font(.system(size: 13, weight: .medium))
      }
      .foregroundStyle(.white.opacity(0.6))
      .padding(.horizontal, 16)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
          ForEach(0..<24) { hour in
            VStack(spacing: 8) {
              Text(hour == 0 ? "Сейчас" : "\(hour):00")
                .font(.system(size: 15))
                .foregroundStyle(.white)
              
              Image(systemName: "cloud.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
              
              Text("\(16 - hour / 2)°")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
            }
            .frame(width: 60)
          }
        }
        .padding(.horizontal, 16)
      }
    }
    .padding(.vertical, 16)
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    }
  }
}

struct DailyForecastView: View {
  let days = ["Сегодня", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс", "Пн", "Вт"]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "calendar")
          .font(.system(size: 14))
        Text("ПРОГНОЗ НА 10 ДНЕЙ")
          .font(.system(size: 13, weight: .medium))
      }
      .foregroundStyle(.white.opacity(0.6))
      .padding(.horizontal, 16)
      .padding(.top, 4)
      
      VStack(spacing: 0) {
        ForEach(Array(days.enumerated()), id: \.offset) { index, day in
          HStack {
            Text(day)
              .font(.system(size: 17))
              .foregroundStyle(.white)
              .frame(width: 80, alignment: .leading)
            
            Image(systemName: "cloud.rain.fill")
              .font(.system(size: 20))
              .foregroundStyle(.white)
              .frame(width: 30)
            
            Spacer()
            
            Text("\(5 + index)°")
              .font(.system(size: 17))
              .foregroundStyle(.white.opacity(0.6))
              .frame(width: 40, alignment: .trailing)
            
            RoundedRectangle(cornerRadius: 2)
              .fill(
                LinearGradient(
                  colors: [.blue.opacity(0.3), .orange.opacity(0.3)],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .frame(width: 80, height: 4)
              .padding(.horizontal, 8)
            
            Text("\(15 - index)°")
              .font(.system(size: 17))
              .foregroundStyle(.white)
              .frame(width: 40, alignment: .leading)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          
          if index < days.count - 1 {
            Divider()
              .background(.white.opacity(0.2))
              .padding(.leading, 16)
          }
        }
      }
      .padding(.vertical, 8)
    }
    .padding(.bottom, 16)
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    }
  }
}

struct WeatherDetailsView: View {
  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
      DetailCard(
        icon: "sunrise.fill",
        title: "ВОСХОД",
        value: "6:42",
        subtitle: "Закат: 18:23"
      )
      
      DetailCard(
        icon: "wind",
        title: "ВЕТЕР",
        value: "15 км/ч",
        subtitle: "Порывы до 25 км/ч"
      )
      
      DetailCard(
        icon: "humidity.fill",
        title: "ВЛАЖНОСТЬ",
        value: "65%",
        subtitle: "Точка росы: 9°"
      )
      
      DetailCard(
        icon: "eye.fill",
        title: "ВИДИМОСТЬ",
        value: "10 км",
        subtitle: "Отличная видимость"
      )
      
      DetailCard(
        icon: "gauge.with.dots.needle.bottom.50percent",
        title: "ДАВЛЕНИЕ",
        value: "1013 мбар",
        subtitle: "Стабильное"
      )
      
      DetailCard(
        icon: "umbrella.fill",
        title: "ОСАДКИ",
        value: "0 мм",
        subtitle: "за последние 24 ч"
      )
    }
  }
}

struct DetailCard: View {
  let icon: String
  let title: String
  let value: String
  let subtitle: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 14))
        Text(title)
          .font(.system(size: 13, weight: .medium))
      }
      .foregroundStyle(.white.opacity(0.6))
      
      Text(value)
        .font(.system(size: 28, weight: .regular))
        .foregroundStyle(.white)
      
      Text(subtitle)
        .font(.system(size: 15))
        .foregroundStyle(.white.opacity(0.8))
      
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: 140)
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    }
  }
}

struct WeatherMapView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "map")
          .font(.system(size: 14))
        Text("КАРТА ОСАДКОВ")
          .font(.system(size: 13, weight: .medium))
      }
      .foregroundStyle(.white.opacity(0.6))
      .padding(.horizontal, 16)
      .padding(.top, 4)
      
      RoundedRectangle(cornerRadius: 12)
        .fill(.white.opacity(0.1))
        .frame(height: 200)
        .overlay {
          Text("Карта")
            .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    }
  }
}

struct AirQualityView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "aqi.medium")
          .font(.system(size: 14))
        Text("КАЧЕСТВО ВОЗДУХА")
          .font(.system(size: 13, weight: .medium))
      }
      .foregroundStyle(.white.opacity(0.6))
      .padding(.horizontal, 16)
      .padding(.top, 4)
      
      VStack(alignment: .leading, spacing: 8) {
        Text("42")
          .font(.system(size: 36, weight: .regular))
          .foregroundStyle(.white)
        
        Text("Хорошее")
          .font(.system(size: 20))
          .foregroundStyle(.white.opacity(0.8))
        
        Text("Качество воздуха считается удовлетворительным")
          .font(.system(size: 15))
          .foregroundStyle(.white.opacity(0.7))
          .padding(.top, 4)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
    }
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    }
  }
}

