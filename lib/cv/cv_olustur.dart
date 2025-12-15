import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cv_helpers.dart';
import 'cv_sablon.dart';
import '../utils/analytics_helper.dart';

// Not: Bu main() fonksiyonu sadece bu dosyayı tek başına test etmek içindir.
// Gerçek uygulama lib/main.dart'tan başlar.
void main() {
  registerTemplates(); // Şablonları kaydet
  runApp(const CvApp());
}

/// =================== GLOBAL STIL & KNOB’LAR ===================

const double kPageHPad = 16.0;
const double kTextScale = 1.00;
const Color  kTextColor = Colors.black;

// Divider (global)
const double kDividerThickness = 0.2;
const double kDividerSpace     = 2.0;

// Form alanı çerçevesi
const double kFieldBorderWidth   = 0.2;
const double kFieldBorderRadius  = 10.0;
const Color  kFieldBorderColor   = Colors.black87;
const Color  kFieldFocusColor    = Colors.black87;

// İkon genel
const Color  kIconColor = Colors.black87;
const double kIconSize  = 22.0;

/// ===== AppBar GÖRSEL KNOB’LARI =====
const double kAppBarRadiusLeft  = 0.0;             // Sol kıvrım
const double kAppBarRadiusRight = 0.0;              // Sağ kıvrım
const double kAppBarElevation   = 0.0;              // Gölge
const Color  kAppBarBgColor     = Color(0xFF3F51B5); // indigo[500] eşdeğeri
const Color  kAppBarFgColor     = Colors.white;     // Yazı/ikon rengi

/// ===== RAPOR / BOTTOM SHEET KNOB’LARI =====
const double kReportMaxWidth      = 660.0;
const Color  kResultSheetBg       = Colors.white;
const double kResultSheetCorner   = 22.0;
const double kResultHeaderScale   = 1.00;
const FontWeight kResultHeaderWeight = FontWeight.w400;

/// ===== YAZI AĞIRLIKLARI =====
class AppW {
  static const appBarTitle = FontWeight.w700;
  static const heading     = FontWeight.w500;
  static const body        = FontWeight.w300;
  static const minor       = FontWeight.w300;
  static const tableHead   = FontWeight.w600;
}

extension AppText on BuildContext {
  TextStyle get sFormLabel => Theme.of(this).textTheme.titleLarge!;
  TextStyle get sBody      => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get sMinor     => Theme.of(this).textTheme.bodySmall!;
  TextStyle get sTableHead =>
      Theme.of(this).textTheme.bodyMedium!.copyWith(fontWeight: AppW.tableHead);
  TextStyle sEmphasis(Color color) =>
      Theme.of(this).textTheme.titleMedium!.copyWith(
        fontWeight: AppW.heading, color: color,
      );
}

/// ----------------------------------------------
///  TEMA
/// ----------------------------------------------
ThemeData uygulamaTemasi = (() {
  final double sizeTitleLg = 16.5 * kTextScale;
  final double sizeTitleMd = 15 * kTextScale;
  final double sizeBody    = 13.5 * kTextScale;
  final double sizeSmall   = 12.5 * kTextScale;
  final double sizeAppBar  = 20.5 * kTextScale;

  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,

    appBarTheme: AppBarTheme(
      backgroundColor: kAppBarBgColor,
      foregroundColor: kAppBarFgColor,
      elevation: kAppBarElevation,
      centerTitle: false,
      toolbarHeight: 52.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(kAppBarRadiusLeft),
          bottomRight: Radius.circular(kAppBarRadiusRight),
        ),
      ),
      titleTextStyle: TextStyle(
        fontSize: sizeAppBar,
        fontWeight: AppW.appBarTitle,
        color: kAppBarFgColor,
        letterSpacing: 0.15,
        height: 1.22,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
    ),

    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: sizeTitleLg,
        fontWeight: AppW.heading,
        color: kTextColor,
        height: 1.25,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      titleMedium: TextStyle(
        fontSize: sizeTitleMd,
        fontWeight: AppW.heading,
        color: kTextColor,
        letterSpacing: 0.2,
        height: 1.22,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodyMedium: TextStyle(
        fontSize: sizeBody,
        color: kTextColor,
        fontWeight: AppW.body,
        height: 1.4,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodySmall: TextStyle(
        fontSize: sizeSmall,
        color: Colors.black87,
        fontWeight: AppW.minor,
        height: 1.45,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      labelLarge: TextStyle(
        fontSize: sizeBody,
        fontWeight: AppW.body,
        color: Colors.black87,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Colors.black,
      thickness: kDividerThickness,
      space: kDividerSpace,
    ),

    iconTheme: const IconThemeData(
      color: kIconColor,
      size: kIconSize,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
      ),
      hintStyle: TextStyle(fontSize: 13 * kTextScale, color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),

    // Indigo butonlar
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.indigo[500],
        foregroundColor: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo[500],
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.black54),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.indigo[500],
        side: BorderSide(color: Colors.indigo[500]!),
      ),
    ),
  );
})();

/// ======================
///  APP
/// ======================
class CvApp extends StatelessWidget {
  const CvApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: uygulamaTemasi.copyWith(useMaterial3: true),
      child: const CvBuilderPage(),
    );
  }
}

/// =====================
///  VERİ MODELLERİ
/// =====================
class CvData {
  String name = '';
  String title = '';
  String email = '';
  String phone = '';
  String address = '';
  String summary = '';
  String? photoUrl;

  final List<Experience> experiences = [];
  final List<Education>  educations  = [];
  final List<String>     skills      = [];
  final List<Language>   languages   = [];

  // Opsiyoneller
  final List<Certificate> certificates = [];
  final List<Project>     projects     = [];
  final List<String>      hobbies      = [];
  final List<String>      licenses     = [];
  final List<Volunteer>   volunteering = [];
  final List<RefItem>     references   = [];

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'email': email,
    'phone': phone,
    'address': address,
    'summary': summary,
    'photoUrl': photoUrl,
    'experiences': experiences.map((e) => e.toJson()).toList(),
    'educations': educations.map((e) => e.toJson()).toList(),
    'skills': skills,
    'languages': languages.map((l) => l.toJson()).toList(),
    'certificates': certificates.map((c) => c.toJson()).toList(),
    'projects': projects.map((p) => p.toJson()).toList(),
    'hobbies': hobbies,
    'licenses': licenses,
    'volunteering': volunteering.map((v) => v.toJson()).toList(),
    'references': references.map((r) => r.toJson()).toList(),
  };

  void fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    title = json['title'] ?? '';
    email = json['email'] ?? '';
    phone = json['phone'] ?? '';
    address = json['address'] ?? '';
    summary = json['summary'] ?? '';
    photoUrl = json['photoUrl'];

    experiences.clear();
    if (json['experiences'] != null) {
      for (var item in json['experiences']) {
        experiences.add(Experience.fromJson(item));
      }
    }

    educations.clear();
    if (json['educations'] != null) {
      for (var item in json['educations']) {
        educations.add(Education.fromJson(item));
      }
    }

    skills.clear();
    if (json['skills'] != null) {
      skills.addAll(List<String>.from(json['skills']));
    }

    languages.clear();
    if (json['languages'] != null) {
      for (var item in json['languages']) {
        languages.add(Language.fromJson(item));
      }
    }

    certificates.clear();
    if (json['certificates'] != null) {
      for (var item in json['certificates']) {
        certificates.add(Certificate.fromJson(item));
      }
    }

    projects.clear();
    if (json['projects'] != null) {
      for (var item in json['projects']) {
        projects.add(Project.fromJson(item));
      }
    }

    hobbies.clear();
    if (json['hobbies'] != null) {
      hobbies.addAll(List<String>.from(json['hobbies']));
    }

    licenses.clear();
    if (json['licenses'] != null) {
      licenses.addAll(List<String>.from(json['licenses']));
    }

    volunteering.clear();
    if (json['volunteering'] != null) {
      for (var item in json['volunteering']) {
        volunteering.add(Volunteer.fromJson(item));
      }
    }

    references.clear();
    if (json['references'] != null) {
      for (var item in json['references']) {
        references.add(RefItem.fromJson(item));
      }
    }
  }
}

class Experience {
  String company;
  String position;
  String start;
  String end;      // boş ise "Güncel"
  bool   isCurrent;
  String desc;
  Experience({
    required this.company,
    required this.position,
    required this.start,
    required this.end,
    required this.desc,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
    'company': company,
    'position': position,
    'start': start,
    'end': end,
    'isCurrent': isCurrent,
    'desc': desc,
  };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
    company: json['company'] ?? '',
    position: json['position'] ?? '',
    start: json['start'] ?? '',
    end: json['end'] ?? '',
    desc: json['desc'] ?? '',
    isCurrent: json['isCurrent'] ?? false,
  );
}

class Language {
  String name;
  String level; // A1–C2, Ana dil, İleri vb.
  Language({required this.name, required this.level});

  Map<String, dynamic> toJson() => {'name': name, 'level': level};
  factory Language.fromJson(Map<String, dynamic> json) => Language(
    name: json['name'] ?? '',
    level: json['level'] ?? '',
  );
}

class Education {
  String school;
  String department;
  String start;
  String end;
  String note;
  String level; // İlk öğretim, Orta öğretim, Lisans, Yüksek lisans, Doktora
  Education({
    required this.school,
    required this.department,
    required this.start,
    required this.end,
    required this.note,
    this.level = '',
  });

  Map<String, dynamic> toJson() => {
    'school': school,
    'department': department,
    'start': start,
    'end': end,
    'note': note,
    'level': level,
  };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
    school: json['school'] ?? '',
    department: json['department'] ?? '',
    start: json['start'] ?? '',
    end: json['end'] ?? '',
    note: json['note'] ?? '',
    level: json['level'] ?? '',
  );
}

class Certificate {
  String title;
  String org;
  String year;
  Certificate({required this.title, required this.org, required this.year});

  Map<String, dynamic> toJson() => {'title': title, 'org': org, 'year': year};
  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
    title: json['title'] ?? '',
    org: json['org'] ?? '',
    year: json['year'] ?? '',
  );
}

class Project {
  String name;
  String description;
  String link;
  Project({required this.name, required this.description, required this.link});

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'link': link};
  factory Project.fromJson(Map<String, dynamic> json) => Project(
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    link: json['link'] ?? '',
  );
}

class Volunteer {
  String organization;
  String role;
  String start;
  String end;
  String description;
  Volunteer({
    required this.organization,
    required this.role,
    required this.start,
    required this.end,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'organization': organization,
    'role': role,
    'start': start,
    'end': end,
    'description': description,
  };

  factory Volunteer.fromJson(Map<String, dynamic> json) => Volunteer(
    organization: json['organization'] ?? '',
    role: json['role'] ?? '',
    start: json['start'] ?? '',
    end: json['end'] ?? '',
    description: json['description'] ?? '',
  );
}

class RefItem {
  String name;
  String position;
  String contact; // e-posta/tel
  String note;    // opsiyonel
  RefItem({required this.name, required this.position, required this.contact, required this.note});

  Map<String, dynamic> toJson() => {
    'name': name,
    'position': position,
    'contact': contact,
    'note': note,
  };

  factory RefItem.fromJson(Map<String, dynamic> json) => RefItem(
    name: json['name'] ?? '',
    position: json['position'] ?? '',
    contact: json['contact'] ?? '',
    note: json['note'] ?? '',
  );
}

/// =====================
///  CV OLUŞTURMA SAYFASI
/// =====================
class CvBuilderPage extends StatefulWidget {
  const CvBuilderPage({super.key});
  @override
  State<CvBuilderPage> createState() => _CvBuilderPageState();
}

class _CvBuilderPageState extends State<CvBuilderPage> {
  final _cv = CvData();
  final _formKey = GlobalKey<FormState>();
  int _templateIndex = 0;

  // Kişisel alan controller'ları
  final _nameCtrl = TextEditingController(text: '');
  late final TextEditingController _titleCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _summaryCtrl;

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('cv_olustur_opened');
    // Controller'ları oluştur
    _titleCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _summaryCtrl = TextEditingController();
    
    // Controller'lara dinleyici ekle - değişince otomatik kaydet
    _nameCtrl.addListener(_saveCvData);
    _titleCtrl.addListener(_saveCvData);
    _emailCtrl.addListener(_saveCvData);
    _phoneCtrl.addListener(_saveCvData);
    _addressCtrl.addListener(_saveCvData);
    _summaryCtrl.addListener(_saveCvData);
    
    _loadCvData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  // CV verilerini yükle
  Future<void> _loadCvData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cvDataString = prefs.getString('cv_data');
      final templateIndex = prefs.getInt('cv_template_index');

      if (cvDataString != null) {
        final jsonData = jsonDecode(cvDataString) as Map<String, dynamic>;
        _cv.fromJson(jsonData);

        // Listener'ları geçici olarak kaldır
        _nameCtrl.removeListener(_saveCvData);
        _titleCtrl.removeListener(_saveCvData);
        _emailCtrl.removeListener(_saveCvData);
        _phoneCtrl.removeListener(_saveCvData);
        _addressCtrl.removeListener(_saveCvData);
        _summaryCtrl.removeListener(_saveCvData);

        // Controller'ları güncelle
        _nameCtrl.text = _cv.name;
        _titleCtrl.text = _cv.title;
        _emailCtrl.text = _cv.email;
        _phoneCtrl.text = _cv.phone;
        _addressCtrl.text = _cv.address;
        _summaryCtrl.text = _cv.summary;

        // Listener'ları tekrar ekle
        _nameCtrl.addListener(_saveCvData);
        _titleCtrl.addListener(_saveCvData);
        _emailCtrl.addListener(_saveCvData);
        _phoneCtrl.addListener(_saveCvData);
        _addressCtrl.addListener(_saveCvData);
        _summaryCtrl.addListener(_saveCvData);

        if (mounted) {
          setState(() {
            if (templateIndex != null) {
              _templateIndex = templateIndex;
            }
          });
        }
        print('✅ CV verileri yüklendi');
      }
    } catch (e) {
      print('⚠️ CV verileri yüklenirken hata: $e');
    }
  }

  // CV verilerini kaydet
  Future<void> _saveCvData() async {
    try {
      _syncModel(); // Model'i güncelle
      final prefs = await SharedPreferences.getInstance();
      final cvDataString = jsonEncode(_cv.toJson());
      await prefs.setString('cv_data', cvDataString);
      await prefs.setInt('cv_template_index', _templateIndex);
      print('✅ CV verileri kaydedildi');
    } catch (e) {
      print('⚠️ CV verileri kaydedilirken hata: $e');
    }
  }

  void _syncModel() {
    _cv
      ..name = _nameCtrl.text.trim()
      ..title = _titleCtrl.text.trim()
      ..email = _emailCtrl.text.trim()
      ..phone = _phoneCtrl.text.trim()
      ..address = _addressCtrl.text.trim()
      ..summary = _summaryCtrl.text.trim();
  }

  // --- Fotoğraf (URL) ekleme ---
  void _editPhoto() async {
    // Fotoğraf ekleme özelliği yakında eklenecek
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf ekleme özelliği yakında eklenecek'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    // Eski kod - yorum satırına alındı (gelecekte kullanılabilir)
    /*
    final urlCtrl = TextEditingController(text: _cv.photoUrl ?? '');
    final res = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kResultSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetGrabber(),
            Text('Fotoğraf URL'si', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'https://... (görsel bağlantısı)',
                labelText: 'URL',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim()),
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() => _cv.photoUrl = res);
      _saveCvData(); // Fotoğraf değişince kaydet
    }
    */
  }

  // --- Ekle/Düzenle helper’ları ---
  Future<T?> _openSheet<T>(Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kResultSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 12,
        ),
        child: child,
      ),
    );
  }

  void _addExperience() async {
    final res = await _openSheet<Experience>(const _ExperienceEditor());
    if (res != null) {
      setState(() => _cv.experiences.add(res));
      _saveCvData();
    }
  }

  void _editExperience(int index) async {
    final origin = _cv.experiences[index];
    final res = await _openSheet<Experience>(_ExperienceEditor(prefill: origin));
    if (res != null) {
      setState(() => _cv.experiences[index] = res);
      _saveCvData();
    }
  }

  void _addEducation() async {
    final res = await _openSheet<Education>(const _EducationEditor());
    if (res != null) {
      setState(() => _cv.educations.add(res));
      _saveCvData();
    }
  }

  void _editEducation(int index) async {
    final origin = _cv.educations[index];
    final res = await _openSheet<Education>(_EducationEditor(prefill: origin));
    if (res != null) {
      setState(() => _cv.educations[index] = res);
      _saveCvData();
    }
  }

  void _addSkill() async {
    final res = await _openSheet<String?>(const _SkillEditor());
    if (res != null && res.trim().isNotEmpty) {
      setState(() => _cv.skills.add(res.trim()));
      _saveCvData();
    }
  }

  void _addLanguage() async {
    final res = await _openSheet<Language?>(const _LanguageEditor());
    if (res != null) {
      setState(() => _cv.languages.add(res));
      _saveCvData();
    }
  }

  void _addCertificate() async {
    final res = await _openSheet<Certificate?>(const _CertificateEditor());
    if (res != null) {
      setState(() => _cv.certificates.add(res));
      _saveCvData();
    }
  }

  void _addProject() async {
    final res = await _openSheet<Project?>(const _ProjectEditor());
    if (res != null) {
      setState(() => _cv.projects.add(res));
      _saveCvData();
    }
  }

  void _addHobby() async {
    final res = await _openSheet<String?>(_SimpleChipEditor(title: 'Hobi/İlgi Alanı Ekle', label: 'Hobi/İlgi'));
    if (res != null && res.trim().isNotEmpty) {
      setState(() => _cv.hobbies.add(res.trim()));
      _saveCvData();
    }
  }

  void _addLicense() async {
    final res = await _openSheet<String?>(_SimpleChipEditor(title: 'Sürücü Belgesi Ekle', label: 'Ehliyet (örn: B)'));
    if (res != null && res.trim().isNotEmpty) {
      setState(() => _cv.licenses.add(res.trim()));
      _saveCvData();
    }
  }

  void _addVolunteer() async {
    final res = await _openSheet<Volunteer?>(const _VolunteerEditor());
    if (res != null) {
      setState(() => _cv.volunteering.add(res));
      _saveCvData();
    }
  }

  void _addReference() async {
    final res = await _openSheet<RefItem?>(const _ReferenceEditor());
    if (res != null) {
      setState(() => _cv.references.add(res));
      _saveCvData();
    }
  }

  // Kullanıcıya şablon listesi gösterir ve seçimi kaydeder — YENİ
  Future<void> _pickTemplate() async {
    final sel = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: CvTemplates.names.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final selected = i == _templateIndex;
              return ListTile(
                title: Text(CvTemplates.names[i]),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.indigo)
                    : null,
                onTap: () => Navigator.of(ctx).pop(i),
              );
            },
          ),
        );
      },
    );
    if (sel != null && mounted) {
      setState(() => _templateIndex = sel);
      _saveCvData(); // Şablon değişince kaydet
    }
  }


  void _preview() {
    _syncModel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kResultSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _CvPreview(
            cv: _cv,
            templateIndex: _templateIndex, // YENİ
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = const Divider(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CV Oluştur',
          style: TextStyle(color: Colors.indigo),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _preview,
            icon: const Icon(Icons.visibility_outlined, color: Colors.indigo),
            label: const Text('Önizle', style: TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(kPageHPad, 12, kPageHPad, 24),
            children: [
              // ===== 1) FOTOĞRAF =====
              Text('Fotoğraf', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.black12,
                    backgroundImage: (_cv.photoUrl != null && _cv.photoUrl!.isNotEmpty)
                        ? NetworkImage(_cv.photoUrl!)
                        : null,
                    child: (_cv.photoUrl == null || _cv.photoUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 32, color: Colors.black45)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _editPhoto,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Fotoğraf Ekle / Değiştir'),
                        ),
                        if (_cv.photoUrl != null && _cv.photoUrl!.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => setState(()=> _cv.photoUrl = null),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Kaldır'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              divider,

              // ===== 2) Kişisel Bilgiler =====
              Text('Kişisel Bilgiler', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
                validator: (v) => (v==null || v.trim().isEmpty) ? 'Gerekli' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Ünvan / Pozisyon')),
              const SizedBox(height: 8),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-posta'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telefon'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Adres')),
              const SizedBox(height: 8),
              TextFormField(controller: _summaryCtrl, decoration: const InputDecoration(labelText: 'Öz Geçmiş'), maxLines: 4),

              divider,

              // ===== 3) Deneyimler =====
              Row(
                children: [
                  Expanded(child: Text('Deneyimler', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addExperience, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              ..._cv.experiences.asMap().entries.map((e) => _CardLine(
                title: '${e.value.position} · ${e.value.company}',
                subtitle: '${e.value.start} — ${(e.value.isCurrent || e.value.end.isEmpty) ? "Güncel" : e.value.end}\n${e.value.desc}',
                trailingBadges: e.value.isCurrent ? const [Chip(label: Text('Güncel'))] : const [],
                onEdit: () => _editExperience(e.key),
                onDelete: () => setState(() => _cv.experiences.removeAt(e.key)),
              )),

              divider,

              // ===== 4) Eğitim =====
              Row(
                children: [
                  Expanded(child: Text('Eğitim', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addEducation, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              ..._cv.educations.asMap().entries.map((e) => _CardLine(
                title: '${e.value.department} · ${e.value.school}',
                subtitle: '${e.value.start} — ${e.value.end}\n${e.value.note}',
                onEdit: () => _editEducation(e.key),
                onDelete: () => setState(() => _cv.educations.removeAt(e.key)),
              )),

              divider,

              // ===== 5) Yetenekler =====
              Row(
                children: [
                  Expanded(child: Text('Yetenekler', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addSkill, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _cv.skills.asMap().entries.map((e) => Chip(
                  label: Text(e.value),
                  onDeleted: () => setState(() => _cv.skills.removeAt(e.key)),
                )).toList(),
              ),

              divider,

              // ===== 6) Diller =====
              Row(
                children: [
                  Expanded(child: Text('Diller', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addLanguage, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _cv.languages.asMap().entries.map((e) => Chip(
                  label: Text('${e.value.name} — ${e.value.level}'),
                  onDeleted: () => setState(() => _cv.languages.removeAt(e.key)),
                )).toList(),
              ),

              divider,

              // ===== 7) Sertifikalar =====
              Row(
                children: [
                  Expanded(child: Text('Sertifikalar', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addCertificate, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              ..._cv.certificates.asMap().entries.map((e) => _CardLine(
                title: e.value.title,
                subtitle: '${e.value.org} • ${e.value.year}',
                onEdit: () async {
                  final res = await _openSheet<Certificate?>(_CertificateEditor(prefill: e.value));
                  if (res != null) setState(()=> _cv.certificates[e.key] = res);
                },
                onDelete: () => setState(() => _cv.certificates.removeAt(e.key)),
              )),

              divider,

              // ===== 8) Projeler =====
              Row(
                children: [
                  Expanded(child: Text('Projeler', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addProject, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              ..._cv.projects.asMap().entries.map((e) => _CardLine(
                title: e.value.name,
                subtitle: '${e.value.description}${e.value.link.trim().isNotEmpty ? '\n${e.value.link}' : ''}',
                onEdit: () async {
                  final res = await _openSheet<Project?>(_ProjectEditor(prefill: e.value));
                  if (res != null) setState(()=> _cv.projects[e.key] = res);
                },
                onDelete: () => setState(() => _cv.projects.removeAt(e.key)),
              )),

              divider,

              // ===== 9) Hobiler / İlgi Alanları =====
              Row(
                children: [
                  Expanded(child: Text('Hobiler / İlgi Alanları', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addHobby, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _cv.hobbies.asMap().entries.map((e) => Chip(
                  label: Text(e.value),
                  onDeleted: () => setState(() => _cv.hobbies.removeAt(e.key)),
                )).toList(),
              ),

              divider,

              // ===== 10) Ehliyet =====
              Row(
                children: [
                  Expanded(child: Text('Sürücü Belgesi', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addLicense, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _cv.licenses.asMap().entries.map((e) => Chip(
                  label: Text(e.value),
                  onDeleted: () => setState(() => _cv.licenses.removeAt(e.key)),
                )).toList(),
              ),

              divider,

              // ===== 11) Gönüllülük =====
              Row(
                children: [
                  Expanded(child: Text('Gönüllülük Faaliyetleri', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addVolunteer, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              ..._cv.volunteering.asMap().entries.map((e) => _CardLine(
                title: '${e.value.role} · ${e.value.organization}',
                subtitle: '${e.value.start} — ${e.value.end}${e.value.description.trim().isNotEmpty ? '\n${e.value.description}' : ''}',
                onEdit: () async {
                  final res = await _openSheet<Volunteer?>(_VolunteerEditor(prefill: e.value));
                  if (res != null) setState(()=> _cv.volunteering[e.key] = res);
                },
                onDelete: () => setState(() => _cv.volunteering.removeAt(e.key)),
              )),

              divider,

              // ===== 12) Referanslar =====
              Row(
                children: [
                  Expanded(child: Text('Referanslar', style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(onPressed: _addReference, icon: const Icon(Icons.add), label: const Text('Ekle')),
                ],
              ),
              ..._cv.references.asMap().entries.map((e) => _CardLine(
                title: '${e.value.name} — ${e.value.position}',
                subtitle: '${e.value.contact}${e.value.note.trim().isNotEmpty ? '\n${e.value.note}' : ''}',
                onEdit: () async {
                  final res = await _openSheet<RefItem?>(_ReferenceEditor(prefill: e.value));
                  if (res != null) setState(()=> _cv.references[e.key] = res);
                },
                onDelete: () => setState(() => _cv.references.removeAt(e.key)),
              )),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) _preview();
                },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Önizle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =====================
///  KART / EDİTÖR PARÇALARI
/// =====================
class _CardLine extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> trailingBadges;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CardLine({
    required this.title,
    required this.subtitle,
    this.trailingBadges = const [],
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: AppW.heading, height: 1.25),
        ),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...trailingBadges,
            if (trailingBadges.isNotEmpty) const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 5, margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
    );
  }
}

/// =====================
///  ORTAK: TR TARİH & CUPERTINO PICKER
/// =====================
const List<String> _ayAdlariTR = [
  'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
  'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
];

String formatDateTR(DateTime d){
  final gun = d.day.toString().padLeft(2,'0');
  final ayAd = _ayAdlariTR[d.month-1];
  final yil = d.year.toString();
  // "gün ay yıl" (örn: 12 Ekim 2025)
  return '$gun $ayAd $yil';
}

DateTime? _tryParseTR(String s){
  if (s.trim().isEmpty) return null;
  // 12 Ekim 2025 ya da 12.10.2025 desteği
  final bySpace = RegExp(r'^(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})$');
  final m1 = bySpace.firstMatch(s.trim());
  if (m1!=null){
    final g = int.tryParse(m1.group(1)!);
    final ayStr = m1.group(2)!.toLowerCase();
    final y = int.tryParse(m1.group(3)!);
    final idx = _ayAdlariTR.indexWhere((e)=> e.toLowerCase()==ayStr);
    if (g!=null && y!=null && idx>=0){
      return DateTime(y, idx+1, g);
    }
  }
  final byDots = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');
  final m2 = byDots.firstMatch(s.trim());
  if (m2!=null){
    final g = int.tryParse(m2.group(1)!);
    final a = int.tryParse(m2.group(2)!);
    final y = int.tryParse(m2.group(3)!);
    if (g!=null && a!=null && y!=null){
      return DateTime(y, a, g);
    }
  }
  return null;
}

/// === Üç sütunlu (Gün–Ay–Yıl) TR Cupertino Tarih Seçici ===
Future<DateTime?> pickCupertinoDate(BuildContext context, {DateTime? initial}) {
  DateTime init = initial ?? DateTime.now();

  int daysInMonth(int year, int month) {
    final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int clampInt(int v, int min, int max) => v < min ? min : (v > max ? max : v);

  int day   = init.day;
  int month = init.month; // 1-12
  int year  = init.year;

  const int minYear = 1950;
  final int maxYear = DateTime.now().year + 50;

  day = clampInt(day, 1, daysInMonth(year, month));

  final dayCtrl   = FixedExtentScrollController(initialItem: day - 1);
  final monthCtrl = FixedExtentScrollController(initialItem: month - 1);
  final yearCtrl  = FixedExtentScrollController(initialItem: year - minYear);

  return showCupertinoModalPopup<DateTime?>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSB) {
          final maxD = daysInMonth(year, month);
          if (day > maxD) {
            day = maxD;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dayCtrl.hasClients) dayCtrl.jumpToItem(day - 1);
            });
          }

          return Container(
            height: 300,
            color: Colors.white,
            child: Column(
              children: [
                // Üst bar: solda İptal, sağda Tamam (renk: black87)
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('İptal',
                            style: TextStyle(fontWeight: FontWeight.w400, color: Colors.black87)),
                        onPressed: () => Navigator.of(ctx).pop(null),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Tamam',
                            style: TextStyle(fontWeight: FontWeight.w400, color: Colors.black87)),
                        onPressed: () => Navigator.of(ctx).pop(DateTime(year, month, day)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Gün – Ay – Yıl sırayla
                Expanded(
                  child: Row(
                    children: [
                      // GÜN
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 36,
                          scrollController: dayCtrl,
                          onSelectedItemChanged: (i) {
                            setSB(() {
                              day = clampInt(i + 1, 1, daysInMonth(year, month));
                            });
                          },
                          children: List.generate(
                            maxD,
                                (i) => Center(child: Text('${i + 1}'.padLeft(2, '0'))),
                          ),
                        ),
                      ),
                      // AY (TR)
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 36,
                          scrollController: monthCtrl,
                          onSelectedItemChanged: (i) {
                            setSB(() {
                              month = i + 1; // 1..12
                              final newMax = daysInMonth(year, month);
                              if (day > newMax) {
                                day = newMax;
                                dayCtrl.jumpToItem(day - 1);
                              }
                            });
                          },
                          children: _ayAdlariTR.map((ad) => Center(child: Text(ad))).toList(),
                        ),
                      ),
                      // YIL
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 36,
                          scrollController: yearCtrl,
                          onSelectedItemChanged: (i) {
                            setSB(() {
                              year = 1950 + i;
                              final newMax = daysInMonth(year, month);
                              if (day > newMax) {
                                day = newMax;
                                dayCtrl.jumpToItem(day - 1);
                              }
                            });
                          },
                          children: List.generate(
                            (maxYear - minYear - 0 + 1),
                                (i) => Center(child: Text('${1950 + i}')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// === DİL SEVİYESİ: Sol üst İptal, sağ üst Tamam (renk black87) ===
Future<String?> pickCupertinoLevel(BuildContext context, List<String> options, {int initialIndex = 0}) {
  int index = (initialIndex>=0 && initialIndex<options.length) ? initialIndex : 0;
  return showCupertinoModalPopup<String?>(
      context: context,
      builder: (ctx){
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              // Üst bar (İptal / Tamam)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal',
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black87)),
                      onPressed: ()=> Navigator.of(ctx).pop(null),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Tamam',
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black87)),
                      onPressed: ()=> Navigator.of(ctx).pop(options[index]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: index),
                  onSelectedItemChanged: (i)=> index = i,
                  children: options.map((e)=> Center(child: Text(e))).toList(),
                ),
              ),
            ],
          ),
        );
      }
  );
}

/// =====================
///  EDITÖRLER
/// =====================
class _ExperienceEditor extends StatefulWidget {
  final Experience? prefill;
  const _ExperienceEditor({this.prefill});
  @override
  State<_ExperienceEditor> createState() => _ExperienceEditorState();
}
class _ExperienceEditorState extends State<_ExperienceEditor> {
  late final TextEditingController _company;
  late final TextEditingController _position;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _desc;
  bool _isCurrent = false;

  @override
  void initState() {
    super.initState();
    _company = TextEditingController(text: widget.prefill?.company ?? '');
    _position = TextEditingController(text: widget.prefill?.position ?? '');
    _start = TextEditingController(text: widget.prefill?.start ?? '');
    _end = TextEditingController(text: widget.prefill?.end ?? '');
    _desc = TextEditingController(text: widget.prefill?.desc ?? '');
    _isCurrent = widget.prefill?.isCurrent ?? false;
  }

  @override
  void dispose() { _company.dispose(); _position.dispose(); _start.dispose(); _end.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _pickStart() async {
    final init = _tryParseTR(_start.text) ?? DateTime.now();
    final d = await pickCupertinoDate(context, initial: init);
    if (d!=null) setState(()=> _start.text = formatDateTR(d));
  }
  Future<void> _pickEnd() async {
    final init = _tryParseTR(_end.text) ?? DateTime.now();
    final d = await pickCupertinoDate(context, initial: init);
    if (d!=null) setState(()=> _end.text = formatDateTR(d));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetGrabber(),
          Text(widget.prefill == null ? 'Deneyim Ekle' : 'Deneyimi Düzenle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: _company, decoration: const InputDecoration(labelText: 'Şirket')),
          const SizedBox(height: 8),
          TextField(controller: _position, decoration: const InputDecoration(labelText: 'Pozisyon')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _start,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Başlangıç (gün ay yıl)'),
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _end,
                  readOnly: true,
                  enabled: !_isCurrent,
                  decoration: InputDecoration(
                    labelText: 'Bitiş (gün ay yıl)',
                    hintText: _isCurrent ? 'Güncel' : null,
                  ),
                  onTap: _isCurrent ? null : _pickEnd,
                ),
              ),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Şu anda bu işyerinde çalışıyorum'),
            value: _isCurrent,
            onChanged: (v) {
              setState(() {
                _isCurrent = v ?? false;
                if (_isCurrent) _end.text = '';
              });
            },
          ),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Açıklama / Sorumluluklar')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(Experience(
                      company: _company.text.trim(),
                      position: _position.text.trim(),
                      start: _start.text.trim(),
                      end: _end.text.trim(),
                      desc: _desc.text.trim(),
                      isCurrent: _isCurrent,
                    ));
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _EducationEditor extends StatefulWidget {
  final Education? prefill;
  const _EducationEditor({this.prefill});
  @override
  State<_EducationEditor> createState() => _EducationEditorState();
}
class _EducationEditorState extends State<_EducationEditor> {
  late final TextEditingController _school;
  late final TextEditingController _dept;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _note;
  late final TextEditingController _levelCtrl;
  String? _selectedLevel;
  final List<String> _levels = const [
    'İlk öğretim',
    'Orta öğretim',
    'Lisans',
    'Yüksek lisans',
    'Doktora',
  ];

  @override
  void initState() {
    super.initState();
    _school = TextEditingController(text: widget.prefill?.school ?? '');
    _dept = TextEditingController(text: widget.prefill?.department ?? '');
    _start = TextEditingController(text: widget.prefill?.start ?? '');
    _end = TextEditingController(text: widget.prefill?.end ?? '');
    _note = TextEditingController(text: widget.prefill?.note ?? '');
    _selectedLevel = widget.prefill?.level;
    _levelCtrl = TextEditingController(text: _selectedLevel ?? '');
  }

  @override
  void dispose() { 
    _school.dispose(); 
    _dept.dispose(); 
    _start.dispose(); 
    _end.dispose(); 
    _note.dispose(); 
    _levelCtrl.dispose();
    super.dispose(); 
  }

  Future<void> _pickStart() async {
    final init = _tryParseTR(_start.text) ?? DateTime.now();
    final d = await pickCupertinoDate(context, initial: init);
    if (d!=null) setState(()=> _start.text = formatDateTR(d));
  }
  Future<void> _pickEnd() async {
    final init = _tryParseTR(_end.text) ?? DateTime.now();
    final d = await pickCupertinoDate(context, initial: init);
    if (d!=null) setState(()=> _end.text = formatDateTR(d));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetGrabber(),
          Text(widget.prefill == null ? 'Eğitim Ekle' : 'Eğitimi Düzenle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            controller: _levelCtrl,
            decoration: const InputDecoration(
              labelText: 'Eğitim Seviyesi (Opsiyonel)',
              filled: true,
              fillColor: Colors.white,
            ),
            onTap: () async {
              final idx = _selectedLevel == null ? 0 : _levels.indexOf(_selectedLevel!);
              final res = await pickCupertinoLevel(context, _levels, initialIndex: idx < 0 ? 0 : idx);
              if (res != null) {
                setState(() {
                  _selectedLevel = res;
                  _levelCtrl.text = res;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          TextField(controller: _school, decoration: const InputDecoration(labelText: 'Okul')),
          const SizedBox(height: 8),
          TextField(controller: _dept, decoration: const InputDecoration(labelText: 'Bölüm / Program')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _start,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Başlangıç (gün ay yıl)'),
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _end,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Bitiş (gün ay yıl)'),
                  onTap: _pickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Not / Derece (opsiyonel)')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(Education(
                      school: _school.text.trim(),
                      department: _dept.text.trim(),
                      start: _start.text.trim(),
                      end: _end.text.trim(),
                      note: _note.text.trim(),
                      level: _selectedLevel ?? '',
                    ));
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SkillEditor extends StatefulWidget {
  const _SkillEditor();
  @override
  State<_SkillEditor> createState() => _SkillEditorState();
}
class _SkillEditorState extends State<_SkillEditor> {
  final _ctrl = TextEditingController();
  late final TextEditingController _levelCtrl;
  String? _selectedLevel;
  final List<String> _levels = const ['Giriş Seviye', 'Orta Seviye', 'İleri Seviye'];
  
  @override
  void initState() {
    super.initState();
    _levelCtrl = TextEditingController(text: '');
  }
  
  @override
  void dispose() { 
    _ctrl.dispose(); 
    _levelCtrl.dispose();
    super.dispose(); 
  }
  
  String _buildSkillString() {
    final skill = _ctrl.text.trim();
    if (skill.isEmpty) return '';
    if (_selectedLevel != null && _selectedLevel!.isNotEmpty) {
      return '$skill — $_selectedLevel';
    }
    return skill;
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetGrabber(),
          Text('Yetenek Ekle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(hintText: 'Örn: Flutter, MS Excel…', labelText: 'Yetenek'),
            onSubmitted: (_) => Navigator.of(context).pop(_buildSkillString()),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            controller: _levelCtrl,
            decoration: const InputDecoration(
              labelText: 'Seviye (Opsiyonel)',
              filled: true,
              fillColor: Colors.white,
            ),
            onTap: () async {
              final idx = _selectedLevel == null ? 0 : _levels.indexOf(_selectedLevel!);
              final res = await pickCupertinoLevel(context, _levels, initialIndex: idx < 0 ? 0 : idx);
              if (res != null) {
                setState(() {
                  _selectedLevel = res;
                  _levelCtrl.text = res;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_buildSkillString()),
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _LanguageEditor extends StatefulWidget {
  const _LanguageEditor();
  @override
  State<_LanguageEditor> createState() => _LanguageEditorState();
}
class _LanguageEditorState extends State<_LanguageEditor> {
  final _nameCtrl = TextEditingController();
  final List<String> _levels = const [
    'Ana dil',
    'C2 (Ustalık)',
    'C1 (İleri)',
    'B2 (Üst-Orta)',
    'B1 (Orta)',
    'A2 (Başlangıç+)',
    'A1 (Başlangıç)',
  ];
  String? _selected;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _pickLevel() async {
    final idx = _selected==null ? 0 : _levels.indexOf(_selected!);
    final res = await pickCupertinoLevel(context, _levels, initialIndex: idx<0?0:idx);
    if (res!=null) setState(()=> _selected = res);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetGrabber(),
          Text('Dil Ekle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Dil (örn: İngilizce)'),
          ),
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: _selected ?? ''),
            decoration: const InputDecoration(labelText: 'Seviye'),
            onTap: _pickLevel,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final name = _nameCtrl.text.trim();
                    final level = _selected ?? '';
                    if (name.isEmpty || level.isEmpty) {
                      Navigator.of(context).pop(null);
                    } else {
                      Navigator.of(context).pop(Language(name: name, level: level));
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CertificateEditor extends StatefulWidget {
  final Certificate? prefill;
  const _CertificateEditor({this.prefill});
  @override
  State<_CertificateEditor> createState() => _CertificateEditorState();
}
class _CertificateEditorState extends State<_CertificateEditor> {
  late final TextEditingController _title;
  late final TextEditingController _org;
  late final TextEditingController _year;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.prefill?.title ?? '');
    _org   = TextEditingController(text: widget.prefill?.org ?? '');
    _year  = TextEditingController(text: widget.prefill?.year ?? '');
  }
  @override
  void dispose() { _title.dispose(); _org.dispose(); _year.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetGrabber(),
        Text(widget.prefill==null?'Sertifika Ekle':'Sertifikayı Düzenle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Sertifika Adı')),
        const SizedBox(height: 8),
        TextField(controller: _org, decoration: const InputDecoration(labelText: 'Kurum')),
        const SizedBox(height: 8),
        TextField(controller: _year, decoration: const InputDecoration(labelText: 'Yıl')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(
            onPressed: ()=> Navigator.of(context).pop(Certificate(title: _title.text.trim(), org: _org.text.trim(), year: _year.text.trim())),
            child: const Text('Kaydet'),
          )),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class _ProjectEditor extends StatefulWidget {
  final Project? prefill;
  const _ProjectEditor({this.prefill});
  @override
  State<_ProjectEditor> createState() => _ProjectEditorState();
}
class _ProjectEditorState extends State<_ProjectEditor> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _link;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.prefill?.name ?? '');
    _desc = TextEditingController(text: widget.prefill?.description ?? '');
    _link = TextEditingController(text: widget.prefill?.link ?? '');
  }
  @override
  void dispose() { _name.dispose(); _desc.dispose(); _link.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetGrabber(),
        Text(widget.prefill==null?'Proje Ekle':'Projeyi Düzenle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Proje Adı')),
        const SizedBox(height: 8),
        TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Kısa Açıklama'), maxLines: 3),
        const SizedBox(height: 8),
        TextField(controller: _link, decoration: const InputDecoration(labelText: 'Bağlantı (opsiyonel)')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(
            onPressed: ()=> Navigator.of(context).pop(Project(name: _name.text.trim(), description: _desc.text.trim(), link: _link.text.trim())),
            child: const Text('Kaydet'),
          )),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class _VolunteerEditor extends StatefulWidget {
  final Volunteer? prefill;
  const _VolunteerEditor({this.prefill});
  @override
  State<_VolunteerEditor> createState() => _VolunteerEditorState();
}
class _VolunteerEditorState extends State<_VolunteerEditor> {
  late final TextEditingController _org;
  late final TextEditingController _role;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _desc;
  @override
  void initState() {
    super.initState();
    _org   = TextEditingController(text: widget.prefill?.organization ?? '');
    _role  = TextEditingController(text: widget.prefill?.role ?? '');
    _start = TextEditingController(text: widget.prefill?.start ?? '');
    _end   = TextEditingController(text: widget.prefill?.end ?? '');
    _desc  = TextEditingController(text: widget.prefill?.description ?? '');
  }
  @override
  void dispose() { _org.dispose(); _role.dispose(); _start.dispose(); _end.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _pickStart() async {
    final init = _tryParseTR(_start.text) ?? DateTime.now();
    final d = await pickCupertinoDate(context, initial: init);
    if (d!=null) setState(()=> _start.text = formatDateTR(d));
  }
  Future<void> _pickEnd() async {
    final init = _tryParseTR(_end.text) ?? DateTime.now();
    final d = await pickCupertinoDate(context, initial: init);
    if (d!=null) setState(()=> _end.text = formatDateTR(d));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetGrabber(),
        Text(widget.prefill==null?'Gönüllülük Faaliyeti Ekle':'Gönüllülük Faaliyetini Düzenle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(controller: _org,  decoration: const InputDecoration(labelText: 'Kurum')),
        const SizedBox(height: 8),
        TextField(controller: _role, decoration: const InputDecoration(labelText: 'Rol')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _start,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Başlangıç (gün ay yıl)'),
              onTap: _pickStart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _end,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Bitiş (gün ay yıl)'),
              onTap: _pickEnd,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)'), maxLines: 3),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(
            onPressed: ()=> Navigator.of(context).pop(Volunteer(
              organization: _org.text.trim(),
              role: _role.text.trim(),
              start: _start.text.trim(),
              end: _end.text.trim(),
              description: _desc.text.trim(),
            )),
            child: const Text('Kaydet'),
          )),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class _ReferenceEditor extends StatefulWidget {
  final RefItem? prefill;
  const _ReferenceEditor({this.prefill});
  @override
  State<_ReferenceEditor> createState() => _ReferenceEditorState();
}
class _ReferenceEditorState extends State<_ReferenceEditor> {
  late final TextEditingController _name;
  late final TextEditingController _pos;
  late final TextEditingController _contact;
  late final TextEditingController _note;
  @override
  void initState() {
    super.initState();
    _name    = TextEditingController(text: widget.prefill?.name ?? '');
    _pos     = TextEditingController(text: widget.prefill?.position ?? '');
    _contact = TextEditingController(text: widget.prefill?.contact ?? '');
    _note    = TextEditingController(text: widget.prefill?.note ?? '');
  }
  @override
  void dispose() { _name.dispose(); _pos.dispose(); _contact.dispose(); _note.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetGrabber(),
        Text(widget.prefill==null?'Referans Ekle':'Referansı Düzenle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Ad Soyad')),
        const SizedBox(height: 8),
        TextField(controller: _pos,  decoration: const InputDecoration(labelText: 'Pozisyon')),
        const SizedBox(height: 8),
        TextField(controller: _contact, decoration: const InputDecoration(labelText: 'İletişim (e-posta / telefon)')),
        const SizedBox(height: 8),
        TextField(controller: _note, decoration: const InputDecoration(labelText: 'Not (opsiyonel)')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(
            onPressed: ()=> Navigator.of(context).pop(RefItem(name: _name.text.trim(), position: _pos.text.trim(), contact: _contact.text.trim(), note: _note.text.trim())),
            child: const Text('Kaydet'),
          )),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class _SimpleChipEditor extends StatefulWidget {
  final String title;
  final String label;
  const _SimpleChipEditor({required this.title, required this.label});
  @override
  State<_SimpleChipEditor> createState() => _SimpleChipEditorState();
}
class _SimpleChipEditorState extends State<_SimpleChipEditor> {
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetGrabber(),
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(controller: _ctrl, decoration: InputDecoration(labelText: widget.label)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(
            onPressed: ()=> Navigator.of(context).pop(_ctrl.text.trim()),
            child: const Text('Kaydet'),
          )),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }
}


// onu SİL ve bununla değiştir:

class _CvPreview extends StatefulWidget {
  final CvData cv;
  final int templateIndex;

  const _CvPreview({
    super.key,
    required this.cv,
    required this.templateIndex,
  });

  @override
  State<_CvPreview> createState() => _CvPreviewState();
}

class _CvPreviewState extends State<_CvPreview> {
  late int _current;
  final GlobalKey _previewKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _current = widget.templateIndex;
  }

  @override
  void didUpdateWidget(covariant _CvPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // dışarıdan farklı şablon seçilirse senkronize et
    if (oldWidget.templateIndex != widget.templateIndex) {
      _current = widget.templateIndex;
    }
  }

  void _onSelectFromScroll(int index) {
    setState(() {
      _current = index;
    });
  }

  Future<void> _shareAsPdf() async {
    setState(() => _isSharing = true);
    try {
      // A4 sayfa boyutları
      final a4Format = PdfPageFormat.a4;
      final a4Width = a4Format.width;  // ~595.32 points
      final a4Height = a4Format.height; // ~842.04 points
      
      // Widget'ları optimal boyutta render ediyoruz
      // A4 sayfası ile uyumlu oranlar
      const double renderWidth = 780.0;
      const double renderHeight = 1104.0;
      
      // PDF modunda widget'ı render etmek için gizli bir overlay oluşturuyoruz
      final pdfKey = GlobalKey();
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000, // Ekran dışına taşıyoruz
          top: -10000,
          child: RepaintBoundary(
            key: pdfKey,
            child: SizedBox(
              width: renderWidth,
              height: renderHeight,
              child: buildTemplateForPdf(context, widget.cv, _current),
            ),
          ),
        ),
      );
      
      Overlay.of(context).insert(overlayEntry);
      
      // Widget'ın render edilmesini bekliyoruz - frame bazlı bekleme
      await SchedulerBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 50)); // Ek güvenlik için kısa bekleme
      
      final boundary =
          pdfKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.size.width == 0 || boundary.size.height == 0) {
        overlayEntry.remove();
        throw Exception('PDF widget render edilemedi');
      }
      
      // Optimize edilmiş çözünürlük - kalite ve performans dengesi
      // 1.5 pixelRatio yeterli kalite sağlarken daha hızlı render eder
      const pixelRatio = 1.5;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      overlayEntry.remove(); // Overlay'i hemen kaldırıyoruz
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Görsel oluşturulamadı');
      final pngBytes = byteData.buffer.asUint8List();

      final doc = pw.Document();
      final pwImage = pw.MemoryImage(Uint8List.fromList(pngBytes));

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (ctx) {
            // Görüntüyü A4 sayfasına tam olarak sığdır
            return pw.SizedBox(
              width: a4Width,
              height: a4Height,
              child: pw.FittedBox(
                fit: pw.BoxFit.contain, // contain kullanarak oranları koru
                alignment: pw.Alignment.topCenter,
                child: pw.Image(pwImage),
              ),
            );
          },
        ),
      );

      final sanitizedName = widget.cv.name.isEmpty
          ? 'cv'
          : widget.cv.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final filename = '$sanitizedName.pdf';

      await Printing.sharePdf(bytes: await doc.save(), filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF paylaşımı başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sheet grabber
        Container(
          width: 48,
          height: 5,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(3),
          ),
        ),

        // Büyük önizleme (tüm alanı dolduran sayfa)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: RepaintBoundary(
                key: _previewKey,
                child: buildTemplatePreview(context, widget.cv, _current),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Yatay şablon scroller (büyük önizlemenin altında)
        _TemplateScroller(
          current: _current,
          cv: widget.cv,
          onSelect: _onSelectFromScroll,
        ),

        const SizedBox(height: 8),

        // Paylaş butonu
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSharing ? null : _shareAsPdf,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: Text(
              _isSharing ? 'Hazırlanıyor...' : 'PDF Olarak Paylaş',
            ),
          ),
        ),
      ],
    );
  }
}

/// Yatay kaydırmalı küçük şablon kartları
class _TemplateScroller extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  final CvData cv;

  const _TemplateScroller({
    required this.current,
    required this.cv,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 116;
    const double cardHeight = 152;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CvTemplates.names.length,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final selected = i == current;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: cardWidth,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Colors.indigo : Colors.black12,
                  width: selected ? 2.0 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 92,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: buildTemplateThumbnail(context, cv, i),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CvTemplates.names[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.8,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.indigo : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
