import 'package:flutter/material.dart';

import '../services/hesaplama_pdf_service.dart';
import '../services/premium_pdf_action.dart';
import 'app_design.dart';

const calculatorAccent = Color(0xFF169B55);
ThemeData calculatorTheme(BuildContext context) {
  final base = Theme.of(context);
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppDesign.activeBorder));
  return base.copyWith(
      primaryColor: calculatorAccent,
      colorScheme: base.colorScheme.copyWith(primary: calculatorAccent),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppDesign.activeSurface,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
              borderSide:
                  const BorderSide(color: calculatorAccent, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          labelStyle: TextStyle(color: AppDesign.activeMuted, fontSize: 14)),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: calculatorAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      textTheme: base.textTheme.copyWith(
          titleLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppDesign.activeInk)));
}

class CalculatorPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final ScrollController? controller;
  final List<Widget> actions;
  const CalculatorPage(
      {super.key,
      required this.title,
      required this.child,
      this.icon = Icons.calculate_outlined,
      this.controller,
      this.actions = const []});
  @override
  Widget build(BuildContext context) => Theme(
      data: calculatorTheme(context),
      child: Scaffold(
          backgroundColor: AppDesign.activeBackground,
          body: SafeArea(
              child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  child: AppContent(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        TextButton.icon(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.chevron_left, size: 20),
                            label: const Text('Geri Dön'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppDesign.activeMuted)),
                        const SizedBox(height: 12),
                        Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                                MediaQuery.sizeOf(context).width < 360
                                    ? 16
                                    : 24),
                            decoration: BoxDecoration(
                                color: AppDesign.activeSurface,
                                borderRadius: BorderRadius.circular(24),
                                border:
                                    Border.all(color: AppDesign.activeBorder),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 3))
                                ]),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Icon(icon,
                                            color: calculatorAccent, size: 24)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(title,
                                            style: TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w700,
                                                color: AppDesign.activeInk))),
                                    ...actions
                                  ]),
                                  const SizedBox(height: 24),
                                  child
                                ])),
                        const SizedBox(height: 20),
                        Text(
                            'Hesaplamalar tahmini ve bilgi amaçlıdır. Uygulama resmi bir kurumu temsil etmez.',
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: AppDesign.activeMuted)),
                      ]))))));
}

class CalculatorResultHighlight extends StatelessWidget {
  final String label, value;
  const CalculatorResultHighlight(
      {super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: AppDesign.isDark
              ? const Color(0xFF12372B)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppDesign.isDark
                  ? const Color(0xFF166534)
                  : const Color(0xFFDCFCE7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: AppDesign.isDark
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFF166534))),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppDesign.isDark
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFF166534))),
      ]));
}

class CalculatorResultSheet extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final String? highlightKey;
  const CalculatorResultSheet(
      {super.key,
      this.title = 'Hesaplama Sonucu',
      required this.details,
      this.highlightKey});

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await PremiumPdfAction.run(context, () => HesaplamaPdfService.shareSummary(
            title: title,
            details: details,
            highlightKey: highlightKey,
          ));
    } catch (error, stackTrace) {
      debugPrint('Hesaplama PDF oluşturma hatası: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PDF oluşturulamadı. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppDesign.activeBorder,
                borderRadius: BorderRadius.circular(4))),
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 12, 4),
            child: Row(children: [
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppDesign.activeInk))),
              IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: AppDesign.activeMuted))
            ])),
        Expanded(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
              if (highlightKey != null &&
                  details.containsKey(highlightKey)) ...[
                CalculatorResultHighlight(
                    label: highlightKey!, value: details[highlightKey]!),
                const SizedBox(height: 20)
              ],
              for (final entry
                  in details.entries.where((e) => e.key != highlightKey))
                Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppDesign.activeBorder))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key,
                              style: TextStyle(
                                  fontSize: 12, color: AppDesign.activeMuted)),
                          const SizedBox(height: 5),
                          Text(entry.value,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: AppDesign.activeInk))
                        ]))
            ])),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _sharePdf(context),
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: const Text('Premium PDF'),
              ),
            ],
          ),
        ),
      ]));
}
