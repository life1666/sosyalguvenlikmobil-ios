import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:src/services/premium_access_service.dart';
import 'package:src/services/personal_profile_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('eksik veya bozuk yerel profil Premium kullanımına hazır sayılmaz',
      () async {
    SharedPreferences.setMockInitialValues({
      'kisisel_bilgiler_v2_test-user': '{bozuk json',
    });
    final access = PremiumAccessService(
        profileStore: PersonalProfileStore(uidProvider: () => 'test-user'));
    expect(await access.hasProfile(), isFalse);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'kisisel_bilgiler_v2_test-user',
        jsonEncode({
          'adSoyad': 'Ayşe Yılmaz',
          'dogumTarihi': DateTime(1990, 1, 1).millisecondsSinceEpoch,
        }));
    expect(await access.hasProfile(), isFalse);
  });

  test('kaydedilmiş temel çalışma bilgileri hazır kabul edilir', () async {
    SharedPreferences.setMockInitialValues({
      'kisisel_bilgiler_v2_test-user': jsonEncode({
        'adSoyad': 'Ayşe Yılmaz',
        'dogumTarihi': DateTime(1990, 1, 1).millisecondsSinceEpoch,
        'ilkIseGirisTarihi': DateTime(2010, 1, 1).millisecondsSinceEpoch,
        'toplamPrimGun': 3600,
        'cinsiyet': 'Kadın',
        'sigortaKolu': '4/a (SSK)',
      }),
    });
    expect(
        await PremiumAccessService(
                profileStore:
                    PersonalProfileStore(uidProvider: () => 'test-user'))
            .hasProfile(),
        isTrue);
  });

  test('hesaplar aynı cihazda birbirinin profilini okuyamaz', () async {
    SharedPreferences.setMockInitialValues({});
    final first = PersonalProfileStore(uidProvider: () => 'account-a');
    final second = PersonalProfileStore(uidProvider: () => 'account-b');
    await first.saveRaw(jsonEncode({'adSoyad': 'Birinci Kullanıcı'}));
    expect((await first.readMap())['adSoyad'], 'Birinci Kullanıcı');
    expect(await second.readMap(), isEmpty);
  });

  test('giriş öncesi bilgiler ilk oturum açılan hesaba taşınır', () async {
    SharedPreferences.setMockInitialValues({});
    final guest = PersonalProfileStore(uidProvider: () => null);
    await guest.saveRaw(jsonEncode({'adSoyad': 'Konuk Profil'}));
    final account = PersonalProfileStore(uidProvider: () => 'account-a');
    expect((await account.readMap())['adSoyad'], 'Konuk Profil');
    expect(await guest.readMap(), isEmpty);
    expect(await PersonalProfileStore(uidProvider: () => 'account-b').readMap(),
        isEmpty);
  });

  test('profilli hesaba giriş konuk taslağını siler, başka hesaba taşımaz',
      () async {
    SharedPreferences.setMockInitialValues({});
    final guest = PersonalProfileStore(uidProvider: () => null);
    final account = PersonalProfileStore(uidProvider: () => 'account-a');
    final other = PersonalProfileStore(uidProvider: () => 'account-b');
    await account.saveRaw(jsonEncode({'adSoyad': 'Mevcut Profil'}));
    await guest.saveRaw(jsonEncode({'adSoyad': 'Konuk Taslağı'}));

    expect((await account.readMap())['adSoyad'], 'Mevcut Profil');
    expect(await guest.readMap(), isEmpty);
    expect(await other.readMap(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('kisisel_bilgiler_v2_guest_pending'), isNull);
  });

  test('eski ortak kayıt bir kez taşınır, sonraki hesaba geçmez', () async {
    SharedPreferences.setMockInitialValues({
      'kisisel_bilgiler': jsonEncode({'adSoyad': 'Eski Profil'}),
    });
    final first = PersonalProfileStore(uidProvider: () => 'account-a');
    expect((await first.readMap())['adSoyad'], 'Eski Profil');
    expect(
        (await SharedPreferences.getInstance()).getString('kisisel_bilgiler'),
        isNull);
    expect(await PersonalProfileStore(uidProvider: () => 'account-b').readMap(),
        isEmpty);
  });
}
