import 'package:flutter_test/flutter_test.dart';
import 'package:src/utils/kidem_yazisi_hesabi.dart';

void main() {
  final kontrolTarihi = DateTime(2026, 9, 21);

  test('eksik prim kazanılmış hak oluşturmaz', () {
    final sonuc = kidemYazisiHesapla(
      sigortaBaslangici: DateTime(2000, 1, 1),
      primGunu: 4499,
      sonIsyerindekiCalismaYili: 5,
      kontrolTarihi: kontrolTarihi,
    );

    expect(sonuc.hakKazandi, isFalse);
    expect(sonuc.eksikPrim, 1);
  });

  test('mevcut işyerinde bir yıl dolmadan hak oluşmaz', () {
    final sonuc = kidemYazisiHesapla(
      sigortaBaslangici: DateTime(2000, 1, 1),
      primGunu: 7000,
      sonIsyerindekiCalismaYili: 0,
      kontrolTarihi: kontrolTarihi,
    );

    expect(sonuc.hakKazandi, isFalse);
    expect(sonuc.eksikCalismaYili, 1);
  });

  test('1999-2008 döneminde 25 yıl ve 4500 gün hakkı oluşturur', () {
    final sonuc = kidemYazisiHesapla(
      sigortaBaslangici: DateTime(2000, 1, 1),
      primGunu: 4500,
      sonIsyerindekiCalismaYili: 5,
      kontrolTarihi: kontrolTarihi,
    );

    expect(sonuc.hakKazandi, isTrue);
  });

  test('1999-2008 döneminde 7000 gün 25 yıl beklemez', () {
    final sonuc = kidemYazisiHesapla(
      sigortaBaslangici: DateTime(2005, 1, 1),
      primGunu: 7000,
      sonIsyerindekiCalismaYili: 2,
      kontrolTarihi: kontrolTarihi,
    );

    expect(sonuc.hakKazandi, isTrue);
  });
}
