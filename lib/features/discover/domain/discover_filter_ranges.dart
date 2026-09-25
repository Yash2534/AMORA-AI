import 'package:amora_ai/features/profile/domain/profile_form_options.dart';

abstract final class DiscoverFilterRanges {
  static const double ageMinimum = 18;
  static const double ageMaximum = 45;
  static const double defaultMinimumAge = 18;
  static const double defaultMaximumAge = 45;

  static const double distanceMinimum = 1;
  static const double distanceMaximum = 300;
  static const double defaultDistance = 80;

  static const double compatibilityMinimum = 50;
  static const double compatibilityMaximum = 100;
  static const double defaultCompatibility = 80;

  static const double dealbreakerAgeMaximum = 60;
  static const double defaultDealbreakerMinimumAge = 24;
  static const double defaultDealbreakerMaximumAge = 34;
  static const double dealbreakerDistanceMinimum = 5;
  static const double dealbreakerDistanceMaximum = 100;
  static const double defaultDealbreakerDistance = 25;
}

class NormalizedFilterRange {
  const NormalizedFilterRange(this.start, this.end);

  final double start;
  final double end;
}

double normalizeFilterNumber(
  Object? raw, {
  required double minimum,
  required double maximum,
  required double fallback,
}) {
  assert(minimum <= maximum);
  final parsed = switch (raw) {
    num value => value.toDouble(),
    String value => double.tryParse(value.trim()),
    _ => null,
  };
  final value = parsed != null && parsed.isFinite ? parsed : fallback;
  return value.clamp(minimum, maximum).toDouble();
}

NormalizedFilterRange normalizeFilterRange({
  required Object? rawStart,
  required Object? rawEnd,
  required double minimum,
  required double maximum,
  required double fallbackStart,
  required double fallbackEnd,
}) {
  final start = normalizeFilterNumber(
    rawStart,
    minimum: minimum,
    maximum: maximum,
    fallback: fallbackStart,
  );
  final end = normalizeFilterNumber(
    rawEnd,
    minimum: minimum,
    maximum: maximum,
    fallback: fallbackEnd,
  );
  return start <= end
      ? NormalizedFilterRange(start, end)
      : NormalizedFilterRange(end, start);
}

int? normalizeMinimumHeight(Object? raw) {
  if (raw == null || (raw is String && raw.trim().isEmpty)) return null;
  final parsed = switch (raw) {
    num value => value.toDouble(),
    String value => double.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null || !parsed.isFinite) return null;
  return parsed.round().clamp(
    ProfileFormOptions.minimumSupportedHeightCm,
    ProfileFormOptions.maximumSupportedHeightCm,
  );
}
