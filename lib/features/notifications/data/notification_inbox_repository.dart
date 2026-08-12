import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:flutter/foundation.dart';

class InboxNotificationActor {
  const InboxNotificationActor({
    required this.userId,
    required this.name,
    this.photoUrl,
  });

  final String userId;
  final String name;
  final String? photoUrl;

  factory InboxNotificationActor.fromJson(Map<String, dynamic> json) =>
      InboxNotificationActor(
        userId: json['userId']?.toString() ?? '',
        name: json['name']?.toString().trim() ?? '',
        photoUrl: json['photoUrl']?.toString(),
      );
}

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.data,
    this.readAt,
    this.actor,
  });

  final String id;
  final String type;
  final String category;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final InboxNotificationActor? actor;

  String get displayTitle {
    final actorName = actor?.name.trim() ?? '';
    if (actorName.isEmpty) return title;
    return switch (type) {
      'like' || 'new_like' => '$actorName liked your profile',
      'superLike' || 'new_super_like' => '$actorName Super Liked you',
      _ => title,
    };
  }

  factory InboxNotification.fromJson(Map<String, dynamic> json) =>
      InboxNotification(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'system',
        category: json['category']?.toString() ?? 'Security',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        isRead: json['isRead'] == true,
        readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        data: ((json['data'] as Map?) ?? const <String, dynamic>{})
            .cast<String, dynamic>(),
        actor: json['actor'] is Map
            ? InboxNotificationActor.fromJson(
                (json['actor'] as Map).cast<String, dynamic>(),
              )
            : null,
      );
}

abstract interface class NotificationInboxRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}

class AuthNotificationInboxRemoteDataSource
    implements NotificationInboxRemoteDataSource {
  const AuthNotificationInboxRemoteDataSource();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => AuthService.instance.authenticatedRequest(method, path, body: body);
}

class NotificationInboxRepository extends ChangeNotifier {
  NotificationInboxRepository({NotificationInboxRemoteDataSource? remote})
    : _remote = remote ?? const AuthNotificationInboxRemoteDataSource();

  static final instance = NotificationInboxRepository();
  final NotificationInboxRemoteDataSource _remote;

  final List<InboxNotification> _notifications = <InboxNotification>[];
  List<InboxNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool loading = false;
  bool loadingMore = false;
  String? error;
  int unreadCount = 0;
  bool hasMore = false;
  int? _nextPage;
  String _filter = 'All';

  void clearSessionState() {
    _notifications.clear();
    loading = false;
    loadingMore = false;
    error = null;
    unreadCount = 0;
    hasMore = false;
    _nextPage = null;
    _filter = 'All';
    notifyListeners();
  }

  Future<void> refresh({String filter = 'All'}) async {
    _filter = filter;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _page(1, filter);
      _notifications
        ..clear()
        ..addAll(page.notifications);
      unreadCount = page.unreadCount;
      hasMore = page.hasMore;
      _nextPage = page.nextPage;
    } on AuthException catch (exception) {
      _notifications.clear();
      unreadCount = 0;
      hasMore = false;
      error = exception.message;
    } catch (_) {
      _notifications.clear();
      unreadCount = 0;
      hasMore = false;
      error = 'Notifications could not be loaded.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final nextPage = _nextPage;
    if (loading || loadingMore || !hasMore || nextPage == null) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await _page(nextPage, _filter);
      _notifications.addAll(page.notifications);
      unreadCount = page.unreadCount;
      hasMore = page.hasMore;
      _nextPage = page.nextPage;
      error = null;
    } on AuthException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'More notifications could not be loaded.';
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    final response = await _remote.request(
      'PUT',
      '/api/notifications/$id/read',
    );
    final data = (response['data'] as Map?)?.cast<String, dynamic>();
    final value = (data?['notification'] as Map?)?.cast<String, dynamic>();
    if (value == null) {
      throw const AuthException('Notification response is invalid.');
    }
    final canonical = InboxNotification.fromJson(value);
    final index = _notifications.indexWhere((item) => item.id == id);
    if (_filter == 'Unread') {
      _notifications.removeWhere((item) => item.id == id);
    } else if (index >= 0) {
      _notifications[index] = canonical;
    }
    unreadCount = (data?['unreadCount'] as num?)?.toInt() ?? unreadCount;
    error = null;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final response = await _remote.request(
      'PUT',
      '/api/notifications/read-all',
    );
    final data = (response['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw const AuthException('Notification response is invalid.');
    }
    for (var index = 0; index < _notifications.length; index++) {
      final item = _notifications[index];
      _notifications[index] = InboxNotification(
        id: item.id,
        type: item.type,
        category: item.category,
        title: item.title,
        message: item.message,
        isRead: true,
        readAt: item.readAt ?? DateTime.now(),
        createdAt: item.createdAt,
        data: item.data,
        actor: item.actor,
      );
    }
    if (_filter == 'Unread') {
      _notifications.clear();
    }
    unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
    error = null;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final response = await _remote.request('DELETE', '/api/notifications/$id');
    final data = (response['data'] as Map?)?.cast<String, dynamic>();
    if (data?['deleted'] != true) {
      throw const AuthException('Notification delete response is invalid.');
    }
    _notifications.removeWhere((item) => item.id == id);
    unreadCount = (data?['unreadCount'] as num?)?.toInt() ?? unreadCount;
    error = null;
    notifyListeners();
  }

  Future<_NotificationPage> _page(int page, String filter) async {
    final parameters = <String, String>{'page': '$page', 'limit': '20'};
    if (filter == 'Unread') parameters['unread'] = 'true';
    if (filter != 'All' && filter != 'Unread') parameters['category'] = filter;
    final query = Uri(queryParameters: parameters).query;
    final response = await _remote.request('GET', '/api/notifications?$query');
    final data = (response['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw const AuthException('Notification response is invalid.');
    }
    final pagination = (data['pagination'] as Map?)?.cast<String, dynamic>();
    return _NotificationPage(
      notifications: ((data['notifications'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => InboxNotification.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      hasMore: pagination?['hasMore'] == true,
      nextPage: (pagination?['nextPage'] as num?)?.toInt(),
    );
  }
}

class _NotificationPage {
  const _NotificationPage({
    required this.notifications,
    required this.unreadCount,
    required this.hasMore,
    required this.nextPage,
  });

  final List<InboxNotification> notifications;
  final int unreadCount;
  final bool hasMore;
  final int? nextPage;
}
