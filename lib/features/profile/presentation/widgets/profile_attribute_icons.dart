import 'package:flutter/material.dart';

/// Canonical semantic icon mapping for profile attributes rendered across the
/// editable profile and public profile surfaces.
abstract final class ProfileAttributeIcons {
  static const IconData pronouns = Icons.person_outline_rounded;

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
    if (value.contains('travel') || value.contains('road')) {
      return Icons.flight_takeoff_rounded;
    }
    if (value.contains('coffee')) {
      return Icons.coffee_rounded;
    }
    if (value.contains('music') || value.contains('concert')) {
      return Icons.music_note_rounded;
    }
    if (value.contains('yoga') ||
        value.contains('fitness') ||
        value.contains('gym')) {
      return Icons.fitness_center_rounded;
    }
    if (value.contains('photo')) {
      return Icons.photo_camera_outlined;
    }
    if (value.contains('dog') || value.contains('pet')) {
      return Icons.pets_rounded;
    }
    if (value.contains('movie') || value.contains('cinema')) {
      return Icons.movie_outlined;
    }
    if (value.contains('art') || value.contains('design')) {
      return Icons.palette_outlined;
    }
    if (value.contains('food') || value.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('game')) {
      return Icons.sports_esports_rounded;
    }
    if (value.contains('book')) {
      return Icons.menu_book_rounded;
    }
    return Icons.interests_rounded;
  }
}
