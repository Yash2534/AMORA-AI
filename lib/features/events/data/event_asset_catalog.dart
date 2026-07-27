/// Local editorial imagery available to the Events presentation layer.
///
/// The resolver deliberately maps by event meaning instead of list position so
/// cards remain visually correct if the repository order changes.
abstract final class EventAssetCatalog {
  static const coffee = 'assets/images/events/coffee_meetup.png';
  static const garba = 'assets/images/events/garba_night.png';
  static const liveMusic = 'assets/images/events/live_music.png';
  static const heritageFoodWalk = 'assets/images/events/old_city_food_walk.png';
  static const foundersMixer =
      'assets/images/events/startup_networking_mixer.png';

  static const all = <String>[
    coffee,
    garba,
    liveMusic,
    heritageFoodWalk,
    foundersMixer,
  ];

  static String forEvent({required String title, required String category}) {
    final value = '$title $category'.toLowerCase();
    if (_containsAny(value, const [
      'startup',
      'founder',
      'network',
      'professional',
      'business',
      'creator',
    ])) {
      return foundersMixer;
    }
    if (_containsAny(value, const ['garba', 'festival', 'dance'])) {
      return garba;
    }
    if (_containsAny(value, const [
      'coffee',
      'cafe',
      'book',
      'mindful',
      'dessert',
      'workshop',
    ])) {
      return coffee;
    }
    if (_containsAny(value, const [
      'music',
      'sufi',
      'comedy',
      'movie',
      'night',
      'rooftop',
    ])) {
      return liveMusic;
    }
    if (_containsAny(value, const [
      'food',
      'heritage',
      'museum',
      'culture',
      'thali',
      'trail',
      'walk',
      'travel',
      'trek',
      'cycling',
      'lake',
      'outdoor',
    ])) {
      return heritageFoodWalk;
    }
    return coffee;
  }

  static bool _containsAny(String source, List<String> needles) =>
      needles.any(source.contains);
}
