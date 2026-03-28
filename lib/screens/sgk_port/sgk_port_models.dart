// sgk_app lib/models.dart + initialBadges / AppLevels — yalnızca port ekranları için.

enum SgkProfileType {
  employee,
  employer,
  beginner,
}

SgkProfileType sgkProfileTypeFromAkisi(String? raw) {
  switch (raw) {
    case 'isveren':
      return SgkProfileType.employer;
    case 'calisan':
      return SgkProfileType.employee;
    default:
      return SgkProfileType.beginner;
  }
}

class SgkUserBadge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool unlocked;

  const SgkUserBadge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.unlocked,
  });

  SgkUserBadge copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    bool? unlocked,
  }) {
    return SgkUserBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

/// sgk [initialBadges]
List<SgkUserBadge> sgkInitialBadges() => const [
      SgkUserBadge(
        id: '1',
        name: 'Yolculuk Başladı',
        icon: '🚀',
        description: 'HakkimVar dünyasına ilk adımını attın!',
        unlocked: true,
      ),
      SgkUserBadge(
        id: '2',
        name: 'Hesap Uzmanı',
        icon: '🧮',
        description: 'İlk hesaplamanı başarıyla tamamladın.',
        unlocked: false,
      ),
      SgkUserBadge(
        id: '3',
        name: 'Hak Dedektifi',
        icon: '🔍',
        description: 'Mevzuat kütüphanesinde 5 madde okudun.',
        unlocked: false,
      ),
      SgkUserBadge(
        id: '4',
        name: 'Hak AI Dostu',
        icon: '🤖',
        description: 'Yapay zeka asistanınla ilk sohbetini ettin.',
        unlocked: false,
      ),
    ];

class SgkAppLevels {
  static const Map<SgkProfileType, List<String>> levels = {
    SgkProfileType.employee: [
      'Stajyer',
      'Uzman Yardımcısı',
      'Uzman',
      'Kıdemli Uzman',
      'Müdür',
      'Genel Müdür',
      'Emekli Kahraman',
    ],
    SgkProfileType.employer: [
      'Acemi Patron',
      'Bilinçli İşveren',
      'Deneyimli Yönetici',
      'Güvenilir Patron',
      'Örnek İşveren',
    ],
    SgkProfileType.beginner: [
      'Meraklı Aday',
      'İş Hayatına Giriş',
      'Haklarını Bilen Çalışan',
      'Deneyimli Çalışan',
    ],
  };

  static String getLevelName(SgkProfileType profileType, int level) {
    final levelList = levels[profileType] ?? levels[SgkProfileType.beginner]!;
    final index = (level - 1).clamp(0, levelList.length - 1);
    return levelList[index];
  }
}

class SgkUserStats {
  final int xp;
  final int level;
  final String levelName;
  final List<SgkUserBadge> badges;

  const SgkUserStats({
    required this.xp,
    required this.level,
    required this.levelName,
    required this.badges,
  });

  SgkUserStats copyWith({
    int? xp,
    int? level,
    String? levelName,
    List<SgkUserBadge>? badges,
  }) {
    return SgkUserStats(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelName: levelName ?? this.levelName,
      badges: badges ?? this.badges,
    );
  }
}

class SgkCommunityAnswer {
  final String id;
  final String author;
  final String content;
  final String timestamp;
  final int upvotes;
  final bool isExpert;
  final bool isHakApproved;

  const SgkCommunityAnswer({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.upvotes,
    this.isExpert = false,
    this.isHakApproved = false,
  });
}

class SgkCommunityQuestion {
  final String id;
  final String author;
  final String title;
  final String content;
  final String category;
  final String timestamp;
  final int upvotes;
  final List<SgkCommunityAnswer> answers;

  const SgkCommunityQuestion({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.category,
    required this.timestamp,
    required this.upvotes,
    required this.answers,
  });
}
