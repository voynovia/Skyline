////
////  MapWebView.swift
////  SkyPackage
////
////  Created by Igor Voynov on 10. 3. 25.
////
//
//import SwiftUI
//import WebKit
//
//private enum MessageName: String, CaseIterable {
//  case console
//  case zoom
//  case click
//}
//
//public struct MapWebView: UIViewRepresentable {
//    
//  @Binding var zoomLevel: Double
//  @Binding var showHypsometry: Bool
//  
//  public init(zoomLevel: Binding<Double>, showHypsometry: Binding<Bool>) {
//    self._zoomLevel = zoomLevel
//    self._showHypsometry = showHypsometry
//  }
//  
//  public func makeCoordinator() -> WebCoordinator {
//    WebCoordinator(parent: self)
//  }
//  
//  public func makeUIView(context: Context) -> WKWebView {
//    let contentController = WKUserContentController()
//    for name in MessageName.allCases {
//      contentController.add(context.coordinator, name: name.rawValue)
//    }
//    
//    let config = WKWebViewConfiguration()
//    config.userContentController = contentController
//    
//    let webView = WKWebView(frame: .zero, configuration: config)
//    webView.navigationDelegate = context.coordinator
//    webView.backgroundColor = .black
//    webView.translatesAutoresizingMaskIntoConstraints = false
//    
//    if let url = URL(string: "http://localhost:8080/index.html") {
//      webView.load(URLRequest(url: url))
//    }
//    
//    return webView
//  }
//  
//  public func updateUIView(_ uiView: WKWebView, context: Context) {
//    guard let superview = uiView.superview else { return }
//    NSLayoutConstraint.activate([
//      uiView.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
//      uiView.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
//      uiView.topAnchor.constraint(equalTo: superview.topAnchor),
//      uiView.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
//    ])
//    
//    let js: String
//    if showHypsometry {
//      let url = "http://localhost:8080/layers/hypsometry.json"
//      js = "window.postMessage('addLayer:\(url)', '*');"
//    } else {
//      js = "window.postMessage('removeLayer:hypsometry', '*');"
//    }
//    uiView.evaluateJavaScript(js, completionHandler: { _, err in
//      if let err {
//        print("window.postMessage error:", err)
//      }
//    })
//  }
//  
//}
//
//public class WebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
//
//  var parent: MapWebView
//  
//  init(parent: MapWebView) {
//    self.parent = parent
//  }
//  
//  // Получаем данные из JS
//  public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//    guard let messageName = MessageName(rawValue: message.name) else {
//      print("unknown message name: \(message.name)")
//      return
//    }
//    switch messageName {
//    case MessageName.console:
//      if let body = message.body as? [String: Any] {
//        let type = body["type"] as? String ?? "log"
//        let message = body["message"] as? String ?? ""
//        print("JS Console \(type): \(message)")
//      }
//    case MessageName.zoom:
//      break
////      if let zoom = message.body as? String, let zoomValue = Double(zoom) {
////        DispatchQueue.main.async {
////          self.parent.zoomLevel = zoomValue
////        }
////      }
//    case MessageName.click:
//      guard
//        let body = message.body as? [String: Any],
//        let lat = body["latitude"] as? Double,
//        let lon = body["longitude"] as? Double,
//        let layers = body["layers"] as? [[String: Any]]
//      else {
//        break
//      }
//      print("Tapped at \(lat), \(lon), layers: \(layers)")
//      for layer in layers {
//        guard
//          let properties = layer["properties"] as? [String: Any],
//          let table = properties["table"] as? String,
//          let id = properties["id"] as? String
//        else {
//          continue
//        }
//        print("under click id: \(id), table: \(table)")
//      }
//    }
//  }
//  
//}
