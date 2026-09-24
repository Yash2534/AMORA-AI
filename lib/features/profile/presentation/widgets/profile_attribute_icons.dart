import 'package:flutter/material.dart';

/// Canonical semantic icon mapping for profile attributes rendered across the
/// editable profile and public profile surfaces.
abstract final class ProfileAttributeIcons {
  static const IconData pronouns = Icons.person_outline_rounded;
  static const IconData height = Icons.straighten_rounded;
  static const IconData education = Icons.school_rounded;
  static const IconData profession = Icons.work_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData languages = Icons.language_rounded;
  static const IconData relationshipIntent = Icons.favorite_border_rounded;
  static const IconData communicationStyle = Icons.chat_rounded;
  static const IconData lifestyle = Icons.self_improvement_rounded;
  static const IconData aboutMe = Icons.auto_awesome_rounded;

  static IconData smoking(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('never') ||
        normalized == 'no' ||
        normalized.contains('non-smoker')) {
      return Icons.smoke_free_rounded;
    }
    if (normalized.contains('sometimes') || normalized.contains('social')) {
      return Icons.smoking_rooms_outlined;
    }
    if (normalized.contains('yes') || normalized.contains('regular')) {
      return Icons.smoking_rooms_rounded;
    }
    return Icons.lock_outline_rounded;
  }

  static IconData interest(String label) {
    final value = label.trim().toLowerCase();
    if (value.contains('travel') || value.contains('road') || value.contains('trip')) {
      return Icons.flight_takeoff_rounded;
    }
    if (value.contains('cafe') || value.contains('coffee')) {
      return Icons.local_cafe_rounded;
    }
    if (value.contains('cook') || value.contains('food') || value.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('book') || value.contains('read')) {
      return Icons.menu_book_rounded;
    }
    if (value.contains('photo') || value.contains('camera')) {
      return Icons.photo_camera_rounded;
    }
    if (value.contains('yoga')) {
      return Icons.self_improvement_rounded;
    }
    if (value.contains('beach') || value.contains('ocean') || value.contains('sea')) {
      return Icons.beach_access_rounded;
    }
    if (value.contains('music') || value.contains('concert')) {
      return Icons.music_note_rounded;
    }
    if (value.contains('fitness') || value.contains('gym') || value.contains('workout')) {
      return Icons.fitness_center_rounded;
    }
    if (value.contains('dog') || value.contains('cat') || value.contains('pet')) {
      return Icons.pets_rounded;
    }
    if (value.contains('movie') || value.contains('cinema') || value.contains('film')) {
      return Icons.movie_rounded;
    }
    if (value.contains('art') || value.contains('paint') || value.contains('design')) {
      return Icons.palette_rounded;
    }
    if (value.contains('game') || value.contains('gaming')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.interests_rounded;
  }
}

