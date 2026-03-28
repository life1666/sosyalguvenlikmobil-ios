import 'package:flutter/material.dart';

import 'akisi/akisi_renkleri.dart';

/// sgk_app [MainApp._buildHomePage] ile aynı yapı (açık tema).
class AnaSayfaSgkIcerik extends StatelessWidget {
  final String selamIsim;
  final bool isverenProfili;
  final String isletmeAdi;
  final bool calisanEksikVeri;
  final bool isverenEksikVeri;
  final String seviyeAdi;
  final int xp;
  final int level;
  final VoidCallback onDuzenle;
  final VoidCallback onBildirim;
  final void Function(bool isveren, int aracIndex) onHizliArac;

  const AnaSayfaSgkIcerik({
    super.key,
    required this.selamIsim,
    required this.isverenProfili,
    this.isletmeAdi = '',
    this.calisanEksikVeri = false,
    this.isverenEksikVeri = false,
    this.seviyeAdi = 'Yeni Üye',
    this.xp = 0,
    this.level = 1,
    required this.onDuzenle,
    required this.onBildirim,
    required this.onHizliArac,
  });

  static const List<Map<String, dynamic>> _hedefler = [
    {'title': 'Profilini tamamla', 'xp': 50, 'done': false},
    {'title': 'İlk hesaplamayı yap', 'xp': 100, 'done': false},
    {'title': 'Hak AI ile sohbet et', 'xp': 30, 'done': false},
    {'title': 'Toplulukta soru sor', 'xp': 80, 'done': false},
  ];

  static final List<(String, IconData, Color)> _araclarCalisan = [
    ('Kıdem Tazminatı', Icons.trending_up_rounded, AkisiRenkleri.green),
    ('Emeklilik Hesaplama', Icons.calendar_today_rounded, AkisiRenkleri.navy),
    ('İhbar Tazminatı', Icons.schedule_rounded, AkisiRenkleri.amber),
    ('Rapor Parası', Icons.medical_services_rounded, const Color(0xFFE11D48)),
  ];

  static final List<(String, IconData, Color)> _araclarIsveren = [
    ('Çalışan Yönetimi', Icons.people_rounded, AkisiRenkleri.navy),
    ('Bordro Merkezi', Icons.payments_rounded, AkisiRenkleri.green),
    ('Yasal Takvim', Icons.calendar_month_rounded, AkisiRenkleri.amber),
    ('İşletme İstatistikleri', Icons.bar_chart_rounded,
        const Color(0xFF4F46E5)),
  ];

  Widget _hizliAracHucre((String, IconData, Color) t, VoidCallback onTap) {
    final tool = t.$1;
    final icon = t.$2;
    final color = t.$3;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AkisiRenkleri.slate100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            Text(
              tool,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AkisiRenkleri.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCalisan = !isverenProfili;
    final isIsveren = isverenProfili;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selam, $selamIsim! 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AkisiRenkleri.slate800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isIsveren
                        ? (isletmeAdi.isEmpty
                            ? 'İşletme yönetim paneline hoş geldin.'
                            : isletmeAdi)
                        : 'Çalışma hayatı asistanın seninle.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AkisiRenkleri.slate500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: onDuzenle,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AkisiRenkleri.slate100),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 24,
                        color: AkisiRenkleri.blue600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: onBildirim,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AkisiRenkleri.slate100),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            size: 24,
                            color: AkisiRenkleri.slate600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isCalisan && calisanEksikVeri) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AkisiRenkleri.blue500.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 48, color: Colors.white.withOpacity(0.2)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hadi Başlayalım!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hesaplamaların ve hak takibinin doğru çalışması için çalışma bilgilerini girmelisin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onDuzenle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AkisiRenkleri.blue600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Bilgilerimi Gir (+150 XP)',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (isIsveren && isverenEksikVeri) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: Icon(Icons.business_rounded,
                      size: 48, color: Colors.white.withOpacity(0.2)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İşletmeni Tanımla',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Maliyet analizleri ve yasal takvim takibi için işletme bilgilerini girmelisin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onDuzenle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'İşletme Bilgilerini Gir (+150 XP)',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AkisiRenkleri.slate100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIsveren ? 'İŞLETME SAĞLIK SKORU' : 'MEVCUT SEVİYE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AkisiRenkleri.slate400,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isIsveren
                            ? (isverenEksikVeri
                                ? 'Yeni İşletme'
                                : 'Güvenilir İşveren')
                            : seviyeAdi,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AkisiRenkleri.navy,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isIsveren
                        ? (isverenEksikVeri ? '%0 Uyum' : '%85 Uyum')
                        : '$xp / ${level * 500} XP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AkisiRenkleri.slate600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: isIsveren
                      ? (isverenEksikVeri ? 0.0 : 0.85)
                      : (xp % 500) / 500,
                  minHeight: 12,
                  backgroundColor: AkisiRenkleri.slate200,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AkisiRenkleri.green),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Hızlı Araçlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AkisiRenkleri.slate800,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            for (var i = 0;
                i <
                    (isCalisan
                        ? _araclarCalisan.length
                        : _araclarIsveren.length);
                i++)
              _hizliAracHucre(
                isCalisan ? _araclarCalisan[i] : _araclarIsveren[i],
                () => onHizliArac(isverenProfili, i),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'BAŞARILAR',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AkisiRenkleri.slate400,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AkisiRenkleri.slate100),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _hedefler.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AkisiRenkleri.slate100),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hedefler[i]['done'] == true
                              ? AkisiRenkleri.amber
                              : Colors.transparent,
                          border: Border.all(
                            color: _hedefler[i]['done'] == true
                                ? AkisiRenkleri.amber
                                : AkisiRenkleri.amber300,
                            width: 2,
                          ),
                        ),
                        child: _hedefler[i]['done'] == true
                            ? const Icon(Icons.check_rounded,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _hedefler[i]['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _hedefler[i]['done'] == true
                                ? AkisiRenkleri.slate400
                                : AkisiRenkleri.amber900,
                            decoration: _hedefler[i]['done'] == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '+${_hedefler[i]['xp']} XP',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AkisiRenkleri.amber600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
