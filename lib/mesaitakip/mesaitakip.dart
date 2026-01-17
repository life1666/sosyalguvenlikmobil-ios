import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'mesaihesaplama.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../utils/analytics_helper.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}


class OvertimeCalendarPage extends StatefulWidget {
  const OvertimeCalendarPage({super.key});

  @override
  State<OvertimeCalendarPage> createState() => _OvertimeCalendarPageState();
}

enum SalaryMode { minimumWage, manual }
enum SalaryKind { gross, net }
enum OtMultiplierChoice { auto, onePointFive, twoPointZero }
enum TimeUnit { day, hour }
enum ResultsMode { monthly, yearly }

class _OvertimeCalendarPageState extends State<OvertimeCalendarPage> {
  bool _restoring = false; // load sırasında autosave tetiklenmesin
  static const double _hoursPerDay = 7.5;
  static const _kStore = 'mesai_takip_v1';

  late DateTime _focusedDay;
  DateTime? _selectedDay; // ilk açılışta null kalsın (mavi olmasın)
  DateTime? _startDate;

  final Map<String, double> _overtimeData = {}; // yyyy-MM-dd_suffix
  int _currentTabIndex = 1;
  ResultsMode _resultsMode = ResultsMode.monthly;

  // Scroll senkron (Yıllık Özet)
  late final ScrollController _hHeaderCtrl;
  late final ScrollController _hBodyCtrl;
  late final ScrollController _vBodyCtrl;
  bool _hSyncingFromHeader = false;
  bool _hSyncingFromBody = false;

  // Ücret girişleri
  final List<TextEditingController> _grossCtrls =
  List.generate(12, (_) => TextEditingController());
  final List<TextEditingController> _netCtrls =
  List.generate(12, (_) => TextEditingController());

  // Ikramiye girişleri
  final List<TextEditingController> _bonusCtrls =
  List.generate(12, (_) => TextEditingController());

  final List<String> _monthNames = const [
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

  SalaryKind _salaryKind = SalaryKind.gross;
  SalaryMode _salaryMode = SalaryMode.manual;
  bool _isRetired = false;

  SalaryKind _bonusKind = SalaryKind.net;

  int _salaryYear = DateTime.now().year;
  final Map<int, _MinWage> _minWageByYear = {
    2022: const _MinWage(
      grossMonthly: 5004.00,
      netMonthly: 4253.40,
      netMonthlyRetired: 4628.70,
    ),
    2023: const _MinWage(
      grossMonthly: 10008.00,
      netMonthly: 8506.80,
      netMonthlyRetired: 9257.40,
    ),
    2024: const _MinWage(
      grossMonthly: 20002.50,
      netMonthly: 17002.12,
      netMonthlyRetired: 18277.28,
    ),
    2025: const _MinWage(
      grossMonthly: 26005.50,
      netMonthly: 22104.67,
      netMonthlyRetired: 23762.53,
    ),
    2026: const _MinWage(
      grossMonthly: 33030.00,
      netMonthly: 28075.50,        // Normal çalışan net asgari
      netMonthlyRetired: 30181.17,
    ),
  };

  final Map<int, double> _annualPaidLeaveDays = {}; // year -> days
  int _leaveYear = DateTime.now().year;
  final TextEditingController _leaveDaysCtrl = TextEditingController();

  int _resultsYear = DateTime.now().year;
  bool _isPropagating = false;

  final NumberFormat _tryFmt =
  NumberFormat.currency(locale: 'tr_TR', symbol: '₺ ', decimalDigits: 2);
  final NumberFormat _numFmt0 =
  NumberFormat.decimalPatternDigits(locale: 'tr_TR', decimalDigits: 0);
  final NumberFormat _numFmt1 =
  NumberFormat.decimalPatternDigits(locale: 'tr_TR', decimalDigits: 1);
  final NumberFormat _trFieldFmt =
  NumberFormat.decimalPatternDigits(locale: 'tr_TR', decimalDigits: 2);


  Future<void> _loadState() async {
    _restoring = true; // yükleme sırasında autosave çalışmasın

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStore);
    if (raw == null) {
      _restoring = false;
      return;
    }

    final map = jsonDecode(raw) as Map<String, dynamic>;

    // küçük yardımcı
    void restoreTexts(List<TextEditingController> ctrls, List? texts) {
      if (texts == null) return;
      for (int i = 0; i < ctrls.length && i < texts.length; i++) {
        ctrls[i].text = texts[i]?.toString() ?? '';
      }
    }

    setState(() {
      // basit alanlar
      final sd = map['startDate'] as String?;
      _startDate   = sd == null ? null : DateTime.tryParse(sd);
      _salaryYear  = (map['salaryYear']  ?? _salaryYear)  as int;
      _salaryKind  = SalaryKind.values[(map['salaryKind'] ?? _salaryKind.index) as int];
      _salaryMode  = SalaryMode.values[(map['salaryMode'] ?? _salaryMode.index) as int];
      _isRetired   = (map['isRetired']   ?? _isRetired)   as bool;
      _bonusKind   = SalaryKind.values[(map['bonusKind']  ?? _bonusKind.index)  as int];
      _leaveYear   = (map['leaveYear']   ?? _leaveYear)   as int;
      _resultsYear = (map['resultsYear'] ?? _resultsYear) as int;

      // map'ler
      final apRaw = map['annualPaidLeaveDays'];
      if (apRaw is Map) {
        _annualPaidLeaveDays
          ..clear()
          ..addAll(apRaw.map<int, double>(
                (k, v) => MapEntry(int.parse(k.toString()), (v as num).toDouble()),
          ));
      }

      final otRaw = map['overtimeData'];
      if (otRaw is Map) {
        _overtimeData
          ..clear()
          ..addAll(otRaw.map<String, double>(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ));
      }

      // controller metinleri
      restoreTexts(_grossCtrls, map['grossTexts'] as List?);
      restoreTexts(_netCtrls,   map['netTexts']   as List?);
      restoreTexts(_bonusCtrls, map['bonusTexts'] as List?);
    });

    _restoring = false;
  }



  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('mesai_takip_opened');
    _focusedDay = DateTime.now();
    _selectedDay = null;
    _resultsYear = _focusedDay.year;
    _salaryYear = _focusedDay.year;

    _hHeaderCtrl = ScrollController();
    _hBodyCtrl = ScrollController();
    _vBodyCtrl = ScrollController();

    // ↙︎ YENİ: metin kutuları değişince otomatik kaydet
    for (final c in _grossCtrls) { c.addListener(_saveState); }
    for (final c in _netCtrls)   { c.addListener(_saveState); }
    for (final c in _bonusCtrls) { c.addListener(_saveState); }

    // yatay sync (senin kodun)
    _hHeaderCtrl.addListener(() {
      if (_hSyncingFromBody) return;
      _hSyncingFromHeader = true;
      _hBodyCtrl.jumpTo(_hHeaderCtrl.offset);
      _hSyncingFromHeader = false;
    });
    _hBodyCtrl.addListener(() {
      if (_hSyncingFromHeader) return;
      _hSyncingFromBody = true;
      _hHeaderCtrl.jumpTo(_hBodyCtrl.offset);
      _hSyncingFromBody = false;
    });

    // ↙︎ YENİ: açılışta kayıtlı durumu yükle
    _loadState();
  }



  @override
  void dispose() {
    // ↙︎ YENİ: dinleyicileri kaldır
    for (final c in _grossCtrls) { c.removeListener(_saveState); c.dispose(); }
    for (final c in _netCtrls)   { c.removeListener(_saveState); c.dispose(); }
    for (final c in _bonusCtrls) { c.removeListener(_saveState); c.dispose(); }
    _leaveDaysCtrl.dispose();
    _hHeaderCtrl.dispose();
    _hBodyCtrl.dispose();
    _vBodyCtrl.dispose();
    super.dispose();
  }


  Future<void> _saveState() async {
    if (_restoring || !mounted) return; // yükleme sırasında veya dispose sonrası tetiklenen dinleyicileri yoksay
    try {
      final prefs = await SharedPreferences.getInstance();

      List<String> _texts(List<TextEditingController> list) =>
          list.map((c) => c.text).toList();

      final data = {
        'startDate': _startDate?.toIso8601String(),
        'salaryYear': _salaryYear,
        'salaryKind': _salaryKind.index,
        'salaryMode': _salaryMode.index,
        'isRetired': _isRetired,
        'bonusKind': _bonusKind.index,
        'leaveYear': _leaveYear,
        'annualPaidLeaveDays': _annualPaidLeaveDays,  // {year: days}
        'resultsYear': _resultsYear,
        'overtimeData': _overtimeData,                // {"yyyy-MM-dd_suffix": double}
        'grossTexts': _texts(_grossCtrls),            // 12 eleman
        'netTexts': _texts(_netCtrls),                // 12 eleman
        'bonusTexts': _texts(_bonusCtrls),            // 12 eleman
      };

      await prefs.setString(_kStore, jsonEncode(data));
    } catch (e) {
      debugPrint('_saveState hatası: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  // ----------------- Helpers -----------------
  String _keyFor(DateTime day) => DateFormat('yyyy-MM-dd').format(day);
  String _fmt(DateTime day) => DateFormat('d.M.yyyy', 'tr_TR').format(day);
  String _monthLabel(DateTime day) => DateFormat('MMMM', 'tr_TR').format(day);
  int _yyyymm(DateTime d) => d.year * 100 + d.month;
  int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  bool _isSunday(DateTime d) => d.weekday == DateTime.sunday;
  bool _isOfficialHoliday(DateTime d) {
    final md = '${d.month}-${d.day}';
    const fixed = {'1-1', '4-23', '5-1', '5-19', '7-15', '8-30', '10-29'};
    return fixed.contains(md);
  }

  double? _parseMoney(String s) {
    if (s.trim().isEmpty) return null;
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    final v = double.tryParse(cleaned);
    return v != null && v >= 1000000 ? v / 100.0 : v;
  }

  double? _proratedMonthlyAmount(DateTime month, double? baseAmount) {
    if (baseAmount == null) return null;
    if (_startDate == null) return baseAmount;

    // Aynı ayda işe başlanmışsa: 30 bazında kalan gün / 30
    if (_startDate!.year == month.year && _startDate!.month == month.month) {
      final lastDayOfMonth = _daysInMonth(month.year, month.month); // örn: Ekim = 31
      final remainingDays = (lastDayOfMonth - _startDate!.day + 1).clamp(0, lastDayOfMonth);
      final ratio = (remainingDays / 30.0).clamp(0.0, 1.0); // <-- 30 baz
      return baseAmount * ratio;
    }

    // Ay tamamen işe girişten önceyse: 0
    final endOfMonth = DateTime(month.year, month.month, _daysInMonth(month.year, month.month));
    if (_startDate!.isAfter(endOfMonth)) return 0.0;

    // Ay tamamen işe girişten sonraysa: tam
    return baseAmount;
  }


  double? _enteredGrossFor(DateTime month) {
    final i = month.month - 1;
    final g = _parseMoney(_grossCtrls[i].text);
    return _proratedMonthlyAmount(month, g);
  }

  double? _enteredNetFor(DateTime month) {
    final i = month.month - 1;
    final n = _parseMoney(_netCtrls[i].text);
    return _proratedMonthlyAmount(month, n);
  }

  double? _enteredBonusFor(DateTime month) {
    final i = month.month - 1;
    return _parseMoney(_bonusCtrls[i].text);
  }

  SalaryEngine _engineFor(int year) => SalaryEngine(
    year: year,
    status: _isRetired ? EmployeeStatus.sgdp : EmployeeStatus.normal,
    incentive: Incentive.none,
  );

  double _cumTaxBaseBefore(DateTime month) {
    final eng = _engineFor(month.year);
    double cum = 0.0;
    for (int m = 1; m < month.month; m++) {
      final idx = m - 1;
      final gEntered = _parseMoney(_grossCtrls[idx].text);
      final nEntered = _parseMoney(_netCtrls[idx].text);

      if (_salaryKind == SalaryKind.gross) {
        final g =
        _proratedMonthlyAmount(DateTime(month.year, m, 1), gEntered);
        if (g != null && g > 0) {
          final res = eng.calculateNetFromGross(
              grossMonthly: g,
              monthIndex: idx,
              cumulativeTaxBasePrev: cum);
          cum = res.cumulativeTaxBase;
        }
      } else {
        final n =
        _proratedMonthlyAmount(DateTime(month.year, m, 1), nEntered);
        if (n != null && n > 0) {
          final res = eng.calculateGrossFromNet(
              targetNetMonthly: n,
              monthIndex: idx,
              cumulativeTaxBasePrev: cum);
          cum = res.cumulativeTaxBase;
        }
      }
    }
    return cum;
  }

  double? _monthlyGrossFor(DateTime month) {
    final i = month.month - 1;
    final eng = _engineFor(month.year);
    final cumPrev = _cumTaxBaseBefore(month);

    if (_salaryKind == SalaryKind.gross) {
      return _enteredGrossFor(month);
    } else {
      final n = _enteredNetFor(month);
      if (n == null) return null;
      final res = eng.calculateGrossFromNet(
          targetNetMonthly: n,
          monthIndex: i,
          cumulativeTaxBasePrev: cumPrev);
      return res.gross;
    }
  }

  double? _monthlyNetFor(DateTime month) {
    final i = month.month - 1;
    final eng = _engineFor(month.year);
    final cumPrev = _cumTaxBaseBefore(month);

    if (_salaryKind == SalaryKind.net) {
      return _enteredNetFor(month);
    } else {
      final g = _enteredGrossFor(month);
      if (g == null) return null;
      final res = eng.calculateNetFromGross(
          grossMonthly: g,
          monthIndex: i,
          cumulativeTaxBasePrev: cumPrev);
      return res.net;
    }
  }
  double? _baseGrossForRate(DateTime month) {
    final year = month.year;

    // Asgari ücret modu: yılın brüt asgari ücreti
    if (_salaryMode == SalaryMode.minimumWage && _minWageByYear.containsKey(year)) {
      return _minWageByYear[year]!.grossMonthly;
    }

    // Manuel mod:
    if (_salaryKind == SalaryKind.gross) {
      // Kullanıcı brüt girdiyse: ham brüt (pro-rata değil)
      return _parseMoney(_grossCtrls[month.month - 1].text);
    } else {
      // Kullanıcı net girdiyse: NET'i tam aylık brüte çevir (oran için)
      final rawNet = _parseMoney(_netCtrls[month.month - 1].text);
      if (rawNet == null) return null;
      final eng = _engineFor(year);
      final cumPrev = _cumTaxBaseBefore(month);
      final conv = eng.calculateGrossFromNet(
        targetNetMonthly: rawNet,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev,
      );
      return conv.gross;
    }
  }

  double? _hourlyGrossFor(DateTime month) {
    final base = _baseGrossForRate(month);
    if (base == null) return null;
    // Aylık baz brüt → günlük (30’a böl) → saatlik (7.5’e böl)
    return base / 30.0 / _hoursPerDay; // _hoursPerDay zaten 7.5
  }


  double _monthlyOvertimeHours(DateTime month) {
    double h = 0;
    _overtimeData.forEach((k, v) {
      final parts = k.split('_');
      final date = DateTime.parse(parts[0]);
      if (date.year == month.year && date.month == month.month && parts[1] == 'overtime') {
        // ↓↓↓ EKLE ↓↓↓
        if (_startDate != null) {
          final sd = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final d0 = DateTime(date.year, date.month, date.day);
          if (d0.isBefore(sd)) return; // işe girişten önceki günleri yoksay
        }
        // ↑↑↑ EKLE ↑↑↑
        h += v;
      }
    });
    return h;
  }


  double _monthlyUnpaidHours(DateTime month) {
    double h = 0;
    _overtimeData.forEach((k, v) {
      final parts = k.split('_');
      final date = DateTime.parse(parts[0]);
      if (date.year == month.year && date.month == month.month && parts[1] == 'unpaid') {
        if (_startDate != null) {
          final sd = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final d0 = DateTime(date.year, date.month, date.day);
          if (d0.isBefore(sd)) return;
        }
        h += v;
      }
    });
    return h;
  }


  double _monthlyPaidHours(DateTime month) {
    double h = 0;
    _overtimeData.forEach((k, v) {
      final parts = k.split('_');
      final date = DateTime.parse(parts[0]);
      if (date.year == month.year && date.month == month.month && parts[1] == 'paid') {
        if (_startDate != null) {
          final sd = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final d0 = DateTime(date.year, date.month, date.day);
          if (d0.isBefore(sd)) return;
        }
        h += v;
      }
    });
    return h;
  }


  double _trunc2(double v) => double.parse(v.toStringAsFixed(2));

  double _monthlyDeductionHours(DateTime month) {
    double h = 0;
    _overtimeData.forEach((k, v) {
      final parts = k.split('_');
      final date = DateTime.parse(parts[0]);
      if (date.year == month.year && date.month == month.month && parts[1] == 'deduction') {
        if (_startDate != null) {
          final sd = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final d0 = DateTime(date.year, date.month, date.day);
          if (d0.isBefore(sd)) return;
        }
        h += v;
      }
    });
    return h;
  }


  double _deductionGrossFor(DateTime month) {
    final h = _monthlyDeductionHours(month);
    final hr = _hourlyGrossFor(month);
    if (hr == null || h <= 0) return 0.0;
    return _trunc2(h * hr); // kesinti brüt = saatlik brüt * kesinti saat
  }

  /// İKRAMİYE (BRÜT):
  /// - Kullanıcı ikramiyeyi NET girdiyse "netin üstüne" eklenecek şekilde GROSS-UP yapılır.
  /// - Brüt girdiyse aynen döner.
  double _bonusGrossFor(DateTime month) {
    final bonusInput = _enteredBonusFor(month) ?? 0.0;
    if (bonusInput <= 0) return 0.0;

    final eng = _engineFor(month.year);
    final cumPrev = _cumTaxBaseBefore(month);

    // Baz brüt + mesai brüt (bonus bunun üstüne eklenecek)
    final baseGross = _monthlyGrossFor(month) ?? 0.0;
    final otGross = _monthlyOvertimeAmount(month, gross: true);
    final baseWithOt = baseGross + otGross;

    if (_salaryKind == SalaryKind.net || _bonusKind == SalaryKind.net) {
      // mevcut neti bul
      final baseNet = eng.calculateNetFromGross(
        grossMonthly: baseWithOt,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev,
      ).net;

      // hedef net = mevcut net + bonusInput olacak şekilde brütü geri bul
      final afterGross = eng.calculateGrossFromNet(
        targetNetMonthly: baseNet + bonusInput,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev,
      ).gross;

      final grossUp = afterGross - baseWithOt;
      return grossUp <= 0 ? 0.0 : _trunc2(grossUp);
    } else {
      // bonus brüt girilmiş
      return _trunc2(bonusInput);
    }
  }


  double _effectiveMultiplierFor(DateTime date) {
    final key = _keyFor(date);
    final manual = _overtimeData['${key}_otmult'];
    if (manual != null && manual > 0) return manual;
    return (_isSunday(date) || _isOfficialHoliday(date)) ? 2.0 : 1.5;
  }

  double _monthlyOvertimeAmount(DateTime month, {required bool gross}) {
    final hrGross = _hourlyGrossFor(month);
    if (hrGross == null) return 0.0;

    double otHoursWeighted = 0.0;
    _overtimeData.forEach((k, v) {
      final parts = k.split('_');
      final date = DateTime.parse(parts[0]);
      if (date.year == month.year &&
          date.month == month.month &&
          parts[1] == 'overtime') {
        final mult = _effectiveMultiplierFor(date);
        otHoursWeighted += v * mult;
      }
    });

    final otGross = otHoursWeighted * hrGross;
    if (gross) return otGross;

    final eng = _engineFor(month.year);
    final cumPrev = _cumTaxBaseBefore(month);
    final baseGross = _monthlyGrossFor(month) ?? 0.0;

    final baseRes = eng.calculateNetFromGross(
        grossMonthly: baseGross,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev);
    final withRes = eng.calculateNetFromGross(
        grossMonthly: baseGross + otGross,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev);
    final netDelta = withRes.net - baseRes.net;
    return netDelta < 0 ? 0.0 : netDelta;
  }

  double _monthlyBonusNet(DateTime month) {
    final bonusInput = _enteredBonusFor(month) ?? 0.0;
    if (bonusInput <= 0.0) return 0.0;

    final eng = _engineFor(month.year);
    final cumPrev = _cumTaxBaseBefore(month);
    final baseGross = _monthlyGrossFor(month) ?? 0.0;
    final otGross = _monthlyOvertimeAmount(month, gross: true);

    final baseWithOt = baseGross + otGross;

    final baseRes = eng.calculateNetFromGross(
      grossMonthly: baseWithOt,
      monthIndex: month.month - 1,
      cumulativeTaxBasePrev: cumPrev,
    ).net;

    if (_salaryKind == SalaryKind.net || _bonusKind == SalaryKind.net) {
      return bonusInput;
    } else {
      final withRes = eng.calculateNetFromGross(
        grossMonthly: baseWithOt + bonusInput,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev,
      ).net;
      final netDelta = withRes - baseRes;
      return netDelta < 0 ? 0.0 : netDelta;
    }
  }

  double _monthlyBonusGross(DateTime month) {
    final bonusInput = _enteredBonusFor(month) ?? 0.0;
    if (bonusInput <= 0.0) return 0.0;

    final eng = _engineFor(month.year);
    final cumPrev = _cumTaxBaseBefore(month);
    final baseGross = _monthlyGrossFor(month) ?? 0.0;
    final otGross = _monthlyOvertimeAmount(month, gross: true);

    final baseWithOt = baseGross + otGross;

    if (_salaryKind == SalaryKind.net || _bonusKind == SalaryKind.net) {
      final targetNetBonus = bonusInput;
      final baseNet = eng.calculateNetFromGross(
        grossMonthly: baseWithOt,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev,
      ).net;
      final withNetRes = eng.calculateGrossFromNet(
        targetNetMonthly: baseNet + targetNetBonus,
        monthIndex: month.month - 1,
        cumulativeTaxBasePrev: cumPrev,
      ).gross;
      return withNetRes - baseWithOt;
    } else {
      return bonusInput;
    }
  }

  void _applyMinimumWageForYear(int year) {
    final mw = _minWageByYear[year];
    if (mw == null) return;
    setState(() {
      _isPropagating = true;
      if (_salaryKind == SalaryKind.gross) {
        for (int i = 0; i < 12; i++) {
          _grossCtrls[i].text = _trFieldFmt.format(mw.grossMonthly);
        }
      } else {
        final net = _isRetired ? mw.netMonthlyRetired : mw.netMonthly;
        for (int i = 0; i < 12; i++) {
          _netCtrls[i].text = _trFieldFmt.format(net);
        }
      }
      _isPropagating = false;
    });
  }

  void _propagateForward({
    required int startMonthIndex,
    required bool isGrossColumn,
    required String value,
    required bool isBonus,
  }) {
    if (_isPropagating || _salaryMode == SalaryMode.minimumWage) return;
    setState(() {
      _isPropagating = true;
      List<TextEditingController> list;
      if (isBonus) {
        list = _bonusCtrls;
      } else {
        list = isGrossColumn ? _grossCtrls : _netCtrls;
      }
      for (int i = startMonthIndex; i < 12; i++) {
        list[i].text = value;
      }
      _isPropagating = false;
    });
  }

  void _formatControllerValue(TextEditingController c) {
    final v = _parseMoney(c.text);
    if (v == null) return;
    c.text = _trFieldFmt.format(v);
    c.selection =
        TextSelection.fromPosition(TextPosition(offset: c.text.length));
  }

  String hoursFmt(double v) {
    if (v == v.floor()) {
      return _numFmt0.format(v);
    } else {
      return _numFmt1.format(v);
    }
  }

  String daysFmt(double v) {
    return hoursFmt(v / _hoursPerDay);
  }

  String daysFmtLocal(double v) {
    return daysFmt(v);
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleForTab(_currentTabIndex),
          style: const TextStyle(color: Colors.indigo),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.indigo),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildSettingsTab(),
          _buildCalendarTab(),
          _buildResultsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (i) => setState(() => _currentTabIndex = i),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Ayarlar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Takvim'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Sonuçlar'),
        ],
      ),
    );
  }

  String _titleForTab(int i) => switch (i) {
    0 => 'Ayarlar',
    1 => 'Mesai Hesaplama (Takvim)',
    2 => 'Sonuçlar',
    _ => 'Mesai Hesaplama',
  };

  // ----------- AYARLAR (eksiksiz) -----------
  Widget _buildSettingsTab() {
    final year = _salaryYear;
    final supportsMW = _minWageByYear.containsKey(year);
    const headingStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.indigo);

    _leaveDaysCtrl.text =
        (_annualPaidLeaveDays[_leaveYear] ?? 0).toStringAsFixed(1);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Material(
                  color: Colors.white,
                  elevation: 1.5,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(
                          style: headingStyle,
                          child: const Text('İşe giriş tarihi'),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showCupertinoDatePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate == null ? 'Seçilmedi' : _fmt(_startDate!),
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                                ),
                                const Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        DefaultTextStyle.merge(
                          style: headingStyle,
                          child: const Text('Ücret Ayarları'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Yıl',
                                style: TextStyle(
                                    color: Colors.black54)),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _showSalaryYearPicker,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$_salaryYear',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, color: Colors.black87)),
                                    const SizedBox(width: 6),
                                    const Icon(CupertinoIcons.chevron_down,
                                        size: 16,
                                        color: Colors.black54),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Ücret Seçimi',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54)),
                        const SizedBox(height: 6),
                        CupertinoSlidingSegmentedControl<SalaryKind>(
                          groupValue: _salaryKind,
                          children: const {
                            SalaryKind.gross: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Text('Brüt')),
                            SalaryKind.net: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Text('Net')),
                          },
                          onValueChanged: (val) {
                            setState(() {
                              _salaryKind = val ?? SalaryKind.gross;
                              if (_salaryKind == SalaryKind.net) {
                                _bonusKind = SalaryKind.net;
                              }
                              if (_salaryMode == SalaryMode.minimumWage &&
                                  supportsMW) {
                                _applyMinimumWageForYear(year);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Asgari ücret alıyorum'),
                            const Spacer(),
                            Switch(
                              value: _salaryMode == SalaryMode.minimumWage,
                              activeColor: Colors.indigo,
                              onChanged: (v) {
                                setState(() {
                                  _salaryMode =
                                  v ? SalaryMode.minimumWage : SalaryMode.manual;
                                  if (v && supportsMW) {
                                    _applyMinimumWageForYear(year);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Emekliyim'),
                            const Spacer(),
                            Switch(
                              value: _isRetired,
                              activeColor: Colors.indigo,
                              onChanged: (v) {
                                setState(() {
                                  _isRetired = v;
                                  if (_salaryMode == SalaryMode.minimumWage &&
                                      supportsMW &&
                                      _salaryKind == SalaryKind.net) {
                                    _applyMinimumWageForYear(year);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _salaryMode == SalaryMode.minimumWage
                              ? (supportsMW
                              ? '$year yılı için seçilen tipte (Brüt/Net) 12 ay otomatik doldurulur.'
                              : '$year yılı için asgari ücret bilgisi yok, manuel girin.')
                              : 'Manuel modda bir ayı değiştirirseniz o aydan itibaren diğer aylar aynı değerle dolar.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _salaryKind == SalaryKind.gross
                                        ? '12 Aylık Brüt Ücret'
                                        : '12 Aylık Net Ücret',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    children: List.generate(12, (i) {
                                      final controller =
                                      _salaryKind == SalaryKind.gross
                                          ? _grossCtrls[i]
                                          : _netCtrls[i];
                                      final isReadOnly = _salaryMode ==
                                          SalaryMode.minimumWage &&
                                          supportsMW;
                                      return Padding(
                                        padding:
                                        const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(_monthNames[i],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54)),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: controller,
                                              decoration: InputDecoration(
                                                hintText: _salaryKind ==
                                                    SalaryKind.gross
                                                    ? 'Brüt ₺'
                                                    : 'Net ₺',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                                ),
                                                filled: true,
                                                fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              ),
                                              readOnly: isReadOnly,
                                              keyboardType:
                                              const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              onChanged: (v) =>
                                                  _propagateForward(
                                                    startMonthIndex: i,
                                                    isGrossColumn: _salaryKind ==
                                                        SalaryKind.gross,
                                                    value: v,
                                                    isBonus: false,
                                                  ),
                                              onSubmitted: (_) {
                                                _formatControllerValue(controller);
                                              },


                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                  if (_salaryMode == SalaryMode.minimumWage &&
                                      supportsMW) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _salaryKind == SalaryKind.gross
                                          ? 'Örnek ($year): Brüt ${_trFieldFmt.format(_minWageByYear[year]!.grossMonthly)} ₺'
                                          : 'Örnek ($year): Net ${_isRetired ? _trFieldFmt.format(_minWageByYear[year]!.netMonthlyRetired) : _trFieldFmt.format(_minWageByYear[year]!.netMonthly)} ₺',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_salaryKind == SalaryKind.gross) ...[
                                    const Text('İkramiye Seçimi',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    CupertinoSlidingSegmentedControl<
                                        SalaryKind>(
                                      groupValue: _bonusKind,
                                      children: const {
                                        SalaryKind.gross: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            child: Text('Brüt')),
                                        SalaryKind.net: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            child: Text('Net')),
                                      },
                                      onValueChanged: (val) {
                                        setState(() {
                                          _bonusKind =
                                              val ?? SalaryKind.net;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    _salaryKind == SalaryKind.net
                                        ? '12 Aylık Net İkramiye'
                                        : (_bonusKind == SalaryKind.gross
                                        ? '12 Aylık Brüt İkramiye'
                                        : '12 Aylık Net İkramiye'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),

                                  const SizedBox(height: 8),
                                  Column(
                                    children: List.generate(12, (i) {
                                      final controller = _bonusCtrls[i];
                                      return Padding(
                                        padding:
                                        const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(_monthNames[i],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54)),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: controller,
                                              decoration: InputDecoration(
                                                hintText: _salaryKind == SalaryKind.net ? 'Net ₺' : (_bonusKind == SalaryKind.gross ? 'Brüt ₺' : 'Net ₺'),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              ),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              onChanged: (v) =>
                                                  _propagateForward(
                                                    startMonthIndex: i,
                                                    isGrossColumn: false,
                                                    value: v,
                                                    isBonus: true,
                                                  ),
                                              onSubmitted: (_) {
                                                _formatControllerValue(controller);
                                              },

                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        DefaultTextStyle.merge(
                          style: headingStyle,
                          child: const Text('İzin Ayarları'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                onTap: _showLeaveYearPicker,
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Yıl',
                                          style: TextStyle(
                                              color: Colors.black54)),
                                      Row(
                                        children: [
                                          Text('$_leaveYear',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 6),
                                          const Icon(CupertinoIcons.chevron_down,
                                              size: 16,
                                              color: Colors.black54),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _leaveDaysCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Gün (örn: 14, 20, 26)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                keyboardType: const TextInputType
                                    .numberWithOptions(
                                    decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bu yıl için yıllık ücretli izin hakkınızı girin.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kayıtlı: ${(_annualPaidLeaveDays[_leaveYear] ?? 0).toStringAsFixed(1)} gün',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54),
                        ),




                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===================== BUTTONS =====================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // TEMİZLE
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          // İşe giriş tarihi
                          _startDate = null;
                          // Ücret alanları
                          for (int i = 0; i < 12; i++) {
                            _grossCtrls[i].clear();
                            _netCtrls[i].clear();
                            _bonusCtrls[i].clear();
                          }
                          // İzin alanı
                          _leaveDaysCtrl.clear();
                          _annualPaidLeaveDays[_leaveYear] = 0.0;
                        });
                      },
                      child: const Text(
                        'Temizle',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // İPTAL
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await _loadState();
                        setState(() {
                          _leaveDaysCtrl.text =
                              (_annualPaidLeaveDays[_leaveYear] ?? 0).toStringAsFixed(1);
                        });
                      },
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // KAYDET
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.indigo.withOpacity(0.1),
                        foregroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          // Format ücret alanları
                          for (int i = 0; i < 12; i++) {
                            if (_grossCtrls[i].text.trim().isNotEmpty) {
                              final v = _parseMoney(_grossCtrls[i].text);
                              if (v != null) _grossCtrls[i].text = _trFieldFmt.format(v);
                            }
                            if (_netCtrls[i].text.trim().isNotEmpty) {
                              final v = _parseMoney(_netCtrls[i].text);
                              if (v != null) _netCtrls[i].text = _trFieldFmt.format(v);
                            }
                            if (_bonusCtrls[i].text.trim().isNotEmpty) {
                              final v = _parseMoney(_bonusCtrls[i].text);
                              if (v != null) _bonusCtrls[i].text = _trFieldFmt.format(v);
                            }
                          }
                          // Kaydet izin günleri
                          final v = double.tryParse(
                              _leaveDaysCtrl.text.replaceAll(',', '.')) ?? 0.0;
                          _annualPaidLeaveDays[_leaveYear] = v.clamp(0, 365);
                          _leaveDaysCtrl.text =
                              (_annualPaidLeaveDays[_leaveYear] ?? 0).toStringAsFixed(1);
                          // Tümünü kaydet
                          _saveState();
                        });
                      },
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSalaryYearPicker() {
    final years = [2022, 2023, 2024, 2025, 2026];
    final initialIndex =
    years.indexOf(_salaryYear).clamp(0, years.length - 1);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        height: 300,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Bitti', style: TextStyle(color: Colors.indigo)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(
                    initialItem: initialIndex),
                onSelectedItemChanged: (i) {
                  setState(() {
                    _saveState();
                    _salaryYear = years[i];
                    if (_salaryMode == SalaryMode.minimumWage) {
                      _applyMinimumWageForYear(_salaryYear);
                    }
                    _saveState();
                  });
                },
                children:
                years.map((y) => Center(child: Text('$y'))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveYearPicker() {
    final years = List<int>.generate(16, (i) => 2020 + i);
    final initialIndex =
    years.indexOf(_leaveYear).clamp(0, years.length - 1);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        height: 300,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Bitti', style: TextStyle(color: Colors.indigo)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(
                    initialItem: initialIndex),
                onSelectedItemChanged: (i) {
                  setState(() {
                    _leaveYear = years[i];
                    _leaveDaysCtrl.text =
                        (_annualPaidLeaveDays[_leaveYear] ?? 0)
                            .toStringAsFixed(1);
                  });
                },
                children:
                years.map((y) => Center(child: Text('$y'))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCupertinoDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        height: 300,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Bitti', style: TextStyle(color: Colors.indigo)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                minimumDate: DateTime(2020, 1, 1),
                maximumDate: DateTime(2030, 12, 31),
                initialDateTime: _startDate ?? _focusedDay,
                onDateTimeChanged: (date) {
                  setState(() => _startDate = date);
                  _saveState();
                },

              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- TAKVİM (sadece Ay Özeti) --------
  Widget _buildCalendarTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernCalendar(),
            const SizedBox(height: 12),
            _buildMonthSummaryTable(
                DateTime(_focusedDay.year, _focusedDay.month, 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCalendar() {
    final firstDay = DateTime(2020, 1, 1);
    final lastDay = DateTime(2030, 12, 31);

    bool _hasTag(DateTime d, String tag) =>
        _overtimeData.containsKey('${_keyFor(d)}_$tag');

    Widget _dot(Color c) => Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration:
      BoxDecoration(color: c, shape: BoxShape.circle),
    );

    return TableCalendar(
      locale: 'tr_TR',
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
      rowHeight: 56, // 52 default'tu; 56 ile taşma kalmaz
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle:
        TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      availableGestures: AvailableGestures.horizontalSwipe,
      startingDayOfWeek: StartingDayOfWeek.monday,
      weekNumbersVisible: true,
      selectedDayPredicate: (day) =>
      _selectedDay != null && isSameDay(day, _selectedDay),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected; // tıklanınca seç
          _focusedDay = focused;
        });
        _showOvertimeDialog(context, selected);
      },
      onPageChanged: (focused) => setState(() => _focusedDay = focused),
      calendarStyle: const CalendarStyle(
        isTodayHighlighted:
        false, // <-- bugün mavi/özel görünmesin, sadece seçilince mavi
        outsideDaysVisible: false,
        todayTextStyle: TextStyle(fontWeight: FontWeight.bold),
        defaultTextStyle: TextStyle(fontWeight: FontWeight.bold),
        weekendTextStyle: TextStyle(fontWeight: FontWeight.bold),
        selectedTextStyle:
        TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        selectedDecoration:
        BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focused) {
          Color? numColor;
          if (_isOfficialHoliday(day)) {
            numColor = Colors.red.shade700;
          } else if (_isSunday(day)) {
            numColor = Colors.blue.shade700;
          }

          final isStart = _startDate != null && isSameDay(day, _startDate);
          final isToday = isSameDay(day, DateTime.now());

          bool _hasTag(DateTime d, String tag) =>
              _overtimeData.containsKey('${_keyFor(d)}_$tag');

          final hasOvertime = _hasTag(day, 'overtime');
          final hasPaid = _hasTag(day, 'paid');
          final hasUnpaid = _hasTag(day, 'unpaid');
          final hasDeduction = _hasTag(day, 'deduction');

          Widget _dot(Color c) => Container(
            width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isStart
                        ? Border.all(color: Colors.amber, width: 2)
                        : (isToday
                        ? Border.all(color: Colors.grey.shade400, width: 2) // gri halka
                        : null),
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: numColor,
                    ),
                  ),
                ),
                if (hasOvertime || hasPaid || hasUnpaid || hasDeduction)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasOvertime) _dot(Colors.indigo),
                        if (hasPaid) _dot(Colors.green),
                        if (hasUnpaid) _dot(Colors.amber),
                        if (hasDeduction) _dot(Colors.red),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------- Takvim altı AY ÖZETİ --------
  Widget _buildMonthSummaryTable(DateTime monthAnchor) {
    // 1) Ayın "ekler dahil" final sonucunu al (vergiler BRÜT toplamdan)
    final yrAll = _yearWithExtras(monthAnchor.year);
    final res = yrAll.months.firstWhere(
          (e) => e.monthIndex == monthAnchor.month - 1,
      orElse: () => MonthResult(
        year: monthAnchor.year,
        monthIndex: monthAnchor.month - 1,
        gross: 0,
        net: 0,
        sgkEmployee: 0,
        unemploymentEmployee: 0,
        sgkEmployer: 0,
        unemploymentEmployer: 0,
        incomeTax: 0,
        incomeTaxBeforeExempt: 0,
        incomeTaxExemption: 0,
        cumulativeTaxBase: 0,
        stampTax: 0,
        stampTaxBeforeExempt: 0,
        stampTaxExemption: 0,
        employerCost: 0,
        monthlyTaxableBase: 0,
      ),
    );

    // 2) Görsel/ayrıştırılmış göstergeler (opsiyonel, bilgi amaçlı)
    final otHours = _monthlyOvertimeHours(monthAnchor);
    final otGross = _monthlyOvertimeAmount(monthAnchor, gross: true);
    final otNet = _monthlyOvertimeAmount(monthAnchor, gross: false);
    final bonusNet = _monthlyBonusNet(monthAnchor);
    final bonusGross = _bonusGrossFor(monthAnchor);
    final unpaidH = _monthlyUnpaidHours(monthAnchor);
    final paidH = _monthlyPaidHours(monthAnchor);
    final dedH = _monthlyDeductionHours(monthAnchor);
    final dedGross = _deductionGrossFor(monthAnchor);

    // 3) Artık "Brüt" ve "Net" için res.gross / res.net kullanacağız
    final gross = res.gross;
    final net = res.net;

    final salaryKindIsGross = _salaryKind == SalaryKind.gross;
    final selectedOvertimeAmount = salaryKindIsGross ? otGross : otNet;


    String moneyFmt(double? v) => v == null ? '-' : _tryFmt.format(v);
    String hoursFmtLocal(double v) => hoursFmt(v);
    String daysFmtLocal(double v) => daysFmt(v);

    Widget row(String left, String right) => Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(right,
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ay Özeti',
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Divider(height: 1),

          row('Brüt maaş', moneyFmt(gross)),
          row('Net maaş', moneyFmt(net)),

          row('Mesai saati', hoursFmtLocal(otHours)),
          row(
              salaryKindIsGross
                  ? 'Brüt mesai ücreti'
                  : 'Net mesai ücreti',
              moneyFmt(selectedOvertimeAmount)),

          const SizedBox(height: 6),
          const Divider(height: 1),

// Önce ÜCRETLİ (yıllık izin), sonra ÜCRETSİZ, sonra KESİNTİ
          row('Ücretli izin (yıllık izin) (gün / saat)',
              '${daysFmtLocal(paidH)} g  /  ${hoursFmtLocal(paidH)} s'),
          row('Ücretsiz izin (gün / saat)',
              '${daysFmtLocal(unpaidH)} g  /  ${hoursFmtLocal(unpaidH)} s'),
          row('Kesinti (gün / saat)',
              '${daysFmtLocal(dedH)} g  /  ${hoursFmtLocal(dedH)} s'),
          row('Kesinti tutarı (brüt)', moneyFmt(dedGross)),

          const SizedBox(height: 6),
          const Divider(height: 1),


          const SizedBox(height: 6),
          row('İkramiye (NET)', moneyFmt(bonusNet)),
          // res.net: (Maaş + Mesai + (Net üstüne) İkramiye − Kesinti) sonrası FİNAL net
          row('Toplam net ücret', moneyFmt(net)),
        ],
      ),
      ),
    );
  }

  // -------- Sonuçlar --------
  Widget _buildResultsTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CupertinoSlidingSegmentedControl<ResultsMode>(
                    groupValue: _resultsMode,
                    children: const {
                      ResultsMode.monthly: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Text('Aylık Özet')),
                      ResultsMode.yearly: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Text('Yıllık Özet')),
                    },
                    onValueChanged: (v) =>
                        setState(() => _resultsMode = v ?? ResultsMode.monthly),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text('Yıl:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showResultsYearPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Text('$_resultsYear',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Icon(CupertinoIcons.chevron_down,
                                size: 16, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_resultsMode == ResultsMode.monthly)
              Expanded(
                child: ListView(
                  children: [
                    _buildMonthlyDetailsCard(
                        DateTime(_resultsYear, _focusedDay.month, 1)),
                  ],
                ),
              )
            else
              Expanded(child: _buildYearlyDetailedFrozenTable()),
          ],
        ),
      ),
    );
  }

  void _showResultsYearPicker() {
    final years = List<int>.generate(16, (i) => 2020 + i);
    final initialIndex =
    years.indexOf(_resultsYear).clamp(0, years.length - 1);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        height: 300,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Bitti', style: TextStyle(color: Colors.indigo)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(
                    initialItem: initialIndex),
                onSelectedItemChanged: (i) =>
                    setState(() => _resultsYear = years[i]),
                children:
                years.map((y) => Center(child: Text('$y'))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- Aylık Detay Kartı (gruplara çizgi eklendi) --------
  Widget _buildMonthlyDetailsCard(DateTime month) {
    final yrAll = _yearWithExtras(month.year);
    final res = yrAll.months.firstWhere(
          (e) => e.monthIndex == month.month - 1,
      orElse: () => MonthResult(
        year: month.year,
        monthIndex: month.month - 1,
        gross: 0,
        net: 0,
        sgkEmployee: 0,
        unemploymentEmployee: 0,
        sgkEmployer: 0,
        unemploymentEmployer: 0,
        incomeTax: 0,
        incomeTaxBeforeExempt: 0,
        incomeTaxExemption: 0,
        cumulativeTaxBase: 0,
        stampTax: 0,
        stampTaxBeforeExempt: 0,
        stampTaxExemption: 0,
        employerCost: 0,
        monthlyTaxableBase: 0,
      ),
    );
    final taxBase =
    (res.gross - res.sgkEmployee - res.unemploymentEmployee)
        .clamp(0.0, double.infinity);


// Görsel bilgi için
    final otGross = _monthlyOvertimeAmount(month, gross: true);
    final otNet = _monthlyOvertimeAmount(month, gross: false);
    final bonusNet = _monthlyBonusNet(month);
    final bonusGross = _bonusGrossFor(month);
    final dedGross = _deductionGrossFor(month);
    final bonus = _monthlyBonusNet(month);

    String money(double v) => _tryFmt.format(v);
    Widget r(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(b,
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );

    Widget groupTitle(String t) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detaylar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),

          r('Brüt', money(res.gross)),
          r('Net', money(res.net)),

          // İşçi kesintileri
          groupTitle('İşçi Kesintileri'),
          r('SGK İşçi', money(res.sgkEmployee)),
          r('İşsizlik İşçi', money(res.unemploymentEmployee)),
          const Divider(thickness: 1),

          // Gelir Vergisi
          groupTitle('Gelir Vergisi'),
          r('GV (İstisna Öncesi)', money(res.incomeTaxBeforeExempt)),
          r('Asgari Ücret GV İstisnası', money(res.incomeTaxExemption)),
          r('GV (Ödenen)', money(res.incomeTax)),
          const Divider(thickness: 1),

          // Damga Vergisi
          groupTitle('Damga Vergisi'),
          r('Damga (İstisna Öncesi)', money(res.stampTaxBeforeExempt)),
          r('Asgari Ücret Damga İstisnası', money(res.stampTaxExemption)),
          r('Damga (Ödenen)', money(res.stampTax)),
          const Divider(thickness: 1),

          r('Aylık GV Matrahı', money(taxBase)),
          r('Kümülatif GV Matrahı', money(res.cumulativeTaxBase)),

          // İşveren tarafı
          groupTitle('İşveren Tarafı'),
          r('SGK İşveren', money(res.sgkEmployer)),
          r('İşsizlik İşveren', money(res.unemploymentEmployer)),
          r('Toplam İşveren Maliyeti', money(res.employerCost)),
          const Divider(),

          groupTitle('Ekler'),
          r('Mesai (Brüt)', money(otGross)),
          r('Mesai (Net)', money(otNet)),
          r('İkramiye (Net)', money(bonusNet)),
          r('İkramiye (Brüt)', money(bonusGross)),
          r('Kesinti (Brüt)', money(dedGross)),
          const Divider(),
// res.net artık (Maaş + Mesai + (Net üstüne) İkramiye − Kesinti) sonrası FİNAL NET
          r('Toplam Net(Maaş+Mesai+İkrm.−Kesinti)', money(res.net)),

        ],
      ),
    );
  }

  // -------- Yıllık Özet (daha sıkı sütunlar) --------
  Widget _buildYearlyDetailedFrozenTable() {
    final List<double?> grossByMonth = List.generate(12, (i) {
      final d = DateTime(_resultsYear, i + 1, 1);
      return _enteredGrossFor(d);
    });
    final List<double?> netByMonth = List.generate(12, (i) {
      final d = DateTime(_resultsYear, i + 1, 1);
      return _enteredNetFor(d);
    });

    final YearResult yr = _yearWithExtras(_resultsYear);

    final months = List.generate(12, (i) => _monthNames[i]);

    final List<Map<String, num>> extras = List.generate(12, (mIdx) {
      final month = DateTime(_resultsYear, mIdx + 1, 1);
      final otH = _monthlyOvertimeHours(month);
      final otAmt = _monthlyOvertimeAmount(
          month, gross: _salaryKind == SalaryKind.gross ? true : false);
      final bonus = _monthlyBonusNet(month);

      final res = yr.months.firstWhere(
            (e) => e.monthIndex == mIdx,
        orElse: () => MonthResult(
          year: _resultsYear,
          monthIndex: mIdx,
          gross: 0,
          net: 0,
          sgkEmployee: 0,
          unemploymentEmployee: 0,
          sgkEmployer: 0,
          unemploymentEmployer: 0,
          incomeTax: 0,
          incomeTaxBeforeExempt: 0,
          incomeTaxExemption: 0,
          cumulativeTaxBase: 0,
          stampTax: 0,
          stampTaxBeforeExempt: 0,
          stampTaxExemption: 0,
          employerCost: 0,
          monthlyTaxableBase: 0,
        ),
      );

      // res.net zaten (maaş + mesai + bonus − kesinti) sonrası FİNAL net
      final netWithAll = res.net;





      return {
        'otHours': otH,
        'otAmount': otAmt,
        'bonus': bonus,
        'netWithAll': netWithAll,
      };
    });

    final headers = <String>[
      'Brüt',
      'Net',
      'SGK İşçi',
      'İşsizlik İşçi',
      'GV (Önce)',
      'GV İstisna',
      'GV (Son)',
      'Damga V.',
      'Damga V. İst.',
      'Damga Öd.',
      'Aylık V. Matrahı',
      'Kümülatif V. Matrahı',
      'SGK İşv. Payı',
      'İşsizlik S. İşv. Payı',
      'İşveren Maliyeti',
      'Ücretsiz İzin (s)',
      'Ücretli İzin (s)',
      'Mesai (s)',
      _salaryKind == SalaryKind.gross ? 'Mesai (Brüt)' : 'Mesai (Net)',
      'İkramiye (Net)',
      'Toplam Net'
    ];

    const double leftColW = 72; // daha dar
    const double cellW = 130; // önce 160'tı
    const double headerH = 44;

    String m(num v) => _tryFmt.format(v.toDouble());
    String h(num v) => _numFmt1.format(v.toDouble());

    List<Widget> _rowForIndex(int i) {
      final month = DateTime(_resultsYear, i + 1, 1);
      final res = yr.months.firstWhere(
            (e) => e.monthIndex == i,
        orElse: () => MonthResult(
          year: _resultsYear,
          monthIndex: i,
          gross: 0,
          net: 0,
          sgkEmployee: 0,
          unemploymentEmployee: 0,
          sgkEmployer: 0,
          unemploymentEmployer: 0,
          incomeTax: 0,
          incomeTaxBeforeExempt: 0,
          incomeTaxExemption: 0,
          cumulativeTaxBase: 0,
          stampTax: 0,
          stampTaxBeforeExempt: 0,
          stampTaxExemption: 0,
          employerCost: 0,
          monthlyTaxableBase: 0,
        ),
      );

      // === EKLEME: Aylık Gelir Vergisi Matrahı (BRÜT bazlı) ===
      final taxBase = (res.gross - res.sgkEmployee - res.unemploymentEmployee)
          .clamp(0.0, double.infinity);
      // ========================================================

      final unpaidH = _monthlyUnpaidHours(month);
      final paidH = _monthlyPaidHours(month);
      final ext = extras[i];

      final cells = <String>[
        m(res.gross),
        m(res.net),
        m(res.sgkEmployee),
        m(res.unemploymentEmployee),
        m(res.incomeTaxBeforeExempt),
        m(res.incomeTaxExemption),
        m(res.incomeTax),
        m(res.stampTaxBeforeExempt),
        m(res.stampTaxExemption),
        m(res.stampTax),

        // Buradaki sütun başlığı “Aylık V. Matrahı” idi:
        m(taxBase),

        m(res.cumulativeTaxBase),
        m(res.sgkEmployer),
        m(res.unemploymentEmployer),
        m(res.employerCost),
        h(unpaidH),
        h(paidH),
        h(ext['otHours'] as num),
        m(ext['otAmount'] as num),
        m(ext['bonus'] as num),
        m(ext['netWithAll'] as num),
      ];

      return cells
          .map((txt) => Container(
        width: cellW,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
        ),
        child: Text(
          txt,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ))
          .toList();
    }


    final totalTaxBase = yr.months.fold<double>(
      0.0,
          (p, r) => p + (r.gross - r.sgkEmployee - r.unemploymentEmployee),
    );


    final totalsRow = <String>[
      m(yr.totalGross),
      m(yr.totalNet),
      m(yr.totalSgkEmployee),
      m(yr.totalUnemploymentEmployee),
      m(yr.totalIncomeTaxBeforeExempt),
      m(yr.totalIncomeTaxExemption),
      m(yr.totalIncomeTax),
      m(yr.totalStampTaxBeforeExempt),
      m(yr.totalStampTaxExemption),
      m(yr.totalStampTax),
      m(totalTaxBase),
      m(yr.lastCumulativeTaxBase),
      m(yr.totalSgkEmployer),
      m(yr.totalUnemploymentEmployer),
      m(yr.totalEmployerCost),
      h(_sumHours(
              (mth) => _monthlyUnpaidHours(DateTime(_resultsYear, mth, 1)))),
      h(_sumHours(
              (mth) => _monthlyPaidHours(DateTime(_resultsYear, mth, 1)))),
      h(extras.fold<num>(0, (p, e) => p + (e['otHours'] as num))),
      m(extras.fold<num>(0, (p, e) => p + (e['otAmount'] as num))),
      m(extras.fold<num>(0, (p, e) => p + (e['bonus'] as num))),
      m(extras.fold<num>(0, (p, e) => p + (e['netWithAll'] as num))),
    ]
        .map((txt) => Container(
      width: cellW,
      padding:
      const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade300)),
        color: Colors.grey.shade100,
      ),
      child: Text(txt,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()])),
    ))
        .toList();

    final headerBar = Container(
      height: headerH,
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Container(
            width: leftColW,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Text('Ay',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _hHeaderCtrl,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: headers
                    .map((h) => Container(
                  width: cellW,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade300)),
                  ),
                  child: Text(h,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );

    final leftColumn = Column(
      children: [
        const SizedBox(height: headerH),
        ...List.generate(
          12,
              (i) => Container(
            width: leftColW,
            padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              border:
              Border(bottom: BorderSide(color: Colors.grey.shade300)),
              color: Colors.white,
            ),
            child: Text(months[i], overflow: TextOverflow.ellipsis),
          ),
        ),
        Container(
          width: leftColW,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            border:
            Border(bottom: BorderSide(color: Colors.grey.shade300)),
            color: Colors.grey.shade100,
          ),
          child: const Text('TOPLAM',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );

    final body = Expanded(
      child: SingleChildScrollView(
        controller: _vBodyCtrl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: leftColW,
              decoration: BoxDecoration(
                  border: Border(
                      right:
                      BorderSide(color: Colors.grey.shade300))),
              child: leftColumn,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _hBodyCtrl,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: headerH),
                    ...List.generate(12, (i) => Row(children: _rowForIndex(i))),
                    Row(children: totalsRow),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white),
        child: Column(children: [headerBar, body]),
      ),
    );
  }

  double _sumHours(double Function(int m) getter) {
    double s = 0;
    for (int m = 1; m <= 12; m++) {
      s += getter(m);
    }
    return s;
  }

  YearResult _yearWithExtras(int year) {
    final eng = _engineFor(year);
    double cumTaxBase = 0.0;
    final months = <MonthResult>[];

    for (int m = 0; m < 12; m++) {
      final month = DateTime(year, m + 1, 1);

      // 1) Baz brüt (net modda önce brüte çevir)
      double baseGross;
      final enteredGross = _enteredGrossFor(month);
      final enteredNet = _enteredNetFor(month);
      if (_salaryKind == SalaryKind.gross) {
        baseGross = (enteredGross ?? 0.0);
      } else {
        final temp = eng.calculateGrossFromNet(
          targetNetMonthly: (enteredNet ?? 0.0),
          monthIndex: m,
          cumulativeTaxBasePrev: cumTaxBase, // kümülatif önemli
        );
        baseGross = temp.gross;
      }

      // 2) Mesai brüt
      final otGross = _monthlyOvertimeAmount(month, gross: true);

      // 3) İkramiye brüt (NET ise gross-up ile "üstüne ekle")
      final bonGross = _bonusGrossFor(month);

      // 4) Kesinti brüt (eksi)
      final dedGross = _deductionGrossFor(month);

      // Toplam brüt
      final totalGross = (baseGross + otGross + bonGross - dedGross)
          .clamp(0.0, double.infinity);

      // Bu ayın ekler dâhil sonucu
      final res = eng.calculateNetFromGross(
        grossMonthly: totalGross,
        monthIndex: m,
        cumulativeTaxBasePrev: cumTaxBase,
      );

      cumTaxBase = res.cumulativeTaxBase; // sonraki aya devreden kümülatif
      months.add(res);
    }

    return YearResult(year: year, months: months);
  }


  // -------- Gün içi diyalog --------
  void _showOvertimeDialog(BuildContext context, DateTime day) {
    if (_startDate != null) {
      final sd = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final d0 = DateTime(day.year, day.month, day.day);
      if (d0.isBefore(sd)) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Uyarı'),
            content: const Text('İşe giriş tarihinden önceye kayıt yapılamaz.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
            ],
          ),
        );
        return;
      }
    }
    final key = _keyFor(day);

    final currentUnpaidH = _overtimeData['${key}_unpaid'] ?? 0.0;
    final currentPaidH = _overtimeData['${key}_paid'] ?? 0.0;
    final currentDedH = _overtimeData['${key}_deduction'] ?? 0.0;

    TimeUnit unpaidUnit = TimeUnit.day;
    TimeUnit paidUnit = TimeUnit.day;
    TimeUnit deductionUnit = TimeUnit.day;

    double _hoursToDays(double h) => h / _hoursPerDay;

    final List<double> quarterHours =
    List.generate(49, (i) => i * 0.25); // 0..12
    int selectedOtIndex = 0;
    final currentOt = _overtimeData['${key}_overtime'] ?? 0.0;
    selectedOtIndex =
        quarterHours.indexWhere((v) => (v - currentOt).abs() < 0.001);
    if (selectedOtIndex == -1) {
      selectedOtIndex =
          (currentOt / 0.25).round().clamp(0, quarterHours.length - 1);
    }

    String _fmtQuarter(double h) {
      final totalMinutes = (h * 60).round();
      final m = totalMinutes % 60;
      final s = totalMinutes ~/ 60;
      if (s == 0 && m > 0) {
        return m == 15
            ? '15 dk'
            : m == 30
            ? '30 dk'
            : m == 45
            ? '45 dk'
            : '$m dk';
      }
      if (m == 0) return '$s s';
      return '$s s ${m} dk';
    }

    final unpaidCtrl = TextEditingController(
        text: currentUnpaidH == 0 ? '' : _hoursToDays(currentUnpaidH).toStringAsFixed(2));
    final paidCtrl = TextEditingController(
        text: currentPaidH == 0 ? '' : _hoursToDays(currentPaidH).toStringAsFixed(2));
    final deductionCtrl = TextEditingController(
        text: currentDedH == 0 ? '' : _hoursToDays(currentDedH).toStringAsFixed(2));

    OtMultiplierChoice otChoice = OtMultiplierChoice.auto;
    final manualMult = _overtimeData['${key}_otmult'];
    if (manualMult != null && manualMult > 0) {
      otChoice = (manualMult >= 2.0)
          ? OtMultiplierChoice.twoPointZero
          : OtMultiplierChoice.onePointFive;
    }

    double _toDouble(String s) =>
        double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
    double _valueToHours(String txt, TimeUnit unit) {
      if (txt.trim().isEmpty) return 0.0;
      final v = _toDouble(txt);
      return unit == TimeUnit.day ? v * _hoursPerDay : v;
    }

    const segText = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    final segBg = Colors.grey.shade300;
    final segThumb = Colors.white;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return AlertDialog(
            title: Text('${_fmt(day)} Girişi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Mesai', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(
                                initialItem: selectedOtIndex),
                            onSelectedItemChanged: (i) =>
                                setSheetState(() => selectedOtIndex = i),
                            children: quarterHours
                                .map((h) => Center(child: Text(_fmtQuarter(h))))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Mesai Oranı (Otomatik: Pazar/Resmi Tatil 2.0x, Diğer 1.5x)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  CupertinoSlidingSegmentedControl<OtMultiplierChoice>(
                    backgroundColor: segBg,
                    thumbColor: segThumb,
                    groupValue: otChoice,
                    children: const {
                      OtMultiplierChoice.auto: Text('Oto', style: segText),
                      OtMultiplierChoice.onePointFive:
                      Text('1,5x', style: segText),
                      OtMultiplierChoice.twoPointZero:
                      Text('2,0x', style: segText),
                    },
                    onValueChanged: (v) =>
                        setSheetState(() => otChoice = v ?? OtMultiplierChoice.auto),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 14),
                  const Text('Ücretli izin',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: paidCtrl,
                          decoration:
                          const InputDecoration(labelText: 'Miktar'),
                          keyboardType: const TextInputType
                              .numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: CupertinoSlidingSegmentedControl<TimeUnit>(
                          backgroundColor: segBg,
                          thumbColor: segThumb,
                          groupValue: paidUnit,
                          children: const {
                            TimeUnit.day: Text('Gün', style: segText),
                            TimeUnit.hour: Text('Saat', style: segText),
                          },
                          onValueChanged: (v) =>
                              setSheetState(() => paidUnit = v ?? TimeUnit.day),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Ücretsiz izin',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: unpaidCtrl,
                          decoration:
                          const InputDecoration(labelText: 'Miktar'),
                          keyboardType: const TextInputType
                              .numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: CupertinoSlidingSegmentedControl<TimeUnit>(
                          backgroundColor: segBg,
                          thumbColor: segThumb,
                          groupValue: unpaidUnit,
                          children: const {
                            TimeUnit.day: Text('Gün', style: segText),
                            TimeUnit.hour: Text('Saat', style: segText),
                          },
                          onValueChanged: (v) =>
                              setSheetState(() => unpaidUnit = v ?? TimeUnit.day),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Text('Kesinti',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: deductionCtrl,
                          decoration:
                          const InputDecoration(labelText: 'Miktar'),
                          keyboardType: const TextInputType
                              .numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: CupertinoSlidingSegmentedControl<TimeUnit>(
                          backgroundColor: segBg,
                          thumbColor: segThumb,
                          groupValue: deductionUnit,
                          children: const {
                            TimeUnit.day: Text('Gün', style: segText),
                            TimeUnit.hour: Text('Saat', style: segText),
                          },
                          onValueChanged: (v) => setSheetState(
                                  () => deductionUnit = v ?? TimeUnit.day),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _saveState();
                  setState(() {
                    _overtimeData.remove('${key}_overtime');
                    _overtimeData.remove('${key}_otmult');
                    _overtimeData.remove('${key}_unpaid');
                    _overtimeData.remove('${key}_paid');
                    _overtimeData.remove('${key}_deduction');
                    _saveState();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Temizle'),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal')),
              TextButton(
                onPressed: () {
                  _saveState();
                  final selectedHours = quarterHours[selectedOtIndex];
                  final unpaidHours =
                  _valueToHours(unpaidCtrl.text, unpaidUnit);
                  final paidHours =
                  _valueToHours(paidCtrl.text, paidUnit);
                  final dedHours =
                  _valueToHours(deductionCtrl.text, deductionUnit);

                  setState(() {
                    if (selectedHours > 0) {
                      _overtimeData['${key}_overtime'] = selectedHours;
                    } else {
                      _overtimeData.remove('${key}_overtime');
                    }

                    switch (otChoice) {
                      case OtMultiplierChoice.auto:
                        _overtimeData.remove('${key}_otmult');
                        break;
                      case OtMultiplierChoice.onePointFive:
                        _overtimeData['${key}_otmult'] = 1.5;
                        break;
                      case OtMultiplierChoice.twoPointZero:
                        _overtimeData['${key}_otmult'] = 2.0;
                        break;
                    }

                    if (unpaidHours > 0) {
                      _overtimeData['${key}_unpaid'] = unpaidHours;
                    } else {
                      _overtimeData.remove('${key}_unpaid');
                    }
                    if (paidHours > 0) {
                      _overtimeData['${key}_paid'] = paidHours;
                    } else {
                      _overtimeData.remove('${key}_paid');
                    }
                    if (dedHours > 0) {
                      _overtimeData['${key}_deduction'] = dedHours;
                    } else {
                      _overtimeData.remove('${key}_deduction');
                    }
                    _saveState();
                  });

                  Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// model
class _MinWage {
  final double grossMonthly;
  final double netMonthly;
  final double netMonthlyRetired;
  const _MinWage({
    required this.grossMonthly,
    required this.netMonthly,
    required this.netMonthlyRetired,
  });
}
