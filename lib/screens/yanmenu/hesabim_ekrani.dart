import 'package:src/utils/app_design.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../auth/giris_ekrani.dart';
import '../calisma_araclari.dart';
import '../ilerleme_ekrani.dart';
import '../../services/personal_profile_store.dart';
import '../../services/account_scoped_local_store.dart';
import '../../services/notification_service.dart';
import '../../sonhesaplama/sonhesaplama.dart';
import '../../utils/progress_service.dart';

class HesabimEkrani extends StatefulWidget {
  const HesabimEkrani({super.key});

  @override
  State<HesabimEkrani> createState() => _HesabimEkraniState();
}

class _HesabimEkraniState extends State<HesabimEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Expansion durumları
  bool _girisAyarlariAcik = false;
  bool _kisiselBilgilerAcik = false;

  // Kişisel Bilgiler Form Controller'ları
  final TextEditingController _dogumTarihiController = TextEditingController();
  final TextEditingController _ilkIseGirisTarihiController =
      TextEditingController();
  final TextEditingController _toplamPrimGunController =
      TextEditingController();
  final TextEditingController _mevcutIsyeriBaslangicController =
      TextEditingController();
  final TextEditingController _guncelBrutMaasController =
      TextEditingController();
  final TextEditingController _cinsiyetController = TextEditingController();

  // Kişisel Bilgiler State
  DateTime? _dogumTarihi;
  DateTime? _ilkIseGirisTarihi;
  DateTime? _mevcutIsyeriBaslangic;
  String _cinsiyet = 'Erkek';
  String _sigortaKolu = '4/a (SSK)'; // Varsayılan olarak SSK

  final _kisiselBilgilerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
    _cinsiyetController.text = _cinsiyet;
    _loadKisiselBilgiler();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dogumTarihiController.dispose();
    _ilkIseGirisTarihiController.dispose();
    _toplamPrimGunController.dispose();
    _mevcutIsyeriBaslangicController.dispose();
    _guncelBrutMaasController.dispose();
    _cinsiyetController.dispose();
    super.dispose();
  }

  // Kişisel bilgileri yükle
  Future<void> _loadKisiselBilgiler() async {
    try {
      final data = await PersonalProfileStore().readRaw();
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        setState(() {
          if (map['dogumTarihi'] != null) {
            _dogumTarihi =
                DateTime.fromMillisecondsSinceEpoch(map['dogumTarihi'] as int);
            _dogumTarihiController.text = _formatDate(_dogumTarihi!);
          }
          if (map['ilkIseGirisTarihi'] != null) {
            _ilkIseGirisTarihi = DateTime.fromMillisecondsSinceEpoch(
                map['ilkIseGirisTarihi'] as int);
            _ilkIseGirisTarihiController.text =
                _formatDate(_ilkIseGirisTarihi!);
          }
          _toplamPrimGunController.text =
              (map['toplamPrimGun'] as int?)?.toString() ?? '';
          _cinsiyet = map['cinsiyet'] as String? ?? 'Erkek';
          _cinsiyetController.text = _cinsiyet;
          if (map['mevcutIsyeriBaslangic'] != null) {
            _mevcutIsyeriBaslangic = DateTime.fromMillisecondsSinceEpoch(
                map['mevcutIsyeriBaslangic'] as int);
            _mevcutIsyeriBaslangicController.text =
                _formatDate(_mevcutIsyeriBaslangic!);
          }
          final brutVal = (map['guncelBrutMaas'] as num?)?.toDouble();
          _guncelBrutMaasController.text =
              brutVal == null || brutVal == 0 ? '' : _formatBrutMaas(brutVal);
          _sigortaKolu = map['sigortaKolu'] as String? ?? '4/a (SSK)';
        });
      }
    } catch (e) {
      debugPrint('Kişisel bilgiler yüklenirken hata: $e');
    }
  }

  /// TR format (50.000,00) veya düz sayı (50000 / 50000.0). Virgül varsa nokta binlik; yoksa nokta ondalık (silinmez).
  double _parseBrutMaas(String value) {
    final raw = value.replaceAll(' TL', '').trim();
    if (raw.isEmpty) return 0.0;
    if (raw.contains(',')) {
      final t = raw.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(t) ?? 0.0;
    }
    if (raw.contains('.')) {
      final afterLastDot = raw.substring(raw.lastIndexOf('.') + 1);
      if (afterLastDot.length == 3 &&
          RegExp(r'^\d{3}$').hasMatch(afterLastDot)) {
        return double.tryParse(raw.replaceAll('.', '')) ?? 0.0;
      }
      return double.tryParse(raw) ?? 0.0;
    }
    return double.tryParse(raw) ?? 0.0;
  }

  /// Brütten nete _formatPlain gibi: binlik nokta, ondalık virgül (50.000,00).
  String _formatBrutMaas(double n) {
    if (n == 0) return '';
    n = n.abs();
    final fixed = n.toStringAsFixed(2);
    final parts = fixed.split('.');
    String intPart = parts[0];
    final frac = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return '${buf.toString()},$frac';
  }

  // Kişisel bilgileri kaydet
  Future<void> _saveKisiselBilgiler() async {
    if (!_kisiselBilgilerFormKey.currentState!.validate()) return;

    try {
      final store = PersonalProfileStore();
      final now = DateTime.now();
      final newPrim = int.tryParse(_toplamPrimGunController.text) ?? 0;
      int? referansTarihiMs = now.millisecondsSinceEpoch;
      final existing = await store.readRaw();
      if (existing != null && existing.isNotEmpty) {
        try {
          final map = jsonDecode(existing) as Map<String, dynamic>;
          final oldPrim =
              int.tryParse((map['toplamPrimGun'] ?? '').toString()) ?? 0;
          if (oldPrim == newPrim && map['primGunuReferansTarihi'] != null) {
            referansTarihiMs = map['primGunuReferansTarihi'] as int;
          }
        } catch (_) {}
      }
      final data = {
        'dogumTarihi': _dogumTarihi?.millisecondsSinceEpoch,
        'ilkIseGirisTarihi': _ilkIseGirisTarihi?.millisecondsSinceEpoch,
        'toplamPrimGun': newPrim,
        'mevcutIsyeriBaslangic': _mevcutIsyeriBaslangic?.millisecondsSinceEpoch,
        'guncelBrutMaas': _parseBrutMaas(_guncelBrutMaasController.text),
        'cinsiyet': _cinsiyet,
        'sigortaKolu': _sigortaKolu,
        'kayitTarihi': now.millisecondsSinceEpoch,
        'primGunuReferansTarihi': referansTarihiMs,
      };
      await store.saveRaw(jsonEncode(data));

      final savedBrut = (data['guncelBrutMaas'] as num).toDouble();
      if (savedBrut > 0 && mounted) {
        setState(
            () => _guncelBrutMaasController.text = _formatBrutMaas(savedBrut));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişisel bilgileriniz kaydedildi')),
        );
      }
    } catch (e) {
      debugPrint('Kişisel bilgiler kaydedilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydetme sırasında bir hata oluştu')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Cupertino tarih seçici göster
  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime? currentDate;
    DateTime minDate = DateTime(1950, 1, 1);
    DateTime maxDate = DateTime.now();

    // Mevcut tarihi belirle
    if (type == 'dogum') {
      currentDate = _dogumTarihi ?? DateTime(1990, 1, 1);
    } else if (type == 'ilkIseGiris') {
      currentDate = _ilkIseGirisTarihi ?? DateTime(2000, 1, 1);
    } else if (type == 'mevcutIsyeri') {
      currentDate = _mevcutIsyeriBaslangic ?? DateTime(2020, 1, 1);
    }

    if (currentDate == null) currentDate = DateTime.now();
    if (currentDate.isBefore(minDate)) currentDate = minDate;
    if (currentDate.isAfter(maxDate)) currentDate = maxDate;

    final DateTime? picked = await _showCupertinoDatePicker(
      context: context,
      initialDate: currentDate,
      minDate: minDate,
      maxDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        if (type == 'dogum') {
          _dogumTarihi = picked;
          _dogumTarihiController.text = _formatDate(picked);
        } else if (type == 'ilkIseGiris') {
          _ilkIseGirisTarihi = picked;
          _ilkIseGirisTarihiController.text = _formatDate(picked);
        } else if (type == 'mevcutIsyeri') {
          _mevcutIsyeriBaslangic = picked;
          _mevcutIsyeriBaslangicController.text = _formatDate(picked);
        }
      });
    }
  }

  // Cupertino Date Picker
  Future<DateTime?> _showCupertinoDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime minDate,
    required DateTime maxDate,
  }) async {
    int day = initialDate.day;
    int month = initialDate.month;
    int year = initialDate.year;

    final dayCtrl = FixedExtentScrollController(initialItem: day - 1);
    final monthCtrl = FixedExtentScrollController(initialItem: month - 1);

    final List<String> months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];

    // Yıl picker'ı ters sırada (en yeni yukarıda)
    final yearList = List.generate(
      maxDate.year - minDate.year + 1,
      (i) => maxDate.year - i, // Ters sırada: 2026, 2025, 2024, ...
    );
    final yearIndex = yearList.indexOf(year);
    final yearCtrl = FixedExtentScrollController(
      initialItem: yearIndex >= 0 ? yearIndex : 0,
    );

    return showCupertinoModalPopup<DateTime?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;
            int maxD = daysInMonth(year, month);
            if (day > maxD) {
              day = maxD;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dayCtrl.hasClients) dayCtrl.jumpToItem(day - 1);
              });
            }

            return Container(
              height: 300,
              color: Colors.white,
              child: Column(
                children: [
                  // Üst bar
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text(
                            'İptal',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(null),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Tamam',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(ctx).pop(DateTime(year, month, day)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Gün - Ay - Yıl picker'ları
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: dayCtrl,
                            onSelectedItemChanged: (i) {
                              setModalState(() {
                                day = i + 1;
                                maxD = daysInMonth(year, month);
                                if (day > maxD) day = maxD;
                              });
                            },
                            children: List.generate(
                              maxD,
                              (i) => Center(
                                child: Text(
                                    '${(i + 1).toString().padLeft(2, '0')}'),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: monthCtrl,
                            onSelectedItemChanged: (i) {
                              setModalState(() {
                                month = i + 1;
                                maxD = daysInMonth(year, month);
                                if (day > maxD) day = maxD;
                                if (dayCtrl.hasClients) {
                                  dayCtrl.jumpToItem(day - 1);
                                }
                              });
                            },
                            children: months
                                .map((m) => Center(child: Text(m)))
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: yearCtrl,
                            onSelectedItemChanged: (i) {
                              setModalState(() {
                                year = yearList[i]; // Ters sıradan seç
                                maxD = daysInMonth(year, month);
                                if (day > maxD) day = maxD;
                                if (dayCtrl.hasClients) {
                                  dayCtrl.jumpToItem(day - 1);
                                }
                              });
                            },
                            children: yearList
                                .map((y) => Center(
                                      child: Text('$y'),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectCinsiyet(BuildContext context) async {
    final themeColor = Theme.of(context).primaryColor;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppDesign.activeBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Cinsiyet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.male, color: themeColor),
              title: const Text('Erkek'),
              onTap: () => Navigator.pop(ctx, 'Erkek'),
            ),
            ListTile(
              leading: Icon(Icons.female, color: themeColor),
              title: const Text('Kadın'),
              onTap: () => Navigator.pop(ctx, 'Kadın'),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() {
        _cinsiyet = chosen;
        _cinsiyetController.text = chosen;
      });
    }
  }

  // Tamamlanma yüzdesi hesapla
  int _calculateCompletionPercentage() {
    int filled = 0;
    int total = 5; // Sigorta kolu her zaman dolu (4/a SSK), kontrol edilmiyor

    if (_dogumTarihi != null) filled++;
    if (_ilkIseGirisTarihi != null) filled++;
    if (_toplamPrimGunController.text.trim().isNotEmpty) filled++;
    if (_mevcutIsyeriBaslangic != null) filled++;
    if (_guncelBrutMaasController.text.trim().isNotEmpty) filled++;
    // Sigorta kolu (4/a SSK) her zaman dolu, sayılmıyor

    if (total == 0) return 0;
    return ((filled / total) * 100).round();
  }

  // ---------- Apple/Firebase için nonce ----------
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  // ---------- Re-auth seçenek alt sayfası ----------
  Future<bool> _promptReauth() async {
    if (!mounted) return false;
    final method = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 12,
              children: [
                const Text(
                  'Güvenlik için yeniden giriş yapın',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop('password'),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('E-posta ve şifre ile'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop('google'),
                  icon: const Icon(Icons.login),
                  label: const Text('Google ile'),
                ),
                if (Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop('apple'),
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple ile'),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || method == null) return false;

    try {
      switch (method) {
        case 'password':
          return await _reauthWithPassword();
        case 'google':
          return await _reauthWithGoogle();
        case 'apple':
          return await _reauthWithApple();
      }
      return false;
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        final message = error.code == 'user-not-found'
            ? 'Bu üyelik artık bulunamıyor. Lütfen yeniden giriş yapın.'
            : (error.message ?? 'Yeniden giriş doğrulanamadı. Tekrar deneyin.');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      return false;
    } on PlatformException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Yeniden giriş bağlantısı kurulamadı. Tekrar deneyin.'),
        ));
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Yeniden giriş tamamlanamadı. Tekrar deneyin.'),
        ));
      }
      return false;
    }
  }

  // ---------- Sağlayıcı bazlı re-auth ----------
  Future<bool> _reauthWithPassword() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Şifreyi girin'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Şifre'),
        ),
        actions: [
          TextButton(
               onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal')),
          TextButton(
               onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Onayla')),
        ],
      ),
    );

    if (ok != true || !mounted) return false;

    final cred =
        EmailAuthProvider.credential(email: user.email!, password: ctrl.text);
    await user.reauthenticateWithCredential(cred);
    return true;
  }

  Future<bool> _reauthWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null || !mounted) return false;
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reauthenticateWithCredential(cred);
    return true;
  }

  Future<bool> _reauthWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final cred = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
    );

    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reauthenticateWithCredential(cred);
    return true;
  }

  // ---------- Bilgi güncelle ----------
  Future<void> _updateUserInfo({bool hasRetried = false}) async {
    final form = _formKey.currentState;
    if (!mounted || form == null || !form.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // E-posta değiştiyse: updateEmail() DEPRECATED → verifyBeforeUpdateEmail()
      if (_emailController.text.trim() != (user.email ?? '').trim()) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Yeni e-posta için doğrulama bağlantısı gönderildi. Lütfen e-postandaki linki onayla.'),
          ),
        );
      }

      // Şifre değişimi varsa
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İstek(ler) başarıyla gönderildi.')),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && !hasRetried) {
        final authenticated = await _promptReauth();
        if (!authenticated || !mounted) return;
        return _updateUserInfo(hasRetried: true);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Bir hata oluştu.')),
      );
    }
  }

  // ---------- Hesap sil ----------
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
            'Hesabınızı silmek istediğinizden emin misiniz? Firebase üyeliğiniz ve bu cihazdaki çalışma bilgileriniz silinir. Topluluk ve iletişim kayıtlarınız için ayrıca silme talebinde bulunabilirsiniz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _auth.currentUser!.delete();
      await PersonalProfileStore().removeForUid(uid);
      await SonHesaplamalarDeposu.removeForUid(uid);
      await ProgressService.removeForUid(uid);
      await AccountScopedLocalStore().removeForUid('mesai_takip_v1', uid);
      await AccountScopedLocalStore()
          .removeForUid(NotificationService.preferencesKey, uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Üyeliğiniz ve bu cihazdaki çalışma bilgileriniz silindi.')),
      );

      // const KALDIRILDI: GirisEkrani const constructor değil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GirisEkrani()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final authenticated = await _promptReauth();
        if (!authenticated || !mounted) return;
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;
        try {
          await _auth.currentUser!.delete();
          await PersonalProfileStore().removeForUid(uid);
          await SonHesaplamalarDeposu.removeForUid(uid);
          await ProgressService.removeForUid(uid);
          await AccountScopedLocalStore().removeForUid('mesai_takip_v1', uid);
          await AccountScopedLocalStore()
              .removeForUid(NotificationService.preferencesKey, uid);
          if (!mounted) return;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => GirisEkrani()));
        } on FirebaseAuthException catch (retryError) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(retryError.message ?? 'Hesap silinemedi.')));
        }
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? 'Hesap silinirken bir hata oluştu.')),
      );
    }
  }

  // Kişisel bilgileri sıfırla (manuel)
  Future<void> _resetKisiselBilgiler() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bilgileri Sıfırla'),
        content: const Text(
            'Tüm kişisel bilgilerinizi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sıfırla', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PersonalProfileStore().removeCurrent();

      // Tüm controller'ları temizle (setState dışında)
      _dogumTarihiController.clear();
      _ilkIseGirisTarihiController.clear();
      _toplamPrimGunController.clear();
      _mevcutIsyeriBaslangicController.clear();
      _guncelBrutMaasController.clear();

      if (!mounted) return;

      // State'i güncelle
      setState(() {
        _dogumTarihi = null;
        _ilkIseGirisTarihi = null;
        _mevcutIsyeriBaslangic = null;
        _cinsiyet = 'Erkek';
        _cinsiyetController.text = 'Erkek';
        _sigortaKolu = '4/a (SSK)';
      });

      // Form validasyonunu sıfırla
      _kisiselBilgilerFormKey.currentState?.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kişisel bilgileriniz sıfırlandı'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Kişisel bilgiler sıfırlanırken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sıfırlama sırasında bir hata oluştu')),
        );
      }
    }
  }

  Widget _buildSettingCard(
          {required String title,
          required bool isExpanded,
          required VoidCallback onTap,
          required Widget child,
          required IconData icon,
          String? badge,
          List<Widget> trailing = const []}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppSurface(
            padding: EdgeInsets.zero,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppActionTile(
                      title: title,
                      subtitle: badge,
                      icon: icon,
                      onTap: onTap,
                      expanded: isExpanded),
                  if (isExpanded)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: child),
                  if (trailing.isNotEmpty)
                    Divider(height: 1, color: AppDesign.activeBorder),
                  ...trailing,
                ])),
      );

  Widget _buildMenuItem(
          {required IconData icon,
          required String title,
          VoidCallback? onTap,
          String? subtitle,
          Color? textColor}) =>
      AppActionTile(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onTap: onTap ?? () {},
        foregroundColor: textColor,
      );
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final border = OutlineInputBorder(
      borderSide:
          BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(12),
    );
    final focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppMenuBar(
        title: Text(
          'Hesabım',
          style: TextStyle(
              color: AppDesign.activeInk,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppDesign.activeInk),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
          child: AppContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üyelik Ayarları
              _buildSettingCard(
                icon: Icons.manage_accounts_outlined,
                title: 'Üyelik Ayarları',
                isExpanded: _girisAyarlariAcik,
                onTap: () {
                  setState(() {
                    _girisAyarlariAcik = !_girisAyarlariAcik;
                  });
                },
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📧 E-posta
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle:
                              TextStyle(color: Theme.of(context).primaryColor),
                          hintText: 'ornek@email.com',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-posta boş olamaz';
                          }
                          if (!value.contains('@')) {
                            return 'Geçerli bir e-posta girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 🔑 Şifre
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle:
                              TextStyle(color: Theme.of(context).primaryColor),
                          hintText: 'En az 6 karakter',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 🔁 Şifre Tekrar
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Şifre Tekrar',
                          labelStyle:
                              TextStyle(color: Theme.of(context).primaryColor),
                          hintText: 'Şifreyi tekrar girin',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (_passwordController.text.isNotEmpty &&
                              value != _passwordController.text) {
                            return 'Şifreler uyuşmuyor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 💾 Kaydet Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _updateUserInfo,
                          child: const Text(
                            'Değişiklikleri Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text(
                            'Hesabı Sil',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: [
                  _buildMenuItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'Bildirim Tercihleri',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BildirimTercihleriEkrani())),
                  ),
                  Divider(height: 1, color: AppDesign.activeBorder),
                  _buildMenuItem(
                    icon: Icons.emoji_events_outlined,
                    title: 'İlerlemem ve Kazanımlarım',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const IlerlemeEkrani())),
                  ),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }
}
