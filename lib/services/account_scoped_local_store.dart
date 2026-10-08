import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps local records on this device without showing one account's data to
/// another account or to a signed-out visitor.
class AccountScopedLocalStore {
  AccountScopedLocalStore({String? Function()? uidProvider})
      : _uidProvider = uidProvider;

  final String? Function()? _uidProvider;

  String? get currentUid {
    if (_uidProvider != null) return _uidProvider();
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static String _key(String base, String? uid) =>
      '${base}_v2_${uid ?? 'guest'}';

  Future<String?> read(String base) async {
    final uid = currentUid;
    final prefs = await SharedPreferences.getInstance();
    // The owner of the old shared key cannot be determined safely.
    // Leave it untouched for a deliberate recovery, but never display it.
    return prefs.getString(_key(base, uid));
  }

  Future<bool> write(String base, String value) async {
    final uid = currentUid;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_key(base, uid), value);
  }

  Future<void> removeForUid(String base, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(base, uid));
    await prefs.remove(base);
  }
}
