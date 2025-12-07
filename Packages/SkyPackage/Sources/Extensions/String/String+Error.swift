//
//  String+Error.swift
//  SkyPackage
//
//  Created by Igor Voynov on 3. 6. 25.
//

import Foundation

extension String: @retroactive LocalizedError {
  public var errorDescription: String? { return self }
}
