import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MevzuatSayfasi extends StatelessWidget {
  const MevzuatSayfasi({super.key});

  // Çalışma hayatına dair kanunlar ve yönetmelikler
  static const List<Map<String, dynamic>> mevzuatListesi = [
    {
      'baslik': '4857 sayılı İş Kanunu',
      'aciklama': 'İş ilişkileri, çalışma süreleri, izin hakları ve işçi hakları',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=4857&MevzuatTur=1&MevzuatTertip=5',
      'kategori': 'Kanun',
      'icon': Icons.gavel,
    },
    {
      'baslik': '6331 sayılı İş Sağlığı ve Güvenliği Kanunu',
      'aciklama': 'İşyerlerinde sağlık ve güvenlik önlemleri',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=6331&MevzuatTur=1&MevzuatTertip=5',
      'kategori': 'Kanun',
      'icon': Icons.health_and_safety,
    },
    {
      'baslik': '5510 sayılı Sosyal Sigortalar ve Genel Sağlık Sigortası Kanunu',
      'aciklama': 'Sosyal güvenlik hakları ve yükümlülükleri',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=5510&MevzuatTur=1&MevzuatTertip=5',
      'kategori': 'Kanun',
      'icon': Icons.verified_user,
    },
    {
      'baslik': '6098 sayılı Türk Borçlar Kanunu',
      'aciklama': 'İş sözleşmeleri ve borçlar hukuku',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=6098&MevzuatTur=1&MevzuatTertip=5',
      'kategori': 'Kanun',
      'icon': Icons.description,
    },
    {
      'baslik': '1475 sayılı İş Kanunu',
      'aciklama': 'Eski İş Kanunu (kıdem tazminatı hükümleri geçerlidir)',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=1475&MevzuatTur=1&MevzuatTertip=5',
      'kategori': 'Kanun',
      'icon': Icons.history,
    },
    {
      'baslik': 'Yıllık Ücretli İzin Yönetmeliği',
      'aciklama': 'Yıllık izin hakları ve kullanımı',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=5451&MevzuatTur=7&MevzuatTertip=5',
      'kategori': 'Yönetmelik',
      'icon': Icons.calendar_today,
    },
    {
      'baslik': 'Uzaktan Çalışma Yönetmeliği',
      'aciklama': 'Uzaktan çalışma düzenlemeleri',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=38393&MevzuatTur=7&MevzuatTertip=5',
      'kategori': 'Yönetmelik',
      'icon': Icons.home_work,
    },
    {
      'baslik': 'İş Sağlığı ve Güvenliği Hizmetleri Yönetmeliği',
      'aciklama': 'İşyeri güvenlik önlemleri ve yükümlülükler',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=16924&MevzuatTur=7&MevzuatTertip=5',
      'kategori': 'Yönetmelik',
      'icon': Icons.shield,
    },
    {
      'baslik': 'İş Kanununa İlişkin Fazla Çalışma ve Fazla Sürelerle Çalışma Yönetmeliği',
      'aciklama': 'Fazla mesai düzenlemeleri',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=6249&MevzuatTur=7&MevzuatTertip=5',
      'kategori': 'Yönetmelik',
      'icon': Icons.access_time,
    },
    {
      'baslik': 'İş Kanununa İlişkin Çalışma Süreleri Yönetmeliği',
      'aciklama': 'Çalışma süreleri ve düzenlemeleri',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=5447&MevzuatTur=7&MevzuatTertip=5',
      'kategori': 'Yönetmelik',
      'icon': Icons.rule,
    },
    {
      'baslik': 'İşyeri Hekimi ve Diğer Sağlık Personelinin Görev, Yetki, Sorumluluk ve Eğitimleri Hakkında Yönetmelik',
      'aciklama': 'İşyeri sağlık personeli görevleri',
      'link': 'https://www.mevzuat.gov.tr/mevzuat?MevzuatNo=18615&MevzuatTur=7&MevzuatTertip=5',
      'kategori': 'Yönetmelik',
      'icon': Icons.medical_services,
    },
  ];

  Future<void> _acLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Link açılamadı: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Mevzuat',
          style: TextStyle(
            color: Colors.indigo,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Bilgilendirme kartı
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.indigo.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.indigo[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Çalışma hayatına dair kanun ve yönetmeliklerin mevzuat.gov.tr linklerine buradan ulaşabilirsiniz.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste başlığı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Çalışma Hayatı Mevzuatı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // Mevzuat listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mevzuatListesi.length,
              itemBuilder: (context, index) {
                final mevzuat = mevzuatListesi[index];
                final isKanun = mevzuat['kategori'] == 'Kanun';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isKanun
                          ? Colors.red.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _acLink(mevzuat['link'] as String),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık ve kategori
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isKanun
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    mevzuat['kategori'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isKanun
                                          ? Colors.red[700]
                                          : Colors.blue[700],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.open_in_new,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // İkon ve başlık
                            Row(
                              children: [
                                Icon(
                                  mevzuat['icon'] as IconData,
                                  color: isKanun
                                      ? Colors.red[700]
                                      : Colors.blue[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    mevzuat['baslik'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Açıklama
                            Text(
                              mevzuat['aciklama'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

