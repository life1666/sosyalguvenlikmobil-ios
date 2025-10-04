import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Türkçe Aylar İçin Sabit Liste
const List<String> months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];

// Genel Tema Tanımlama
ThemeData buildAppTheme() {
  return ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.grey[100],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 14, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 12, color: Colors.black54),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.indigo,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),
  );
}

// Genel Kart Widget'ı
Widget buildCard({
  required String title,
  required Widget content,
  EdgeInsets padding = const EdgeInsets.all(12.0),
}) {
  return Card(
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, // Örneğin: "İşe Başlangıç Tarihi"
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    ),
  );
}

// Gradient Buton
Widget buildGradientButton({
  required String text,
  required VoidCallback onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: const LinearGradient(
        colors: [Colors.indigo, Colors.blueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Text(
        text, // Örneğin: "Hesapla"
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    ),
  );
}

// Dropdown Kartı – Artık İsteğe Bağlı Icon Parametresi Alıyor
Widget buildDropdownCard({
  required String label,
  required String? value,
  required List<DropdownMenuItem<String>> items,
  required ValueChanged<String?> onChanged,
  IconData? icon,
}) {
  return buildCard(
    title: label,
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.indigo.shade200, width: 1),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey[100],
      ),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon, color: Colors.indigo, size: 20),
            ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: const Text('Seçiniz', style: TextStyle(fontSize: 12)),
                isExpanded: true,
                items: items,
                onChanged: onChanged,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                dropdownColor: Colors.white,
                menuMaxHeight: 300,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Tarih Seçici Kart
Widget buildDatePickerCard({
  required String label,
  required String? day,
  required String? month,
  required String? year,
  required ValueChanged<String?> onDayChanged,
  required ValueChanged<String?> onMonthChanged,
  required ValueChanged<String?> onYearChanged,
}) {
  return buildCard(
    title: label,
    content: Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: day,
            hint: const Text(
              'Gün',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            items: List.generate(31, (index) => (index + 1).toString())
                .map((e) => DropdownMenuItem(
              value: e,
              child: Center(child: Text(e, style: const TextStyle(fontSize: 12))),
            ))
                .toList(),
            onChanged: onDayChanged,
            isDense: true,
            isExpanded: true,
            menuMaxHeight: 200,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: month,
            hint: const Text(
              'Ay',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            items: months
                .map((e) => DropdownMenuItem(
              value: e,
              child: Center(child: Text(e, style: const TextStyle(fontSize: 12))),
            ))
                .toList(),
            onChanged: onMonthChanged,
            isDense: true,
            isExpanded: true,
            menuMaxHeight: 200,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: year,
            hint: const Text(
              'Yıl',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            items: List.generate(
                DateTime.now().year - 1969, (index) => (DateTime.now().year - index).toString())
                .map((e) => DropdownMenuItem(
              value: e,
              child: Center(child: Text(e, style: const TextStyle(fontSize: 12))),
            ))
                .toList(),
            onChanged: onYearChanged,
            isDense: true,
            isExpanded: true,
            menuMaxHeight: 200,
          ),
        ),
      ],
    ),
  );
}

// Mesaj Kartı
Widget buildMessageCard(String message, bool isSuccess) {
  return Card(
    child: Container(
      height: 50,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

// Detaylar Kartı
Widget buildDetailsCard(Map<String, String> details) {
  final iconMap = {
    'İşe Başlangıç Tarihi': Icons.calendar_today,
    'Sigorta Kolu': Icons.shield,
    'Çalışma Süresi': Icons.access_time,
    'Yıllık Ücretli İzin Hakkı': Icons.check_circle,
    'Açıklama': Icons.warning,
  };
  List<MapEntry<String, String>> entries = details.entries.toList();
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Detaylar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 4),
          ...entries.map((entry) {
            return Column(
              children: [
                ListTile(
                  leading: Icon(
                    iconMap[entry.key] ?? Icons.info_outline,
                    color: Colors.indigo,
                    size: 18,
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(entry.value, style: const TextStyle(fontSize: 14)),
                ),
                if (entry != entries.last) const Divider(height: 1),
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}

// Ek Bilgi Kartı
Widget buildExtraInfoCard(Map<String, String> extraInfo) {
  final List<String> orderedKeys = [
    'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!',
    'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!',
    'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!',
    'Hesaplama Tarihi'
  ];
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Ek Bilgiler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 4),
          ...orderedKeys.map((key) {
            if (key == 'Hesaplama Tarihi' && !extraInfo.containsKey(key)) return Container();
            if (key != 'Hesaplama Tarihi' && !extraInfo.containsKey(key)) {
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
                    key == 'Hesaplama Tarihi' ? '$key: ${extraInfo[key]}' : key,
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
  );
}

// Sonuç Bölümü
Widget buildResultSection({
  required bool isSuccess,
  required String message,
  required Map<String, String> details,
  required Map<String, String> extraInfo,
  required GlobalKey resultKey,
}) {
  return Column(
    key: resultKey,
    children: [
      buildMessageCard(message, isSuccess),
      const SizedBox(height: 6),
      if (details.isNotEmpty) buildDetailsCard(details),
      const SizedBox(height: 6),
      if (extraInfo.isNotEmpty) buildExtraInfoCard(extraInfo),
    ],
  );
}

// Otomatik Kaydırma Fonksiyonu
void scrollToResult(GlobalKey key, ScrollController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const YillikUcretliIzinApp());
}

class YillikUcretliIzinApp extends StatelessWidget {
  const YillikUcretliIzinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: const YillikUcretliIzinSayfasi(),
    );
  }
}

class YillikUcretliIzinSayfasi extends StatefulWidget {
  const YillikUcretliIzinSayfasi({super.key});

  @override
  State<YillikUcretliIzinSayfasi> createState() => _YillikUcretliIzinSayfasiState();
}

class _YillikUcretliIzinSayfasiState extends State<YillikUcretliIzinSayfasi> {
  String? sigortaKolu;
  String? day, month, year;
  Map<String, dynamic>? result;
  final GlobalKey resultKey = GlobalKey();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _showHesaplamaSonucu() {
    print("showHesaplamaSonucu çağrıldı");

    // Giriş Doğrulama
    if (sigortaKolu == null || day == null || month == null || year == null) {
      setState(() {
        result = {
          'isSuccess': false,
          'message': 'Lütfen Tüm Alanları Eksiksiz Doldurunuz.',
          'details': {
            'Açıklama': 'Tüm Alanların Doldurulması Gerekmektedir.',
          },
          'extraInfo': {
            'Hesaplama Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!': '',
            'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!': '',
            'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!': '',
          },
        };
      });
      scrollToResult(resultKey, scrollController);
      return;
    }

    DateTime? iseBaslangic;
    try {
      iseBaslangic = DateTime(
        int.parse(year!),
        months.indexOf(month!) + 1,
        int.parse(day!),
      );
    } catch (e) {
      setState(() {
        result = {
          'isSuccess': false,
          'message': 'Geçersiz Tarih Girişi.',
          'details': {
            'Açıklama': 'Lütfen Doğru Bir Tarih Seçiniz.',
          },
          'extraInfo': {
            'Hesaplama Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!': '',
            'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!': '',
            'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!': '',
          },
        };
      });
      scrollToResult(resultKey, scrollController);
      return;
    }

    final bugun = DateTime.now();
    if (iseBaslangic.isAfter(bugun)) {
      setState(() {
        result = {
          'isSuccess': false,
          'message': 'Henüz Yıllık Ücretli İzin Hakkınız Bulunmamaktadır.',
          'details': {
            'Açıklama': 'İşe Başlangıç Tarihi Gelecekte Olamaz.',
          },
          'extraInfo': {
            'Hesaplama Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
            'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!': '',
            'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!': '',
            'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!': '',
          },
        };
      });
      scrollToResult(resultKey, scrollController);
      return;
    }

    final fark = bugun.difference(iseBaslangic);
    final yilSayisi = fark.inDays ~/ 365;
    String izinHakki;
    if (yilSayisi < 1) {
      izinHakki =
      'Çalışma Süreniz 1 Yıldan Az Olduğu İçin Yıllık Ücretli İzin Hakkınız Bulunmamaktadır.\nMinimum 1 Yıl Çalışma Şartı Gerekmektedir.';
    } else {
      if (sigortaKolu == '4/C') {
        izinHakki = (yilSayisi <= 10) ? '20 Gün' : '30 Gün';
      } else {
        if (yilSayisi <= 5) {
          izinHakki = '14 Gün';
        } else if (yilSayisi <= 15) {
          izinHakki = '20 Gün';
        } else {
          izinHakki = '26 Gün';
        }
      }
    }

    setState(() {
      result = {
        'isSuccess': yilSayisi >= 1,
        'message': yilSayisi >= 1
            ? 'Yıllık Ücretli İzin Kullanmaya Hak Kazandınız.'
            : 'Henüz Yıllık Ücretli İzin Hakkınız Bulunmamaktadır.',
        'details': {
          'İşe Başlangıç Tarihi': '$day/${months.indexOf(month!) + 1}/$year',
          'Sigorta Kolu': sigortaKolu!,
          'Çalışma Süresi': '$yilSayisi Yıl',
          if (yilSayisi >= 1) 'Yıllık Ücretli İzin Hakkı': izinHakki,
          if (yilSayisi < 1) 'Açıklama': izinHakki,
        },
        'extraInfo': {
          'Sosyal Güvenlik Mobil Herhangi Resmi Bir Kurumun Uygulaması Değildir!': '',
          'Yapılan Hesaplamalar Tahmini Olup Resmi Bir Nitelik Taşımamaktadır!': '',
          'Hesaplamalar Bilgi İçindir Hiçbir Sorumluluk Kabul Edilmez!': '',
          'Hesaplama Tarihi': DateFormat('dd/MM/yyyy', 'tr_TR').format(DateTime.now()),
        },
      };
    });
    scrollToResult(resultKey, scrollController);
    print("Hesaplama Sonucu: ${result!['details'].length} detay");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yıllık Ücretli İzin Hakkı Uygulaması'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDatePickerCard(
              label: 'İşe Başlangıç Tarihi',
              day: day,
              month: month,
              year: year,
              onDayChanged: (value) => setState(() => day = value),
              onMonthChanged: (value) => setState(() => month = value),
              onYearChanged: (value) => setState(() => year = value),
            ),
            buildDropdownCard(
              label: 'Sigorta Kolu',
              value: sigortaKolu,
              items: const [
                DropdownMenuItem(value: '4/A', child: Text('4/A (SSK)')),
                DropdownMenuItem(value: '4/C', child: Text('4/C (Emekli Sandığı)')),
              ],
              onChanged: (value) => setState(() => sigortaKolu = value),
              icon: Icons.shield,
            ),
            const SizedBox(height: 20),
            buildGradientButton(
              text: 'Hesapla',
              onPressed: _showHesaplamaSonucu,
            ),
            const SizedBox(height: 20),
            if (result != null)
              buildResultSection(
                isSuccess: result!['isSuccess'],
                message: result!['message'],
                details: Map<String, String>.from(result!['details']),
                extraInfo: Map<String, String>.from(result!['extraInfo']),
                resultKey: resultKey,
              ),
          ],
        ),
      ),
    );
  }
}