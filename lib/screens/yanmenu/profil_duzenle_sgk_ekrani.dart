import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sgk_port/sgk_app_colors.dart';
import '../sgk_port/sgk_port_models.dart';

const String _prefAvatarUrl = 'yan_menu_avatar_url';

/// sgk_app [EditProfileScreen] ile aynı düzen; veriler SharedPreferences + Firebase ile kalır.
String dicebearAvatarUrl(String nickname) {
  final seed = nickname.isEmpty ? 'default' : Uri.encodeComponent(nickname);
  const base = 'https://api.dicebear.com/7.x/avataaars/png';
  final lower = nickname.toLowerCase().trim();
  const maleNames = {
    'hakan', 'mehmet', 'ali', 'mustafa', 'ahmet', 'emre', 'can', 'burak',
    'kaan', 'eren', 'barış', 'oğuz', 'oguz', 'cem', 'onur', 'serkan', 'volkan',
    'tolga', 'berk', 'alp', 'efe', 'kerem', 'umut', 'mert', 'yusuf', 'ibrahim',
    'osman', 'halil', 'süleyman', 'suleyman', 'fatih', 'engin', 'deniz', 'arda',
  };
  if (maleNames.contains(lower)) {
    return '$base?seed=$seed&facialHairProbability=100&top=shortCurly,shortFlat,shortRound,shortWaved,sides,theCaesar,theCaesarAndSidePart,dreads01,dreads02,frizzle';
  }
  return '$base?seed=$seed';
}

const String _avatarBase = 'https://api.dicebear.com/7.x/avataaars/png';
const String _avatarOpts =
    '&skinColor=edb98a,ffdbb4,f8d25c,fd9841&top=shortCurly,shortFlat,shortRound,bob,curly,longButNotTooLong,bigHair,bun,straight01,straight02,shaggy,miaWallace,turban,hijab';
const List<String> _avatarOptions = [
  '$_avatarBase?seed=avatar1$_avatarOpts',
  '$_avatarBase?seed=avatar2$_avatarOpts',
  '$_avatarBase?seed=avatar3$_avatarOpts',
  '$_avatarBase?seed=avatar4$_avatarOpts',
  '$_avatarBase?seed=avatar5$_avatarOpts',
  '$_avatarBase?seed=avatar6$_avatarOpts',
  '$_avatarBase?seed=avatar7$_avatarOpts',
  '$_avatarBase?seed=avatar8$_avatarOpts',
  '$_avatarBase?seed=avatar9$_avatarOpts',
  '$_avatarBase?seed=avatar10$_avatarOpts',
];

class ProfilDuzenleSgkEkrani extends StatefulWidget {
  final VoidCallback? onKaydedildi;

  const ProfilDuzenleSgkEkrani({super.key, this.onKaydedildi});

  @override
  State<ProfilDuzenleSgkEkrani> createState() => _ProfilDuzenleSgkEkraniState();
}

class _ProfilDuzenleSgkEkraniState extends State<ProfilDuzenleSgkEkrani> {
  late TextEditingController _nameController;
  late String _avatarUrl;
  late SgkProfileType _profileType;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _avatarUrl = dicebearAvatarUrl('');
    _profileType = SgkProfileType.employee;
    _yukle();
  }

  Future<void> _yukle() async {
    final p = await SharedPreferences.getInstance();
    final u = FirebaseAuth.instance.currentUser;
    final takma = p.getString('akisi_takma_ad');
    final tip = p.getString('akisi_profil_tipi');
    final kayitliAvatar = p.getString(_prefAvatarUrl);

    String ad = '';
    if (u?.displayName != null && u!.displayName!.trim().isNotEmpty) {
      ad = u.displayName!.trim();
    } else if (takma != null && takma.trim().isNotEmpty) {
      ad = takma.trim();
    } else if (u?.email != null) {
      ad = u!.email!.split('@').first;
    }

    SgkProfileType tipEnum = sgkProfileTypeFromAkisi(tip);
    if (tipEnum == SgkProfileType.beginner) tipEnum = SgkProfileType.employee;

    String avatar = kayitliAvatar ?? '';
    if (avatar.isEmpty) {
      avatar = u?.photoURL ?? dicebearAvatarUrl(ad);
    }

    if (!mounted) return;
    setState(() {
      _nameController.text = ad;
      _avatarUrl = avatar;
      _profileType = tipEnum == SgkProfileType.employer
          ? SgkProfileType.employer
          : SgkProfileType.employee;
      _yukleniyor = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    final name = _nameController.text.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString('akisi_takma_ad', name);
    await p.setString(
      'akisi_profil_tipi',
      _profileType == SgkProfileType.employer ? 'isveren' : 'calisan',
    );
    await p.setString(_prefAvatarUrl, _avatarUrl);

    final u = FirebaseAuth.instance.currentUser;
    if (u != null && name.isNotEmpty) {
      try {
        await u.updateDisplayName(name);
      } catch (_) {}
    }

    widget.onKaydedildi?.call();
    if (mounted) Navigator.of(context).maybePop(true);
  }

  void _openAvatarPicker() {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: darkMode ? SgkAppColors.slate900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Avatar Seç',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: darkMode ? Colors.white : SgkAppColors.slate800,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  final url = _avatarOptions[index];
                  final isSelected = _avatarUrl == url;
                  return InkWell(
                    onTap: () {
                      setState(() => _avatarUrl = url);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? SgkAppColors.navy
                              : (darkMode
                                  ? SgkAppColors.slate700
                                  : SgkAppColors.slate200),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: SgkAppColors.slate400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    if (_yukleniyor) {
      return Scaffold(
        backgroundColor:
            darkMode ? SgkAppColors.slate950 : SgkAppColors.gray,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: darkMode ? SgkAppColors.slate950 : SgkAppColors.gray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: darkMode
                          ? SgkAppColors.slate400
                          : SgkAppColors.slate600,
                    ),
                    label: Text(
                      'Geri Dön',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: darkMode
                            ? SgkAppColors.slate400
                            : SgkAppColors.slate600,
                      ),
                    ),
                  ),
                  Text(
                    'Profili Düzenle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: darkMode ? Colors.white : SgkAppColors.slate800,
                    ),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openAvatarPicker,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: darkMode
                                  ? SgkAppColors.slate800
                                  : Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              _avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: SgkAppColors.navy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Material(
                        color: darkMode
                            ? SgkAppColors.blue500
                            : SgkAppColors.navy,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _openAvatarPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.camera_alt_rounded,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'KULLANICI ADI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: darkMode
                      ? SgkAppColors.slate500
                      : SgkAppColors.slate400,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Kullanıcı adınızı girin...',
                  filled: true,
                  fillColor:
                      darkMode ? SgkAppColors.slate800 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: darkMode
                          ? SgkAppColors.slate700
                          : SgkAppColors.slate100,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: darkMode ? Colors.white : SgkAppColors.slate800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PROFİL TİPİ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: darkMode
                      ? SgkAppColors.slate500
                      : SgkAppColors.slate400,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _profileTypeOption(
                SgkProfileType.employee,
                'Çalışan',
                Icons.person_rounded,
                SgkAppColors.green,
                darkMode,
              ),
              const SizedBox(height: 12),
              _profileTypeOption(
                SgkProfileType.employer,
                'İşveren / İK',
                Icons.business_center_rounded,
                SgkAppColors.navy,
                darkMode,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _kaydet,
                  icon: const Icon(Icons.save_rounded, size: 22),
                  label: const Text(
                    'Değişiklikleri Kaydet',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkMode
                        ? SgkAppColors.blue500
                        : SgkAppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTypeOption(
    SgkProfileType type,
    String label,
    IconData icon,
    Color color,
    bool darkMode,
  ) {
    final isSelected = _profileType == type;
    return Material(
      color: isSelected
          ? (darkMode ? SgkAppColors.slate800 : Colors.white)
          : (darkMode ? SgkAppColors.slate900 : SgkAppColors.slate50),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _profileType = type),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : (darkMode
                      ? SgkAppColors.slate700
                      : SgkAppColors.slate100),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? color
                    : (darkMode
                        ? SgkAppColors.slate600
                        : SgkAppColors.slate400),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: darkMode
                      ? SgkAppColors.slate200
                      : SgkAppColors.slate800,
                ),
              ),
              const Spacer(),
              if (isSelected) Icon(Icons.check_rounded, size: 22, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
