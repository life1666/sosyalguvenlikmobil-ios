// UI'dan bağımsız, saf hesap modülü. (Kuruş/int motor + 2026 uyumlu)

enum EmployeeStatus { normal, sgdp } // SGDP = Emekli/SGDP kapsamında çalışan
enum Incentive { none, twoPoints, fourPoints, fivePoints }

class TaxBrackets {
  /// TL cinsinden dilimler (kümülatif matrah)
  final List<double> brackets;
  /// oranlar (0.15 gibi)
  final List<double> rates;
  const TaxBrackets(this.brackets, this.rates);
}

/// Tek ay için tüm bileşenlerin sonucu
class MonthResult {
  final int year;
  final int monthIndex; // 0..11
  final double gross; // brüt
  final double net; // net
  // İşçi kesintileri
  final double sgkEmployee;
  final double unemploymentEmployee;
  // İşveren kesintileri
  final double sgkEmployer;
  final double unemploymentEmployer;
  // Vergi
  final double incomeTax; // aylık ödenen gelir vergisi
  final double incomeTaxBeforeExempt; // istisna öncesi aylık GV
  final double incomeTaxExemption; // uygulanan asgari ücret GV istisnası
  final double cumulativeTaxBase; // kümülatif GV matrahı (istisna öncesi)
  // Damga
  final double stampTax;
  final double stampTaxBeforeExempt;
  final double stampTaxExemption;
  // İşveren maliyeti
  final double employerCost;
  // Matrah (aylık)
  final double monthlyTaxableBase;

  const MonthResult({
    required this.year,
    required this.monthIndex,
    required this.gross,
    required this.net,
    required this.sgkEmployee,
    required this.unemploymentEmployee,
    required this.sgkEmployer,
    required this.unemploymentEmployer,
    required this.incomeTax,
    required this.incomeTaxBeforeExempt,
    required this.incomeTaxExemption,
    required this.cumulativeTaxBase,
    required this.stampTax,
    required this.stampTaxBeforeExempt,
    required this.stampTaxExemption,
    required this.employerCost,
    required this.monthlyTaxableBase,
  });
}

/// 12 ayın özet sonuçları
class YearResult {
  final int year;
  final List<MonthResult> months; // boş aylar eklenmez (giriş yoksa)
  YearResult({required this.year, required this.months});

  double get totalGross => months.fold(0.0, (p, m) => p + m.gross);
  double get totalNet => months.fold(0.0, (p, m) => p + m.net);
  double get totalSgkEmployee => months.fold(0.0, (p, m) => p + m.sgkEmployee);
  double get totalUnemploymentEmployee =>
      months.fold(0.0, (p, m) => p + m.unemploymentEmployee);
  double get totalSgkEmployer => months.fold(0.0, (p, m) => p + m.sgkEmployer);
  double get totalUnemploymentEmployer =>
      months.fold(0.0, (p, m) => p + m.unemploymentEmployer);
  double get totalIncomeTax => months.fold(0.0, (p, m) => p + m.incomeTax);
  double get totalIncomeTaxBeforeExempt =>
      months.fold(0.0, (p, m) => p + m.incomeTaxBeforeExempt);
  double get totalIncomeTaxExemption =>
      months.fold(0.0, (p, m) => p + m.incomeTaxExemption);
  double get totalStampTax => months.fold(0.0, (p, m) => p + m.stampTax);
  double get totalStampTaxBeforeExempt =>
      months.fold(0.0, (p, m) => p + m.stampTaxBeforeExempt);
  double get totalStampTaxExemption =>
      months.fold(0.0, (p, m) => p + m.stampTaxExemption);
  double get totalEmployerCost => months.fold(0.0, (p, m) => p + m.employerCost);
  double get lastCumulativeTaxBase => months.isEmpty ? 0.0 : months.last.cumulativeTaxBase;
}

/// Hesap makinesi (KURUŞ/INT motor)
class SalaryEngine {
  final int year;
  final EmployeeStatus status;
  final Incentive incentive;

  // Oranlar/parametreler
  late double sgkEmployeeRate;
  late double sgkEmployerBaseRate;
  late double unemploymentEmployeeRate;
  late double unemploymentEmployerRate;
  late double stampTaxRate; // damga
  late TaxBrackets tax; // GV dilimleri + oranları

  SalaryEngine({
    required this.year,
    required this.status,
    required this.incentive,
  }) {
    _updateConstants();
  }

  /// ========= KURUŞ yardımcıları =========
  int _toKurus(double tl) => (tl * 100).round();
  double _fromKurus(int k) => k / 100.0;
  int _mulRateKurus(int baseK, double rate) => (baseK * rate).round();
  int _minInt(int a, int b) => a < b ? a : b;
  int _maxInt(int a, int b) => a > b ? a : b;
  double _round2(double v) => double.parse(v.toStringAsFixed(2));

  // ---- Parametreler ----
  void _updateConstants() {
    if (status == EmployeeStatus.sgdp) {
      sgkEmployeeRate = 0.075;
      unemploymentEmployeeRate = 0.0;
      unemploymentEmployerRate = 0.0;
      sgkEmployerBaseRate = 0.225;
    } else {
      sgkEmployeeRate = 0.14;
      unemploymentEmployeeRate = 0.01;
      unemploymentEmployerRate = 0.02;

      // ✅ 2026+ baz işveren oranı
      sgkEmployerBaseRate = (year >= 2026) ? 0.195 : 0.185;
    }

    stampTaxRate = 0.00759;

    if (year == 2022) {
      tax = TaxBrackets([32000, 70000, 250000, 880000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else if (year == 2023) {
      tax = TaxBrackets([70000, 150000, 550000, 1900000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else if (year == 2024) {
      tax = TaxBrackets([110000, 230000, 870000, 3000000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else if (year == 2025) {
      tax = TaxBrackets([158000, 330000, 1200000, 4300000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else if (year == 2026) {
      // ✅ 2026
      tax = TaxBrackets([190000, 400000, 1500000, 5300000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else {
      // fallback
      tax = TaxBrackets([190000, 400000, 1500000, 5300000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    }
  }

  // Aylık kısa vadeli prim ek oranı ve 2024 SGDP istisnası
  double _monthlyEmployerRate(int monthIndex) {
    final m = monthIndex; // 0..11
    double shortTerm = (year < 2024 || (year == 2024 && m < 7)) ? 0.02 : 0.0225;
    double base = sgkEmployerBaseRate + shortTerm;

    // 2024 SGDP özel
    if (status == EmployeeStatus.sgdp && year == 2024) {
      base = (m < 7) ? 0.245 : 0.2475;
    }

    double incentiveCut = 0.0;

    if (status == EmployeeStatus.sgdp) {
      if (incentive == Incentive.fivePoints && (year == 2023 || year == 2024)) {
        incentiveCut = 0.05;
      }
    } else {
      if (incentive == Incentive.fivePoints) {
        incentiveCut = 0.05;
      } else if (incentive == Incentive.fourPoints && year == 2025) {
        incentiveCut = 0.04;
      } else if (incentive == Incentive.twoPoints && year >= 2026) {
        incentiveCut = 0.02;
      }
    }

    return (base - incentiveCut).clamp(0.0, 1.0);
  }

  // Asgari ücret (brüt) ay bazlı
  double _minWageMonthly(int monthIndex) {
    final m = monthIndex;
    if (year == 2022) {
      return (m < 5) ? 5004.00 : 6471.00;
    } else if (year == 2023) {
      return (m < 5) ? 10008.00 : 13414.50;
    } else if (year == 2024) {
      return 20002.50;
    } else if (year == 2025) {
      return 26005.50;
    } else if (year == 2026) {
      return 33030.00;
    } else {
      return 33030.00;
    }
  }

  // Aylık GV istisnası tutarı
  double _incomeTaxExemptionAmount(int monthIndex) {
    if (year == 2022) {
      if (monthIndex < 6) return 638.01;
      if (monthIndex == 6) return 825.05;
      if (monthIndex == 7) return 1051.11;
      return 1100.07;
    } else if (year == 2023) {
      if (monthIndex < 6) return 1276.02;
      if (monthIndex == 6) return 1710.35;
      if (monthIndex == 7) return 1902.62;
      return 2280.46;
    } else if (year == 2024) {
      if (monthIndex < 6) return 2550.32;
      if (monthIndex == 6) return 3001.06;
      return 3400.42;
    } else if (year == 2025) {
      if (monthIndex < 7) return 3315.70;
      if (monthIndex == 7) return 4257.57;
      return 4420.93;
    } else if (year == 2026) {
      if (monthIndex < 6) return 4211.33;
      if (monthIndex == 6) return 4537.75;
      return 5615.10;
    } else {
      if (monthIndex < 6) return 4211.33;
      if (monthIndex == 6) return 4537.75;
      return 5615.10;
    }
  }

  // ✅ 2026+ SGK tavan çarpanı 9.0
  double _sgkCeiling(int monthIndex) {
    final mult = (year >= 2026) ? 9.0 : 7.5;
    return _minWageMonthly(monthIndex) * mult;
  }

  // ✅ Asgari vergi matrahı (kuruş kalem kalem)
  int _minWageTaxableBaseK(int monthIndex) {
    final mwK = _toKurus(_minWageMonthly(monthIndex));
    final sgkMinEmpK = _mulRateKurus(mwK, sgkEmployeeRate);
    final unempMinEmpK = _mulRateKurus(mwK, unemploymentEmployeeRate);
    return mwK - sgkMinEmpK - unempMinEmpK;
  }

  // ✅ GV hesap (kuruş)
  Map<String, int> _incomeTaxCalcKurus({
    required int monthlyTaxableIncomeK,
    required int cumulativeTaxableBeforeExemptK,
    required int cumulativeTaxableBeforeExemptPrevK,
    required int monthIndex,
  }) {
    if (monthlyTaxableIncomeK <= 0) {
      return {
        'taxK': 0,
        'exemptionK': 0,
        'taxBeforeExemptionK': 0,
      };
    }

    // Kümülatif vergi hesabı: (kuruş * yüzde) biriktir
    int _calcTaxBP(int cumulativeK) {
      int rem = cumulativeK;
      int prevLimit = 0;
      int totalBP = 0;

      final bracketsK = tax.brackets.map(_toKurus).toList();

      for (int i = 0; i < bracketsK.length + 1; i++) {
        if (rem <= 0) break;

        final limitK = (i < bracketsK.length) ? bracketsK[i] : rem;
        final sliceK = rem > (limitK - prevLimit) ? (limitK - prevLimit) : rem;

        final ratePercent = (tax.rates[i] * 100).round(); // 0.15 -> 15
        totalBP += sliceK * ratePercent;

        prevLimit = limitK;
        rem -= sliceK;
      }
      return totalBP;
    }

    final totalBP = _calcTaxBP(cumulativeTaxableBeforeExemptK);
    final prevBP = _calcTaxBP(cumulativeTaxableBeforeExemptPrevK);
    final monthlyBPdiff = totalBP - prevBP;

    // (kuruş*%)/100 => kuruş; half-up için +50
    final taxBeforeExemptionK = (monthlyBPdiff + 50) ~/ 100;

    // ✅ Uygulanan istisna = min(istisna, istisna öncesi vergi)
    final rawExemptionK = _toKurus(_incomeTaxExemptionAmount(monthIndex));
    final appliedExemptionK = rawExemptionK > taxBeforeExemptionK ? taxBeforeExemptionK : rawExemptionK;

    int monthlyTaxK = taxBeforeExemptionK - appliedExemptionK;
    if (monthlyTaxK < 0) monthlyTaxK = 0;

    return {
      'taxK': monthlyTaxK,
      'exemptionK': appliedExemptionK,
      'taxBeforeExemptionK': taxBeforeExemptionK,
    };
  }

  /// BRÜT → NET (tek ay)  ✅ kuruş motorlu
  MonthResult calculateNetFromGross({
    required double grossMonthly,
    required int monthIndex, // 0..11
    required double cumulativeTaxBasePrev,
  }) {
    final grossK = _toKurus(grossMonthly);
    final cumPrevK = _toKurus(cumulativeTaxBasePrev);

    final sgkCeilK = _toKurus(_sgkCeiling(monthIndex));
    final employerRate = _monthlyEmployerRate(monthIndex);

    final sgkBaseK = _minInt(grossK, sgkCeilK);

    final sgkEmployeeK = _mulRateKurus(sgkBaseK, sgkEmployeeRate);
    final unempEmployeeK = _mulRateKurus(sgkBaseK, unemploymentEmployeeRate);
    final totalEmployeeK = sgkEmployeeK + unempEmployeeK;

    final taxableBaseK = grossK - totalEmployeeK;
    final cumulativeThisK = cumPrevK + taxableBaseK;

    final taxPack = _incomeTaxCalcKurus(
      monthlyTaxableIncomeK: taxableBaseK,
      cumulativeTaxableBeforeExemptK: cumulativeThisK,
      cumulativeTaxableBeforeExemptPrevK: cumPrevK,
      monthIndex: monthIndex,
    );

    final minWageK = _toKurus(_minWageMonthly(monthIndex));
    final stampExK = _mulRateKurus(minWageK, stampTaxRate);
    final stampBeforeK = _mulRateKurus(grossK, stampTaxRate);
    final stampK = _maxInt(0, stampBeforeK - stampExK);

    final totalDeductionsK = totalEmployeeK + taxPack['taxK']! + stampK;
    final netK = grossK - totalDeductionsK;

    final sgkEmployerK = _mulRateKurus(sgkBaseK, employerRate);

    // ✅ iyileştirme: işveren işsizlik sgkBase üzerinden
    final unempEmployerK = _mulRateKurus(sgkBaseK, unemploymentEmployerRate);

    final employerCostK = grossK + sgkEmployerK + unempEmployerK;

    return MonthResult(
      year: year,
      monthIndex: monthIndex,
      gross: _round2(_fromKurus(grossK)),
      net: _round2(_fromKurus(netK)),
      sgkEmployee: _round2(_fromKurus(sgkEmployeeK)),
      unemploymentEmployee: _round2(_fromKurus(unempEmployeeK)),
      sgkEmployer: _round2(_fromKurus(sgkEmployerK)),
      unemploymentEmployer: _round2(_fromKurus(unempEmployerK)),
      incomeTax: _round2(_fromKurus(taxPack['taxK']!)),
      incomeTaxBeforeExempt: _round2(_fromKurus(taxPack['taxBeforeExemptionK']!)),
      incomeTaxExemption: _round2(_fromKurus(taxPack['exemptionK']!)),
      cumulativeTaxBase: _round2(_fromKurus(cumulativeThisK)),
      stampTax: _round2(_fromKurus(stampK)),
      stampTaxBeforeExempt: _round2(_fromKurus(stampBeforeK)),
      stampTaxExemption: _round2(_fromKurus(stampExK)),
      employerCost: _round2(_fromKurus(employerCostK)),
      monthlyTaxableBase: _round2(_fromKurus(taxableBaseK)),
    );
  }

  /// NET → BRÜT (tek ay) ✅ minimum brüt mantığı + kuruş motor
  MonthResult calculateGrossFromNet({
    required double targetNetMonthly,
    required int monthIndex, // 0..11
    required double cumulativeTaxBasePrev,
  }) {
    final targetNetK = _toKurus(targetNetMonthly);
    final cumPrevK = _toKurus(cumulativeTaxBasePrev);

    if (targetNetK <= 0) {
      return calculateNetFromGross(
        grossMonthly: 0,
        monthIndex: monthIndex,
        cumulativeTaxBasePrev: cumulativeTaxBasePrev,
      );
    }

    int netFromGrossK(int grossK) {
      final res = calculateNetFromGross(
        grossMonthly: _fromKurus(grossK),
        monthIndex: monthIndex,
        cumulativeTaxBasePrev: _fromKurus(cumPrevK),
      );
      return _toKurus(res.net);
    }

    // üst sınır
    int low = 0;
    int high = targetNetK * 2;

    for (int i = 0; i < 60; i++) {
      if (netFromGrossK(high) >= targetNetK) break;
      high *= 2;
    }

    // lower-bound: net(gross) >= targetNet sağlayan minimum gross
    int ans = high;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final netMid = netFromGrossK(mid);

      if (netMid >= targetNetK) {
        ans = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    // asgari ücrete 1 kuruş yakınsa asgariye kilitle (sadece asgari civarında)
    final minWageK = _toKurus(_minWageMonthly(monthIndex));
    if ((ans - minWageK).abs() <= 1) ans = minWageK;

    return calculateNetFromGross(
      grossMonthly: _fromKurus(ans),
      monthIndex: monthIndex,
      cumulativeTaxBasePrev: cumulativeTaxBasePrev,
    );
  }

  /// 12 ay BRÜT listesinden yıl hesabı (boş/0 olan aylar atlanır)
  YearResult yearFromGross(List<double?> grossByMonth) {
    double cumTaxBase = 0.0;
    final results = <MonthResult>[];
    for (int m = 0; m < 12; m++) {
      final g = grossByMonth[m];
      if (g == null || g <= 0) continue;
      final res = calculateNetFromGross(
        grossMonthly: g,
        monthIndex: m,
        cumulativeTaxBasePrev: cumTaxBase,
      );
      cumTaxBase = res.cumulativeTaxBase;
      results.add(res);
    }
    return YearResult(year: year, months: results);
  }

  /// 12 ay NET listesinden yıl hesabı (boş/0 olan aylar atlanır)
  YearResult yearFromNet(List<double?> netByMonth) {
    double cumTaxBase = 0.0;
    final results = <MonthResult>[];
    for (int m = 0; m < 12; m++) {
      final n = netByMonth[m];
      if (n == null || n <= 0) continue;
      final res = calculateGrossFromNet(
        targetNetMonthly: n,
        monthIndex: m,
        cumulativeTaxBasePrev: cumTaxBase,
      );
      cumTaxBase = res.cumulativeTaxBase;
      results.add(res);
    }
    return YearResult(year: year, months: results);
  }

  // Saatlik oran yard.
  static double hourlyFromMonthlyGross(double grossMonthly) => grossMonthly / 225.0;
  static double hourlyFromMonthlyNet(double netMonthly) => netMonthly / 225.0;
}
