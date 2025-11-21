import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// =====================
///  SON HESAPLAMA MODELİ
/// =====================
class SonHesaplama {
  final String id; // Benzersiz ID
  final String hesaplamaTuru; // Örn: "4/a (SSK) Emeklilik", "Brütten Nete Maaş", vb.
  final DateTime tarihSaat;
  final Map<String, dynamic> veriler; // Hesaplama verileri (JSON serializable)
  final Map<String, String> sonuclar; // Hesaplama sonuçları (gösterim için)
  final String? ozet; // Kısa özet metni (opsiyonel)

  SonHesaplama({
    required this.id,
    required this.hesaplamaTuru,
    required this.tarihSaat,
    required this.veriler,
    required this.sonuclar,
    this.ozet,
  });

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hesaplamaTuru': hesaplamaTuru,
      'tarihSaat': tarihSaat.toIso8601String(),
      'veriler': veriler,
      'sonuclar': sonuclar,
      'ozet': ozet,
    };
  }

  // JSON'dan oluşturma
  factory SonHesaplama.fromJson(Map<String, dynamic> json) {
    return SonHesaplama(
      id: json['id'] as String,
      hesaplamaTuru: json['hesaplamaTuru'] as String,
      tarihSaat: DateTime.parse(json['tarihSaat'] as String),
      veriler: Map<String, dynamic>.from(json['veriler'] as Map),
      sonuclar: Map<String, String>.from(json['sonuclar'] as Map),
      ozet: json['ozet'] as String?,
    );
  }
}

/// ==================================================
///  SON HESAPLAMALAR DEPOSU (SharedPreferences ile kalıcı)
/// ==================================================
class SonHesaplamalarDeposu {
  static const String _key = 'son_hesaplamalar';
  static const int _maxKayit = 15;

  /// Yeni hesaplama ekle (en fazla 15 kayıt, en eskiden silinir)
  static Future<void> ekle(SonHesaplama hesaplama) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mevcutListe = await listele();
      
      // Yeni kaydı en başa ekle
      mevcutListe.insert(0, hesaplama);
      
      // En fazla 15 kayıt tut
      if (mevcutListe.length > _maxKayit) {
        mevcutListe.removeRange(_maxKayit, mevcutListe.length);
      }
      
      // JSON'a dönüştür ve kaydet
      final jsonList = mevcutListe.map((h) => h.toJson()).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Son hesaplama eklenirken hata: $e');
    }
  }

  /// Tüm hesaplamaları listele (en yeni en başta)
  static Future<List<SonHesaplama>> listele() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => SonHesaplama.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Son hesaplamalar listelenirken hata: $e');
      return [];
    }
  }

  /// Belirli bir hesaplamayı sil
  static Future<void> sil(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mevcutListe = await listele();
      
      mevcutListe.removeWhere((h) => h.id == id);
      
      final jsonList = mevcutListe.map((h) => h.toJson()).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Son hesaplama silinirken hata: $e');
    }
  }

  /// Tüm hesaplamaları sil
  static Future<void> tumunuSil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Tüm son hesaplamalar silinirken hata: $e');
    }
  }
}

/// ==================================================
///  SON HESAPLAMALAR EKRANI
/// ==================================================
class SonHesaplamalarEkrani extends StatefulWidget {
  const SonHesaplamalarEkrani({super.key});

  @override
  State<SonHesaplamalarEkrani> createState() => _SonHesaplamalarEkraniState();
}

class _SonHesaplamalarEkraniState extends State<SonHesaplamalarEkrani> {
  List<SonHesaplama> _hesaplamalar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    final liste = await SonHesaplamalarDeposu.listele();
    if (mounted) {
      setState(() {
        _hesaplamalar = liste;
        _yukleniyor = false;
      });
    }
  }

  Future<void> _sil(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesaplamayı Sil'),
        content: const Text('Bu hesaplamayı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SonHesaplamalarDeposu.sil(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesaplama silindi')),
        );
        _yukle();
      }
    }
  }

  void _detayGoster(SonHesaplama hesaplama) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      hesaplama.hesaplamaTuru,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatTarih(hesaplama.tarihSaat),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Divider(height: 32),
              
              // Sonuçlar
              if (hesaplama.sonuclar.isNotEmpty) ...[
                const Text(
                  'Hesaplama Sonuçları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...hesaplama.sonuclar.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 32),
              ],
              
              // Özet
              if (hesaplama.ozet != null && hesaplama.ozet!.isNotEmpty) ...[
                const Text(
                  'Özet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hesaplama.ozet!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTarih(DateTime tarih) {
    final now = DateTime.now();
    final fark = now.difference(tarih);
    
    if (fark.inDays == 0) {
      if (fark.inHours == 0) {
        if (fark.inMinutes == 0) {
          return 'Az önce';
        }
        return '${fark.inMinutes} dakika önce';
      }
      return '${fark.inHours} saat önce';
    } else if (fark.inDays == 1) {
      return 'Dün';
    } else if (fark.inDays < 7) {
      return '${fark.inDays} gün önce';
    } else {
      return '${tarih.day}.${tarih.month}.${tarih.year} ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Son Hesaplamalar',
          style: TextStyle(
            color: Colors.indigo,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (_hesaplamalar.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.indigo),
              tooltip: 'Tümünü Sil',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tümünü Sil'),
                    content: const Text('Tüm hesaplamaları silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Tümünü Sil'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await SonHesaplamalarDeposu.tumunuSil();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tüm hesaplamalar silindi')),
                    );
                    _yukle();
                  }
                }
              },
            ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _hesaplamalar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz hesaplama yapılmamış',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hesaplamalar bölümünden yeni hesaplamalar yapabilirsiniz',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _yukle,
                  color: Colors.indigo,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _hesaplamalar.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final hesaplama = _hesaplamalar[index];
                      return Material(
                        color: Colors.white,
                        elevation: 1,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _detayGoster(hesaplama),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calculate_rounded,
                                    color: Colors.indigo,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hesaplama.hesaplamaTuru,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTarih(hesaplama.tarihSaat),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (hesaplama.sonuclar.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          hesaplama.sonuclar.entries.first.value,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _sil(hesaplama.id),
                                  tooltip: 'Sil',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}






