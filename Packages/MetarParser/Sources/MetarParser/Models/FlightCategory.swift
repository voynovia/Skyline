/// FAA flight category based on ceiling and visibility.
///
/// Used to quickly assess weather conditions for flight planning.
/// Determined by the worse of ceiling or visibility criteria.
public enum FlightCategory: String, Sendable {
  /// Visual Flight Rules - ceiling > 3000 ft AND visibility > 5 SM
  case vfr = "VFR"

  /// Marginal VFR - ceiling 1000-3000 ft OR visibility 3-5 SM
  case mvfr = "MVFR"

  /// Instrument Flight Rules - ceiling 500-1000 ft OR visibility 1-3 SM
  case ifr = "IFR"

  /// Low IFR - ceiling < 500 ft OR visibility < 1 SM
  case lifr = "LIFR"
}
