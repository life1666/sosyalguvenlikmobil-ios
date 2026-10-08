import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:src/screens/yillik_maas_analizi.dart';
import 'package:src/services/calisma_hayati_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('12 aylık Türkçe çalışma raporu PDF olarak oluşturulur', () async {
    await initializeDateFormatting('tr_TR');
    final months = List.generate(
      12,
      (index) => AylikMaasAnalizi(
        monthIndex: index,
        deductions: const {
          'brut': 65000,
          'net': 45705,
          'toplam': 19295,
          'sgk': 9100,
          'issizlik': 650,
          'gelirVergisi': 9302,
          'damgaVergisi': 243,
        },
      ),
    );

    final bytes = await CalismaHayatiPdfService.generate(
      CalismaHayatiRaporVerisi(
        adSoyad: 'Çağrı Şahin',
        cinsiyet: 'Erkek',
        sigortaKolu: '4/a (SSK)',
        dogumTarihi: DateTime(1988, 5, 15),
        ilkSigortaTarihi: DateTime(2008, 9, 1),
        mevcutIsBaslangici: DateTime(2021, 3, 15),
        primGunu: 5400,
        guncelBrutMaas: 65000,
        aylikAnalizler: months,
        emeklilik: null,
        kidem: null,
        yillikIzinGunu: 12,
      ),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));
  });
}
