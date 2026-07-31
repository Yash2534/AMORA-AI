import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:flutter/widgets.dart';

class AppImages {
  const AppImages._();

  static const _root = 'assets/images/profiles';
  static const _eventRoot = 'assets/images/events';

  static const logo = AmoraBrandAssets.icon;
  static const defaultAvatar = '$_root/female/profile_fallback_female.jpg';
  static const fallbackProfile = '$_root/female/profile_fallback_female.jpg';
  static const femaleProfileFallback =
      '$_root/female/profile_fallback_female.jpg';
  static const maleProfileFallback = '$_root/male/male_05.jpg';
  static const fallbackMaleProfile = maleProfileFallback;

  static const profileAadhya = '$_root/female/female_01.png';
  static const profileKavya = '$_root/female/female_02.png';
  static const profileRiya = '$_root/female/female_03.png';
  static const profileAnanya = '$_root/female/female_04.png';
  static const profileYash = '$_root/male/male_02.png';
  static const profileAarav = '$_root/male/male_01.png';

  static const networkProfileKavya = profileKavya;
  static const networkProfileAarav = profileAarav;

  static const eventCoffee = '$_eventRoot/coffee_meetup.png';
  static const eventCoffeeMeetup = eventCoffee;
  static const eventGarba = '$_eventRoot/garba_night.png';
  static const eventGarbaNight = eventGarba;
  static const eventRooftop = '$_eventRoot/startup_networking_mixer.png';
  static const eventWorkshop = '$_eventRoot/old_city_food_walk.png';
  static const eventPremiumCafe = '$_eventRoot/live_music.png';
  static const fallbackEvent = eventCoffee;

  static const dateSpotCafe = eventCoffee;
  static const dateSpotRestaurant = '$_eventRoot/old_city_food_walk.png';
  static const dateSpotRooftopOnline =
      '$_eventRoot/startup_networking_mixer.png';
  static const fallbackDateSpot = dateSpotRestaurant;

  static const _femaleProfiles = [
    '$_root/female/female_01.png',
    '$_root/female/female_02.png',
    '$_root/female/female_03.png',
    '$_root/female/female_04.png',
    '$_root/female/female_05.png',
    '$_root/female/female_06.png',
    '$_root/female/female_07.png',
    '$_root/female/female_08.png',
    '$_root/female/female_09.png',
    '$_root/female/female_10.png',
    '$_root/female/female_11.png',
    '$_root/female/female_12.png',
    '$_root/female/female_13.png',
    '$_root/female/female_14.png',
    '$_root/female/female_15.png',
    '$_root/female/female_16.png',
    '$_root/female/female_17.png',
    '$_root/female/female_18.png',
    '$_root/female/female_19.png',
    '$_root/female/female_20.png',
  ];

  static const _maleProfiles = [
    '$_root/male/male_01.png',
    '$_root/male/male_02.png',
    '$_root/male/male_03.png',
    '$_root/male/male_04.png',
    '$_root/male/male_05.jpg',
    '$_root/male/male_06.jpg',
    '$_root/male/male_07.jpg',
    '$_root/male/male_08.jpg',
    '$_root/male/male_09.jpg',
    '$_root/male/male_10.jpg',
    '$_root/male/male_11.jpg',
    '$_root/male/male_12.jpg',
    '$_root/male/male_13.jpg',
    '$_root/male/male_14.jpg',
    '$_root/male/male_15.jpg',
    '$_root/male/male_16.jpg',
    '$_root/male/male_17.jpg',
    '$_root/male/male_18.jpg',
    '$_root/male/male_19.jpg',
    '$_root/male/male_20.jpg',
  ];

  static const _events = [
    eventCoffee,
    eventGarba,
    eventPremiumCafe,
    eventWorkshop,
    eventRooftop,
  ];

  static const _dateSpots = [
    dateSpotCafe,
    dateSpotRestaurant,
    dateSpotRooftopOnline,
    eventPremiumCafe,
    eventGarba,
  ];

  static String profileAt(int index, {required bool male}) {
    final source = male ? _maleProfiles : _femaleProfiles;
    return source[index % source.length];
  }

  static List<String> galleryForIndex(int index, {required bool male}) {
    final gender = male ? 'male' : 'female';
    final oneBased = (index % 20) + 1;
    final prefix = oneBased.toString().padLeft(2, '0');
    final extension = male && oneBased >= 5 ? 'jpg' : 'png';
    final maxCount =
        (!male && (oneBased == 3 || oneBased == 7)) ||
            (male && (oneBased == 3 || oneBased == 8))
        ? 2
        : 3;
    return [
      for (var i = 1; i <= maxCount; i++)
        '$_root/profile_gallery/${gender}_${prefix}_gallery_${i.toString().padLeft(2, '0')}.$extension',
    ];
  }

  static String eventAt(int index) => _events[index % _events.length];

  static String dateSpotAt(int index) => _dateSpots[index % _dateSpots.length];

  static String profileForName(String name) {
    final first = name.trim().toLowerCase().split(RegExp(r'\s+')).first;
    return switch (first) {
      'aadhya' => profileAadhya,
      'kavya' => profileKavya,
      'riya' => profileRiya,
      'ananya' => profileAnanya,
      'yash' => profileYash,
      'aarav' => profileAarav,
      _ => profileAt(_stableIndex(first), male: _looksMale(first)),
    };
  }

  static String initialsForName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AM';
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1
        ? parts.last.characters.first.toUpperCase()
        : '';
    return '$first$second';
  }

  static String resolveAsset(
    String? asset, {
    String fallback = fallbackProfile,
  }) {
    if (asset == null || asset.trim().isEmpty) return fallback;
    final value = asset.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return fallback;
    }
    return value;
  }

  static void precacheCore(BuildContext context) {
    for (final asset in const [
      logo,
      fallbackProfile,
      maleProfileFallback,
      profileAadhya,
      profileKavya,
      profileAarav,
      profileYash,
      eventCoffee,
      eventGarba,
      dateSpotRestaurant,
    ]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  static int _stableIndex(String seed) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static bool _looksMale(String firstName) {
    const maleNames = {
      'aarav',
      'aditya',
      'arjun',
      'dhruv',
      'kabir',
      'rohan',
      'yash',
      'vihaan',
      'neil',
      'samar',
    };
    return maleNames.contains(firstName);
  }
}
