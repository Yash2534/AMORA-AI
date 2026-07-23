import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/data/image_repository.dart';

class AmoraImageData {
  const AmoraImageData._();

  static String get profileAadhya =>
      ImageRepository.profileByName('Aadhya').imageUrl;
  static String get profileKavya =>
      ImageRepository.profileByName('Kavya').imageUrl;
  static String get profileRiya =>
      ImageRepository.profileByName('Riya').imageUrl;
  static String get profileAarav =>
      ImageRepository.profileByName('Aarav').imageUrl;
  static String get profileYash =>
      ImageRepository.profileByName('Yash').imageUrl;
  static String get profileAnanya =>
      ImageRepository.profileByName('Ananya').imageUrl;

  static String get eventCoffee =>
      ImageRepository.eventByName('Coffee Meetup').imageUrl;
  static String get eventGarba =>
      ImageRepository.eventByName('Garba Night').imageUrl;
  static String get eventRooftop =>
      ImageRepository.eventByName('Rooftop Dinner').imageUrl;
  static String get eventTravel =>
      ImageRepository.eventByName('Travel Club').imageUrl;
  static String get eventWorkshop =>
      ImageRepository.eventByName('Art Workshop').imageUrl;
  static String get eventSpeedDating =>
      ImageRepository.eventByName('Speed Dating').imageUrl;
  static String get eventMusicNight =>
      ImageRepository.eventByName('Music Night').imageUrl;
  static String get eventLuxuryDinner =>
      ImageRepository.eventByName('Rooftop Dinner').imageUrl;

  static String get dateSpotCafe =>
      ImageRepository.venueByName('Velvet Bean Luxury Cafe').imageUrl;
  static String get dateSpotRestaurant =>
      ImageRepository.venueByName('Saffron Room Fine Dining').imageUrl;
  static String get dateSpotLuxuryHotel =>
      ImageRepository.venueByName('Skyline Social Lounge').imageUrl;
  static String get dateSpotRooftop =>
      ImageRepository.venueByName('Rooftop 28').imageUrl;

  static const assetProfileYash = AppImages.profileYash;
  static const assetProfileAadhya = AppImages.profileAadhya;
  static const assetProfileKavya = AppImages.profileKavya;
  static const assetProfileAarav = AppImages.profileAarav;
  static const assetProfileRiya = AppImages.profileRiya;
  static const assetProfileAnanya = AppImages.profileAnanya;
  static const assetEventCoffee = AppImages.eventCoffee;
  static const assetEventGarba = AppImages.eventGarba;
  static const assetEventRooftop = AppImages.eventRooftop;
  static const assetDateSpotCafe = AppImages.dateSpotCafe;
  static const assetDateSpotRestaurant = AppImages.dateSpotRestaurant;
  static const assetLogo = AppImages.logo;

  static String profileAssetForName(String name) {
    return ImageRepository.profileByName(name).fallbackAsset;
  }

  static String initialsForName(String name) {
    return AppImages.initialsForName(name);
  }
}
