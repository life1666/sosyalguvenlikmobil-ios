class KidemYazisiSonucu {
  const KidemYazisiSonucu({
    required this.hakKazandi,
    required this.gerekenPrim,
    required this.eksikPrim,
    required this.eksikCalismaYili,
    this.hata,
  });

  final bool hakKazandi;
  final int gerekenPrim;
  final int eksikPrim;
  final int eksikCalismaYili;
  final String? hata;
}

/// SGK'dan kıdem tazminatına esas yazı alınabilmesi için kullanılan ortak
/// hesap. Hesapla ve Haklarım ekranları aynı sonucu bu fonksiyondan alır.
KidemYazisiSonucu kidemYazisiHesapla({
  required DateTime sigortaBaslangici,
  required int primGunu,
  required int sonIsyerindekiCalismaYili,
  DateTime? kontrolTarihi,
}) {
  final now = kontrolTarihi ?? DateTime.now();
  final gunFarki = now.difference(sigortaBaslangici).inDays;
  final yilFarki = gunFarki ~/ 365;

  if (sigortaBaslangici.isAfter(now)) {
    return const KidemYazisiSonucu(
      hakKazandi: false,
      gerekenPrim: 0,
      eksikPrim: 0,
      eksikCalismaYili: 0,
      hata: 'Sigorta başlangıç tarihi gelecekte olamaz.',
    );
  }

  if (gunFarki < primGunu) {
    return const KidemYazisiSonucu(
      hakKazandi: false,
      gerekenPrim: 0,
      eksikPrim: 0,
      eksikCalismaYili: 0,
      hata:
          'Başlangıç tarihi ile kontrol tarihi arasındaki süreden fazla prim günü girilemez.',
    );
  }

  final eksikCalismaYili = sonIsyerindekiCalismaYili >= 1 ? 0 : 1;
  late final int gerekenPrim;
  late final bool sigortaKosuluSaglandi;

  if (sigortaBaslangici.isBefore(DateTime(1999, 9, 8))) {
    gerekenPrim = 3600;
    sigortaKosuluSaglandi = yilFarki >= 15 && primGunu >= gerekenPrim;
  } else if (sigortaBaslangici.isBefore(DateTime(2008, 5, 1))) {
    final prim7000Tamam = primGunu >= 7000;
    gerekenPrim = prim7000Tamam ? 7000 : 4500;
    sigortaKosuluSaglandi =
        prim7000Tamam || (yilFarki >= 25 && primGunu >= 4500);
  } else {
    final yil = sigortaBaslangici.year;
    gerekenPrim = yil < 2009
        ? 4600
        : yil < 2010
            ? 4700
            : yil < 2011
                ? 4800
                : yil < 2012
                    ? 4900
                    : yil < 2013
                        ? 5000
                        : yil < 2014
                            ? 5100
                            : yil < 2015
                                ? 5200
                                : yil < 2016
                                    ? 5300
                                    : 5400;
    sigortaKosuluSaglandi = primGunu >= gerekenPrim;
  }

  final eksikPrim = primGunu >= gerekenPrim ? 0 : gerekenPrim - primGunu;
  return KidemYazisiSonucu(
    hakKazandi: sigortaKosuluSaglandi && eksikCalismaYili == 0,
    gerekenPrim: gerekenPrim,
    eksikPrim: eksikPrim,
    eksikCalismaYili: eksikCalismaYili,
  );
}
