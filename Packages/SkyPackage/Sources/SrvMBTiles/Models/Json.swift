//
//  Json.swift
//  geojsonMerge
//
//  Created by Igor Voynov on 7. 5. 24.
//

import Foundation

struct Json: Codable {
  let vectorLayers: [VectorLayer]
  enum CodingKeys: String, CodingKey {
    case vectorLayers = "vector_layers"
  }
}

struct VectorLayer: Codable {
  let id, description: String
  let minzoom, maxzoom: Int
//  let fields: Fields
}

//struct Fields: Codable {
//  let idapron: String
//}

//{
//    "vector_layers":
//    [
//        {
//            "id": "abApronElement",
//            "description": "",
//            "minzoom": 9,
//            "maxzoom": 18,
//            "fields":
//            {
//                "idapron": "String"
//            }
//        }
//    ]
//}
