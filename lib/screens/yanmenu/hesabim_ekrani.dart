import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/giris_ekrani.dart';
import 'tema_ayarlari.dart';

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
  bool _girisAyarlariAcik = false; // İlk açılışta kapalı
  bool _kisiselBilgilerAcik = false;
  bool _digerAyarlarAcik = false;
  
  // Kişisel Bilgiler Form Controller'ları
  final TextEditingController _dogumTarihiController = TextEditingController();
  final TextEditingController _ilkIseGirisTarihiController = TextEditingController();
  final TextEditingController _toplamPrimGunController = TextEditingController();
  final TextEditingController _mevcutIsyeriBaslangicController = TextEditingController();
  final TextEditingController _guncelBrutMaasController = TextEditingController();
  
  // Kişisel Bilgiler State
  DateTime? _dogumTarihi;
  DateTime? _ilkIseGirisTarihi;
  DateTime? _mevcutIsyeriBaslangic;
  String _sigortaKolu = '4/a (SSK)'; // Varsayılan olarak SSK
  
  final _kisiselBilgilerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
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
    super.dispose();
  }
  
  // Kişisel bilgileri yükle
  Future<void> _loadKisiselBilgiler() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('kisisel_bilgiler');
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        setState(() {
          if (map['dogumTarihi'] != null) {
            _dogumTarihi = DateTime.fromMillisecondsSinceEpoch(map['dogumTarihi'] as int);
            _dogumTarihiController.text = _formatDate(_dogumTarihi!);
          }
          if (map['ilkIseGirisTarihi'] != null) {
            _ilkIseGirisTarihi = DateTime.fromMillisecondsSinceEpoch(map['ilkIseGirisTarihi'] as int);
            _ilkIseGirisTarihiController.text = _formatDate(_ilkIseGirisTarihi!);
          }
          _toplamPrimGunController.text = (map['toplamPrimGun'] as int?)?.toString() ?? '';
          if (map['mevcutIsyeriBaslangic'] != null) {
            _mevcutIsyeriBaslangic = DateTime.fromMillisecondsSinceEpoch(map['mevcutIsyeriBaslangic'] as int);
            _mevcutIsyeriBaslangicController.text = _formatDate(_mevcutIsyeriBaslangic!);
          }
          _guncelBrutMaasController.text = (map['guncelBrutMaas'] as num?)?.toString() ?? '';
          _sigortaKolu = map['sigortaKolu'] as String? ?? '4/a (SSK)';
        });
      }
    } catch (e) {
      debugPrint('Kişisel bilgiler yüklenirken hata: $e');
    }
  }
  
  // Kişisel bilgileri kaydet
  Future<void> _saveKisiselBilgiler() async {
    if (!_kisiselBilgilerFormKey.currentState!.validate()) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'dogumTarihi': _dogumTarihi?.millisecondsSinceEpoch,
        'ilkIseGirisTarihi': _ilkIseGirisTarihi?.millisecondsSinceEpoch,
        'toplamPrimGun': int.tryParse(_toplamPrimGunController.text) ?? 0,
        'mevcutIsyeriBaslangic': _mevcutIsyeriBaslangic?.millisecondsSinceEpoch,
        'guncelBrutMaas': double.tryParse(_guncelBrutMaasController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0,
        'sigortaKolu': _sigortaKolu,
        'kayitTarihi': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('kisisel_bilgiler', jsonEncode(data));
      
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
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
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
                          child: const Text(
                            'Tamam',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Colors.indigo,
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(DateTime(year, month, day)),
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
                                child: Text('${(i + 1).toString().padLeft(2, '0')}'),
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
                            children: months.map((m) => Center(child: Text(m))).toList(),
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
                            children: yearList.map((y) => Center(
                              child: Text('$y'),
                            )).toList(),
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
  Future<void> _promptReauth() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
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
                  onPressed: () async {
                    Navigator.pop(context);
                    await _reauthWithPassword();
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('E-posta ve şifre ile'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _reauthWithGoogle();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Google ile'),
                ),
                if (Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _reauthWithApple();
                    },
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple ile'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Sağlayıcı bazlı re-auth ----------
  Future<void> _reauthWithPassword() async {
    final email = _auth.currentUser?.email ?? '';
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Şifreyi girin'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Şifre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Onayla')),
        ],
      ),
    );

    if (ok != true) return;

    final cred =
    EmailAuthProvider.credential(email: email, password: ctrl.text);
    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  Future<void> _reauthWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  Future<void> _reauthWithApple() async {
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

    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  // ---------- Bilgi güncelle ----------
  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;
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
      if (e.code == 'requires-recent-login') {
        await _promptReauth();        // yeniden doğrula
        return _updateUserInfo();     // sonra işlemi tekrar dene
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
            'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz. Tüm kişisel bilgileriniz de silinecektir.'),
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
      // Kişisel bilgileri de sil
      await _clearKisiselBilgiler();
      
      await _auth.currentUser?.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap ve tüm veriler başarıyla silindi.')),
      );

      // const KALDIRILDI: GirisEkrani const constructor değil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GirisEkrani()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _promptReauth();
        return _deleteAccount();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Hesap silinirken bir hata oluştu.')),
      );
    }
  }
  
  // Kişisel bilgileri temizle (hesap silindiğinde)
  Future<void> _clearKisiselBilgiler() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kisisel_bilgiler');
    } catch (e) {
      debugPrint('Kişisel bilgiler temizlenirken hata: $e');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kisisel_bilgiler');
      
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

  // Kart widget'ı
  Widget _buildSettingCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            badge,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.indigo.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(12),
    );
    final focusedBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.indigo, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(color: Colors.indigo),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.indigo.withOpacity(0.02),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Giriş Ayarları
              _buildSettingCard(
                title: 'Giriş Ayarları',
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
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'ornek@email.com',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'En az 6 karakter',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.indigo,
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 6) {
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
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'Şifreyi tekrar girin',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.indigo,
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            backgroundColor: Colors.indigo,
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
                    ],
                  ),
                ),
              ),

              // Kişisel Bilgiler
              _buildSettingCard(
                title: 'Kişisel Bilgiler',
                isExpanded: _kisiselBilgilerAcik,
                badge: '${_calculateCompletionPercentage()}% ${_calculateCompletionPercentage() == 100 ? '✅' : '😔'}',
                onTap: () {
                  setState(() {
                    _kisiselBilgilerAcik = !_kisiselBilgilerAcik;
                  });
                },
                child: Form(
                  key: _kisiselBilgilerFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doğum Tarihi
                      TextFormField(
                        controller: _dogumTarihiController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Doğum Tarihi',
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'GG.AA.YYYY',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.calendar_today, color: Colors.indigo),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onTap: () => _selectDate(context, 'dogum'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Doğum tarihi seçiniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // İlk İşe Giriş Tarihi
                      TextFormField(
                        controller: _ilkIseGirisTarihiController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'İlk İşe Giriş Tarihi',
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'GG.AA.YYYY',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.work_outline, color: Colors.indigo),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onTap: () => _selectDate(context, 'ilkIseGiris'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'İlk işe giriş tarihi seçiniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Toplam Prim Gün Sayısı
                      TextFormField(
                        controller: _toplamPrimGunController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Toplam Prim Gün Sayısı',
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'Örn: 6500',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.calendar_view_day, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Prim gün sayısı giriniz';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Geçerli bir sayı giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Mevcut İşyeri Başlangıç Tarihi
                      TextFormField(
                        controller: _mevcutIsyeriBaslangicController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Mevcut İşyeri Başlangıç Tarihi',
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'GG.AA.YYYY',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.business, color: Colors.indigo),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onTap: () => _selectDate(context, 'mevcutIsyeri'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mevcut işyeri başlangıç tarihi seçiniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Güncel Brüt Maaş
                      TextFormField(
                        controller: _guncelBrutMaasController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Güncel Brüt Maaş (TL)',
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: 'Örn: 35000',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.attach_money, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Güncel brüt maaş giriniz';
                          }
                          final parsed = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
                          if (parsed == null || parsed <= 0) {
                            return 'Geçerli bir tutar giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Sigorta Kolu (Sadece 4/a SSK, değiştirilemez)
                      TextFormField(
                        initialValue: '4/a (SSK)',
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Sigorta Kolu',
                          labelStyle: const TextStyle(color: Colors.indigo),
                          hintText: '4/a (SSK)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.shield_outlined, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: border,
                          enabledBorder: border,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          helperText: 'Uygulama şu anda sadece 4/a (SSK) çalışanları için hizmet vermektedir.',
                          helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Kaydet Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _saveKisiselBilgiler,
                          child: const Text(
                            'Bilgilerimi Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Bilgilerimi Sıfırla Butonu
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _resetKisiselBilgiler,
                          child: const Text(
                            'Bilgilerimi Sıfırla',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Diğer Ayarlar
              _buildSettingCard(
                title: 'Diğer Ayarlar',
                isExpanded: _digerAyarlarAcik,
                onTap: () {
                  setState(() {
                    _digerAyarlarAcik = !_digerAyarlarAcik;
                  });
                },
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined, color: Colors.indigo),
                      title: const Text('Bildirim Ayarları'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Bildirim ayarları
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bildirim ayarları yakında eklenecek')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.accessibility_new, color: Colors.indigo),
                      title: const Text('Tema Ayarları'),
                      subtitle: const Text('Yazı boyutu ve tema'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TemaAyarlariEkrani(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
