import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:src/screens/calisma_hayatim.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> showProfile(
    WidgetTester tester, {
    required String status,
    required DateTime insuranceStart,
  }) async {
    SharedPreferences.setMockInitialValues({
      'kisisel_bilgiler_v2_guest': jsonEncode({
        'adSoyad': 'Test Kullanıcısı',
        'dogumTarihi': DateTime(1980, 1, 1).millisecondsSinceEpoch,
        'ilkIseGirisTarihi': insuranceStart.millisecondsSinceEpoch,
        'toplamPrimGun': 3000,
        'primGunuReferansTarihi': DateTime.now().millisecondsSinceEpoch,
        'cinsiyet': 'Erkek',
        'sigortaKolu': status,
      }),
    });
    await initializeDateFormatting('tr_TR');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    await tester.pumpWidget(
      const MaterialApp(home: CalismaHayatimEkrani()),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('4/b ana ekranda 9000 gün hedefi gösterir', (tester) async {
    await showProfile(
      tester,
      status: '4/b (Bağ-Kur)',
      insuranceStart: DateTime(2010, 1, 1),
    );

    expect(find.text('3.000 / 9.000 gün'), findsOneWidget);
    expect(find.text('3.000 / 7.200 gün'), findsNothing);
  });

  testWidgets('4/c hizmet yılı gerektiğinde doğru satırı gösterir',
      (tester) async {
    await showProfile(
      tester,
      status: '4/c (Memur)',
      insuranceStart: DateTime(2000, 1, 1),
    );

    expect(find.text('Sigortalılık'), findsOneWidget);
    expect(find.textContaining('/ 25 yıl'), findsOneWidget);
    expect(find.text('3.000 / 7.200 gün'), findsNothing);
  });

  testWidgets('örnek görünüm kayıtlı kişisel verileri göstermez', (tester) async {
    SharedPreferences.setMockInitialValues({
      'kisisel_bilgiler_v2_guest': jsonEncode({
        'ilkIseGirisTarihi': DateTime(2020, 1, 1).millisecondsSinceEpoch,
      }),
    });
    await initializeDateFormatting('tr_TR');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    await tester.pumpWidget(const MaterialApp(
      home: CalismaHayatimEkrani(demoMode: true),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('01.09.2006'), findsOneWidget);
    expect(find.text('01.01.2020'), findsNothing);
  });
}
