import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:src/services/account_scoped_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mesai ve bildirimler hesaplar arasında görünmez', () async {
    const mesai = 'mesai_takip_v1';
    const bildirim = 'personal_notification_preferences';
    final hakan = AccountScopedLocalStore(uidProvider: () => 'hakan');
    final diger = AccountScopedLocalStore(uidProvider: () => 'diger');
    final misafir = AccountScopedLocalStore(uidProvider: () => null);

    await hakan.write(mesai, '{"saat":8}');
    await hakan.write(bildirim, '{"izin":false}');
    expect(await diger.read(mesai), isNull);
    expect(await diger.read(bildirim), isNull);
    expect(await misafir.read(mesai), isNull);
    expect(await misafir.read(bildirim), isNull);
    expect(await hakan.read(mesai), '{"saat":8}');
    expect(await hakan.read(bildirim), '{"izin":false}');
  });

  test('eski ortak kayıt belirsiz hesaba atanmaz', () async {
    SharedPreferences.setMockInitialValues({'mesai_takip_v1': 'eski kayit'});
    final store = AccountScopedLocalStore(uidProvider: () => 'yeni');
    expect(await store.read('mesai_takip_v1'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mesai_takip_v1'), 'eski kayit');
  });

  test('hesap silinince yalnız o hesabın kayıtları silinir', () async {
    final a = AccountScopedLocalStore(uidProvider: () => 'a');
    final b = AccountScopedLocalStore(uidProvider: () => 'b');
    await a.write('mesai_takip_v1', 'a verisi');
    await b.write('mesai_takip_v1', 'b verisi');
    await a.removeForUid('mesai_takip_v1', 'a');
    expect(await a.read('mesai_takip_v1'), isNull);
    expect(await b.read('mesai_takip_v1'), 'b verisi');
  });
}
