import UIKit
import SwiftUI

//VStack {
//  FontFallbackFinder(character: "►", font: UIFont(name: "AvenirNextCondensed-Bold", size: 20)!)
//    .frame(height: 0) // Мы не отображаем представление, оно используется только для логики
//}

public struct FontFallbackFinder: UIViewRepresentable {
  
  private let character: Character
  private let font: UIFont
  
  public init(character: Character, font: UIFont) {
    self.character = character
    self.font = font
  }
  
  public class Coordinator: NSObject {
    var parent: FontFallbackFinder
    
    init(parent: FontFallbackFinder) {
      self.parent = parent
    }
    
    func findFallbackFont() -> UIFont? {
      let attributedString = NSAttributedString(string: String(parent.character), attributes: [.font: parent.font])
      let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
      textView.attributedText = attributedString
      
      let layoutManager = textView.layoutManager
      let textStorage = textView.textStorage
      let glyphRange = layoutManager.glyphRange(forBoundingRect: textView.bounds, in: textView.textContainer)
      
      var actualFont: UIFont? = nil
      textStorage.enumerateAttribute(.font, in: glyphRange, options: []) { (value, range, stop) in
        if let usedFont = value as? UIFont {
          actualFont = usedFont
          stop.pointee = true
        }
      }
      
      return actualFont
    }
  }
  
  public func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }
  
  public func makeUIView(context: Context) -> UIView {
    let view = UIView()
    
    DispatchQueue.main.async {
      let fallbackFont = context.coordinator.findFallbackFont()
      if let fallbackFont = fallbackFont, fallbackFont.fontName != font.fontName {
        print("Для символа '\(character)' используется шрифт подмены: \(fallbackFont.fontName)")
      } else {
        print("Символ '\(character)' доступен в исходном шрифте \(font.fontName)")
      }
    }
    
    return view
  }
  
  public func updateUIView(_ uiView: UIView, context: Context) {}
  
}
