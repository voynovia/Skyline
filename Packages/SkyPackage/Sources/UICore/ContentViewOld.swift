//
//  ContentViewOld.swift
//  SkyPackage
//
//  Created by Igor Vojnov on 04.10.2025.
//

import SwiftUI

public struct ContentViewOld: View {
  
  public init() {}
  
  @State private var searchText: String = ""
  @State private var expandMiniPlayer: Bool = false
  @Namespace private var animation
  
  public var body: some View {
//    NotamView()
    Group {
      if #available(iOS 26, *) {
        NativeTabView()
          .tabBarMinimizeBehavior(.onScrollDown)
          .tabViewBottomAccessory {
            MiniPlayerView()
              .matchedTransitionSource(id: "MINIPLAYER", in: animation)
              .onTapGesture {
                expandMiniPlayer.toggle()
              }
          }
      } else {
        NativeTabView(60)
          .overlay(alignment: .bottom) {
            MiniPlayerView()
              .padding(.vertical, 8)
              .background(.ultraThinMaterial, in: .rect(cornerRadius: 15, style: .continuous))
              .matchedTransitionSource(id: "MINIPLAYER", in: animation)
              .onTapGesture {
                expandMiniPlayer.toggle()
              }
              .offset(y: -60)
              .padding(.horizontal, 15)
          }
          .ignoresSafeArea(.keyboard, edges: .all)
      }
    }
    .fullScreenCover(isPresented: $expandMiniPlayer) {
      ScrollView {
        
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        VStack(spacing: 10) {
          // Drag Indicator Mimick
          Capsule()
            .fill(.primary.secondary)
            .frame(width: 35, height: 3)
          HStack(spacing: 0) {
            PlayerInfo(.init(width: 80, height: 80))
            Spacer(minLength: 0)
            /// Expanded actions
            Group {
              Button("", systemImage: "star.circle.fill") {
                
              }
              Button("", systemImage: "ellipsis.circle.fill") {
                
              }
            }
            .font(.title)
            .foregroundStyle(Color.primary, Color.primary.opacity(0.1))
          }
          .padding(.horizontal, 15)
        }
        .navigationTransition(.zoom(sourceID: "MINIPLAYER", in: animation))
      }
      /// To Avoid Transparency!
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.background)
    }
  }
  
  @ViewBuilder
  func NativeTabView(_ safeAreaBottomPadding: CGFloat = 0) -> some View {
    TabView {
      Tab.init("Home", systemImage: "house.fill") {
        NavigationStack {
          List {
            
          }
          .navigationTitle("Home")
          .safeAreaPadding(.bottom, safeAreaBottomPadding)
        }
      }
      Tab.init("New", systemImage: "square.grid.2x2.fill") {
        NavigationStack {
          List {
            
          }
          .navigationTitle("What's new")
          .safeAreaPadding(.bottom, safeAreaBottomPadding)
        }
      }
      Tab.init("Radio", systemImage: "dot.radiowaves.left.and.right") {
        NavigationStack {
          List {
            
          }
          .navigationTitle("Radio")
          .safeAreaPadding(.bottom, safeAreaBottomPadding)
        }
      }
      Tab.init("Library", systemImage: "square.stack.fill") {
        NavigationStack {
          List {
            
          }
          .navigationTitle("Library")
          .safeAreaPadding(.bottom, safeAreaBottomPadding)
        }
      }
      Tab.init("Search", systemImage: "magnifyingglass", role: .search) {
        NavigationStack {
          List {
            
          }
          .navigationTitle("Search")
          .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search..."))
          .safeAreaPadding(.bottom, safeAreaBottomPadding)
        }
      }
    }
  }
  
  /// Reusable Player Info
  @ViewBuilder
  func PlayerInfo(_ size: CGSize) -> some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: size.height / 4)
        .fill(.blue.gradient)
        .frame(width: size.width, height: size.height)
      VStack(alignment: .leading, spacing: 6) {
        Text("Some Apple Music Title")
          .font(.callout)
        Text("Some Artist Name")
          .font(.caption2)
          .foregroundStyle(.gray)
      }
      .lineLimit(1)
    }
  }
  
  /// MiniPLayer View
  @ViewBuilder
  func MiniPlayerView() -> some View {
    HStack(spacing: 15) {
      PlayerInfo(.init(width: 30, height: 30))
      Spacer(minLength: 0)
      /// Action buttons
      Button {
        
      } label: {
        Image(systemName: "play.fill")
          .contentShape(.rect)
      }
      .padding(.trailing, 10)
      
      Button {
        
      } label: {
        Image(systemName: "forward.fill")
          .contentShape(.rect)
      }
    }
    .foregroundStyle(Color.primary)
    .padding(.horizontal, 15)
  }
  
}

#Preview {
  ContentView()
}

//import UIMap
//import SrvHttpServer
//public struct ContentView: View {
//
////  @State private var server: HttpServer?
//
//  @State private var zoomLevel: Double = 0.0
//  @State private var showHypsometry: Bool = false
//
//  public init() {}
//
//  public var body: some View {
//    ZStack(alignment: .bottomLeading) {
////      MapNativeView()
//      MapWebView(zoomLevel: $zoomLevel, showHypsometry: $showHypsometry)
////        .task {
////          server = TileServer()
////          await server?.startServer()
////        }
//      HStack {
//        Text("Zoom: \(zoomLevel, specifier: "%.2f")")
//          .font(.headline)
//          .foregroundStyle(Color.red)
//          .padding()
//        Button((showHypsometry ? "hide" : "show") + " hypsometry") {
//          showHypsometry.toggle()
//        }
//      }
//
//    }
//    .background(Color.black)
//    .frame(width: .infinity, height: .infinity)
//  }
//
//}
