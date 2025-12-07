import FlyingFox

extension HTTPHeader {
  static let accessControlAllowOrigin  = HTTPHeader("Access-Control-Allow-Origin")
  static let accessControlAllowMethods = HTTPHeader("Access-Control-Allow-Methods")
  static let accessControlAllowHeaders = HTTPHeader("Access-Control-Allow-Headers")
  static let range                     = HTTPHeader("Range")
  static let contentRange              = HTTPHeader("Content-Range")
  static let acceptRanges              = HTTPHeader("Accept-Ranges")
}
