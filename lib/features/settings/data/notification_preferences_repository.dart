import 'package:amora_ai/core/auth/auth_service.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.newMatches,
    required this.messages,
    required this.eventReminders,
    required this.paymentsAndMembership,
    required this.offers,
    required this.safetyUpdates,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.quietHoursEnabled,
    required this.quietStart,
    required this.quietEnd,
  });

  final bool newMatches;
  final bool messages;
  final bool eventReminders;
  final bool paymentsAndMembership;
  final bool offers;
  final bool safetyUpdates;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool quietHoursEnabled;
  final String quietStart;
  final String quietEnd;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        newMatches: json['newMatches'] == true,
        messages: json['messages'] == true,
        eventReminders: json['eventReminders'] == true,
        paymentsAndMembership: json['paymentsAndMembership'] == true,
        offers: json['offers'] == true,
        safetyUpdates: json['safetyUpdates'] != false,
        pushEnabled: json['pushEnabled'] == true,
        emailEnabled: json['emailEnabled'] == true,
        smsEnabled: json['smsEnabled'] == true,
        quietHoursEnabled: json['quietHoursEnabled'] == true,
        quietStart: json['quietStart']?.toString() ?? '22:00',
        quietEnd: json['quietEnd']?.toString() ?? '07:00',
      );
}

abstract interface class NotificationPreferencesRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}

class AuthNotificationPreferencesRemoteDataSource
    implements NotificationPreferencesRemoteDataSource {
  const AuthNotificationPreferencesRemoteDataSource();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => AuthService.instance.authenticatedRequest(method, path, body: body);
}

class NotificationPreferencesRepository {
  NotificationPreferencesRepository({
    NotificationPreferencesRemoteDataSource? remote,
  }) : _remote = remote ?? const AuthNotificationPreferencesRemoteDataSource();

  static final instance = NotificationPreferencesRepository();
  final NotificationPreferencesRemoteDataSource _remote;

  Map<String, dynamic> _preferences(Map<String, dynamic> response) =>
      ((((response['data'] as Map?) ?? const <String, dynamic>{})['preferences']
                  as Map?) ??
              const <String, dynamic>{})
          .cast<String, dynamic>();

  Future<NotificationPreferences> get() async =>
      NotificationPreferences.fromJson(
        _preferences(
          await _remote.request('GET', '/api/notification-preferences'),
        ),
      );

  Future<NotificationPreferences> update(Map<String, dynamic> values) async =>
      NotificationPreferences.fromJson(
        _preferences(
          await _remote.request(
            'PUT',
            '/api/notification-preferences',
            body: values,
          ),
        ),
      );
}
