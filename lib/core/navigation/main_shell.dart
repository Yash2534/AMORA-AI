import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';

/// Persistent five-tab application shell.
///
/// IndexedStack keeps each tab subtree alive, including its scroll position and
/// local presentation state. Secondary routes continue to use the root
/// Navigator, so Back returns to the selected tab without creating tab stacks.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = AmoraNavTab.discover});

  static const routeName = '/main';

  final AmoraNavTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late AmoraNavTab _activeTab;

  static const _tabs = <AmoraNavTab>[
    AmoraNavTab.discover,
    AmoraNavTab.chats,
    AmoraNavTab.matches,
    AmoraNavTab.events,
    AmoraNavTab.profile,
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = _tabs.contains(widget.initialTab)
        ? widget.initialTab
        : AmoraNavTab.discover;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            key: const ValueKey('main-shell-navigation-content-inset'),
            data: media.copyWith(
              padding: media.padding.copyWith(
                bottom: FloatingBottomNav.navigationHeightFor(context),
              ),
            ),
            child: IndexedStack(
              index: _tabs.indexOf(_activeTab),
              children: const [
                BrowseGridScreen(showNavigation: false),
                ChatListScreen(showNavigation: false),
                MatchesScreen(showNavigation: false),
                EventsScreen(showNavigation: false),
                ProfileScreen(showNavigation: false),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FloatingBottomNav(
        activeTab: _activeTab,
        onTabSelected: (tab) {
          if (tab == _activeTab) return;
          setState(() => _activeTab = tab);
        },
      ),
    );
  }
}
