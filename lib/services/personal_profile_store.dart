import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps work information on this device, separately for each Firebase account.
class PersonalProfileStore {
  PersonalProfileStore({FirebaseAuth? auth, String? Function()? uidProvider})
      : _auth = auth,
        _uidProvider = uidProvider;

  final FirebaseAuth? _auth;
  final String? Function()? _uidProvider;
  static const _legacyKey = 'kisisel_bilgiler';
  static const _migrationKey = 'kisisel_bilgiler_v2_migrated';
  static const _guestPendingKey = 'kisisel_bilgiler_v2_guest_pending';
  static const _guestKey = 'kisisel_bilgiler_v2_guest';

  static String _accountKey(String uid) => 'kisisel_bilgiler_v2_$uid';

  String? get _currentUid {
    if (_uidProvider != null) return _uidProvider();
    try {
      return (_auth ?? FirebaseAuth.instance).currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<String?> readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUid;
    if (uid == null) return prefs.getString(_guestKey);

    final key = _accountKey(uid);
    final existing = prefs.getString(key);
    if (existing != null) {
      // An existing account profile takes precedence. A guest draft left on
      // this device must not later be imported into a different account.
      await prefs.remove(_guestKey);
      await prefs.remove(_guestPendingKey);
      if (prefs.getBool(_migrationKey) != true) {
        await prefs.setBool(_migrationKey, true);
      }
      await prefs.remove(_legacyKey);
      return existing;
    }

    // A profile entered before sign-in follows the user into the first account.
    final guest = prefs.getString(_guestKey);
    if (guest != null && prefs.getBool(_guestPendingKey) == true) {
      if (!await prefs.setString(key, guest)) return null;
      await prefs.remove(_guestKey);
      await prefs.remove(_guestPendingKey);
      await prefs.setBool(_migrationKey, true);
      await prefs.remove(_legacyKey);
      return guest;
    }

    // Import the old unscoped record once, for the account currently signed in.
    // A signed-out user never sees an old account's unscoped profile.
    if (prefs.getBool(_migrationKey) != true) {
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null) {
        if (!await prefs.setString(key, legacy)) return null;
        await prefs.setBool(_migrationKey, true);
        await prefs.remove(_legacyKey);
        return legacy;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> readMap() async {
    final raw = await readRaw();
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<bool> saveRaw(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUid;
    final saved = await prefs.setString(
        uid == null ? _guestKey : _accountKey(uid), value);
    if (saved && uid == null) await prefs.setBool(_guestPendingKey, true);
    if (saved && uid != null) {
      await prefs.setBool(_migrationKey, true);
      await prefs.remove(_legacyKey);
    }
    return saved;
  }

  Future<void> removeCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUid;
    await prefs.remove(uid == null ? _guestKey : _accountKey(uid));
    if (uid == null) await prefs.remove(_guestPendingKey);
  }

  Future<void> removeForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountKey(uid));
  }
}
