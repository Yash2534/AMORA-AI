import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

typedef DiscoverAccessTokenProvider = Future<String?> Function();

bool isRetryableDiscoverFailure(int statusCode) =>
    statusCode == 0 ||
    statusCode == 408 ||
    statusCode == 429 ||
    statusCode >= 500;

Map<String, String> buildDiscoverFeedQuery({
  required int page,
  required int limit,
  Iterable<String> communicationStyles = const <String>[],
  bool? onlineNow,
  bool? hasEventInterest,
}) {
  final styles = communicationStyles.toSet().toList(growable: false);
  return {
    'page': '$page',
    'limit': '$limit',
    if (styles.isNotEmpty) 'communicationStyles': styles.join(','),
    if (onlineNow != null) 'onlineNow': '$onlineNow',
    if (hasEventInterest != null) 'hasEventInterest': '$hasEventInterest',
  };
}

class DiscoverApiResult<T> {
  const DiscoverApiResult.success(
    this.data, {
    required this.statusCode,
    this.message = '',
  }) : success = true;
  const DiscoverApiResult.failure(this.message, {required this.statusCode})
    : success = false,
      data = null;

  final bool success;
  final T? data;
  final String message;
  final int statusCode;
}

class DiscoverFeedPage {
  const DiscoverFeedPage({
    required this.profiles,
    required this.hasMore,
    this.nextPage,
  });

  final List<Map<String, dynamic>> profiles;
  final bool hasMore;
  final int? nextPage;
}

class DiscoverSwipeResult {
  const DiscoverSwipeResult({
    required this.matched,
    this.matchId,
    this.matchedProfile,
  });

  final bool matched;
  final String? matchId;
  final Map<String, dynamic>? matchedProfile;
}

class DiscoverApiService {
  DiscoverApiService({
    http.Client? client,
    DiscoverAccessTokenProvider? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _accessTokenProvider =
           accessTokenProvider ?? (() => _storage.read(key: _accessTokenKey));

  static const _accessTokenKey = 'amora_access_token';
  static const _timeout = Duration(seconds: 10);
  static const _storage = FlutterSecureStorage();
  final http.Client _client;
  final DiscoverAccessTokenProvider _accessTokenProvider;

  Future<DiscoverApiResult<DiscoverFeedPage>> getFeed({
    required int page,
    int limit = 10,
    Iterable<String> communicationStyles = const <String>[],
  }) async {
    final result = await _request(
      'GET',
      '/api/discover/feed',
      query: buildDiscoverFeedQuery(
        page: page,
        limit: limit,
        communicationStyles: communicationStyles,
      ),
    );
    if (!result.success || result.data == null) {
      return DiscoverApiResult.failure(
        result.message,
        statusCode: result.statusCode,
      );
    }
    final profiles = ((result.data!['profiles'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((profile) => profile.cast<String, dynamic>())
        .toList(growable: false);
    final pagination = result.data!['pagination'] as Map?;
    return DiscoverApiResult.success(
      DiscoverFeedPage(
        profiles: profiles,
        hasMore: pagination?['hasMore'] == true,
        nextPage: (pagination?['nextPage'] as num?)?.toInt(),
      ),
      statusCode: result.statusCode,
      message: result.message,
    );
  }

  Future<DiscoverApiResult<DiscoverSwipeResult>> swipe({
    required String targetUserId,
    required String action,
  }) async {
    final result = await _request(
      'POST',
      '/api/discover/swipe',
      body: {
        'targetUserId': int.tryParse(targetUserId) ?? targetUserId,
        'action': action,
      },
    );
    if (!result.success || result.data == null) {
      return DiscoverApiResult.failure(
        result.message,
        statusCode: result.statusCode,
      );
    }
    final matchedProfile = result.data!['matchedProfile'];
    return DiscoverApiResult.success(
      DiscoverSwipeResult(
        matched: result.data!['matched'] == true,
        matchId: result.data!['matchId']?.toString(),
        matchedProfile: matchedProfile is Map
            ? matchedProfile.cast<String, dynamic>()
            : null,
      ),
      statusCode: result.statusCode,
      message: result.message,
    );
  }

  Future<DiscoverApiResult<Map<String, dynamic>>> rewind() =>
      _request('POST', '/api/discover/rewind');
  Future<DiscoverApiResult<Map<String, dynamic>>> getFilters() async {
    final result = await _request('GET', '/api/me/preferences');
    if (!result.success || result.data == null) {
      return DiscoverApiResult.failure(
        result.message,
        statusCode: result.statusCode,
      );
    }
    final filters = result.data!['preferences'];
    return DiscoverApiResult.success(
      filters is Map ? filters.cast<String, dynamic>() : <String, dynamic>{},
      statusCode: result.statusCode,
      message: result.message,
    );
  }

  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> filters,
  ) async {
    final result = await _request('PUT', '/api/me/preferences', body: filters);
    if (!result.success || result.data == null) {
      return DiscoverApiResult.failure(
        result.message,
        statusCode: result.statusCode,
      );
    }
    final saved = result.data!['preferences'];
    return DiscoverApiResult.success(
      saved is Map ? saved.cast<String, dynamic>() : <String, dynamic>{},
      statusCode: result.statusCode,
      message: result.message,
    );
  }

  Future<DiscoverApiResult<Map<String, dynamic>>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final setup = await _setup(path, query);
    if (setup == null) {
      developer.log(
        '$method $path was not sent because the authenticated session is missing.',
        name: 'AmoraDiscover',
      );
      return const DiscoverApiResult.failure(
        'Discover is unavailable because the session is missing.',
        statusCode: 401,
      );
    }
    try {
      final request = http.Request(method, setup.uri)
        ..headers.addAll(setup.headers)
        ..headers.addAll(headers ?? const <String, String>{});
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
      return _parse(method, path, response);
    } on TimeoutException {
      developer.log('$method $path timed out.', name: 'AmoraDiscover');
      return const DiscoverApiResult.failure(
        'The Discover request timed out.',
        statusCode: 408,
      );
    } catch (error) {
      developer.log('$method $path failed: $error', name: 'AmoraDiscover');
      return const DiscoverApiResult.failure(
        'Unable to reach Discover right now.',
        statusCode: 0,
      );
    }
  }

  Future<_RequestSetup?> _setup(String path, Map<String, String>? query) async {
    try {
      final token = await _accessTokenProvider();
      if (AmoraApiConfig.baseUrl.isEmpty || token == null || token.isEmpty) {
        return null;
      }
      return _RequestSetup(
        Uri.parse(
          '${AmoraApiConfig.baseUrl}$path',
        ).replace(queryParameters: query),
        <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
    } catch (error) {
      developer.log(
        'Could not prepare Discover request: $error',
        name: 'AmoraDiscover',
      );
      return null;
    }
  }

  DiscoverApiResult<Map<String, dynamic>> _parse(
    String method,
    String path,
    http.Response response,
  ) {
    try {
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(response.body) as Map).cast<String, dynamic>();
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
        return DiscoverApiResult.success(
          (body['data'] as Map? ?? const <String, dynamic>{})
              .cast<String, dynamic>(),
          statusCode: response.statusCode,
          message: body['message'] as String? ?? '',
        );
      }
      final message = body['message'] as String? ?? 'Discover request failed.';
      developer.log(
        '$method $path failed with ${response.statusCode}: $message',
        name: 'AmoraDiscover',
      );
      return DiscoverApiResult.failure(
        message,
        statusCode: response.statusCode,
      );
    } catch (error) {
      developer.log(
        '$method $path returned an unreadable response: $error',
        name: 'AmoraDiscover',
      );
      return DiscoverApiResult.failure(
        'Unable to read the Discover service response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class _RequestSetup {
  const _RequestSetup(this.uri, this.headers);

  final Uri uri;
  final Map<String, String> headers;
}
