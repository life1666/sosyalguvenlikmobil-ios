/// 4/a (SSK) emeklilik hesaplama mantığı — Çalışma Hayatım ve 4a ekranı tarafından paylaşılır.
/// Birebir SSK kademeli yaş ve prim kuralları uygulanır.

String _formatDateDot(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
String _formatDateSlash(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

/// [dogumTarihi], [cinsiyet] (Erkek/Kadın), [sigortaBaslangic] (ilk işe giriş), [primGun] ile
/// 4/a emeklilik sonucunu döndürür. Ek alanlar: reqPrimNormal, reqAgeNormal, reqPrimYas, reqAgeYas, currentAge, currentPrim.
Map<String, dynamic> emeklilikHesapla4a(
  DateTime dogumTarihi,
  String cinsiyet,
  DateTime sigortaBaslangic,
  int primGun,
) {
  DateTime today = DateTime.now();

  int age = today.year - dogumTarihi.year;
  if (DateTime(today.year, dogumTarihi.month, dogumTarihi.day).isAfter(today)) {
    age--;
  }

  int insuranceYears = today.year - sigortaBaslangic.year;
  if (DateTime(today.year, sigortaBaslangic.month, sigortaBaslangic.day).isAfter(today)) {
    insuranceYears--;
  }

  bool normalEligible = false;
  bool ageLimitEligible = false;
  String message = "";
  Map<String, String> details = {};
  Map<String, Map<String, dynamic>> tahminiSonuclar = {};

  DateTime cat1Upper = DateTime(1999, 9, 9);
  DateTime cat2Upper = DateTime(2008, 5, 1);
  DateTime cat3Lower = DateTime(2008, 5, 1);

  int reqInsuranceYearsNormal = 0;
  int reqPrimNormal = 0;
  int reqAgeNormal = 0;

  int reqInsuranceYearsYas = 0;
  int reqPrimYas = 0;
  int reqAgeYas = 0;

  if (sigortaBaslangic.isBefore(cat1Upper)) {
    if (cinsiyet == "Erkek") {
      reqInsuranceYearsNormal = 25;
      if (sigortaBaslangic.isBefore(DateTime(1976, 9, 9))) {
        reqPrimNormal = 5000;
      } else if (sigortaBaslangic.isBefore(DateTime(1979, 5, 24))) {
        reqPrimNormal = 5000;
      } else if (sigortaBaslangic.isBefore(DateTime(1980, 11, 24))) {
        reqPrimNormal = 5000;
      } else if (sigortaBaslangic.isBefore(DateTime(1982, 5, 24))) {
        reqPrimNormal = 5075;
      } else if (sigortaBaslangic.isBefore(DateTime(1983, 11, 24))) {
        reqPrimNormal = 5150;
      } else if (sigortaBaslangic.isBefore(DateTime(1985, 5, 24))) {
        reqPrimNormal = 5225;
      } else if (sigortaBaslangic.isBefore(DateTime(1986, 11, 24))) {
        reqPrimNormal = 5300;
      } else if (sigortaBaslangic.isBefore(DateTime(1988, 5, 24))) {
        reqPrimNormal = 5375;
      } else if (sigortaBaslangic.isBefore(DateTime(1989, 11, 24))) {
        reqPrimNormal = 5450;
      } else if (sigortaBaslangic.isBefore(DateTime(1991, 5, 24))) {
        reqPrimNormal = 5525;
      } else if (sigortaBaslangic.isBefore(DateTime(1992, 11, 24))) {
        reqPrimNormal = 5600;
      } else if (sigortaBaslangic.isBefore(DateTime(1994, 5, 24))) {
        reqPrimNormal = 5675;
      } else if (sigortaBaslangic.isBefore(DateTime(1995, 11, 24))) {
        reqPrimNormal = 5750;
      } else if (sigortaBaslangic.isBefore(DateTime(1997, 5, 24))) {
        reqPrimNormal = 5825;
      } else if (sigortaBaslangic.isBefore(DateTime(1998, 11, 24))) {
        reqPrimNormal = 5900;
      } else {
        reqPrimNormal = 5975;
      }
      reqAgeNormal = 0;

      reqInsuranceYearsYas = 15;
      reqPrimYas = 3600;
      reqAgeYas = 60;

      normalEligible = (primGun >= reqPrimNormal && insuranceYears >= reqInsuranceYearsNormal);
      ageLimitEligible = today.isAfter(DateTime(2014, 5, 24)) &&
          age >= 60 &&
          primGun >= 3600 &&
          insuranceYears >= 15;

      details["Normal Emeklilik"] =
          "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 60 Yaş, 3600 Gün, 15 Yıl";
    } else {
      reqInsuranceYearsNormal = 20;
      if (sigortaBaslangic.isBefore(DateTime(1981, 9, 9))) {
        reqPrimNormal = 5000;
      } else if (sigortaBaslangic.isBefore(DateTime(1984, 5, 24))) {
        reqPrimNormal = 5000;
      } else if (sigortaBaslangic.isBefore(DateTime(1985, 5, 24))) {
        reqPrimNormal = 5000;
      } else if (sigortaBaslangic.isBefore(DateTime(1986, 5, 24))) {
        reqPrimNormal = 5075;
      } else if (sigortaBaslangic.isBefore(DateTime(1987, 5, 24))) {
        reqPrimNormal = 5150;
      } else if (sigortaBaslangic.isBefore(DateTime(1988, 5, 24))) {
        reqPrimNormal = 5225;
      } else if (sigortaBaslangic.isBefore(DateTime(1989, 5, 24))) {
        reqPrimNormal = 5300;
      } else if (sigortaBaslangic.isBefore(DateTime(1990, 5, 24))) {
        reqPrimNormal = 5375;
      } else if (sigortaBaslangic.isBefore(DateTime(1991, 5, 24))) {
        reqPrimNormal = 5450;
      } else if (sigortaBaslangic.isBefore(DateTime(1992, 5, 24))) {
        reqPrimNormal = 5525;
      } else if (sigortaBaslangic.isBefore(DateTime(1993, 5, 24))) {
        reqPrimNormal = 5600;
      } else if (sigortaBaslangic.isBefore(DateTime(1994, 5, 24))) {
        reqPrimNormal = 5675;
      } else if (sigortaBaslangic.isBefore(DateTime(1995, 5, 24))) {
        reqPrimNormal = 5750;
      } else if (sigortaBaslangic.isBefore(DateTime(1996, 5, 24))) {
        reqPrimNormal = 5825;
      } else if (sigortaBaslangic.isBefore(DateTime(1997, 5, 24))) {
        reqPrimNormal = 5900;
      } else {
        reqPrimNormal = 5975;
      }
      reqAgeNormal = 0;

      reqInsuranceYearsYas = 15;
      reqPrimYas = 3600;
      reqAgeYas = 58;

      normalEligible = (primGun >= reqPrimNormal && insuranceYears >= reqInsuranceYearsNormal);
      ageLimitEligible = today.isAfter(DateTime(2011, 5, 24)) &&
          age >= 58 &&
          primGun >= 3600 &&
          insuranceYears >= 15;

      details["Normal Emeklilik"] =
          "Mevcut: $primGun Gün, $insuranceYears Yıl | Gerekli: $reqPrimNormal Gün, $reqInsuranceYearsNormal Yıl";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 58 Yaş, 3600 Gün, 15 Yıl";
    }
  } else if (sigortaBaslangic.isBefore(cat2Upper) &&
      sigortaBaslangic.isAfter(cat1Upper.subtract(const Duration(days: 1)))) {
    if (cinsiyet == "Erkek") {
      reqInsuranceYearsNormal = 0;
      reqPrimNormal = 7000;
      reqAgeNormal = 60;

      reqInsuranceYearsYas = 25;
      reqPrimYas = 4500;
      reqAgeYas = 60;

      normalEligible = (primGun >= 7000 && age >= 60);
      ageLimitEligible = (primGun >= 4500 && age >= 60 && insuranceYears >= 25);

      details["Normal Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 60 Yaş, 7000 Gün";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 60 Yaş, 4500 Gün, 25 Yıl";
    } else {
      reqInsuranceYearsNormal = 0;
      reqPrimNormal = 7000;
      reqAgeNormal = 58;

      reqInsuranceYearsYas = 25;
      reqPrimYas = 4500;
      reqAgeYas = 58;

      normalEligible = (primGun >= 7000 && age >= 58);
      ageLimitEligible = (primGun >= 4500 && age >= 58 && insuranceYears >= 25);

      details["Normal Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün | Gerekli: 58 Yaş, 7000 Gün";
      details["Yaş Haddinden Emeklilik"] =
          "Mevcut: $age Yaş, $primGun Gün, $insuranceYears Yıl | Gerekli: 58 Yaş, 4500 Gün, 25 Yıl";
    }
  } else if (sigortaBaslangic.isAfter(cat3Lower.subtract(const Duration(days: 1)))) {
    final int normalReqPrim = 7200;
    reqPrimNormal = normalReqPrim;

    int eksikPrimGunu = normalReqPrim - primGun;
    int eksikTamYil = eksikPrimGunu ~/ 360;
    int eksikGunKalan = eksikPrimGunu % 360;
    DateTime araTarih = DateTime(DateTime.now().year + eksikTamYil, DateTime.now().month, DateTime.now().day);
    DateTime primCompletion = araTarih.add(Duration(days: eksikGunKalan));

    if (primCompletion.isBefore(DateTime(2036, 1, 1))) {
      reqAgeNormal = (cinsiyet == "Erkek") ? 60 : 58;
    } else if (primCompletion.isBefore(DateTime(2038, 1, 1))) {
      reqAgeNormal = (cinsiyet == "Erkek") ? 61 : 59;
    } else if (primCompletion.isBefore(DateTime(2040, 1, 1))) {
      reqAgeNormal = (cinsiyet == "Erkek") ? 62 : 60;
    } else if (primCompletion.isBefore(DateTime(2042, 1, 1))) {
      reqAgeNormal = (cinsiyet == "Erkek") ? 63 : 61;
    } else if (primCompletion.isBefore(DateTime(2044, 1, 1))) {
      reqAgeNormal = (cinsiyet == "Erkek") ? 64 : 62;
    } else if (primCompletion.isBefore(DateTime(2046, 1, 1))) {
      reqAgeNormal = (cinsiyet == "Erkek") ? 65 : 63;
    } else if (primCompletion.isBefore(DateTime(2048, 1, 1))) {
      reqAgeNormal = (cinsiyet == "Erkek") ? 65 : 64;
    } else {
      reqAgeNormal = 65;
    }

    if (sigortaBaslangic.isBefore(DateTime(2009, 1, 1))) {
      reqPrimYas = 4600;
    } else if (sigortaBaslangic.isBefore(DateTime(2010, 1, 1))) {
      reqPrimYas = 4700;
    } else if (sigortaBaslangic.isBefore(DateTime(2011, 1, 1))) {
      reqPrimYas = 4800;
    } else if (sigortaBaslangic.isBefore(DateTime(2012, 1, 1))) {
      reqPrimYas = 4900;
    } else if (sigortaBaslangic.isBefore(DateTime(2013, 1, 1))) {
      reqPrimYas = 5000;
    } else if (sigortaBaslangic.isBefore(DateTime(2014, 1, 1))) {
      reqPrimYas = 5100;
    } else if (sigortaBaslangic.isBefore(DateTime(2015, 1, 1))) {
      reqPrimYas = 5200;
    } else if (sigortaBaslangic.isBefore(DateTime(2016, 1, 1))) {
      reqPrimYas = 5300;
    } else {
      reqPrimYas = 5400;
    }

    int eksikPrimYas = reqPrimYas - primGun;
    int eksikTamYilYas = eksikPrimYas ~/ 360;
    int eksikGunKalanYas = eksikPrimYas % 360;
    DateTime araTarihYas = DateTime(DateTime.now().year + eksikTamYilYas, DateTime.now().month, DateTime.now().day);
    DateTime ageLimitPrimCompletion = araTarihYas.add(Duration(days: eksikGunKalanYas));

    if (ageLimitPrimCompletion.isBefore(DateTime(2036, 1, 1))) {
      reqAgeYas = (cinsiyet == "Erkek") ? 63 : 61;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2038, 1, 1))) {
      reqAgeYas = (cinsiyet == "Erkek") ? 64 : 62;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2040, 1, 1))) {
      reqAgeYas = (cinsiyet == "Erkek") ? 65 : 63;
    } else if (ageLimitPrimCompletion.isBefore(DateTime(2042, 1, 1))) {
      reqAgeYas = (cinsiyet == "Erkek") ? 65 : 64;
    } else {
      reqAgeYas = 65;
    }

    normalEligible = (primGun >= reqPrimNormal && age >= reqAgeNormal);
    ageLimitEligible = (primGun >= reqPrimYas && age >= reqAgeYas);

    details["Normal Emeklilik"] =
        "Mevcut: $primGun Gün, $age Yaş | Gerekli: $reqPrimNormal Gün, $reqAgeNormal Yaş";
    details["Yaş Haddinden Emeklilik"] =
        "Mevcut: $primGun Gün, $age Yaş | Gerekli: $reqPrimYas Gün, $reqAgeYas Yaş";
  } else {
    message = "Sistem uygun emeklilik kriterini belirleyemedi.";
  }

  if (!normalEligible && reqPrimNormal > 0) {
    int eksikPrim = reqPrimNormal - primGun;
    int eksikTamYil = eksikPrim ~/ 360;
    int eksikGunKalan = eksikPrim % 360;
    DateTime araTarih = DateTime(DateTime.now().year + eksikTamYil, DateTime.now().month, DateTime.now().day);
    DateTime primDolma = araTarih.add(Duration(days: eksikGunKalan));

    int olasiYas = primDolma.year - dogumTarihi.year;
    if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day).isAfter(primDolma)) {
      olasiYas--;
    }

    if (reqAgeNormal > 0 && olasiYas < reqAgeNormal) {
      primDolma = DateTime(dogumTarihi.year + reqAgeNormal, dogumTarihi.month, dogumTarihi.day);
      olasiYas = reqAgeNormal;
    }

    tahminiSonuclar["Normal Emeklilik"] = {
      "tahminiTarih": primDolma,
      "tahminiYas": olasiYas,
      "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
      "eksikYil": eksikPrim > 0 ? eksikPrim / 360 : 0.0,
      "mesaj":
          "Hesaplama Tarihi İtibarıyla Sigorta Bildirimleriniz Kesintisiz Devam Ederse, ${_formatDateDot(primDolma)} Tarihinde Normal Emeklilik Hakkı Kazanabilirsiniz."
    };
  }

  if (!ageLimitEligible && reqPrimYas > 0) {
    final int eksikPrim = reqPrimYas - primGun;
    final int eksikTamYilYas = eksikPrim ~/ 360;
    final int eksikGunKalanYas = eksikPrim % 360;
    final DateTime araTarihYas = DateTime(
      DateTime.now().year + eksikTamYilYas,
      DateTime.now().month,
      DateTime.now().day,
    );
    DateTime primDolma = araTarihYas.add(Duration(days: eksikGunKalanYas));

    final DateTime yasEsigiTarihi = (reqAgeYas > 0)
        ? DateTime(dogumTarihi.year + reqAgeYas, dogumTarihi.month, dogumTarihi.day)
        : primDolma;

    DateTime emeklilikTarihi =
        primDolma.isAfter(yasEsigiTarihi) ? primDolma : yasEsigiTarihi;

    int olasiYas = emeklilikTarihi.year - dogumTarihi.year;
    if (DateTime(emeklilikTarihi.year, dogumTarihi.month, dogumTarihi.day).isAfter(emeklilikTarihi)) {
      olasiYas--;
    }

    tahminiSonuclar["Yaş Haddinden Emeklilik"] = {
      "tahminiTarih": emeklilikTarihi,
      "tahminiYas": olasiYas,
      "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
      "eksikYil": eksikPrim > 0 ? eksikPrim / 360 : 0.0,
      "mesaj":
          "Hesaplama Tarihi İtibarıyla Sigorta Bildirimleriniz Kesintisiz Devam Ederse, ${_formatDateDot(emeklilikTarihi)} Tarihinde Yaş Haddinden Emeklilik Hakkı Kazanabilirsiniz."
    };
  }

  return {
    'emekliMi': {'normal': normalEligible, 'yasHaddi': ageLimitEligible},
    'mesaj': {'birlesik': message},
    'detaylar': {'birlesik': details},
    'tahminiSonuclar': tahminiSonuclar,
    'ekBilgi': {'Kontrol Tarihi': _formatDateSlash(DateTime.now())},
    'reqPrimNormal': reqPrimNormal,
    'reqAgeNormal': reqAgeNormal,
    'reqPrimYas': reqPrimYas,
    'reqAgeYas': reqAgeYas,
    'currentAge': age,
    'currentPrim': primGun,
  };
}
