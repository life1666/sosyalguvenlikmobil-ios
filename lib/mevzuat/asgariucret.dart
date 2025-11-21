import 'package:flutter/material.dart';

class AsgariUcretSayfasi extends StatelessWidget {
  const AsgariUcretSayfasi({super.key});

  // Tarih aralıklarına göre asgari ücret verileri
  static const List<Map<String, dynamic>> asgariUcretler = [
    // 2025
    {
      'tarihAraligi': '01.01.2025-31.12.2025',
      'gunluk': 866.85,
      'aylik': 26005.50,
      'aylikNet': 22104.67,
      'artisOrani': 30.0,
    },
    // 2024
    {
      'tarihAraligi': '01.01.2024-31.12.2024',
      'gunluk': 666.75,
      'aylik': 20002.50,
      'aylikNet': 17002.12,
      'artisOrani': 49.1,
    },
    // 2023
    {
      'tarihAraligi': '01.07.2023-31.12.2023',
      'gunluk': 500.25,
      'aylik': 13414.50,
      'aylikNet': 11402.32,
      'artisOrani': 34.0,
    },
    {
      'tarihAraligi': '01.01.2023-30.06.2023',
      'gunluk': 333.60,
      'aylik': 10008.00,
      'aylikNet': 8506.80,
      'artisOrani': 54.7,
    },
    // 2022
    {
      'tarihAraligi': '01.07.2022-31.12.2022',
      'gunluk': 250.20,
      'aylik': 6471.00,
      'aylikNet': 5500.35,
      'artisOrani': 29.3,
    },
    {
      'tarihAraligi': '01.01.2022-30.06.2022',
      'gunluk': 166.80,
      'aylik': 5004.00,
      'aylikNet': 4253.40,
      'artisOrani': 39.9,
    },
    // 2021
    {
      'tarihAraligi': '01.07.2021-31.12.2021',
      'gunluk': 130.50,
      'aylik': 3577.50,
      'aylikNet': 2557.59,
      'artisOrani': 21.6,
    },
    {
      'tarihAraligi': '01.01.2021-30.06.2021',
      'gunluk': 107.40,
      'aylik': 2943.00,
      'aylikNet': 2103.98,
      'artisOrani': 15.0,
    },
    // 2020
    {
      'tarihAraligi': '01.07.2020-31.12.2020',
      'gunluk': 93.30,
      'aylik': 2799.00,
      'aylikNet': 2685.00,
      'artisOrani': 26.1,
    },
    {
      'tarihAraligi': '01.01.2020-30.06.2020',
      'gunluk': 74.00,
      'aylik': 2220.00,
      'aylikNet': 2020.00,
      'artisOrani': 14.2,
    },
    // 2019
    {
      'tarihAraligi': '01.07.2019-31.12.2019',
      'gunluk': 64.80,
      'aylik': 2558.40,
      'aylikNet': 1829.03,
      'artisOrani': 7.9,
    },
    {
      'tarihAraligi': '01.01.2019-30.06.2019',
      'gunluk': 60.10,
      'aylik': 1803.00,
      'aylikNet': 1890.00,
      'artisOrani': 26.1,
    },
    // 2018
    {
      'tarihAraligi': '01.07.2018-31.12.2018',
      'gunluk': 55.80,
      'aylik': 1674.00,
      'aylikNet': 1603.00,
      'artisOrani': 6.1,
    },
    {
      'tarihAraligi': '01.01.2018-30.06.2018',
      'gunluk': 52.60,
      'aylik': 1578.00,
      'aylikNet': 1404.00,
      'artisOrani': 4.1,
    },
    // 2017
    {
      'tarihAraligi': '01.07.2017-31.12.2017',
      'gunluk': 50.50,
      'aylik': 1515.00,
      'aylikNet': 1404.00,
      'artisOrani': 4.1,
    },
    {
      'tarihAraligi': '01.01.2017-30.06.2017',
      'gunluk': 48.50,
      'aylik': 1455.00,
      'aylikNet': 1300.00,
      'artisOrani': 4.1,
    },
    // 2016
    {
      'tarihAraligi': '01.01.2016-31.12.2016',
      'gunluk': 54.90,
      'aylik': 1647.00,
      'aylikNet': 1300.00,
      'artisOrani': 29.3,
    },
    // 2015
    {
      'tarihAraligi': '01.07.2015-31.12.2015',
      'gunluk': 42.50,
      'aylik': 1275.00,
      'aylikNet': 1001.00,
      'artisOrani': 6.1,
    },
    {
      'tarihAraligi': '01.01.2015-30.06.2015',
      'gunluk': 40.05,
      'aylik': 1201.50,
      'aylikNet': 950.00,
      'artisOrani': 4.1,
    },
    // 2014
    {
      'tarihAraligi': '01.07.2014-31.12.2014',
      'gunluk': 38.45,
      'aylik': 1153.50,
      'aylikNet': 891.00,
      'artisOrani': 4.1,
    },
    {
      'tarihAraligi': '01.01.2014-30.06.2014',
      'gunluk': 36.90,
      'aylik': 1107.00,
      'aylikNet': 846.00,
      'artisOrani': 4.1,
    },
    // 2013
    {
      'tarihAraligi': '01.07.2013-31.12.2013',
      'gunluk': 35.40,
      'aylik': 1062.00,
      'aylikNet': 803.00,
      'artisOrani': 4.1,
    },
    {
      'tarihAraligi': '01.01.2013-30.06.2013',
      'gunluk': 34.00,
      'aylik': 1020.00,
      'aylikNet': 773.00,
      'artisOrani': 4.1,
    },
    // 2012
    {
      'tarihAraligi': '01.07.2012-31.12.2012',
      'gunluk': 31.35,
      'aylik': 940.50,
      'aylikNet': 701.00,
      'artisOrani': 6.1,
    },
    {
      'tarihAraligi': '01.01.2012-30.06.2012',
      'gunluk': 29.55,
      'aylik': 886.50,
      'aylikNet': 663.00,
      'artisOrani': 4.1,
    },
    // 2011
    {
      'tarihAraligi': '01.07.2011-31.12.2011',
      'gunluk': 27.90,
      'aylik': 837.00,
      'aylikNet': 623.00,
      'artisOrani': 5.1,
    },
    {
      'tarihAraligi': '01.01.2011-30.06.2011',
      'gunluk': 26.55,
      'aylik': 796.50,
      'aylikNet': 594.00,
      'artisOrani': 4.7,
    },
    // 2010
    {
      'tarihAraligi': '01.07.2010-31.12.2010',
      'gunluk': 25.35,
      'aylik': 760.50,
      'aylikNet': 567.00,
      'artisOrani': 4.3,
    },
    {
      'tarihAraligi': '01.01.2010-30.06.2010',
      'gunluk': 24.30,
      'aylik': 729.00,
      'aylikNet': 544.00,
      'artisOrani': 4.9,
    },
    // 2009
    {
      'tarihAraligi': '01.07.2009-31.12.2009',
      'gunluk': 23.10,
      'aylik': 693.00,
      'aylikNet': 517.00,
      'artisOrani': 4.1,
    },
    {
      'tarihAraligi': '01.01.2009-30.06.2009',
      'gunluk': 22.20,
      'aylik': 666.00,
      'aylikNet': 497.00,
      'artisOrani': 4.5,
    },
    // 2008
    {
      'tarihAraligi': '01.07.2008-31.12.2008',
      'gunluk': 21.29,
      'aylik': 638.70,
      'aylikNet': 476.00,
      'artisOrani': 5.0,
    },
    {
      'tarihAraligi': '01.01.2008-30.06.2008',
      'gunluk': 20.28,
      'aylik': 608.40,
      'aylikNet': 454.00,
      'artisOrani': 4.0,
    },
    // 2007
    {
      'tarihAraligi': '01.07.2007-31.12.2007',
      'gunluk': 19.50,
      'aylik': 585.00,
      'aylikNet': 436.00,
      'artisOrani': 4.0,
    },
    {
      'tarihAraligi': '01.01.2007-30.06.2007',
      'gunluk': 18.75,
      'aylik': 562.50,
      'aylikNet': 419.00,
      'artisOrani': 5.9,
    },
    // 2006
    {
      'tarihAraligi': '01.01.2006-31.12.2006',
      'gunluk': 17.70,
      'aylik': 531.00,
      'aylikNet': 396.00,
      'artisOrani': 8.7,
    },
    // 2005
    {
      'tarihAraligi': '01.01.2005-31.12.2005',
      'gunluk': 16.29,
      'aylik': 488.70,
      'aylikNet': 365.00,
      'artisOrani': null,
    },
  ];

  String _formatPara(double tutar) {
    return '${tutar.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} ₺';
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
          'Asgari Ücret',
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
                    'Asgari ücret tutarları yıllara göre listelenmiştir. '
                    'Güncel asgari ücret bilgileri için resmi kaynakları kontrol ediniz.',
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
                  'Tarih Aralıklarına Göre Asgari Ücret',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // Asgari ücret listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: asgariUcretler.length,
              itemBuilder: (context, index) {
                final veri = asgariUcretler[index];
                final isGuncel = index == 0; // En üstteki güncel
                final artisOrani = veri['artisOrani'] as double?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isGuncel
                        ? Colors.indigo.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isGuncel
                          ? Colors.indigo.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarih aralığı
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                veri['tarihAraligi'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isGuncel
                                      ? Colors.indigo[700]
                                      : Colors.grey[800],
                                ),
                              ),
                            ),
                            if (isGuncel) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Güncel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Aylık Brüt ve Aylık Net yan yana
                        Row(
                          children: [
                            Expanded(
                              child: _buildTutarKart(
                                label: 'Aylık (Brüt)',
                                tutar: veri['aylik'] as double,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTutarKart(
                                label: 'Aylık Net',
                                tutar: veri['aylikNet'] as double,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Günlük ve Artış oranı yan yana
                        Row(
                          children: [
                            Expanded(
                              child: _buildTutarKart(
                                label: 'Günlük',
                                tutar: veri['gunluk'] as double,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (artisOrani != null)
                              Expanded(
                                child: Container(
                                  height: 70, // Tutar kartları ile aynı yükseklik
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Artış Oranı: ${artisOrani.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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

  Widget _buildTutarKart({
    required String label,
    required double tutar,
    required Color color,
  }) {
    return Container(
      height: 70, // Artış oranı kutusu ile aynı yükseklik
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              _formatPara(tutar),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

