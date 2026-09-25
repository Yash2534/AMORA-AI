import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/settings/presentation/likes_super_likes_screen.dart';

class NotificationDestination {
  const NotificationDestination(this.route, {this.arguments});

  final String route;
  final Object? arguments;
}

abstract final class NotificationDeepLink {
  static const _allowedRoutes = <String>{
    ChatDetailScreen.routeName,
    MatchesScreen.routeName,
    NotificationsHubScreen.routeName,
    ProfileDetailScreen.routeName,
    LikesSuperLikesScreen.routeName,
  };

  static NotificationDestination resolve(Map<String, dynamic> data) {
    final type = _clean(data['type']).toLowerCase();
    final category = _clean(data['category']).toLowerCase();
    final requestedRoute = _clean(data['route']);
    final conversationId = _safeId(data['conversationId']);
    final targetUserId =
        _safeId(data['targetUserId']) ?? _safeId(data['userId']);

    if (requestedRoute.isNotEmpty && _allowedRoutes.contains(requestedRoute)) {
      final requested = _forRoute(
        requestedRoute,
        conversationId: conversationId,
        targetUserId: targetUserId,
      );
      if (requested != null) return requested;
    }

    if (type == 'new_message' ||
        category == 'message' ||
        category == 'messages') {
      if (conversationId != null) {
        return NotificationDestination(
          ChatDetailScreen.routeName,
          arguments: ChatDetailArgs(
            conversationId: conversationId,
            recipientId: targetUserId,
          ),
        );
      }
    }
    if (type == 'new_match' || category == 'match' || category == 'matches') {
      return const NotificationDestination(MatchesScreen.routeName);
    }
    if (type == 'new_like' ||
        type == 'new_super_like' ||
        type == 'rose_received' ||
        category == 'likes' ||
        category == 'super likes') {
      if (targetUserId != null) {
        return NotificationDestination(
          ProfileDetailScreen.routeName,
          arguments: targetUserId,
        );
      }
      return const NotificationDestination(LikesSuperLikesScreen.routeName);
    }
    return const NotificationDestination(NotificationsHubScreen.routeName);
  }

  static NotificationDestination? _forRoute(
    String route, {
    required String? conversationId,
    required String? targetUserId,
  }) {
    return switch (route) {
      ChatDetailScreen.routeName when conversationId != null =>
        NotificationDestination(
          route,
          arguments: ChatDetailArgs(
            conversationId: conversationId,
            recipientId: targetUserId,
          ),
        ),
      ProfileDetailScreen.routeName when targetUserId != null =>
        NotificationDestination(route, arguments: targetUserId),
      MatchesScreen.routeName ||
      NotificationsHubScreen.routeName ||
      LikesSuperLikesScreen.routeName => NotificationDestination(route),
      _ => null,
    };
  }

  static String _clean(Object? value) => value?.toString().trim() ?? '';

  static String? _safeId(Object? value) {
    final clean = _clean(value);
    return RegExp(r'^[1-9]\d*$').hasMatch(clean) ? clean : null;
  }
}
