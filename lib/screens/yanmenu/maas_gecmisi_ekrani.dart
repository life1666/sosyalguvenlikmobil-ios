import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../utils/app_design.dart';
import '../../utils/personal_profile.dart';

class MaasGecmisiEkrani extends StatefulWidget {
  final Map<String, double> values;
  final DateTime? jobStart;

  const MaasGecmisiEkrani({
    super.key,
    required this.values,
    required this.jobStart,
  });

  @override
  State<MaasGecmisiEkrani> createState() => _MaasGecmisiEkraniState();
}

class _MaasGecmisiEkraniState extends State<MaasGecmisiEkrani> {
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
    'Aralık'
  ];
  final _controllers = <int, TextEditingController>{};
  final _formKey = GlobalKey<FormState>();
  late final int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    for (var month = 1; month <= 12; month++) {
      final value = widget.values['$_year-${month.toString().padLeft(2, '0')}'];
      _controllers[month] = TextEditingController(
        text: value == null
            ? ''
            : NumberFormat('#,##0.00', 'tr_TR').format(value),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isBeforeEmployment(int month) =>
      widget.jobStart != null &&
      widget.jobStart!.year == _year &&
      month < widget.jobStart!.month;

  Future<void> _showApplyOptions(int sourceMonth) async {
    final source = PersonalProfile.parseMoney(_controllers[sourceMonth]!.text);
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Önce bu ay için geçerli bir brüt maaş girin.'),
        behavior: SnackBarBehavior.floating,
      ));
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
            _option(context, 'first6', 'İlk 6 aya uygula'),
            if (sourceMonth <= DateTime.now().month)
              _option(context, 'untilNow', 'Bu aydan bugüne uygula'),
            _option(context, 'after', 'Bu aydan yıl sonuna uygula'),
            _option(context, 'all', '12 ayın tamamına uygula'),
          ]),
        ),
      ),
    );
    if (action == null || !mounted) return;
    Iterable<int> months;
    switch (action) {
      case 'first6':
        months = List.generate(6, (index) => index + 1);
        break;
      case 'untilNow':
        final count = DateTime.now().month - sourceMonth + 1;
        months = count > 0
            ? List.generate(count, (index) => sourceMonth + index)
            : const <int>[];
        break;
      case 'after':
        months =
            List.generate(13 - sourceMonth, (index) => sourceMonth + index);
        break;
      default:
        months = List.generate(12, (index) => index + 1);
    }
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(source);
    setState(() {
      for (final month in months) {
        if (!_isBeforeEmployment(month)) _controllers[month]!.text = formatted;
      }
    });
  }

  Widget _option(BuildContext context, String value, String title) => ListTile(
        leading: const Icon(Icons.content_copy_rounded),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pop(context, value),
      );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = <String, double>{};
    for (var month = 1; month <= 12; month++) {
      if (_isBeforeEmployment(month)) continue;
      final value = PersonalProfile.parseMoney(_controllers[month]!.text);
      if (value != null) {
        result['$_year-${month.toString().padLeft(2, '0')}'] = value;
      }
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    return Scaffold(
      backgroundColor: AppDesign.activeBackground,
      appBar: AppDesign.appBar('$_year Maaş Geçmişi', actions: [
        TextButton(onPressed: _save, child: const Text('Kaydet')),
        const SizedBox(width: 8),
      ]),
      body: AppContent(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Text(
                'Her ayın brüt maaşını ayrı girebilirsiniz. Bir tutarı yazdıktan '
                'sonra sağdaki çoğaltma düğmesiyle ilk 6 aya veya 12 ayın '
                'tamamına uygulayabilirsiniz.',
                style: TextStyle(
                    color: AppDesign.activeMuted, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      size: 20, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_year maaşları',
                          style: TextStyle(
                              color: AppDesign.activeInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text('Tutarlar aylık brüt ücret olarak kaydedilir.',
                          style: TextStyle(
                              color: AppDesign.activeMuted, fontSize: 11.5)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              Text('OCAK – HAZİRAN',
                  style: TextStyle(
                      color: AppDesign.activeMuted,
                      fontSize: 11,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (var month = 1; month <= 6; month++) ...[
                _monthField(month, currentMonth),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 2),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppDesign.activeSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppDesign.activeBorder),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                    leading: Icon(Icons.expand_circle_down_outlined,
                        color: Theme.of(context).primaryColor),
                    title: Text('Temmuz – Aralık',
                        style: TextStyle(
                            color: AppDesign.activeInk,
                            fontWeight: FontWeight.w700)),
                    subtitle: Text('Yılın ikinci 6 ayını göster',
                        style: TextStyle(
                            color: AppDesign.activeMuted, fontSize: 11.5)),
                    children: [
                      for (var month = 7; month <= 12; month++) ...[
                        _monthField(month, currentMonth),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthField(int month, int currentMonth) {
    final disabled = _isBeforeEmployment(month);
    final future = month > currentMonth;
    return TextFormField(
      controller: _controllers[month],
      enabled: !disabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: _months[month - 1],
        hintText: disabled ? 'İşe başlamadan önce' : 'Brüt maaş',
        helperText: future ? 'Tahmini dönem' : null,
        filled: true,
        fillColor: disabled
            ? AppDesign.activeBorder.withOpacity(.35)
            : AppDesign.activeSurface,
        suffixIcon: disabled
            ? const Icon(Icons.block_rounded)
            : IconButton(
                tooltip: 'Döneme uygula',
                onPressed: () => _showApplyOptions(month),
                icon: const Icon(Icons.copy_all_outlined),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppDesign.activeBorder),
        ),
      ),
      validator: (value) {
        if (disabled || (value ?? '').trim().isEmpty) return null;
        return PersonalProfile.parseMoney(value!) == null
            ? 'Geçerli bir pozitif tutar girin.'
            : null;
      },
    );
  }
}
