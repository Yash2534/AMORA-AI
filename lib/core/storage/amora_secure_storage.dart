import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The single secure-storage configuration used by AMORAA.
abstract final class AmoraSecureStorage {
  static const instance = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );
}
