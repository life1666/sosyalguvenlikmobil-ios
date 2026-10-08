import 'dart:convert';

import 'personal_profile_store.dart';
import 'premium_trial_service.dart';
import 'premium_entitlement_service.dart';

class PremiumAccessStatus {
  const PremiumAccessStatus({required this.hasProfile, required this.trial,
    required this.entitlement});

  final bool hasProfile;
  final PremiumTrialStatus trial;
  final PremiumEntitlement entitlement;

  bool get hasPremium => trial.phase == PremiumTrialPhase.active || entitlement.active;

  bool get canUsePersonalFeatures =>
      hasProfile && hasPremium;
}

/// Çalışma verileri yalnızca cihazda kalır; sunucudan erişim durumu okunur.
class PremiumAccessService {
  PremiumAccessService({PremiumTrialService? trialService,
      PersonalProfileStore? profileStore,
      PremiumEntitlementService? entitlementService})
      : _trialService = trialService,
        _profileStore = profileStore ?? PersonalProfileStore(),
        _entitlementService = entitlementService;

  final PremiumTrialService? _trialService;
  final PersonalProfileStore _profileStore;
  final PremiumEntitlementService? _entitlementService;

  Future<bool> hasProfile() async {
    final raw = await _profileStore.readRaw();
    if (raw == null || raw.isEmpty) return false;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return (data['adSoyad'] as String?)?.trim().isNotEmpty == true &&
          data['dogumTarihi'] is int &&
          data['ilkIseGirisTarihi'] is int &&
          int.tryParse('${data['toplamPrimGun']}') != null &&
          (data['cinsiyet'] as String?)?.isNotEmpty == true &&
          (data['sigortaKolu'] as String?)?.isNotEmpty == true;
    } catch (_) {
      return false;
    }
  }

  Future<PremiumAccessStatus> load() async {
    final profile = await hasProfile();
    PremiumTrialStatus trial;
    try {
      trial = await (_trialService ?? PremiumTrialService()).load();
    } catch (_) {
      // A trial lookup failure must not hide an independently valid purchase.
      // Trial access itself remains closed until its server check succeeds.
      trial = const PremiumTrialStatus(PremiumTrialPhase.expired);
    }
    PremiumEntitlement entitlement;
    try {
      entitlement = await (_entitlementService ?? PremiumEntitlementService()).load();
    } catch (_) {
      // A missing or offline verification service must never grant paid access.
      entitlement = const PremiumEntitlement(active: false);
    }
    return PremiumAccessStatus(
        hasProfile: profile, trial: trial, entitlement: entitlement);
  }
}
