import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:src/services/personal_profile_store.dart';
import 'package:src/sonhesaplama/sonhesaplama.dart';
import 'package:src/utils/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SonHesaplama calculation(String id) => SonHesaplama(
        id: id,
        hesaplamaTuru: 'Kıdem Tazminatı',
        tarihSaat: DateTime(2026, 9, 29),
        veriler: const {},
        sonuclar: const {},
      );

  test('çıkış ve hesap değişiminde ilerleme ile geçmiş karışmaz', () async {
    SharedPreferences.setMockInitialValues({});
    await PersonalProfileStore(uidProvider: () => 'account-a').saveRaw(
      jsonEncode({
        'dogumTarihi': DateTime(1990).millisecondsSinceEpoch,
        'cinsiyet': 'Kadın',
        'sigortaKolu': '4/a (SSK)',
        'ilkIseGirisTarihi': DateTime(2010).millisecondsSinceEpoch,
        'toplamPrimGun': 3600,
      }),
    );
    await SonHesaplamalarDeposu.ekle(calculation('a'),
        uidProvider: () => 'account-a');
    await ProgressService.record('community_question_created',
        uidProvider: () => 'account-a');

    final first = await ProgressService.load(uidProvider: () => 'account-a');
    final second = await ProgressService.load(uidProvider: () => 'account-b');
    final guest = await ProgressService.load(uidProvider: () => null);

    expect(first.score, greaterThan(0));
    expect(first.calculationCount, 1);
    expect(first.badges.first.unlocked, isTrue);
    expect(
        first.badges
            .firstWhere((badge) => badge.title == 'Topluluk Üyesi')
            .unlocked,
        isTrue);
    expect(second.score, 0);
    expect(second.calculationCount, 0);
    expect(guest.score, 0);
    expect(guest.calculationCount, 0);
  });

  test('eski ortak kayıt misafire görünmez ve yalnız ilk hesaba taşınır',
      () async {
    SharedPreferences.setMockInitialValues({
      'progress_events_v1': jsonEncode({'rights_opened': 1}),
      'son_hesaplamalar': jsonEncode([calculation('old').toJson()]),
    });

    final guest = await ProgressService.load(uidProvider: () => null);
    expect(guest.score, 0);
    expect(guest.calculationCount, 0);

    final first = await ProgressService.load(uidProvider: () => 'account-a');
    final second = await ProgressService.load(uidProvider: () => 'account-b');
    expect(first.calculationCount, 1);
    expect(first.tasks.firstWhere((task) => task.id == 'rights_open').completed,
        isTrue);
    expect(second.calculationCount, 0);
    expect(
        second.tasks.firstWhere((task) => task.id == 'rights_open').completed,
        isFalse);
  });

  test('hesap silinince ilerleme ve geçmiş bu cihazdan kaldırılır', () async {
    SharedPreferences.setMockInitialValues({});
    await SonHesaplamalarDeposu.ekle(calculation('a'),
        uidProvider: () => 'account-a');
    await ProgressService.record('rights_opened',
        uidProvider: () => 'account-a');
    await SonHesaplamalarDeposu.removeForUid('account-a');
    await ProgressService.removeForUid('account-a');

    final snapshot = await ProgressService.load(uidProvider: () => 'account-a');
    expect(snapshot.calculationCount, 0);
    expect(snapshot.score, 0);
  });
}
