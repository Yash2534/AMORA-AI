/// Frontend-only product visibility switches.
abstract final class AppFeatureFlags {
  /// Events is temporarily hidden from the frontend. Keep all implementation
  /// intact for future re-enablement.
  static const bool eventsEnabled = false;
}
