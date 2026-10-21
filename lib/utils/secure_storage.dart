import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================
// SecureLocalStorage
// =============================================================
// Implements supabase_flutter's LocalStorage abstract interface.
// The supabase-dart client serialises the full session as a single
// JSON string and passes it to persistSession(). We store that one
// string in flutter_secure_storage.
//
// API verified against supabase_flutter 2.x source:
//   lib/src/local_storage.dart — abstract class LocalStorage {
//     Future<void> initialize();
//     Future<String?> accessToken();
//     Future<bool> hasAccessToken();
//     Future<void> persistSession(String persistSessionString);
//     Future<void> removePersistedSession();
//   }
//
// FIX #11: Do NOT use FlutterSecureStorageLocalStorage unless confirmed
// in official docs. Implement LocalStorage manually — this is safe and correct.
// No strings.xml hack needed; EncryptedSharedPreferences is configured below.
// =============================================================

class SecureLocalStorage extends LocalStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // EncryptedSharedPreferences on Android
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // survives reboot without unlock
    ),
  );
  static const _sessionKey = 'riforni_sb_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(key: _sessionKey)) != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
}

// =============================================================
// SecureAsyncStorage
// =============================================================
// Implements GoTrueAsyncStorage used by PKCE flow (email confirmation deep links).
// Required when pkceAsyncStorage is set in FlutterAuthClientOptions.
// =============================================================
class SecureAsyncStorage extends GoTrueAsyncStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: key);
}
