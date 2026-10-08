import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:src/screens/yanmenu/kvkk_ekrani.dart';
import 'package:src/utils/app_design.dart';
import 'package:src/utils/calculator_design.dart';
import 'package:src/utils/theme_helper.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeHelper().setDarkMode(true);
  });

  tearDown(() async => ThemeHelper().setDarkMode(false));

  testWidgets('hesaplayıcı alt sayfası koyu zemin ve yüzey kullanır',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalculatorPage(title: 'Test hesap', child: Text('Form alanı')),
    ));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppDesign.activeBackground);
    final surfaces = tester.widgetList<Container>(find.byType(Container));
    expect(
        surfaces.any((container) =>
            container.decoration is BoxDecoration &&
            (container.decoration! as BoxDecoration).color ==
                AppDesign.activeSurface),
        isTrue);
    expect(tester.widget<Text>(find.text('Test hesap')).style?.color,
        AppDesign.activeInk);
  });

  testWidgets('KVKK alt sayfasında koyu zeminde okunabilir metin kalır',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KvkkEkrani()));

    final title = tester.widget<Text>(find.text('KVKK Aydınlatma Metni'));
    expect(title.style?.color, AppDesign.activeInk);
    final gradients = tester.widgetList<Container>(find.byType(Container));
    expect(
        gradients.any((container) =>
            container.decoration is BoxDecoration &&
            (container.decoration! as BoxDecoration).gradient
                is LinearGradient &&
            ((container.decoration! as BoxDecoration).gradient!
                        as LinearGradient)
                    .colors
                    .first ==
                AppDesign.activeBackground),
        isTrue);
  });

  testWidgets('hesap sonucu vurgusu koyu temada açık zemin kullanmaz',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CalculatorResultHighlight(label: 'Net tutar', value: '10.000 TL'),
      ),
    ));

    final highlight = tester.widget<Container>(
        find.ancestor(of: find.text('Net tutar'), matching: find.byType(Container)).first);
    expect((highlight.decoration! as BoxDecoration).color,
        const Color(0xFF12372B));
  });
}
