import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:flutter/material.dart';

/// Compatibility route alias for the single canonical Discover experience.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  static const routeName = '/discover';

  @override
  Widget build(BuildContext context) => const BrowseGridScreen();
}
