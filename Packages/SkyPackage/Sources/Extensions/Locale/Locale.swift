import Foundation

public extension Locale {
  
  enum SupportedLanguageCode: String, Equatable, CaseIterable {
    case en
    case ru
    //case es
    
    public var description: String {
      switch self {
      case .en: return "English"
      case .ru: return "Русский"
      }
    }
  }
  
  var currentLanguage: SupportedLanguageCode? {
    guard let code = (UserDefaults.standard.value(forKey: "AppleLanguages") as? [String])?.first else { return nil }
    return SupportedLanguageCode(rawValue: code)
  }
  
  func setENG() {
    guard
      let code = SupportedLanguageCode(rawValue: "en")
    else { return }
    set(language: code)
  }
  
  private func set(language: SupportedLanguageCode) {
    UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
  }
  
//  private var supportedLanguages: [SupportedLanguageCode] {
//    SupportedLanguageCode.allCases
//  }
  
//  private func check() {
//    guard
//      currentLanguage == nil,
//      let lang = Locale.current.languageCode,
//      let code = SupportedLanguageCode(rawValue: lang)
//    else { return }
//    set(language: code)
//  }

}
