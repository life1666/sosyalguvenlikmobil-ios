import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'referral_api_constants.dart';
import 'referral_icerik_model.dart';

/// Uzaktan JSON çeker; hata veya boş URL durumunda asset yedeğini kullanır.
class ReferralIcerikService {
  ReferralIcerikService._();

  static ReferralIcerikModel? _bellek;

  static void onbellekTemizle() => _bellek = null;

  static Future<ReferralIcerikModel> yukle() async {
    if (_bellek != null) return _bellek!;

    ReferralIcerikModel? yerel;
    try {
      final raw = await rootBundle.loadString('assets/referral_ui_config.json');
      yerel = ReferralIcerikModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, st) {
      debugPrint('ReferralIcerikService asset: $e\n$st');
    }

    final url = kReferralUiConfigUrl.trim();
    if (url.isNotEmpty) {
      try {
        final res =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final uzak = ReferralIcerikModel.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>,
          );
          final birlesik = uzak.birlestir(yerel);
          _bellek = birlesik;
          return birlesik;
        }
      } catch (e, st) {
        debugPrint('ReferralIcerikService uzak: $e\n$st');
      }
    }

    _bellek = yerel ?? ReferralIcerikModel.bosVarsayilan();
    return _bellek!;
  }
}
