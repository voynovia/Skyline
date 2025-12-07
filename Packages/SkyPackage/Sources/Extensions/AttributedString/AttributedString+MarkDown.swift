//
//  AttributedString+MarkDown.swift
//  SkyPackage
//
//  Created by Igor Voynov on 8. 3. 25.
//

import Foundation
import UIKit

public extension AttributedString {
  
  init(styledMarkdown markdownString: String) throws {
    var output = try AttributedString(
      markdown: markdownString,
      options: .init(
        allowsExtendedAttributes: true,
        interpretedSyntax: .full,
        failurePolicy: .returnPartiallyParsedIfPossible
      ),
      baseURL: nil
    )
    
    for (intentBlock, intentRange) in output.runs[AttributeScopes.FoundationAttributes.PresentationIntentAttribute.self].reversed() {
//      guard let intentBlock = intentBlock else { continue }
//      for intent in intentBlock.components {
//        switch intent.kind {
//        case .header(level: let level):
//          switch level {
//          case 1:
//            output[intentRange].font = .avenirNextCondensed(.title, weight: .bold)
//          case 2:
//            output[intentRange].font = .avenirNextCondensed(.title2, weight: .bold)
//          case 3:
//            output[intentRange].font = .avenirNextCondensed(.title3, weight: .bold)
//          default:
//            break
//          }
//        default:
//          break
//        }
//      }
      
      if intentRange.lowerBound != output.startIndex {
        output.characters.insert(contentsOf: "\n", at: intentRange.lowerBound)
      }
    }
    
    self = output
  }
  
}
