import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_design.dart';
import '../../utils/personal_profile.dart';
import '../../services/notification_service.dart';
import '../../services/personal_profile_store.dart';
import '../auth/giris_ekrani.dart';
import 'hesabim_ekrani.dart';

class CalismaBilgilerim extends StatefulWidget {
  const CalismaBilgilerim({super.key});
  @override
  State<CalismaBilgilerim> createState() => _CalismaBilgilerimState();
}

class _CalismaBilgilerimState extends State<CalismaBilgilerim> {
  static const _tabs = ['Üyelik', 'Kişisel', 'SGK', 'İş', 'Özet'];
  static const _months = [
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
    'Aralık',
  ];
  final _keys = List.generate(3, (_) => GlobalKey<FormState>());
  final _name = TextEditingController();
  final _prim = TextEditingController();
  final _birthText = TextEditingController();
  final _insuranceText = TextEditingController();
  final _jobText = TextEditingController();
  final _scroll = ScrollController();
  DateTime? _birth, _insurance, _job;
  String? _gender;
  String _insuranceType = '4/a (SSK)';
  Map<String, dynamic> _original = {};
  Map<String, double> _monthlySalaries = {};
  int _salaryEditorRevision = 0;
  int _step = 0;
  bool _loading = true, _saving = false, _dirty = false, _allowPop = false;
  String? _loadError;
  String? _validationError;
  String? _loadedUid;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadedUid = FirebaseAuth.instance.currentUser?.uid;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted && _loadedUid != user?.uid) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    for (final c in [_name, _prim, _birthText, _insuranceText, _jobText]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String _date(DateTime? value) =>
      value == null ? '' : DateFormat('dd.MM.yyyy').format(value);
  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (mounted)
      setState(() {
        _loading = true;
        _loadError = null;
      });
    try {
      final raw = await PersonalProfileStore().readRaw();
      final data = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      DateTime? date(String key) => data[key] is int
          ? DateTime.fromMillisecondsSinceEpoch(data[key] as int)
          : null;
      if (!mounted || uid != FirebaseAuth.instance.currentUser?.uid) return;
      if (_loadedUid != uid) {
        _dirty = false;
        _validationError = null;
        _step = 0;
      }
      _loadedUid = uid;
      _original = data;
      _monthlySalaries = {};
      _birth = date('dogumTarihi');
      _insurance = date('ilkIseGirisTarihi');
      _job = date('mevcutIsyeriBaslangic');
      _birthText.text = _date(_birth);
      _insuranceText.text = _date(_insurance);
      _jobText.text = _date(_job);
      _name.text = data['adSoyad'] as String? ??
          FirebaseAuth.instance.currentUser?.displayName ??
          '';
      _prim.text = data['toplamPrimGun']?.toString() ?? '';
      final legacySalary = (data['guncelBrutMaas'] as num?)?.toDouble();
      final rawMonthly = data['aylikBrutMaaslar'];
      if (rawMonthly is Map) {
        _monthlySalaries = Map<String, dynamic>.from(rawMonthly)
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      if (_monthlySalaries.isEmpty &&
          legacySalary != null &&
          legacySalary > 0) {
        final year = DateTime.now().year;
        final firstMonth = _job?.year == year ? _job!.month : 1;
        for (var month = firstMonth; month <= 12; month++) {
          _monthlySalaries['$year-${month.toString().padLeft(2, '0')}'] =
              legacySalary;
        }
      }
      _removeCurrentYearSalariesBeforeEmployment();
      _gender = ['Erkek', 'Kadın'].contains(data['cinsiyet'])
          ? data['cinsiyet'] as String
          : null;
      _insuranceType = '4/a (SSK)';
      if (['4/a (SSK)', '4/b (Bağ-Kur)', '4/c (Emekli Sandığı)']
          .contains(data['sigortaKolu'])) {
        _insuranceType = data['sigortaKolu'] as String;
      } else if ('${data['sigortaKolu']}'.startsWith('4/b')) {
        _insuranceType = '4/b (Bağ-Kur)';
      } else if ('${data['sigortaKolu']}'.startsWith('4/c')) {
        _insuranceType = '4/c (Emekli Sandığı)';
      }
    } catch (_) {
      if (mounted)
        _loadError =
            'Kayıtlı bilgiler yüklenemedi. Verilerinizin üzerine yazılmaması için yeniden deneyin.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changed() {
    if (!_dirty || _validationError != null) {
      setState(() {
        _dirty = true;
        _validationError = null;
      });
    }
  }

  void _showValidationError(String message, {int? step}) {
    if (!mounted) return;
    setState(() {
      _validationError = message;
      if (step != null) _step = step;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  String? _retirementValidationError() =>
      PersonalProfile.validateRetirementInputs(
        birthDate: _birth,
        insuranceStartDate: _insurance,
        premiumDays: int.tryParse(_prim.text),
      );

  String get _salaryHistorySummary {
    final yearPrefix = '${DateTime.now().year}-';
    final values = _monthlySalaries.entries
        .where((entry) => entry.key.startsWith(yearPrefix))
        .map((entry) => entry.value)
        .toList();
    if (values.isEmpty)
      return '${DateTime.now().year} için aylık tutarları girin';
    final distinct =
        values.map((value) => value.toStringAsFixed(2)).toSet().length;
    return '${DateTime.now().year} · ${values.length}/12 ay · $distinct maaş dönemi';
  }

  String _monthKey(int month) =>
      '${DateTime.now().year}-${month.toString().padLeft(2, '0')}';

  double? get _currentMonthlySalary =>
      _monthlySalaries[_monthKey(DateTime.now().month)];

  String? _workValidationError() {
    if (_job == null) {
      return _monthlySalaries.isEmpty
          ? null
          : 'Aylık maaşlarla birlikte mevcut işe giriş tarihini de seçmelisiniz.';
    }
    final now = DateTime.now();
    final firstRequiredMonth = _job!.year == now.year ? _job!.month : 1;
    final missingMonths = <String>[];
    for (var month = firstRequiredMonth; month <= now.month; month++) {
      final salary = _monthlySalaries[_monthKey(month)];
      if (salary == null || salary <= 0) missingMonths.add(_months[month - 1]);
    }
    if (missingMonths.isNotEmpty) {
      final visible = missingMonths.take(3).join(', ');
      final suffix = missingMonths.length > 3
          ? ' ve ${missingMonths.length - 3} ay daha'
          : '';
      return 'Doğru kümülatif vergi hesabı için $visible$suffix brüt maaşını girin.';
    }
    return null;
  }

  void _removeCurrentYearSalariesBeforeEmployment() {
    final job = _job;
    if (job == null || job.year != DateTime.now().year) return;
    for (var month = 1; month < job.month; month++) {
      _monthlySalaries.remove(_monthKey(month));
    }
  }

  bool _monthBeforeEmployment(int month) =>
      _job != null && _job!.year == DateTime.now().year && month < _job!.month;

  void _monthlySalaryChanged(int month, String value) {
    final parsed = PersonalProfile.parseMoney(value);
    setState(() {
      if (parsed == null) {
        _monthlySalaries.remove(_monthKey(month));
      } else {
        _monthlySalaries[_monthKey(month)] = parsed;
      }
      _dirty = true;
      _validationError = null;
    });
  }

  Future<void> _applyMonthlySalary(int sourceMonth) async {
    final source = _monthlySalaries[_monthKey(sourceMonth)];
    if (source == null || source <= 0) {
      _showValidationError(
          'Önce ${_months[sourceMonth - 1]} ayı için geçerli bir brüt maaş girin.');
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppDesign.activeSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${_months[sourceMonth - 1]} maaşını uygula',
                style: TextStyle(
                    color: AppDesign.activeInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.looks_6_outlined),
              title: const Text('İlk 6 aya uygula'),
              onTap: () => Navigator.pop(context, 'first6'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month_outlined),
              title: const Text('Bu aydan yıl sonuna uygula'),
              onTap: () => Navigator.pop(context, 'after'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('12 ayın tamamına uygula'),
              onTap: () => Navigator.pop(context, 'all'),
            ),
          ]),
        ),
      ),
    );
    if (action == null || !mounted) return;
    final months = action == 'first6'
        ? List.generate(6, (index) => index + 1)
        : action == 'after'
            ? List.generate(13 - sourceMonth, (index) => sourceMonth + index)
            : List.generate(12, (index) => index + 1);
    setState(() {
      for (final month in months) {
        if (!_monthBeforeEmployment(month)) {
          _monthlySalaries[_monthKey(month)] = source;
        }
      }
      _salaryEditorRevision++;
      _dirty = true;
    });
  }

  Widget _monthSalaryField(int month) {
    final disabled = _monthBeforeEmployment(month);
    final value = _monthlySalaries[_monthKey(month)];
    return TextFormField(
      key: ValueKey('salary-$month-$disabled-revision-$_salaryEditorRevision'),
      initialValue:
          value == null ? '' : NumberFormat('#,##0.00', 'tr_TR').format(value),
      enabled: !disabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: _decoration(
        _months[month - 1],
        hint: disabled ? 'İşe başlamadan önce' : 'Brüt maaş',
        suffix: disabled
            ? const Icon(Icons.block_rounded)
            : IconButton(
                tooltip: 'Diğer aylara uygula',
                onPressed: () => _applyMonthlySalary(month),
                icon: const Icon(Icons.copy_all_outlined),
              ),
      ),
      onChanged: (text) => _monthlySalaryChanged(month, text),
      validator: (text) {
        if (disabled || (text ?? '').trim().isEmpty) return null;
        return PersonalProfile.parseMoney(text!) == null
            ? 'Geçerli bir pozitif tutar girin.'
            : null;
      },
    );
  }

  Widget _monthlySalaryEditor() => Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: AppDesign.activeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppDesign.activeBorder),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('12 aylık brüt maaşlar',
              style: TextStyle(
                  color: AppDesign.activeInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_salaryHistorySummary,
              style: TextStyle(color: AppDesign.activeMuted, fontSize: 11.5)),
          const SizedBox(height: 5),
          Text(
            'Net maaş ve vergi dilimi hesabı için işe başladığınız aydan bu aya kadar olan brüt ücretleri doldurun.',
            style: TextStyle(
                color: AppDesign.activeMuted, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 16),
          Text('OCAK – HAZİRAN',
              style: TextStyle(
                  color: AppDesign.activeMuted,
                  fontSize: 10.5,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (var month = 1; month <= 6; month++) ...[
            _monthSalaryField(month),
            if (month < 6) const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: Icon(Icons.expand_circle_down_outlined,
                  color: Theme.of(context).primaryColor),
              title: const Text('Temmuz – Aralık',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Yılın ikinci 6 ayını göster',
                  style:
                      TextStyle(fontSize: 11.5, color: AppDesign.activeMuted)),
              children: [
                const SizedBox(height: 6),
                for (var month = 7; month <= 12; month++) ...[
                  _monthSalaryField(month),
                  if (month < 12) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ]),
      );

  InputDecoration _decoration(String label, {String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppDesign.activeSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppDesign.activeBorder)),
        errorMaxLines: 3,
      );

  Future<void> _pickDate(int field) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final current = field == 0
        ? _birth
        : field == 1
            ? _insurance
            : _job;
    var initial = current ?? (field == 0 ? DateTime(now.year - 30) : now);
    if (initial.isAfter(now)) initial = now;
    if (initial.isBefore(DateTime(1900))) initial = DateTime(1900);
    final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: now,
        locale: const Locale('tr', 'TR'));
    if (picked == null || !mounted) return;
    setState(() {
      _dirty = true;
      _validationError = null;
      if (field == 0) {
        _birth = picked;
        _birthText.text = _date(picked);
      } else if (field == 1) {
        _insurance = picked;
        _insuranceText.text = _date(picked);
      } else {
        _job = picked;
        _jobText.text = _date(picked);
        _removeCurrentYearSalariesBeforeEmployment();
        _salaryEditorRevision++;
      }
    });
  }

  Widget _dateField(String title, int field, TextEditingController controller,
          {bool required = true}) =>
      TextFormField(
        controller: controller,
        readOnly: true,
        decoration: _decoration(title,
            hint: 'GG.AA.YYYY',
            suffix: const Icon(Icons.calendar_today_outlined)),
        onTap: () => _pickDate(field),
        validator: (_) {
          final value = field == 0
              ? _birth
              : field == 1
                  ? _insurance
                  : _job;
          if (value == null) return required ? 'Lütfen tarih seçin.' : null;
          if (value.isAfter(DateTime.now()))
            return 'Gelecekte bir tarih seçilemez.';
          if (field != 0 && _birth != null && !value.isAfter(_birth!))
            return 'Tarih doğum tarihinizden sonra olmalı.';
          if (field == 1 &&
              _birth != null &&
              value.isBefore(
                  DateTime(_birth!.year + 15, _birth!.month, _birth!.day))) {
            return 'İlk sigorta girişinde en az 15 yaşında olmalısınız.';
          }
          if (field == 2 && _insurance != null && value.isBefore(_insurance!))
            return 'Mevcut işe giriş ilk sigorta girişinden önce olamaz.';
          return null;
        },
      );

  Widget _form(List<Widget> children) => Form(
      key: _keys[_step - 1],
      onChanged: _changed,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          children[i]
        ],
      ]));

  Widget _membershipStep() => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final primary = Theme.of(context).primaryColor;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                    user == null
                        ? Icons.person_outline_rounded
                        : Icons.verified_user_outlined,
                    color: primary,
                    size: 36),
                const SizedBox(height: 16),
                Text(
                    user == null
                        ? 'Çalışma bilgileri için üyelik isteğe bağlı'
                        : 'Üyeliğiniz hazır',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppDesign.activeInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                    user == null
                        ? 'Bilgilerinizi üye olmadan bu cihazda saklayabilirsiniz. 7 günlük Premium deneme ve abonelik için giriş yapmanız gerekir. Uygulamayı yeniden kurarsanız aboneliğinize aynı hesapla erişebilirsiniz; çalışma bilgilerinizi yeniden girmeniz gerekebilir.'
                        : (user.email ?? 'Hesabınızla giriş yaptınız.'),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppDesign.activeMuted, height: 1.45)),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (user == null) {
                      await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                              builder: (_) =>
                                  const GirisEkrani(returnToCaller: true)));
                    } else {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const HesabimEkrani()));
                    }
                    if (mounted) await _load();
                  },
                  icon: Icon(user == null
                      ? Icons.login_rounded
                      : Icons.manage_accounts_outlined),
                  label: Text(user == null
                      ? 'Giriş yap / Kayıt ol'
                      : 'Üyelik ayarlarını aç'),
                ),
              ]);
        },
      );

  Widget _content() {
    if (_step == 0) return _membershipStep();
    if (_step == 1)
      return _form([
        TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Ad soyad *'),
            maxLength: 100,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ad soyad girin.'
                : null),
        _dateField('Doğum tarihi *', 0, _birthText),
        DropdownButtonFormField<String>(
            value: _gender,
            isExpanded: true,
            decoration: _decoration('Cinsiyet *'),
            items: ['Kadın', 'Erkek']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() {
                  _gender = v;
                  _dirty = true;
                  _validationError = null;
                }),
            validator: (v) => v == null ? 'Lütfen seçim yapın.' : null),
      ]);
    if (_step == 2)
      return _form([
        DropdownButtonFormField<String>(
            value: _insuranceType,
            isExpanded: true,
            decoration: _decoration('SGK statüsü *'),
            items: ['4/a (SSK)', '4/b (Bağ-Kur)', '4/c (Emekli Sandığı)']
                .map((v) => DropdownMenuItem(
                    value: v,
                    enabled: v == '4/a (SSK)',
                    child: Text(v,
                        style: TextStyle(
                            color: v == '4/a (SSK)'
                                ? AppDesign.activeInk
                                : AppDesign.activeMuted))))
                .toList(),
            validator: (v) => v == '4/a (SSK)'
                ? null
                : 'Kişisel çalışma özeti şu anda yalnızca 4/a için destekleniyor.',
            onChanged: (v) => setState(() {
                  _insuranceType = v!;
                  _dirty = true;
                  _validationError = null;
                })),
        Text(
            'Kişisel çalışma özeti şu anda 4/a (SSK) içindir. Diğer statülerin hesaplamalarına Hesapla menüsünden ulaşabilirsiniz.',
            style: TextStyle(
                color: AppDesign.activeMuted, fontSize: 12, height: 1.4)),
        _dateField('İlk sigorta giriş tarihi *', 1, _insuranceText),
        TextFormField(
            controller: _prim,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decoration('Toplam prim günü *', hint: 'Örn. 5400'),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 0) return 'Geçerli bir prim günü girin.';
              final validation = PersonalProfile.validateRetirementInputs(
                birthDate: _birth,
                insuranceStartDate: _insurance,
                premiumDays: n,
              );
              if (validation != null && validation.contains('prim günü'))
                return validation;
              return null;
            }),
        Text(
            'Hizmet dökümünüzdeki toplamı girin. Borçlanma günlerini ikinci kez eklemeyin.',
            style: TextStyle(color: AppDesign.activeMuted, height: 1.4)),
      ]);
    if (_step == 3)
      return _form([
        Text(
            'Mevcut iş bilginiz isteğe bağlıdır. İşe giriş tarihinizi seçtiğinizde aylık brüt maaşlarınızı aşağıdan girebilirsiniz.',
            style: TextStyle(color: AppDesign.activeMuted, height: 1.5)),
        _dateField('Mevcut işe giriş tarihi', 2, _jobText, required: false),
        if (_job != null) _monthlySalaryEditor(),
        if (_job != null || _monthlySalaries.isNotEmpty)
          TextButton.icon(
              onPressed: () => setState(() {
                    _job = null;
                    _jobText.clear();
                    _monthlySalaries.clear();
                    _dirty = true;
                  }),
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Mevcut iş bilgilerini temizle')),
      ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          'Kaydetmeden önce bilgilerinizi kontrol edin. Değiştirmek için ilgili sekmeye dokunabilirsiniz.',
          style: TextStyle(color: AppDesign.activeMuted, height: 1.5)),
      const SizedBox(height: 20),
      for (final entry in {
        if (_name.text.trim().isNotEmpty) 'Ad soyad': _name.text.trim(),
        'Doğum tarihi': _date(_birth),
        'Cinsiyet': _gender ?? '',
        'SGK statüsü': _insuranceType,
        'İlk sigorta girişi': _date(_insurance),
        'Toplam prim günü': _prim.text,
        'Mevcut işe giriş': _job == null ? 'Belirtilmedi' : _date(_job),
        'Güncel brüt maaş': _currentMonthlySalary == null
            ? 'Belirtilmedi'
            : '${NumberFormat('#,##0.00', 'tr_TR').format(_currentMonthlySalary)} ₺',
        if (_monthlySalaries.isNotEmpty) 'Maaş geçmişi': _salaryHistorySummary,
      }.entries)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.key,
                  style: TextStyle(color: AppDesign.activeMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(entry.value,
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ])),
    ]);
  }

  void _go(int target) {
    if (_saving || target == _step) return;
    FocusScope.of(context).unfocus();
    if (target > _step &&
        _step >= 1 &&
        _step < 4 &&
        !(_keys[_step - 1].currentState?.validate() ?? false)) {
      final message = _step == 2
          ? (_retirementValidationError() ??
              'Eksik ya da hatalı alanları kontrol edin.')
          : 'Eksik ya da hatalı alanları kontrol edin.';
      _showValidationError(message);
      return;
    }
    if (target > _step && _step == 2) {
      final error = _retirementValidationError();
      if (error != null) {
        _showValidationError(error);
        return;
      }
    }
    if (target > _step && _step == 3) {
      final error = _workValidationError();
      if (error != null) {
        _showValidationError(error);
        return;
      }
    }
    // Forward navigation visits each section; earlier sections remain editable.
    setState(() {
      _validationError = null;
      _step = target > _step ? _step + 1 : target;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _save() async {
    if (_saving) return;
    final retirementError = _retirementValidationError();
    if (retirementError != null) {
      _showValidationError(retirementError, step: 2);
      return;
    }
    final workError = _workValidationError();
    if (workError != null) {
      _showValidationError(workError, step: 3);
      return;
    }
    setState(() => _saving = true);
    try {
      final salary = _currentMonthlySalary;
      final store = PersonalProfileStore();
      final current = await store.readRaw();
      final latest = current == null
          ? _original
          : Map<String, dynamic>.from(jsonDecode(current) as Map);
      final updated = PersonalProfile.merge(
          latest,
          {
            'adSoyad': _name.text.trim(),
            'dogumTarihi': _birth!.millisecondsSinceEpoch,
            'cinsiyet': _gender,
            'sigortaKolu': _insuranceType,
            'ilkIseGirisTarihi': _insurance!.millisecondsSinceEpoch,
            'toplamPrimGun': int.parse(_prim.text),
            'mevcutIsyeriBaslangic': _job?.millisecondsSinceEpoch,
            // Eski ekranlar ve raporlar bu anahtarı kullanmaya devam ediyor.
            // Değer artık ayrı bir alandan değil, içinde bulunduğumuz aydan türetilir.
            'guncelBrutMaas': salary ?? 0.0,
            'aylikBrutMaaslar': _monthlySalaries,
          },
          DateTime.now());
      if (!await store.saveRaw(jsonEncode(updated)))
        throw StateError('Save failed');
      await NotificationService.instance.syncFromStoredPreferences();
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _allowPop = true;
        _saving = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Bilgiler kaydedilemedi. Girdileriniz burada duruyor; tekrar deneyin.')));
      }
    }
  }

  Future<void> _confirmExit() async {
    if (_saving) return;
    final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Değişiklikler kaydedilmedi'),
              content: const Text(
                  'Çıkarsanız bu formdaki değişiklikler kaybolacak.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Düzenlemeye devam et')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Kaydetmeden çık'))
              ],
            ));
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _allowPop || (!_dirty && !_saving),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _confirmExit();
        },
        child: Scaffold(
          backgroundColor: AppDesign.activeBackground,
          appBar: AppDesign.appBar('Çalışma bilgilerim'),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(_loadError!),
                            const SizedBox(height: 16),
                            FilledButton(
                                onPressed: _load,
                                child: const Text('Yeniden dene')),
                          ])))
                  : SafeArea(
                      child: AppContent(
                          child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < _tabs.length; i++)
                                  Expanded(
                                      child: Semantics(
                                    selected: _step == i,
                                    button: true,
                                    child: InkWell(
                                      onTap: _saving ? null : () => _go(i),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3, vertical: 10),
                                          child: Column(children: [
                                            CircleAvatar(
                                                radius: 13,
                                                backgroundColor: i <= _step
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : AppDesign.activeBorder,
                                                child: Text('${i + 1}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: i <= _step
                                                            ? Colors.white
                                                            : AppDesign
                                                                .activeMuted))),
                                            const SizedBox(height: 7),
                                            Text(_tabs[i],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: _step == i
                                                        ? AppDesign.activeInk
                                                        : AppDesign.activeMuted,
                                                    fontWeight: _step == i
                                                        ? FontWeight.w700
                                                        : FontWeight.w500)),
                                          ])),
                                    ),
                                  )),
                              ])),
                      LinearProgressIndicator(
                          value: (_step + 1) / _tabs.length,
                          minHeight: 3,
                          backgroundColor: AppDesign.activeBorder),
                      Expanded(
                          child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.all(20),
                        child: AppSurface(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              Text(
                                  [
                                    'Üyelik ayarları',
                                    'Kişisel bilgileriniz',
                                    'SGK bilgileriniz',
                                    'Mevcut iş ve maaş',
                                    'Kontrol edin ve kaydedin'
                                  ][_step],
                                  style: TextStyle(
                                      color: AppDesign.activeInk,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                  'Adım ${_step + 1} / ${_tabs.length}${_step == 1 || _step == 2 ? ' · * Zorunlu alanlar' : ''}',
                                  style: TextStyle(
                                      color: AppDesign.activeMuted,
                                      fontSize: 12)),
                              if (_validationError != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.error_outline_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(_validationError!,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onErrorContainer))),
                                      ]),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _content(),
                            ])),
                      )),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                          child: Row(children: [
                            if (_step > 0)
                              OutlinedButton(
                                  onPressed:
                                      _saving ? null : () => _go(_step - 1),
                                  child: const Text('Geri')),
                            const SizedBox(width: 12),
                            Expanded(
                                child: FilledButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () {
                                      if (_step == 4) {
                                        _save();
                                      } else {
                                        _go(_step + 1);
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              icon: Icon(_saving
                                  ? Icons.hourglass_top_rounded
                                  : _step == 4
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded),
                              label: Text(_saving
                                  ? 'Kaydediliyor…'
                                  : _step == 4
                                      ? 'Kaydet ve tamamla'
                                      : 'İleri'),
                            )),
                          ])),
                    ]))),
        ),
      );
}
