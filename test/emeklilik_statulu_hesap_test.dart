import 'package:flutter_test/flutter_test.dart';
import 'package:src/utils/emeklilik_statulu_hesap.dart';

void main() {
  Map<String, dynamic> calculate(String status, DateTime start) =>
      emeklilikHesaplaStatulu(
        sigortaKolu: status,
        dogumTarihi: DateTime(1980, 1, 1),
        cinsiyet: 'Erkek',
        sigortaBaslangici: start,
        primGunu: 3000,
      )!;

  test('4/b ve 4/c seçimi 4/a prim kuralına düşmez', () {
    final start = DateTime(2010, 1, 1);
    final ssk = calculate('4/a (SSK)', start);
    final bagkur = calculate('4/b (Bağ-Kur)', start);
    final memur = calculate('4/c (Memur)', start);

    expect(ssk['reqPrimNormal'], 7200);
    expect(bagkur['reqPrimNormal'], 9000);
    expect(memur['reqPrimNormal'], 9000);
  });

  test('2000 girişli 4/c için hizmet yılı koşulu döner', () {
    final result = calculate('4/c (Memur)', DateTime(2000, 1, 1));

    expect(result['reqPrimNormal'], 0);
    expect(result['reqInsuranceYearsNormal'], 25);
    expect(result['reqAgeNormal'], 60);
  });

  test('bilinmeyen statü 4/a hesabına yönlendirilmez', () {
    expect(
      emeklilikHesaplaStatulu(
        sigortaKolu: 'bilinmiyor',
        dogumTarihi: DateTime(1980, 1, 1),
        cinsiyet: 'Erkek',
        sigortaBaslangici: DateTime(2010, 1, 1),
        primGunu: 3000,
      ),
      isNull,
    );
  });
}
