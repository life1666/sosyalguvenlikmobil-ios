import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const EmeklilikHesaplamaApp());
}

class EmeklilikHesaplamaApp extends StatelessWidget {
  const EmeklilikHesaplamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4/B – Bağkur Emeklilik Hesaplama',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
          headlineSmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        cardTheme: const CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
      ),
      home: const EmeklilikHesaplama4bSayfasi(),
    );
  }
}

class EmeklilikHesaplama4bSayfasi extends StatefulWidget {
  const EmeklilikHesaplama4bSayfasi({super.key});

  @override
  _EmeklilikHesaplama4bSayfasiState createState() =>
      _EmeklilikHesaplama4bSayfasiState();
}

class _EmeklilikHesaplama4bSayfasiState extends State<EmeklilikHesaplama4bSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _resultKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  DateTime? dogumTarihi;
  int? dogumGun;
  int? dogumAy;
  int? dogumYil;
  String? cinsiyet;
  DateTime? sigortaBaslangicTarihi;
  int? sigortaGun;
  int? sigortaAy;
  int? sigortaYil;
  int? primGunSayisi;

  Map<String, dynamic>? hesaplamaSonucu;

  final List<String> aylar = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];

  @override
  void initState() {
    super.initState();
  }

  Map<String, dynamic> emeklilikHesapla(
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

    // 1. Kategori (1999 öncesi, 08.09.1999 dahil)
    DateTime cat1Upper = DateTime(1999, 9, 9);
    // 2. Kategori (09.09.1999 – 30.04.2008)
    DateTime cat2Upper = DateTime(2008, 5, 1);
    // 3. Kategori (01.05.2008 ve sonrası)
    DateTime cat3Lower = DateTime(2008, 5, 1);

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

        normalEligible = (primGun >= reqPrimNormal && insuranceYears >= reqInsuranceYearsNormal);
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

        normalEligible = (primGun >= reqPrimNormal && insuranceYears >= reqInsuranceYearsNormal);
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
    } else if (sigortaBaslangic.isAfter(cat3Lower.subtract(const Duration(days: 1)))) {
      // 3. Kategori: 01.05.2008 ve sonrası
      int normalReqPrim = 9000;
      reqPrimNormal = normalReqPrim;

      // 1) Kaç prim günü eksik?
      int eksikPrimGunu = normalReqPrim - primGun;

      // 2) Eksik prim günlerini "360 prim günü = 1 yıl" mantığıyla ekle
      int eksikTamYil = eksikPrimGunu ~/ 360;
      int eksikGunKalan = eksikPrimGunu % 360;
      DateTime araTarih = DateTime(today.year + eksikTamYil, today.month, today.day);
      DateTime primCompletion = araTarih.add(Duration(days: eksikGunKalan));

      // 3) Prim tamamlandığı gün kademeli yaş şartını belirle
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

      // --- YAŞ HADDİNDEN EMEKLİLİK HESABI ---
      int ageLimitPrim = 5400;
      reqPrimYas = ageLimitPrim;

      // 1) Kaç prim günü eksik (yaş haddinden)?
      int eksikPrimYas = ageLimitPrim - primGun;
      int eksikTamYilYas = eksikPrimYas ~/ 360;
      int eksikGunKalanYas = eksikPrimYas % 360;
      DateTime araTarihYas = DateTime(today.year + eksikTamYilYas, today.month, today.day);
      DateTime ageLimitPrimCompletion = araTarihYas.add(Duration(days: eksikGunKalanYas));

      // 2) Tabloya göre yaş şartını belirle (01.05.2008 - 31.12.2047 arası)
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

      ageLimitEligible = (primGun >= ageLimitPrim && age >= reqAgeYas);

      details["Normal Emeklilik"] =
      "Mevcut: $primGun Gün, $age Yaş | Gerekli: $normalReqPrim Gün, $reqAgeNormal Yaş";
      details["Yaş Haddinden Emeklilik"] =
      "Mevcut: $primGun Gün, $age Yaş | Gerekli: $ageLimitPrim Gün, $reqAgeYas Yaş";
    } else {
      message = "Sistem uygun emeklilik kriterini belirleyemedi.";
    }

    // --- TAHMİNİ EMEKLİLİK HESABI ---

    // NORMAL
    if (!normalEligible && reqPrimNormal > 0) {
      int eksikPrim = reqPrimNormal - primGun;
      double eksikYilDouble = eksikPrim > 0 ? eksikPrim / 360 : 0.0;

      // Eksik prim günlerini "360 prim günü = 1 yıl" olarak ekle
      int eksikTamYil = eksikPrim ~/ 360;
      int eksikGunKalan = eksikPrim % 360;
      DateTime araTarih = DateTime(today.year + eksikTamYil, today.month, today.day);
      DateTime primDolma = araTarih.add(Duration(days: eksikGunKalan));

      int olasiYas = primDolma.year - dogumTarihi.year;
      if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day).isAfter(primDolma)) {
        olasiYas--;
      }

      // Eğer prim tamamlandığı tarihte yaş şartı sağlanmıyorsa,
      // gereken yaşı tamamlayacağı doğum günü tarihine atlıyoruz.
      if (reqAgeNormal > 0 && olasiYas < reqAgeNormal) {
        primDolma = DateTime(dogumTarihi.year + reqAgeNormal, dogumTarihi.month, dogumTarihi.day);
        olasiYas = reqAgeNormal;
      }

      tahminiSonuclar["Normal Emeklilik"] = {
        "tahminiTarih": primDolma,
        "tahminiYas": olasiYas,
        "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
        "eksikYil": eksikYilDouble > 0 ? eksikYilDouble : 0,
        "mesaj":
        "Kontrol tarihi itibarıyla sigorta bildirimleriniz kesintisiz devam ederse, ${DateFormat('dd.MM.yyyy').format(primDolma)} tarihinde normal emeklilik hakkı kazanabilirsiniz."
      };
    }

    // YAŞ HADDİNDEN
    if (!ageLimitEligible && reqPrimYas > 0) {
      int eksikPrim = reqPrimYas - primGun;
      double eksikYilDouble = eksikPrim > 0 ? eksikPrim / 360 : 0.0;

      // Eksik prim günlerini "360 prim günü = 1 yıl" olarak ekle
      int eksikTamYilYas = eksikPrim ~/ 360;
      int eksikGunKalanYas = eksikPrim % 360;
      DateTime araTarihYas = DateTime(today.year + eksikTamYilYas, today.month, today.day);
      DateTime primDolma = araTarihYas.add(Duration(days: eksikGunKalanYas));

      int olasiYas = primDolma.year - dogumTarihi.year;
      if (DateTime(primDolma.year, dogumTarihi.month, dogumTarihi.day).isAfter(primDolma)) {
        olasiYas--;
      }

      if (reqAgeYas > 0 && olasiYas < reqAgeYas) {
        primDolma = DateTime(dogumTarihi.year + reqAgeYas, dogumTarihi.month, dogumTarihi.day);
        olasiYas = reqAgeYas;
      }

      tahminiSonuclar["Yaş Haddinden Emeklilik"] = {
        "tahminiTarih": primDolma,
        "tahminiYas": olasiYas,
        "eksikPrim": eksikPrim > 0 ? eksikPrim : 0,
        "eksikYil": eksikYilDouble > 0 ? eksikYilDouble : 0,
        "mesaj":
        "Kontrol tarihi itibarıyla sigorta bildirimleriniz kesintisiz devam ederse, ${DateFormat('dd.MM.yyyy').format(primDolma)} tarihinde yaş haddinden emeklilik hakkı kazanabilirsiniz."
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
      'ekBilgi': {
        'Kontrol Tarihi': DateFormat('dd/MM/yyyy').format(today),
      },
    };
  }

  void _hesaplaEmeklilik() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _showEmeklilikSonucu();
    }
  }

  void _showEmeklilikSonucu() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (dogumGun != null && dogumAy != null && dogumYil != null) {
        dogumTarihi = DateTime(dogumYil!, dogumAy!, dogumGun!);
      }
      if (sigortaGun != null && sigortaAy != null && sigortaYil != null) {
        sigortaBaslangicTarihi = DateTime(sigortaYil!, sigortaAy!, sigortaGun!);
      }

      if (cinsiyet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen cinsiyet seçiniz."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      DateTime today = DateTime.now();
      String? errorMessage;

      if (dogumTarihi!.isAfter(today)) {
        errorMessage = capitalizeWords("doğum tarihi günümüzden sonra olamaz.");
      } else if (sigortaBaslangicTarihi!.isBefore(dogumTarihi!)) {
        errorMessage =
            capitalizeWords("sigorta başlangıç tarihi doğum tarihinden önce olamaz.");
      } else if (sigortaBaslangicTarihi!.isAfter(today)) {
        errorMessage =
            capitalizeWords("sigorta başlangıç tarihi günümüzden sonra olamaz.");
      } else {
        // Maksimum prim gün sayısını hesapla (1 gün tolerans ile)
        int totalDays = today.difference(sigortaBaslangicTarihi!).inDays;
        int fullYears = totalDays ~/ 365; // Tam yıl sayısı
        int remainingDays = totalDays % 365; // Kalan gün sayısı
        int maxPremiumDays = (fullYears * 360) + remainingDays + 1; // 1 gün tolerans

        if (primGunSayisi! > maxPremiumDays) {
          errorMessage = capitalizeWords(
              "prim gün sayısı ($primGunSayisi) maksimum olası gün sayısından ($maxPremiumDays) fazla.");
        }
      }

      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        hesaplamaSonucu = emeklilikHesapla(
          dogumTarihi!,
          cinsiyet!,
          sigortaBaslangicTarihi!,
          primGunSayisi!,
        );
      });
      _scrollToResult();
    }
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildCinsiyetKart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cinsiyet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Seçiniz',
                border: const OutlineInputBorder(),
                prefixIcon: cinsiyet == null
                    ? const Icon(Icons.account_circle, color: Colors.indigo)
                    : null,
              ),
              items: [
                DropdownMenuItem(
                  value: 'Erkek',
                  child: Row(
                    children: const [
                      Icon(Icons.man, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Erkek'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Kadın',
                  child: Row(
                    children: const [
                      Icon(Icons.woman, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Kadın'),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  cinsiyet = val;
                });
              },
              validator: (val) => val == null ? 'Cinsiyet Seçiniz' : null,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String? initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: initialValue,
              decoration: const InputDecoration(
                hintText: 'Gün',
                prefixIcon: Icon(Icons.work, color: Colors.indigo),
                border: OutlineInputBorder(),
              ),
              keyboardType: keyboardType,
              onSaved: onSaved,
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHesaplaButton() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ElevatedButton(
          onPressed: _hesaplaEmeklilik,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text('Hesapla',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildResultDetailsTable(
      Map<String, String> detaylar, bool olumlu, Map<String, dynamic> emekliMi) {
    final iconMap = {
      'Normal Emeklilik': Icons.check_circle_outline,
      'Yaş Haddinden Emeklilik': Icons.access_time_outlined,
    };

    if (detaylar.isEmpty) return Container();

    BoxDecoration kutuStyle(bool yeterli) => BoxDecoration(
      color: yeterli ? Colors.green[100] : Colors.red[100],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: yeterli ? Colors.green : Colors.red,
        width: 1.2,
      ),
    );

    Widget header = Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            "Kategori",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "Mevcut",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "Gerekli",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    List<Widget> satirlar = [
      header,
      const Divider(height: 8),
    ];

    detaylar.entries.forEach((entry) {
      final parts = entry.value.split('|');
      final mevcut = parts[0].replaceFirst('Mevcut: ', '').trim();
      final gerekli = parts.length > 1
          ? parts[1].replaceFirst('Gerekli: ', '').trim()
          : '';

      bool yeterli = false;
      if (entry.key.contains('Normal')) {
        yeterli = emekliMi['normal'] == true;
      } else if (entry.key.contains('Yaş')) {
        yeterli = emekliMi['yasHaddi'] == true;
      }

      satirlar.add(
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(iconMap[entry.key] ?? Icons.info_outline,
                      color: yeterli ? Colors.green : Colors.red, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: yeterli ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: kutuStyle(yeterli),
                child: Text(
                  mevcut,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: yeterli ? Colors.green[900] : Colors.red[900],
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: kutuStyle(true),
                child: Text(gerekli,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.black87)),
              ),
            ),
          ],
        ),
      );
    });

    return Card(
      color: olumlu ? Colors.green[50] : Colors.red[50],
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: satirlar,
        ),
      ),
    );
  }

  Widget _buildEkBilgiCard(Map<String, String> ekBilgi) {
    final List<String> orderedKeys = [
      'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!',
      'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!',
      'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!',
      'Kontrol Tarihi',
    ];

    return Card(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Ek Bilgiler',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 4),
                ...orderedKeys.map((key) {
                  if (key == 'Kontrol Tarihi') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '$key: ${ekBilgi[key] ?? DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSonucKart() {
    if (hesaplamaSonucu == null) return Container();

    var sonuc = hesaplamaSonucu!;
    var emekliMi = sonuc['emekliMi'];
    var detaylar = Map<String, String>.from(sonuc['detaylar']['birlesik']);
    var ekBilgi = Map<String, String>.from(sonuc['ekBilgi']);
    var tahminiSonuclar = sonuc['tahminiSonuclar'] ?? {};

    bool hakKazandi = emekliMi['normal'] == true || emekliMi['yasHaddi'] == true;

    Color cardColor = hakKazandi ? Colors.green.shade50 : Colors.red.shade50;
    Color textColor = hakKazandi ? Colors.green.shade900 : Colors.red.shade900;
    IconData icon = hakKazandi ? Icons.check_circle : Icons.error_outline;

    String anaMesaj = hakKazandi
        ? "Tebrikler! Belirtmiş olduğunuz koşullar altında emekliliğe hak kazanabiliyorsunuz."
        : "Mevcut koşullar altında emekliliğe hak kazanamıyorsunuz.";

    List<Widget> tahminler = [];
    if (!emekliMi['normal'] && !emekliMi['yasHaddi']) {
      tahminiSonuclar.forEach((key, val) {
        tahminler.add(
          Card(
            color: Colors.indigo[50],
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.indigo),
              title: Text(key,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo)),
              subtitle: Text(val["mesaj"] ?? "",
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        );
      });
    }

    return Column(
      key: _resultKey,
      children: [
        Card(
          color: cardColor,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 40),
                const SizedBox(height: 10),
                Text(
                  anaMesaj,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildResultDetailsTable(detaylar, hakKazandi, emekliMi),
                ...tahminler,
              ],
            ),
          ),
        ),
        _buildEkBilgiCard(ekBilgi),
      ],
    );
  }

  String capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.toLowerCase() == 've') return 've';
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('4/B – Bağkur Emeklilik Hesaplama'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doğum Tarihi',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: dogumGun != null ? dogumGun.toString() : null,
                              hint: const Text(
                                'Gün',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              items: List.generate(31, (index) => (index + 1).toString())
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  dogumGun = int.parse(val!);
                                });
                              },
                              validator: (value) => value == null ? 'Gün Seçin' : null,
                              isExpanded: true,
                              menuMaxHeight: 200,
                              icon:
                              const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: dogumAy != null ? aylar[dogumAy! - 1] : null,
                              hint: const Text(
                                'Ay',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              items: aylar
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  dogumAy = aylar.indexOf(val!) + 1;
                                });
                              },
                              validator: (value) => value == null ? 'Ay Seçin' : null,
                              isExpanded: true,
                              menuMaxHeight: 200,
                              icon:
                              const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: dogumYil != null ? dogumYil.toString() : null,
                              hint: const Text(
                                'Yıl',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              items: List.generate(
                                  2025 - 1957 + 1, (index) => (1957 + index).toString())
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  dogumYil = int.parse(val!);
                                });
                              },
                              validator: (value) => value == null ? 'Yıl Seçin' : null,
                              isExpanded: true,
                              menuMaxHeight: 200,
                              icon:
                              const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildCinsiyetKart(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sigorta Başlangıç Tarihi',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value:
                              sigortaGun != null ? sigortaGun.toString() : null,
                              hint: const Text(
                                'Gün',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              items: List.generate(31, (index) => (index + 1).toString())
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  sigortaGun = int.parse(val!);
                                });
                              },
                              validator: (value) => value == null ? 'Gün Seçin' : null,
                              isExpanded: true,
                              menuMaxHeight: 200,
                              icon:
                              const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value:
                              sigortaAy != null ? aylar[sigortaAy! - 1] : null,
                              hint: const Text(
                                'Ay',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              items: aylar
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  sigortaAy = aylar.indexOf(val!) + 1;
                                });
                              },
                              validator: (value) => value == null ? 'Ay Seçin' : null,
                              isExpanded: true,
                              menuMaxHeight: 200,
                              icon:
                              const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value:
                              sigortaYil != null ? sigortaYil.toString() : null,
                              hint: const Text(
                                'Yıl',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              items: List.generate(
                                  2025 - 1960 + 1, (index) => (2025 - index).toString())
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  sigortaYil = int.parse(val!);
                                });
                              },
                              validator: (value) => value == null ? 'Yıl Seçin' : null,
                              isExpanded: true,
                              menuMaxHeight: 200,
                              icon:
                              const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildNumberField(
                label: 'Prim Gün Sayısı',
                initialValue: primGunSayisi?.toString(),
                onSaved: (val) {
                  primGunSayisi = int.parse(val!);
                },
                validator: (val) =>
                val == null || val.isEmpty || int.tryParse(val) == null
                    ? 'Lütfen Geçerli Bir Sayı Girin'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildHesaplaButton(),
              const SizedBox(height: 20),
              _buildSonucKart(),
            ],
          ),
        ),
      ),
    );
  }
}