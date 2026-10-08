import 'package:flutter_test/flutter_test.dart';
import 'package:src/utils/personal_profile.dart';

void main() {
  final today = DateTime(2026, 9, 22);

  test('sigorta girişi çocuk yaşta olamaz', () {
    expect(
      PersonalProfile.validateRetirementInputs(
        birthDate: DateTime(1990, 1, 1),
        insuranceStartDate: DateTime(1995, 1, 1),
        premiumDays: 100,
        referenceDate: today,
      ),
      contains('15 yaşında'),
    );
  });

  test('sigorta süresinden fazla prim günü kabul edilmez', () {
    expect(
      PersonalProfile.validateRetirementInputs(
        birthDate: DateTime(1990, 1, 1),
        insuranceStartDate: DateTime(2025, 9, 22),
        premiumDays: 9000,
        referenceDate: today,
      ),
      contains('aşamaz'),
    );
  });

  test('prim referans tarihi yalnız gün değişince yenilenir', () {
    final earlier = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    final existing = <String, dynamic>{
      'toplamPrimGun': 3000,
      'primGunuReferansTarihi': earlier,
    };
    final unchanged = PersonalProfile.merge(
      existing,
      {'toplamPrimGun': 3000},
      today,
    );
    final changed = PersonalProfile.merge(
      existing,
      {'toplamPrimGun': 3001},
      today,
    );

    expect(unchanged['primGunuReferansTarihi'], earlier);
    expect(changed['primGunuReferansTarihi'], today.millisecondsSinceEpoch);
  });
}
