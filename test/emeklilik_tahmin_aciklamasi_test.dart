import 'package:flutter_test/flutter_test.dart';
import 'package:src/hesaplamalar/4a_hesapla.dart';
import 'package:src/hesaplamalar/emeklilik_tahmin_aciklamasi.dart';

void main() {
  test('3600 gün tamamlandığında yalnız yaş koşulu açıklanır', () {
    final sonuc = emeklilikHesapla4a(
      DateTime(1975, 1, 1),
      'Erkek',
      DateTime(1995, 1, 1),
      6000,
    );
    final yasHaddi =
        sonuc['tahminiSonuclar']['Yaş Haddinden Emeklilik'] as Map;
    final mesaj = yasHaddi['mesaj'] as String;

    expect(yasHaddi['eksikPrim'], 0);
    expect(mesaj, contains('yaş dışındaki koşullarınız tamam'));
    expect(mesaj, contains('01.01.2035'));
    expect(mesaj, isNot(contains('bildirilmesi')));
  });

  test('prim eksikse tahmin bildirimin sürmesi varsayımını söyler', () {
    final mesaj = emeklilikTahminAciklamasi(
      tur: 'yaş haddinden emeklilik',
      tahminiTarih: DateTime(2035, 1, 1),
      mevcutPrim: 3000,
      gerekliPrim: 3600,
      mevcutSigortalilikYili: 30,
      gerekliSigortalilikYili: 15,
      mevcutYas: 51,
      gerekliYas: 60,
    );
    expect(mesaj, contains('Eksik prim günlerinizin düzenli bildirilmesi'));
  });

  test('sigortalılık süresi eksikse çalışmayı zorunlu göstermez', () {
    final mesaj = emeklilikTahminAciklamasi(
      tur: 'yaş haddinden emeklilik',
      tahminiTarih: DateTime(2035, 1, 1),
      mevcutPrim: 6000,
      gerekliPrim: 4500,
      mevcutSigortalilikYili: 20,
      gerekliSigortalilikYili: 25,
      mevcutYas: 51,
      gerekliYas: 60,
    );
    expect(mesaj, contains('Sigortalılık süresi'));
    expect(mesaj, isNot(contains('bildirilmesi')));
  });
}
