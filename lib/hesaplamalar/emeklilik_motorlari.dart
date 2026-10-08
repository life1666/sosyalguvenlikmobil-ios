import 'emeklilik_tahmin_aciklamasi.dart';

// Existing 4/b and 4/c retirement rules shared by calculators and profile views.
String _formatDateDot(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

String _formatDateSlash(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

Map<String, dynamic> emeklilikHesapla4b(
  DateTime dogumTarihi,
  String cinsiyet,
  DateTime sigortaBaslangic,
  int primGun,
) {
  final DateTime today = DateTime.now();

  int age = today.year - dogumTarihi.year;
  if (DateTime(today.year, dogumTarihi.month, dogumTarihi.day).isAfter(today)) {
    age--;
  }

  int insuranceYears = today.year - sigortaBaslangic.year;
  if (DateTime(today.year, sigortaBaslangic.month, sigortaBaslangic.day)
      .isAfter(today)) {
    insuranceYears--;
  }

  bool normalEligible = false;
  bool ageLimitEligible = false;
  String message = "";
  Map<String, String> details = {};
  Map<String, Map<String, dynamic>> tahminiSonuclar = {};

  // Kategoriler
  final DateTime cat1Upper = DateTime(1999, 9, 9); // 08.09.1999 dahil
  final DateTime cat2Upper = DateTime(2008, 5, 1); // 30.04.2008 dahil
  final DateTime cat3Lower = DateTime(2008, 5, 1); // 01.05.2008 ve sonrası

  int reqInsuranceYearsNormal = 0;
  int reqPrimNormal = 0;
  int reqAgeNormal = 0;

  int reqInsuranceYearsYas = 0;
  int reqPrimYas = 0;
  int reqAgeYas = 0;

  if (sigortaBaslangic.isBefore(cat1Upper)) {
    // 1. Kategori: 09.09.1999'dan önceki tarihler (08.09.1999 dahil)
    if (cinsiyet == "Erkek") {
      reqInsuranceYearsNormal = 25;
      reqPrimNormal = 9000;
      reqAgeNormal = 0;

      reqInsuranceYearsYas = 0;
      reqPrimYas = 5400;
      reqAgeYas = 58;

      normalEligible = (primGun >= reqPrimNormal &&
          insuranceYears >= reqInsuranceYearsNormal);
      ageLimitEligible = (age >= 58 && primGun >= 5400);

      details["Normal Emeklilik"] =
          "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 58 Yaş, 5400 Gün";
    } else if (cinsiyet == "Kadın") {
      reqInsuranceYearsNormal = 20;
      reqPrimNormal = 7200;
      reqAgeNormal = 0;

      reqInsuranceYearsYas = 0;
      reqPrimYas = 5400;
      reqAgeYas = 56;

      normalEligible = (primGun >= reqPrimNormal &&
          insuranceYears >= reqInsuranceYearsNormal);
      ageLimitEligible = (age >= 56 && primGun >= 5400);

      details["Normal Emeklilik"] =
          "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 56 Yaş, 5400 Gün";
    }
  } else if (sigortaBaslangic.isBefore(cat2Upper) &&
      sigortaBaslangic.isAfter(cat1Upper.subtract(const Duration(days: 1)))) {
    // 2. Kategori: 09.09.1999 – 30.04.2008
    if (cinsiyet == "Erkek") {
      reqInsuranceYearsNormal = 0;
      reqPrimNormal = 9000;
      reqAgeNormal = 60;

      reqInsuranceYearsYas = 0;
      reqPrimYas = 5400;
      reqAgeYas = 62;

      normalEligible = (primGun >= 9000 && age >= 60);
      ageLimitEligible = (primGun >= 5400 && age >= 62);

      details["Normal Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 60 Yaş, 9000 Gün";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 62 Yaş, 5400 Gün";
    } else if (cinsiyet == "Kadın") {
      reqInsuranceYearsNormal = 0;
      reqPrimNormal = 9000;
      reqAgeNormal = 58;

      reqInsuranceYearsYas = 0;
      reqPrimYas = 5400;
      reqAgeYas = 60;

      normalEligible = (primGun >= 9000 && age >= 58);
      ageLimitEligible = (primGun >= 5400 && age >= 60);

      details["Normal Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 58 Yaş, 9000 Gün";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 60 Yaş, 5400 Gün";
    }
  } else if (sigortaBaslangic
      .isAfter(cat3Lower.subtract(const Duration(days: 1)))) {
    // 3. Kategori: 01.05.2008 ve sonrası
    const int normalReqPrim = 9000;
    reqPrimNormal = normalReqPrim;

    // 1) Eksik prim (360 gün = 1 yıl varsayımı)
    final int eksikPrimGunu = normalReqPrim - primGun;
    final int eksikTamYil = eksikPrimGunu ~/ 360;
    final int eksikGunKalan = eksikPrimGunu % 360;
    final DateTime araTarih =
        DateTime(today.year + eksikTamYil, today.month, today.day);
    DateTime primCompletion = araTarih.add(Duration(days: eksikGunKalan));

    // 2) Kademeli yaş
    int normalReqAge;
    if (primCompletion.isBefore(DateTime(2036, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 60 : 58;
    } else if (primCompletion.isBefore(DateTime(2038, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 61 : 59;
    } else if (primCompletion.isBefore(DateTime(2040, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 62 : 60;
    } else if (primCompletion.isBefore(DateTime(2042, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 63 : 61;
    } else if (primCompletion.isBefore(DateTime(2044, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 64 : 62;
    } else if (primCompletion.isBefore(DateTime(2046, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 65 : 63;
    } else if (primCompletion.isBefore(DateTime(2048, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 65 : 64;
    } else {
      normalReqAge = 65;
    }
    reqAgeNormal = normalReqAge;

    normalEligible = (primGun >= normalReqPrim && age >= reqAgeNormal);

    // --- YAŞ HADDİ ---
    const int ageLimitPrim = 5400;
    reqPrimYas = ageLimitPrim;

    final int eksikPrimYas = ageLimitPrim - primGun;
    final int eksikTamYilYas = eksikPrimYas ~/ 360;
    final int eksikGunKalanYas = eksikPrimYas % 360;
    final DateTime araTarihYas =
        DateTime(today.year + eksikTamYilYas, today.month, today.day);
    DateTime ageLimitPrimCompletion =
        araTarihYas.add(Duration(days: eksikGunKalanYas));

    int ageLimitReqAge;
    if (ageLimitPrimCompletion.isBefore(DateTime(2036, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 63 : 61;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2038, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 64 : 62;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2040, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 65 : 63;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2042, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 65 : 64;
    } else {
      ageLimitReqAge = 65;
    }
    reqAgeYas = ageLimitReqAge;

    ageLimitEligible = (primGun >= ageLimitPrim && age >= ageLimitReqAge);

    details["Normal Emeklilik"] =
        "Mevcut: $primGun Gün, $age Yaş | Gerekli: $normalReqPrim Gün, $reqAgeNormal Yaş";
    details["Yaş Haddinden Emeklilik"] =
        "Mevcut: $primGun Gün, $age Yaş | Gerekli: $ageLimitPrim Gün, $reqAgeYas Yaş";
  } else {
    message = "Sistem uygun emeklilik kriterini belirleyemedi.";
  }

  // --- TAHMİNİ TARİHLER ---

  // Normal
  if (!normalEligible && reqPrimNormal > 0) {
    int eksikPrim = reqPrimNormal - primGun;
    double eksikYilDouble = eksikPrim > 0 ? eksikPrim / 360 : 0.0;

    int eksikTamYil = eksikPrim ~/ 360;
    int eksikGunKalan = eksikPrim % 360;
    DateTime araTarih =
        DateTime(today.year + eksikTamYil, today.month, today.day);
    DateTime primDolma = araTarih.add(Duration(days: eksikGunKalan));

    int olasiYas = primDolma.year - dogumTarihi.year;
    if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day)
        .isAfter(primDolma)) {
      olasiYas--;
    }

    if (reqAgeNormal > 0 && olasiYas < reqAgeNormal) {
      primDolma = DateTime(
          dogumTarihi.year + reqAgeNormal, dogumTarihi.month, dogumTarihi.day);
      olasiYas = reqAgeNormal;
    }

    tahminiSonuclar["Normal Emeklilik"] = {
      "tahminiTarih": primDolma,
      "tahminiYas": olasiYas,
      "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
      "eksikYil": eksikYilDouble > 0 ? eksikYilDouble : 0,
      "mesaj":
          emeklilikTahminAciklamasi(
            tur: 'normal emeklilik',
            tahminiTarih: primDolma,
            mevcutPrim: primGun,
            gerekliPrim: reqPrimNormal,
            mevcutSigortalilikYili: insuranceYears,
            gerekliSigortalilikYili: reqInsuranceYearsNormal,
            mevcutYas: age,
            gerekliYas: reqAgeNormal,
          )
    };
  }

  // Yaş haddi
  if (!ageLimitEligible && reqPrimYas > 0) {
    int eksikPrim = reqPrimYas - primGun;
    double eksikYilDouble = eksikPrim > 0 ? eksikPrim / 360 : 0.0;

    int eksikTamYilYas = eksikPrim ~/ 360;
    int eksikGunKalanYas = eksikPrim % 360;
    DateTime araTarihYas =
        DateTime(today.year + eksikTamYilYas, today.month, today.day);
    DateTime primDolma = araTarihYas.add(Duration(days: eksikGunKalanYas));

    int olasiYas = primDolma.year - dogumTarihi.year;
    if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day)
        .isAfter(primDolma)) {
      olasiYas--;
    }

    if (reqAgeYas > 0 && olasiYas < reqAgeYas) {
      primDolma = DateTime(
          dogumTarihi.year + reqAgeYas, dogumTarihi.month, dogumTarihi.day);
      olasiYas = reqAgeYas;
    }

    tahminiSonuclar["Yaş Haddinden Emeklilik"] = {
      "tahminiTarih": primDolma,
      "tahminiYas": olasiYas,
      "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
      "eksikYil": eksikYilDouble > 0 ? eksikYilDouble : 0,
      "mesaj":
          emeklilikTahminAciklamasi(
            tur: 'yaş haddinden emeklilik',
            tahminiTarih: primDolma,
            mevcutPrim: primGun,
            gerekliPrim: reqPrimYas,
            mevcutSigortalilikYili: insuranceYears,
            gerekliSigortalilikYili: reqInsuranceYearsYas,
            mevcutYas: age,
            gerekliYas: reqAgeYas,
          )
    };
  }

  return {
    'emekliMi': {
      'normal': normalEligible,
      'yasHaddi': ageLimitEligible,
    },
    'mesaj': {
      'birlesik': message,
    },
    'detaylar': {
      'birlesik': details,
    },
    'tahminiSonuclar': tahminiSonuclar,
    'reqPrimNormal': reqPrimNormal,
    'reqAgeNormal': reqAgeNormal,
    'reqInsuranceYearsNormal': reqInsuranceYearsNormal,
    'reqPrimYas': reqPrimYas,
    'reqAgeYas': reqAgeYas,
    'reqInsuranceYearsYas': reqInsuranceYearsYas,
    'currentAge': age,
    'currentInsuranceYears': insuranceYears,
    'currentPrim': primGun,
    'ekBilgi': {
      'Kontrol Tarihi': _formatDateSlash(DateTime.now()),
    },
  };
}

Map<String, dynamic> emeklilikHesapla4c(
  DateTime dogumTarihi,
  String cinsiyet,
  DateTime sigortaBaslangic,
  int primGun,
) {
  final DateTime today = DateTime.now();

  int age = today.year - dogumTarihi.year;
  if (DateTime(today.year, dogumTarihi.month, dogumTarihi.day).isAfter(today)) {
    age--;
  }

  int insuranceYears = today.year - sigortaBaslangic.year;
  if (DateTime(today.year, sigortaBaslangic.month, sigortaBaslangic.day)
      .isAfter(today)) {
    insuranceYears--;
  }

  bool normalEligible = false;
  bool ageLimitEligible = false;
  String message = "";
  Map<String, String> details = {};
  Map<String, Map<String, dynamic>> tahminiSonuclar = {};

  // Kategoriler (4/C – Emekli Sandığı)
  final DateTime cat1Upper = DateTime(1999, 9, 9); // 08.09.1999 dahil
  final DateTime cat2Upper = DateTime(2008, 5, 1); // 30.04.2008 dahil
  final DateTime cat3Lower = DateTime(2008, 5, 1); // 01.05.2008 ve sonrası

  int reqInsuranceYearsNormal = 0;
  int reqPrimNormal = 0;
  int reqAgeNormal = 0;

  int reqInsuranceYearsYas = 0;
  int reqPrimYas = 0;
  int reqAgeYas = 0;

  if (sigortaBaslangic.isBefore(cat1Upper)) {
    // 1. Kategori: 09.09.1999'dan önce
    if (cinsiyet == "Erkek") {
      reqInsuranceYearsNormal = 25;
      reqPrimNormal = 9000;

      reqPrimYas = 5400;
      reqAgeYas = 60;

      normalEligible = (primGun >= reqPrimNormal &&
          insuranceYears >= reqInsuranceYearsNormal);
      ageLimitEligible = (age >= 60 && primGun >= 5400);

      details["Normal Emeklilik"] =
          "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 60 Yaş, 5400 Gün";
    } else if (cinsiyet == "Kadın") {
      reqInsuranceYearsNormal = 20;
      reqPrimNormal = 7200;

      reqPrimYas = 5400;
      reqAgeYas = 58;

      normalEligible = (primGun >= reqPrimNormal &&
          insuranceYears >= reqInsuranceYearsNormal);
      ageLimitEligible = (age >= 58 && primGun >= 5400);

      details["Normal Emeklilik"] =
          "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 58 Yaş, 5400 Gün";
    }
  } else if (sigortaBaslangic.isBefore(cat2Upper) &&
      sigortaBaslangic.isAfter(cat1Upper.subtract(const Duration(days: 1)))) {
    // 2. Kategori: 09.09.1999 – 30.04.2008
    if (cinsiyet == "Erkek") {
      reqInsuranceYearsNormal = 25;
      reqAgeNormal = 60;

      reqInsuranceYearsYas = 15;
      reqAgeYas = 61;

      normalEligible = (insuranceYears >= 25 && age >= 60);
      ageLimitEligible = (insuranceYears >= 15 && age >= 61);

      details["Normal Emeklilik"] =
          "Mevcut: $age Yaş, $insuranceYears Yıl | Gerekli: 60 Yaş, 25 Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $insuranceYears Yıl | Gerekli: 61 Yaş, 15 Yıl";
    } else if (cinsiyet == "Kadın") {
      reqInsuranceYearsNormal = 25;
      reqAgeNormal = 58;

      reqInsuranceYearsYas = 15;
      reqAgeYas = 61;

      normalEligible = (insuranceYears >= 25 && age >= 58);
      ageLimitEligible = (insuranceYears >= 15 && age >= 61);

      details["Normal Emeklilik"] =
          "Mevcut: $age Yaş, $insuranceYears Yıl | Gerekli: 58 Yaş, 25 Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $insuranceYears Yıl | Gerekli: 61 Yaş, 15 Yıl";
    }
  } else if (sigortaBaslangic
      .isAfter(cat3Lower.subtract(const Duration(days: 1)))) {
    // 3. Kategori: 01.05.2008 ve sonrası
    const int normalReqPrim = 9000;
    reqPrimNormal = normalReqPrim;

    // 1) Eksik prim (360 gün = 1 yıl varsayımı)
    final int eksikPrimGunu = normalReqPrim - primGun;
    final int eksikTamYil = eksikPrimGunu ~/ 360;
    final int eksikGunKalan = eksikPrimGunu % 360;
    final DateTime araTarih =
        DateTime(today.year + eksikTamYil, today.month, today.day);
    DateTime primCompletion = araTarih.add(Duration(days: eksikGunKalan));

    // 2) Kademeli yaş
    int normalReqAge;
    if (primCompletion.isBefore(DateTime(2036, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 60 : 58;
    } else if (primCompletion.isBefore(DateTime(2038, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 61 : 59;
    } else if (primCompletion.isBefore(DateTime(2040, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 62 : 60;
    } else if (primCompletion.isBefore(DateTime(2042, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 63 : 61;
    } else if (primCompletion.isBefore(DateTime(2044, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 64 : 62;
    } else if (primCompletion.isBefore(DateTime(2046, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 65 : 63;
    } else if (primCompletion.isBefore(DateTime(2048, 1, 1))) {
      normalReqAge = (cinsiyet == "Erkek") ? 65 : 64;
    } else {
      normalReqAge = 65;
    }
    reqAgeNormal = normalReqAge;

    normalEligible = (primGun >= normalReqPrim && age >= reqAgeNormal);

    // --- YAŞ HADDİ ---
    const int ageLimitPrim = 5400;
    reqPrimYas = ageLimitPrim;

    final int eksikPrimYas = ageLimitPrim - primGun;
    final int eksikTamYilYas = eksikPrimYas ~/ 360;
    final int eksikGunKalanYas = eksikPrimYas % 360;
    final DateTime araTarihYas =
        DateTime(today.year + eksikTamYilYas, today.month, today.day);
    DateTime ageLimitPrimCompletion =
        araTarihYas.add(Duration(days: eksikGunKalanYas));

    int ageLimitReqAge;
    if (ageLimitPrimCompletion.isBefore(DateTime(2036, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 63 : 61;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2038, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 64 : 62;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2040, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 65 : 63;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2042, 1, 1))) {
      ageLimitReqAge = (cinsiyet == "Erkek") ? 65 : 64;
    } else {
      ageLimitReqAge = 65;
    }
    reqAgeYas = ageLimitReqAge;

    ageLimitEligible = (primGun >= ageLimitPrim && age >= ageLimitReqAge);

    details["Normal Emeklilik"] =
        "Mevcut: $primGun Gün, $age Yaş | Gerekli: $normalReqPrim Gün, $reqAgeNormal Yaş";
    details["Yaş Haddinden Emeklilik"] =
        "Mevcut: $primGun Gün, $age Yaş | Gerekli: $ageLimitPrim Gün, $reqAgeYas Yaş";
  } else {
    message = "Sistem uygun emeklilik kriterini belirleyemedi.";
  }

  // --- TAHMİNİ TARİHLER ---

  // Normal (prim gününe dayalı)
  if (!normalEligible && reqPrimNormal > 0) {
    int eksikPrim = reqPrimNormal - primGun;
    double eksikYilDouble = eksikPrim > 0 ? eksikPrim / 360 : 0.0;

    int eksikTamYil = eksikPrim ~/ 360;
    int eksikGunKalan = eksikPrim % 360;
    DateTime araTarih =
        DateTime(today.year + eksikTamYil, today.month, today.day);
    DateTime primDolma = araTarih.add(Duration(days: eksikGunKalan));

    int olasiYas = primDolma.year - dogumTarihi.year;
    if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day)
        .isAfter(primDolma)) {
      olasiYas--;
    }

    if (reqAgeNormal > 0 && olasiYas < reqAgeNormal) {
      primDolma = DateTime(
          dogumTarihi.year + reqAgeNormal, dogumTarihi.month, dogumTarihi.day);
      olasiYas = reqAgeNormal;
    }

    tahminiSonuclar["Normal Emeklilik"] = {
      "tahminiTarih": primDolma,
      "tahminiYas": olasiYas,
      "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
      "eksikYil": eksikYilDouble > 0 ? eksikYilDouble : 0,
      "mesaj":
          emeklilikTahminAciklamasi(
            tur: 'normal emeklilik',
            tahminiTarih: primDolma,
            mevcutPrim: primGun,
            gerekliPrim: reqPrimNormal,
            mevcutSigortalilikYili: insuranceYears,
            gerekliSigortalilikYili: reqInsuranceYearsNormal,
            mevcutYas: age,
            gerekliYas: reqAgeNormal,
          )
    };
  } else if (!normalEligible && reqInsuranceYearsNormal > 0) {
    // Normal (sigortalılık yılına dayalı)
    int eksikYil = reqInsuranceYearsNormal - insuranceYears;
    DateTime primDolma =
        DateTime(today.year + eksikYil, today.month, today.day);

    int olasiYas = primDolma.year - dogumTarihi.year;
    if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day)
        .isAfter(primDolma)) {
      olasiYas--;
    }

    if (reqAgeNormal > 0 && olasiYas < reqAgeNormal) {
      primDolma = DateTime(
          dogumTarihi.year + reqAgeNormal, dogumTarihi.month, dogumTarihi.day);
      olasiYas = reqAgeNormal;
    }

    tahminiSonuclar["Normal Emeklilik"] = {
      "tahminiTarih": primDolma,
      "tahminiYas": olasiYas,
      "eksikPrim": 0,
      "eksikYil": eksikYil > 0 ? eksikYil : 0,
      "mesaj":
          emeklilikTahminAciklamasi(
            tur: 'normal emeklilik',
            tahminiTarih: primDolma,
            mevcutPrim: primGun,
            gerekliPrim: reqPrimNormal,
            mevcutSigortalilikYili: insuranceYears,
            gerekliSigortalilikYili: reqInsuranceYearsNormal,
            mevcutYas: age,
            gerekliYas: reqAgeNormal,
          )
    };
  }

  // Yaş haddi
  if (!ageLimitEligible && reqPrimYas > 0) {
    int eksikPrim = reqPrimYas - primGun;
    double eksikYilDouble = eksikPrim > 0 ? eksikPrim / 360 : 0.0;

    int eksikTamYilYas = eksikPrim ~/ 360;
    int eksikGunKalanYas = eksikPrim % 360;
    DateTime araTarihYas =
        DateTime(today.year + eksikTamYilYas, today.month, today.day);
    DateTime primDolma = araTarihYas.add(Duration(days: eksikGunKalanYas));

    int olasiYas = primDolma.year - dogumTarihi.year;
    if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day)
        .isAfter(primDolma)) {
      olasiYas--;
    }

    if (reqAgeYas > 0 && olasiYas < reqAgeYas) {
      primDolma = DateTime(
          dogumTarihi.year + reqAgeYas, dogumTarihi.month, dogumTarihi.day);
      olasiYas = reqAgeYas;
    }

    tahminiSonuclar["Yaş Haddinden Emeklilik"] = {
      "tahminiTarih": primDolma,
      "tahminiYas": olasiYas,
      "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
      "eksikYil": eksikYilDouble > 0 ? eksikYilDouble : 0,
      "mesaj":
          emeklilikTahminAciklamasi(
            tur: 'yaş haddinden emeklilik',
            tahminiTarih: primDolma,
            mevcutPrim: primGun,
            gerekliPrim: reqPrimYas,
            mevcutSigortalilikYili: insuranceYears,
            gerekliSigortalilikYili: reqInsuranceYearsYas,
            mevcutYas: age,
            gerekliYas: reqAgeYas,
          )
    };
  } else if (!ageLimitEligible && reqInsuranceYearsYas > 0) {
    int eksikYil = reqInsuranceYearsYas - insuranceYears;
    DateTime primDolma =
        DateTime(today.year + eksikYil, today.month, today.day);

    int olasiYas = primDolma.year - dogumTarihi.year;
    if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day)
        .isAfter(primDolma)) {
      olasiYas--;
    }

    if (reqAgeYas > 0 && olasiYas < reqAgeYas) {
      primDolma = DateTime(
          dogumTarihi.year + reqAgeYas, dogumTarihi.month, dogumTarihi.day);
      olasiYas = reqAgeYas;
    }

    tahminiSonuclar["Yaş Haddinden Emeklilik"] = {
      "tahminiTarih": primDolma,
      "tahminiYas": olasiYas,
      "eksikPrim": 0,
      "eksikYil": eksikYil > 0 ? eksikYil : 0,
      "mesaj":
          emeklilikTahminAciklamasi(
            tur: 'yaş haddinden emeklilik',
            tahminiTarih: primDolma,
            mevcutPrim: primGun,
            gerekliPrim: reqPrimYas,
            mevcutSigortalilikYili: insuranceYears,
            gerekliSigortalilikYili: reqInsuranceYearsYas,
            mevcutYas: age,
            gerekliYas: reqAgeYas,
          )
    };
  }

  return {
    'emekliMi': {
      'normal': normalEligible,
      'yasHaddi': ageLimitEligible,
    },
    'mesaj': {
      'birlesik': message,
    },
    'detaylar': {
      'birlesik': details,
    },
    'tahminiSonuclar': tahminiSonuclar,
    'reqPrimNormal': reqPrimNormal,
    'reqAgeNormal': reqAgeNormal,
    'reqInsuranceYearsNormal': reqInsuranceYearsNormal,
    'reqPrimYas': reqPrimYas,
    'reqAgeYas': reqAgeYas,
    'reqInsuranceYearsYas': reqInsuranceYearsYas,
    'currentAge': age,
    'currentInsuranceYears': insuranceYears,
    'currentPrim': primGun,
    'ekBilgi': {
      'Kontrol Tarihi': _formatDateSlash(DateTime.now()),
    },
  };
}
