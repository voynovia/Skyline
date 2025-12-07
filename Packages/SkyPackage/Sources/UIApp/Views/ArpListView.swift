import CoreLocation
import SwiftUI

// https://youtu.be/IiLDbrtBsn0

public struct ArpListView: View {

  @State private var cities = Arp.sampleCities
  @State private var searchText = ""
  @Namespace private var namespace

  @State private var currentGradient: GradientColors = .init([])

  public var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: currentGradient.colors.isEmpty
            ? [] : Array(repeating: currentGradient.colors[1], count: 2),
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
          VStack {
            ForEach(cities) { arp in
              //              CityCardButtonView(city: city)
              NavigationLink(value: arp) {
                ArpCardView(arp: arp)
              }
              .buttonStyle(
                FluidZoomTransitionButtonStyle(
                  id: arp.id.uuidString,
                  namespace: namespace,
                  shape: .rect(cornerRadius: 20),
                  glass: .identity
                ))
            }
          }
          .padding(.horizontal, 8)
          .padding(.top, 16)
          .padding(.bottom, 100)
        }

        VStack {
          Spacer()

          SearchBarView(text: $searchText)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
      }

      // navigationBar
      .navigationTitle("Airports")
      .navigationDestination(for: Arp.self) { arp in
        ArpDetailView(arp: arp)
          .navigationTransition(.zoom(sourceID: arp.id, in: namespace))
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            // действие (например: открыть настройки)
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
      .toolbarTitleDisplayMode(.inlineLarge)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbarColorScheme(.dark, for: .navigationBar)  // статус бар белым цветом
      .containerBackground(.black, for: .navigation)  // обязательно
    }
    .background(.black)  // обязательно
    .task {
      do {
        currentGradient = try await LocationGradient().getGradient(
          for: CLLocationCoordinate2D(latitude: 46.48, longitude: 15.686111))
      } catch {
        print(error.localizedDescription)
      }
    }
  }

}

// https://www.youtube.com/watch?v=DM0w25Ko4p4
struct CityCardButtonView: View {
  let city: Arp

  @State private var isExpanded: Bool = false
  @Namespace private var animation

  var body: some View {
    Button {
      isExpanded.toggle()
    } label: {
      ArpCardView(arp: city)
    }
    .buttonStyle(
      FluidZoomTransitionButtonStyle(
        id: city.id.uuidString, namespace: animation, shape: .rect(cornerRadius: 20),
        glass: .identity)
    )
    .sheet(isPresented: $isExpanded) {
      //      CityDetailView(city: city, isExpanded: $isExpanded)
      //        .navigationTransition(.zoom(sourceID: city.id, in: animation))
    }
  }
}

struct FluidZoomTransitionButtonStyle<S: Shape>: ButtonStyle {
  var id: String
  var namespace: Namespace.ID
  var shape: S
  var glass: Glass
  @State private var hapticsTrigger: Bool = false
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .matchedTransitionSource(id: id, in: namespace)
      .glassEffect(glass.interactive(), in: shape)
      .sensoryFeedback(.impact, trigger: hapticsTrigger)
      .onChange(of: configuration.isPressed) { oldValue, newValue in
        guard newValue else { return }
        /// Since isPressed will become false when interaction is finished!
        hapticsTrigger.toggle()
      }
  }
}

struct SearchBarView: View {
  @Binding var text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 18))
        .foregroundStyle(.white.opacity(0.6))

      TextField(
        "", text: $text,
        prompt: Text("Поиск города или аэропорта")
          .foregroundStyle(.white.opacity(0.4))
      )
      .foregroundStyle(.white)
      .font(.system(size: 17))

      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 18))
            .foregroundStyle(.white.opacity(0.6))
        }
      } else {
        Button {
          // microphone action
        } label: {
          Image(systemName: "mic.fill")
            .font(.system(size: 18))
            .foregroundStyle(.white.opacity(0.6))
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
    }
  }
}
