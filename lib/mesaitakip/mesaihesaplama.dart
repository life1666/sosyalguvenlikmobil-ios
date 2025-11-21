// UI'dan bağımsız, saf hesap modülü.

enum EmployeeStatus { normal, sgdp } // SGDP = Emekli/SGDP kapsamında çalışan
enum Incentive { none, fourPoints, fivePoints }

class TaxBrackets {
  final List<double> brackets;
  final List<double> rates;
  const TaxBrackets(this.brackets, this.rates);
}

/// Tek ay için tüm bileşenlerin sonucu
class MonthResult {
  final int year;
  final int monthIndex; // 0..11
  final double gross;   // brüt
  final double net;     // net
  // İşçi kesintileri
  final double sgkEmployee;
  final double unemploymentEmployee;
  // İşveren kesintileri
  final double sgkEmployer;
  final double unemploymentEmployer;
  // Vergi
  final double incomeTax;              // aylık ödenen gelir vergisi
  final double incomeTaxBeforeExempt;  // istisna öncesi aylık GV
  final double incomeTaxExemption;     // asgari ücret GV istisnası tutarı
  final double cumulativeTaxBase;      // kümülatif GV matrahı (istisna öncesi)
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
  double get totalNet   => months.fold(0.0, (p, m) => p + m.net);
  double get totalSgkEmployee           => months.fold(0.0, (p, m) => p + m.sgkEmployee);
  double get totalUnemploymentEmployee  => months.fold(0.0, (p, m) => p + m.unemploymentEmployee);
  double get totalSgkEmployer           => months.fold(0.0, (p, m) => p + m.sgkEmployer);
  double get totalUnemploymentEmployer  => months.fold(0.0, (p, m) => p + m.unemploymentEmployer);
  double get totalIncomeTax             => months.fold(0.0, (p, m) => p + m.incomeTax);
  double get totalIncomeTaxBeforeExempt => months.fold(0.0, (p, m) => p + m.incomeTaxBeforeExempt);
  double get totalIncomeTaxExemption    => months.fold(0.0, (p, m) => p + m.incomeTaxExemption);
  double get totalStampTax              => months.fold(0.0, (p, m) => p + m.stampTax);
  double get totalStampTaxBeforeExempt  => months.fold(0.0, (p, m) => p + m.stampTaxBeforeExempt);
  double get totalStampTaxExemption     => months.fold(0.0, (p, m) => p + m.stampTaxExemption);
  double get totalEmployerCost          => months.fold(0.0, (p, m) => p + m.employerCost);
  double get lastCumulativeTaxBase      => months.isEmpty ? 0.0 : months.last.cumulativeTaxBase;
}

/// Hesap makinesi
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
  late TaxBrackets tax;     // GV dilimleri + oranları

  SalaryEngine({
    required this.year,
    required this.status,
    required this.incentive,
  }) {
    _updateConstants();
  }

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
      sgkEmployerBaseRate = 0.185;
    }
    stampTaxRate = 0.00759;

    if (year == 2022) {
      tax = TaxBrackets([32000, 70000, 250000, 880000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else if (year == 2023) {
      tax = TaxBrackets([70000, 150000, 550000, 1900000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else if (year == 2024) {
      tax = TaxBrackets([110000, 230000, 870000, 3000000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    } else {
      tax = TaxBrackets([158000, 330000, 1200000, 4300000], [0.15, 0.20, 0.27, 0.35, 0.40]);
    }
  }

  // Aylık kısa vadeli prim ek oranı ve 2024 SGDP istisnası
  double _monthlyEmployerRate(int monthIndex) {
    final m = monthIndex; // 0..11
    double shortTerm = (year < 2024 || (year == 2024 && m < 7)) ? 0.02 : 0.0225;
    double base = sgkEmployerBaseRate + shortTerm;

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
      }
    }
    return (base - incentiveCut).clamp(0.0, 1.0);
  }

  // Asgari ücret (brüt)
  double _minWageMonthly(int monthIndex) {
    final m = monthIndex;
    if (year == 2022) {
      return (m < 5) ? 5004.00 : 6471.00;
    } else if (year == 2023) {
      return (m < 5) ? 10008.00 : 13414.50;
    } else if (year == 2024) {
      return 20002.50;
    } else {
      return 26005.50; // 2025
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
    } else {
      if (monthIndex < 7) return 3315.70;
      if (monthIndex == 7) return 4257.57;
      return 4420.93;
    }
  }

  double _round2(double v) => double.parse(v.toStringAsFixed(2));
  double _sgkCeiling(int monthIndex) => _minWageMonthly(monthIndex) * 7.5;

  double _minWageTaxableBase(int monthIndex) {
    final mw = _minWageMonthly(monthIndex);
    return _round2(mw * (1 - sgkEmployeeRate - unemploymentEmployeeRate));
  }

  Map<String, double> _calculateIncomeTax({
    required double monthlyTaxableIncome,
    required double cumulativeTaxableBeforeExempt,
    required double cumulativeTaxableBeforeExemptPrev,
    required int monthIndex,
  }) {
    double monthlyTI = _round2(monthlyTaxableIncome);
    double cumTotal = _round2(cumulativeTaxableBeforeExempt);
    double cumPrev  = _round2(cumulativeTaxableBeforeExemptPrev);
    double minBase  = _round2(_minWageTaxableBase(monthIndex));

    if (monthlyTI <= 0) {
      return {
        'tax': 0,
        'exemption': 0,
        'taxableIncomeAfterExemption': 0,
        'taxBeforeExemption': 0,
      };
    }

    double exemption = monthlyTI >= minBase ? minBase : monthlyTI;
    double taxableAfter = _round2(monthlyTI - exemption);

    double _calcTax(double cumulative) {
      double rem = cumulative;
      double prevLimit = 0;
      double total = 0;
      for (int i = 0; i < tax.brackets.length + 1; i++) {
        if (rem <= 0) break;
        double limit = i < tax.brackets.length ? tax.brackets[i] : rem;
        double slice = rem > (limit - prevLimit) ? (limit - prevLimit) : rem;
        total += _round2(slice * tax.rates[i]);
        prevLimit = limit;
        rem -= slice;
      }
      return total;
    }

    double totalTax = _calcTax(cumTotal);
    double prevTax  = _calcTax(cumPrev);
    double monthlyTaxBefore = _round2(totalTax - prevTax);

    double exemptionTax = _round2(_incomeTaxExemptionAmount(monthIndex));
    double monthlyTax = _round2(monthlyTaxBefore - exemptionTax);
    if (monthlyTax < 0) monthlyTax = 0;

    return {
      'tax': monthlyTax,
      'exemption': exemptionTax,
      'taxableIncomeAfterExemption': taxableAfter,
      'taxBeforeExemption': monthlyTaxBefore,
    };
  }

  /// BRÜT → NET (tek ay)
  MonthResult calculateNetFromGross({
    required double grossMonthly,
    required int monthIndex, // 0..11
    required double cumulativeTaxBasePrev,
  }) {
    final sgkCeil = _sgkCeiling(monthIndex);
    final employerRate = _monthlyEmployerRate(monthIndex);

    final sgkBase = grossMonthly > sgkCeil ? sgkCeil : grossMonthly;

    final sgkEmployee = _round2(sgkBase * sgkEmployeeRate);
    final unempEmployee = _round2(sgkBase * unemploymentEmployeeRate);
    final totalEmployee = _round2(sgkEmployee + unempEmployee);

    final taxableBase = _round2(grossMonthly - totalEmployee);

    final cumulativeThis = _round2(cumulativeTaxBasePrev + taxableBase);
    final incomeTaxPack = _calculateIncomeTax(
      monthlyTaxableIncome: taxableBase,
      cumulativeTaxableBeforeExempt: cumulativeThis,
      cumulativeTaxableBeforeExemptPrev: cumulativeTaxBasePrev,
      monthIndex: monthIndex,
    );

    final minWage = _minWageMonthly(monthIndex);
    final stampTaxExempt = _round2(minWage * stampTaxRate);
    final stampBefore = _round2(grossMonthly * stampTaxRate);
    double stamp = _round2(stampBefore - stampTaxExempt);
    if (stamp < 0) stamp = 0;

    final totalDeductions = _round2(totalEmployee + incomeTaxPack['tax']! + stamp);
    final net = _round2(grossMonthly - totalDeductions);

    final sgkEmployer = _round2(sgkBase * employerRate);
    final unempEmployer = _round2(grossMonthly * unemploymentEmployerRate);
    final employerCost = _round2(grossMonthly + sgkEmployer + unempEmployer);

    return MonthResult(
      year: year,
      monthIndex: monthIndex,
      gross: _round2(grossMonthly),
      net: net,
      sgkEmployee: sgkEmployee,
      unemploymentEmployee: unempEmployee,
      sgkEmployer: sgkEmployer,
      unemploymentEmployer: unempEmployer,
      incomeTax: incomeTaxPack['tax']!,
      incomeTaxBeforeExempt: incomeTaxPack['taxBeforeExemption']!,
      incomeTaxExemption: incomeTaxPack['exemption']!,
      cumulativeTaxBase: cumulativeThis,
      stampTax: stamp,
      stampTaxBeforeExempt: stampBefore,
      stampTaxExemption: stampTaxExempt,
      employerCost: employerCost,
      monthlyTaxableBase: taxableBase,
    );
  }

  /// NET → BRÜT (tek ay)
  MonthResult calculateGrossFromNet({
    required double targetNetMonthly,
    required int monthIndex, // 0..11
    required double cumulativeTaxBasePrev,
  }) {
    if (targetNetMonthly <= 0) {
      return calculateNetFromGross(
        grossMonthly: 0,
        monthIndex: monthIndex,
        cumulativeTaxBasePrev: cumulativeTaxBasePrev,
      );
    }

    double lower = targetNetMonthly;
    double upper = targetNetMonthly * 2;
    const tol = 0.00001;
    const maxIter = 300;

    double bestGross = upper;
    for (int i = 0; i < maxIter; i++) {
      double mid = (lower + upper) / 2;
      final tmp = calculateNetFromGross(
        grossMonthly: mid,
        monthIndex: monthIndex,
        cumulativeTaxBasePrev: cumulativeTaxBasePrev,
      );
      final diff = tmp.net - targetNetMonthly;
      if (diff.abs() < tol) {
        bestGross = _round2(mid);
        break;
      }
      if (diff < 0) {
        lower = mid;
      } else {
        upper = mid;
      }
      bestGross = _round2(lower);
    }

    return calculateNetFromGross(
      grossMonthly: bestGross,
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
