import 'package:flutter/material.dart';

import '../sgk_port/sgk_app_colors.dart';
import '../../utils/analytics_helper.dart';

/// sgk_app [MyRightsScreen] ile aynı içerik ve düzen.
class HaklarimEkrani extends StatefulWidget {
  const HaklarimEkrani({super.key});

  @override
  State<HaklarimEkrani> createState() => _HaklarimEkraniState();
}

class _HaklarimEkraniState extends State<HaklarimEkrani> {
  static const List<Map<String, dynamic>> rights = [
    {
      'name': 'Yıllık Ücretli İzin',
      'desc': '1 yıl dolduğunda 14 gün izin hakkın başlar.',
      'status': 'earned',
      'icon': Icons.flight_takeoff_rounded,
    },
    {
      'name': 'Kıdem Tazminatı',
      'desc': '1 yıl dolduğunda işten çıkarılma halinde ödenir.',
      'status': 'earned',
      'icon': Icons.monetization_on_rounded,
    },
    {
      'name': 'İhbar Tazminatı',
      'desc': 'Belirsiz süreli sözleşmelerde fesih bildirimi hakkı.',
      'status': 'earned',
      'icon': Icons.schedule_rounded,
    },
    {
      'name': 'Haftalık İzin',
      'desc': '7 günlük zaman diliminde en az 24 saat kesintisiz dinlenme.',
      'status': 'earned',
      'icon': Icons.calendar_today_rounded,
    },
    {
      'name': 'Süt İzni',
      'desc': 'Çocuğun 1 yaşına gelene kadar günde 1.5 saat.',
      'status': 'locked',
      'daysLeft': 0,
      'icon': Icons.child_care_rounded,
    },
    {
      'name': 'Yemek & Yol Yardımı',
      'desc': 'Sözleşmede varsa nakdi veya ayni olarak ödenir.',
      'status': 'earned',
      'icon': Icons.restaurant_rounded,
    },
    {
      'name': 'İş Sağlığı Eğitimi',
      'desc': 'İşveren tarafından verilmesi zorunlu eğitimler.',
      'status': 'locked',
      'daysLeft': 15,
      'icon': Icons.medical_services_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logScreenOpen('haklarim_opened');
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final earned = rights.where((r) => r['status'] == 'earned').toList();
    final locked = rights.where((r) => r['status'] == 'locked').toList();

    return Scaffold(
      backgroundColor: darkMode ? SgkAppColors.slate950 : SgkAppColors.gray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: darkMode
                          ? SgkAppColors.slate400
                          : SgkAppColors.slate600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Haklarım',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: darkMode ? Colors.white : SgkAppColors.slate800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SgkAppColors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded,
                        color: SgkAppColors.green, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkMode ? SgkAppColors.slate800 : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: darkMode
                        ? SgkAppColors.slate700
                        : SgkAppColors.slate100,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: SgkAppColors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          size: 32, color: SgkAppColors.green),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Güvendesin!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color:
                            darkMode ? Colors.white : SgkAppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Şu ana kadar ',
                        style: TextStyle(
                          fontSize: 12,
                          color: darkMode
                              ? SgkAppColors.slate400
                              : SgkAppColors.slate500,
                        ),
                        children: [
                          TextSpan(
                            text: '${earned.length} yasal hakkın',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: SgkAppColors.green,
                            ),
                          ),
                          const TextSpan(text: ' aktifleşti.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'KAZANILMIŞ HAKLAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: darkMode
                      ? SgkAppColors.slate500
                      : SgkAppColors.slate400,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              ...earned.map((r) => _rightCard(r, darkMode, earned: true)),
              const SizedBox(height: 24),
              Text(
                'BEKLEYEN HAKLAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: darkMode
                      ? SgkAppColors.slate500
                      : SgkAppColors.slate400,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              ...locked.map((r) => _rightCard(r, darkMode, earned: false)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SgkAppColors.blue500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: SgkAppColors.blue500.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: SgkAppColors.blue500, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hakların, işe giriş tarihin ve çalışma sürene göre otomatik hesaplanır. Bir yanlışlık olduğunu düşünüyorsan Hak AI\'ya sorabilirsin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: darkMode
                              ? SgkAppColors.blue200
                              : SgkAppColors.blue800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rightCard(
    Map<String, dynamic> r,
    bool darkMode, {
    required bool earned,
  }) {
    final daysLeft = r['daysLeft'] as int?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: earned
              ? (darkMode ? SgkAppColors.slate800 : Colors.white)
              : (darkMode ? SgkAppColors.slate900 : SgkAppColors.slate50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: earned
                ? (darkMode ? SgkAppColors.slate700 : SgkAppColors.slate100)
                : (darkMode ? SgkAppColors.slate800 : SgkAppColors.slate200),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: earned
                    ? SgkAppColors.green.withOpacity(0.2)
                    : (darkMode ? SgkAppColors.slate800 : SgkAppColors.slate200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                r['icon'] as IconData,
                size: 22,
                color: earned
                    ? SgkAppColors.green
                    : (darkMode
                        ? SgkAppColors.slate400
                        : SgkAppColors.slate500),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['name'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: earned
                          ? (darkMode ? Colors.white : SgkAppColors.slate800)
                          : (darkMode
                              ? SgkAppColors.slate500
                              : SgkAppColors.slate400),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r['desc'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: earned
                          ? (darkMode
                              ? SgkAppColors.slate400
                              : SgkAppColors.slate500)
                          : (darkMode
                              ? SgkAppColors.slate600
                              : SgkAppColors.slate400),
                    ),
                  ),
                ],
              ),
            ),
            if (earned)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: SgkAppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 18, color: SgkAppColors.slate300),
                  if (daysLeft != null && daysLeft > 0)
                    Text(
                      '$daysLeft GÜN KALDI',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: SgkAppColors.blue500,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
