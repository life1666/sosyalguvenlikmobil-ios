/// API / asset JSON ile uyumlu referans ekranı içeriği (sgk_app şemasına yakın).
class ReferralIcerikModel {
  final String? heroImageUrl;
  final String title;
  final String subtitle;
  final List<ReferralAdimModel> steps;

  const ReferralIcerikModel({
    this.heroImageUrl,
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  factory ReferralIcerikModel.fromJson(Map<String, dynamic> j) {
    final hero = j['heroImageUrl'] as String? ??
        j['hero_image_url'] as String? ??
        j['gorselHero'] as String? ??
        j['gorsel_hero'] as String?;

    final title = (j['title'] as String?) ??
        (j['baslik'] as String?) ??
        'Arkadaşını davet et';

    final subtitle = (j['subtitle'] as String?) ??
        (j['aciklama'] as String?) ??
        '';

    final rawSteps = j['steps'] ?? j['adimlar'] ?? [];
    final list = <ReferralAdimModel>[];
    if (rawSteps is List) {
      for (final e in rawSteps) {
        if (e is Map<String, dynamic>) {
          list.add(ReferralAdimModel.fromJson(e));
        } else if (e is Map) {
          list.add(ReferralAdimModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return ReferralIcerikModel(
      heroImageUrl: hero?.trim().isEmpty == true ? null : hero?.trim(),
      title: title,
      subtitle: subtitle,
      steps: list,
    );
  }

  static ReferralIcerikModel bosVarsayilan() {
    return const ReferralIcerikModel(
      title: 'Arkadaşını davet et',
      subtitle: 'Referans kodunu paylaşarak arkadaşlarını uygulamaya davet et.',
      steps: [],
    );
  }

  /// API kısmi döndürdüğünde (ör. yalnızca görseller) yerel ile birleştirir.
  ReferralIcerikModel birlestir(ReferralIcerikModel? yerel) {
    if (yerel == null) return this;
    return ReferralIcerikModel(
      heroImageUrl: heroImageUrl ?? yerel.heroImageUrl,
      title: title.isNotEmpty ? title : yerel.title,
      subtitle: subtitle.isNotEmpty ? subtitle : yerel.subtitle,
      steps: steps.isNotEmpty ? steps : yerel.steps,
    );
  }
}

class ReferralAdimModel {
  final String? iconUrl;
  final String title;
  final String subtitle;

  const ReferralAdimModel({
    this.iconUrl,
    required this.title,
    this.subtitle = '',
  });

  factory ReferralAdimModel.fromJson(Map<String, dynamic> j) {
    final icon = j['iconUrl'] as String? ??
        j['icon_url'] as String? ??
        j['ikonUrl'] as String? ??
        j['gorselUrl'] as String?;

    final title = (j['title'] as String?) ??
        (j['baslik'] as String?) ??
        '';

    final subtitle = (j['subtitle'] as String?) ??
        (j['aciklama'] as String?) ??
        '';

    return ReferralAdimModel(
      iconUrl: icon?.trim().isEmpty == true ? null : icon?.trim(),
      title: title,
      subtitle: subtitle,
    );
  }
}
