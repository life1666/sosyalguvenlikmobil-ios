import 'dart:math' as math;
import 'package:flutter/material.dart';

/// =================== SGK SÖZLÜK MODELİ ===================

@immutable
class SgkTerm {
  final String key;         // benzersiz anahtar (id)
  final String title;       // ekranda görünen başlık
  final String description; // açıklama
  final String category;    // kategori etiketi

  const SgkTerm({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
  });
}

const List<SgkTerm> sgkGlossary = [

  // 1
  SgkTerm(
    key: 'sosyal_guvenlik',
    title: 'Sosyal Güvenlik',
    description:
    'Çalışanları hastalık, yaşlılık, ölüm gibi risklere karşı koruyan sistem.',
    category: 'Genel',
  ),

  // 2
  SgkTerm(
    key: 'sgk',
    title: 'SGK',
    description:
    'Sosyal güvenlik ve genel sağlık sigortası işlemlerini yürüten kamu kurumu.',
    category: 'Genel',
  ),

  // 3
  SgkTerm(
    key: 'gss',
    title: 'Genel Sağlık Sigortası (GSS)',
    description:
    'Türkiye’de yaşayanların sağlık hizmetlerinden yararlanmasını sağlayan zorunlu sigorta sistemi.',
    category: 'Sağlık',
  ),

  // 4
  SgkTerm(
    key: 'sosyal_sigorta',
    title: 'Sosyal Sigorta',
    description:
    'Prim ödemesine dayalı, risk gerçekleştiğinde gelir veya yardım sağlayan sistem.',
    category: 'Genel',
  ),

  // 5
  SgkTerm(
    key: 'kisa_vadeli_sigorta',
    title: 'Kısa Vadeli Sigorta Kolları',
    description:
    'İş kazası, meslek hastalığı, hastalık ve analık gibi kısa süreli riskleri kapsayan sigortalar.',
    category: 'Genel',
  ),

  // 6
  SgkTerm(
    key: 'uzun_vadeli_sigorta',
    title: 'Uzun Vadeli Sigorta Kolları',
    description:
    'Malullük, yaşlılık ve ölüm risklerini kapsayan uzun vadeli sigorta kolları.',
    category: 'Genel',
  ),

  // 7
  SgkTerm(
    key: 'sigortali',
    title: 'Sigortalı',
    description:
    'Adına prim ödenen ve sosyal güvenlik haklarından yararlanan kişi.',
    category: 'Sigortalılık',
  ),

  // 8
  SgkTerm(
    key: 'zorunlu_sigortali',
    title: 'Zorunlu Sigortalı',
    description:
    'Kanun gereği otomatik olarak sigortalı sayılan ve prim ödenen kişi.',
    category: 'Sigortalılık',
  ),

  // 9
  SgkTerm(
    key: 'istege_bagli_sigorta',
    title: 'İsteğe Bağlı Sigorta',
    description:
    'Kişinin kendi talebiyle prim ödeyerek sigortalı statüsünü devam ettirmesi.',
    category: 'Sigortalılık',
  ),

  // 10
  SgkTerm(
    key: 'sigorta_baslangici',
    title: 'Sigorta Başlangıç Tarihi',
    description:
    'Kişi adına ilk kez prim ödenen tarih; birçok hak bu tarihe göre hesaplanır.',
    category: 'Sigortalılık',
  ),

  // 11
  SgkTerm(
    key: 'sigortaliligin_sona_ermesi',
    title: 'Sigortalılığın Sona Ermesi',
    description:
    'İşe son verme, işten ayrılma veya faaliyetin bitmesiyle sigortalı sayılmanın bitmesi.',
    category: 'Sigortalılık',
  ),

  // 12
  SgkTerm(
    key: 'sigortalilik_suresi',
    title: 'Sigortalılık Süresi',
    description:
    'Sigorta başlangıcı ile sigortalılığın sona erdiği tarih arasındaki toplam süre.',
    category: 'Sigortalılık',
  ),

  // 13
  SgkTerm(
    key: 'prim',
    title: 'Prim',
    description:
    'Sigortalılık için işçi, işveren veya devlet tarafından SGK’ya ödenen tutar.',
    category: 'Prim ve Gün',
  ),

  // 14
  SgkTerm(
    key: 'prim_orani',
    title: 'Prim Oranı',
    description:
    'Brüt kazanç üzerinden, ilgili sigorta kolu için uygulanacak yüzde oran.',
    category: 'Prim ve Gün',
  ),

  // 15
  SgkTerm(
    key: 'prim_gun_sayisi',
    title: 'Prim Gün Sayısı',
    description:
    'Sigortalı için prim ödenmiş toplam gün sayısı; emeklilikte temel ölçütlerden biridir.',
    category: 'Prim ve Gün',
  ),

  // 16
  SgkTerm(
    key: 'prim_borcu',
    title: 'Prim Borcu',
    description:
    'Ödenmesi gereken fakat süresinde ödenmemiş prim tutarı.',
    category: 'Prim ve Gün',
  ),

  // 17
  SgkTerm(
    key: 'prim_tahakkuku',
    title: 'Prim Tahakkuku',
    description:
    'Sigortalı için ödenmesi gereken prim tutarının hesaplanması ve kayda alınması.',
    category: 'Prim ve Gün',
  ),

  // 18
  SgkTerm(
    key: 'prime_esas_kazanc',
    title: 'Prime Esas Kazanç',
    description:
    'Prim hesaplanırken dikkate alınan brüt kazanç ve ek ödemelerin toplamı.',
    category: 'Prim ve Gün',
  ),

  // 19
  SgkTerm(
    key: 'alt_sinir_pek',
    title: 'Prime Esas Kazanç Alt Sınırı',
    description:
    'Prim hesaplanırken dikkate alınabilecek en düşük brüt kazanç tutarı.',
    category: 'Prim ve Gün',
  ),

  // 20
  SgkTerm(
    key: 'ust_sinir_pek',
    title: 'Prime Esas Kazanç Üst Sınırı',
    description:
    'Prim hesaplanırken dikkate alınabilecek en yüksek brüt kazanç tutarı.',
    category: 'Prim ve Gün',
  ),

  // 21
  SgkTerm(
    key: 'isveren',
    title: 'İşveren',
    description:
    'Sigortalı çalıştıran gerçek veya tüzel kişi; işveren primi ödeme yükümlüsüdür.',
    category: 'Çalışma Hayatı',
  ),

  // 22
  SgkTerm(
    key: 'isveren_pay',
    title: 'İşveren Prim Payı',
    description:
    'Sigortalı için ödenen primin işverene ait olan kısmı.',
    category: 'Prim ve Gün',
  ),

  // 23
  SgkTerm(
    key: 'sigortali_pay',
    title: 'Sigortalı Prim Payı',
    description:
    'Sigortalının ücretinden kesilerek ödenen prim oranı.',
    category: 'Prim ve Gün',
  ),

  // 24
  SgkTerm(
    key: 'devlet_katkisi',
    title: 'Devlet Katkısı',
    description:
    'Bazı sigorta kolları için primlere devlet tarafından yapılan katkı payı.',
    category: 'Prim ve Gün',
  ),

  // 25
  SgkTerm(
    key: 'eksik_gun',
    title: 'Eksik Gün',
    description:
    'Ay içinde tam çalışılmayan veya SGK’ya tam bildirilmemiş çalışma günleri.',
    category: 'Prim ve Gün',
  ),

  // 26
  SgkTerm(
    key: 'eksik_ucret_bildirimi',
    title: 'Eksik Ücret Bildirimi',
    description:
    'Sigortalının gerçek ücretinden daha düşük tutarın SGK’ya bildirilmesi durumu.',
    category: 'Prim ve Gün',
  ),

  // 27
  SgkTerm(
    key: 'hizmet_dokumu',
    title: 'Hizmet Dökümü',
    description:
    'Sigortalının çalıştığı işyerleri, prim günleri ve kazançlarını gösteren kayıt özeti.',
    category: 'Kayıt ve Evrak',
  ),

  // 28
  SgkTerm(
    key: 'hizmet_birlesmesi',
    title: 'Hizmet Birleştirmesi',
    description:
    'Farklı sigorta kollarındaki hizmet sürelerinin emeklilikte birlikte değerlendirilmesi.',
    category: 'Emeklilik',
  ),

  // 29
  SgkTerm(
    key: 'hizmet_borclanmasi',
    title: 'Hizmet Borçlanması',
    description:
    'Çalışılmamış fakat kanunen borçlanılabilen süreler için prim ödenerek hizmete saydırma işlemi.',
    category: 'Prim ve Gün',
  ),

  // 30
  SgkTerm(
    key: 'dogum_borclanmasi',
    title: 'Doğum Borçlanması',
    description:
    'Sigortalı kadının doğumdan sonraki çalışmadığı süreleri prim ödeyerek hizmete eklemesi.',
    category: 'Aile ve Analık',
  ),

  // 31
  SgkTerm(
    key: 'askerlik_borclanmasi',
    title: 'Askerlik Borçlanması',
    description:
    'Er veya erbaş olarak yapılan askerlik sürelerinin prim ödenerek hizmetten sayılması.',
    category: 'Prim ve Gün',
  ),

  // 32
  SgkTerm(
    key: 'yurt_disi_borclanmasi',
    title: 'Yurtdışı Borçlanması',
    description:
    'Yurt dışında geçirilen belirli sürelerin borçlanılarak Türkiye’deki hizmete eklenmesi.',
    category: 'Prim ve Gün',
  ),

  // 33
  SgkTerm(
    key: 'emeklilik',
    title: 'Emeklilik',
    description:
    'Belirli yaş, prim gün sayısı ve sigortalılık süresi şartları tamamlanınca düzenli gelir alma durumu.',
    category: 'Emeklilik',
  ),

  // 34
  SgkTerm(
    key: 'emekli_ayligi',
    title: 'Emekli Aylığı',
    description:
    'Emekli olan sigortalıya, her ay ödenen düzenli gelir.',
    category: 'Emeklilik',
  ),

  // 35
  SgkTerm(
    key: 'emekli_maasi',
    title: 'Emekli Maaşı',
    description:
    'Emekli aylığı için halk arasında kullanılan yaygın ifade.',
    category: 'Emeklilik',
  ),

  // 36
  SgkTerm(
    key: 'emeklilik_yasi',
    title: 'Emeklilik Yaşı',
    description:
    'Sigortalının emekli olabilmesi için ulaşması gereken yasal yaş sınırı.',
    category: 'Emeklilik',
  ),

  // 37
  SgkTerm(
    key: 'erken_emeklilik',
    title: 'Erken Emeklilik',
    description:
    'Normal yaştan önce, kanundaki özel şartları sağlayarak emekli olma imkânı.',
    category: 'Emeklilik',
  ),

  // 38
  SgkTerm(
    key: 'kismi_emeklilik',
    title: 'Kısmi Emeklilik',
    description:
    'Daha düşük prim ve yaş şartlarıyla, oransal olarak daha düşük emekli aylığı bağlanması.',
    category: 'Emeklilik',
  ),

  // 39
  SgkTerm(
    key: 'tam_emeklilik',
    title: 'Tam Emeklilik',
    description:
    'Kanundaki tam prim ve yaş şartlarını sağlayarak tam emekli aylığı alma durumu.',
    category: 'Emeklilik',
  ),

  // 40
  SgkTerm(
    key: 'malulluk_sigortasi',
    title: 'Malullük Sigortası',
    description:
    'Çalışma gücünü önemli oranda kaybeden sigortalıya gelir sağlayan sigorta kolu.',
    category: 'Engellilik ve Malullük',
  ),

  // 41
  SgkTerm(
    key: 'malulluk_ayligi',
    title: 'Malullük Aylığı',
    description:
    'Malul sayılan sigortalıya bağlanan sürekli gelir.',
    category: 'Engellilik ve Malullük',
  ),

  // 42
  SgkTerm(
    key: 'engelli_emekliligi',
    title: 'Engelli Emekliliği',
    description:
    'Çalışma gücünün belirli oranda azaldığı durumda, daha esnek şartlarla emeklilik imkânı.',
    category: 'Engellilik ve Malullük',
  ),

  // 43
  SgkTerm(
    key: 'engellilik_orani',
    title: 'Engellilik Oranı',
    description:
    'Sağlık kurulu raporuyla belirlenen, çalışma gücü kaybı yüzdesi.',
    category: 'Engellilik ve Malullük',
  ),

  // 44
  SgkTerm(
    key: 'olum_sigortasi',
    title: 'Ölüm Sigortası',
    description:
    'Sigortalının ölümü hâlinde hak sahiplerine gelir sağlayan uzun vadeli sigorta kolu.',
    category: 'Emeklilik',
  ),

  // 45
  SgkTerm(
    key: 'olum_ayligi',
    title: 'Ölüm Aylığı',
    description:
    'Ölen sigortalının hak sahiplerine uzun vadeli sigorta kapsamında bağlanan aylık.',
    category: 'Emeklilik',
  ),

  // 46
  SgkTerm(
    key: 'olum_geliri',
    title: 'Ölüm Geliri',
    description:
    'İş kazası veya meslek hastalığı sonucu ölen sigortalının hak sahiplerine bağlanan gelir.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 47
  SgkTerm(
    key: 'dul_ayligi',
    title: 'Dul Aylığı',
    description:
    'Ölen sigortalının eşine, kanunda belirtilen oranlarda bağlanan aylık.',
    category: 'Emeklilik',
  ),

  // 48
  SgkTerm(
    key: 'yetim_ayligi',
    title: 'Yetim Aylığı',
    description:
    'Ölen sigortalının çocuklarına, şartları sağladıkları sürece bağlanan aylık.',
    category: 'Emeklilik',
  ),

  // 49
  SgkTerm(
    key: 'cenaze_oyu',
    title: 'Cenaze Ödeneği',
    description:
    'Sigortalının veya emeklinin ölümü hâlinde, defin masrafı için bir defaya mahsus ödeme.',
    category: 'Emeklilik',
  ),

  // 50
  SgkTerm(
    key: 'ikramiye_bayram',
    title: 'Bayram İkramiyesi',
    description:
    'Emekli ve hak sahiplerine dini bayramlar öncesinde ödenen ek tutar.',
    category: 'Emeklilik',
  ),

  // 51
  SgkTerm(
    key: 'gss_primi',
    title: 'GSS Primi',
    description:
    'Genel sağlık sigortasından yararlanmak için ödenen prim.',
    category: 'Sağlık',
  ),

  // 52
  SgkTerm(
    key: 'gelir_testi',
    title: 'Gelir Testi',
    description:
    'GSS priminin devletçe karşılanıp karşılanmayacağını belirlemek için yapılan inceleme.',
    category: 'Sağlık',
  ),

  // 53
  SgkTerm(
    key: 'yesil_kart',
    title: 'Yeşil Kart',
    description:
    'Geliri düşük kişilerin sağlık giderlerinin devletçe karşılanmasını sağlayan sistemin eski adı.',
    category: 'Sağlık',
  ),

  // 54
  SgkTerm(
    key: 'katilim_payi',
    title: 'Katılım Payı',
    description:
    'Muayene, ilaç veya tıbbi malzeme için sigortalı tarafından ödenen katkı tutarı.',
    category: 'Sağlık',
  ),

  // 55
  SgkTerm(
    key: 'sut',
    title: 'Sağlık Uygulama Tebliği (SUT)',
    description:
    'Hangi sağlık hizmetlerinin hangi şartlarla karşılanacağını düzenleyen tebliğ.',
    category: 'Sağlık',
  ),

  // 56
  SgkTerm(
    key: 'saglik_hizmeti_sunar',
    title: 'Sağlık Hizmeti Sunucusu',
    description:
    'Hastane, aile hekimi, özel klinik gibi sağlık hizmeti veren kurumlar.',
    category: 'Sağlık',
  ),

  // 57
  SgkTerm(
    key: 'aile_hekimligi',
    title: 'Aile Hekimliği',
    description:
    'Kişiye birinci basamak sağlık hizmeti sunan hekimlik sistemi.',
    category: 'Sağlık',
  ),

  // 58
  SgkTerm(
    key: 'recete',
    title: 'Reçete',
    description:
    'Doktorun ilaçları ve kullanım şekillerini yazdığı resmi belge.',
    category: 'Sağlık',
  ),

  // 59
  SgkTerm(
    key: 'ilac_raporu',
    title: 'İlaç Raporu',
    description:
    'Bazı ilaçların bedelinin karşılanması için gereken, süreli sağlık kurulu raporu.',
    category: 'Sağlık',
  ),

  // 60
  SgkTerm(
    key: 'raporlu_ilac',
    title: 'Raporlu İlaç',
    description:
    'Kullanımı için sağlık kurulu raporu gereken ve uzun süreli kullanılan ilaç.',
    category: 'Sağlık',
  ),

  // 61
  SgkTerm(
    key: 'gecici_is_goremezlik',
    title: 'Geçici İş Göremezlik Ödeneği',
    description:
    'Raporlu olduğu sürede çalışamayan sigortalıya günlük gelir sağlayan ödeme.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 62
  SgkTerm(
    key: 'suresiz_rapor',
    title: 'Sürekli İş Göremezlik Geliri',
    description:
    'İş kazası veya meslek hastalığı sonucu kalıcı kayıp yaşayan sigortalıya bağlanan gelir.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 63
  SgkTerm(
    key: 'is_kazasi',
    title: 'İş Kazası',
    description:
    'Sigortalının işini yaparken veya iş nedeniyle uğradığı, bedenen veya ruhen zarara yol açan olay.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 64
  SgkTerm(
    key: 'meslek_hastaligi',
    title: 'Meslek Hastalığı',
    description:
    'İşin yürütümünden kaynaklanan, zamanla ortaya çıkan ve sigortalının sağlığını bozan hastalık.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 65
  SgkTerm(
    key: 'is_goremezlik_orani',
    title: 'İş Göremezlik Oranı',
    description:
    'Sigortalının çalışma gücü kaybının yüzdesel olarak belirlenmiş oranı.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 66
  SgkTerm(
    key: 'risk',
    title: 'Sosyal Güvenlik Riski',
    description:
    'Hastalık, işsizlik, yaşlılık, ölüm gibi geliri azaltan veya gideri artıran durumlar.',
    category: 'Genel',
  ),

  // 67
  SgkTerm(
    key: 'tahsis_talep',
    title: 'Tahsis Talep Dilekçesi',
    description:
    'Emekli aylığı bağlanması için SGK’ya verilen resmi başvuru dilekçesi.',
    category: 'Kayıt ve Evrak',
  ),

  // 68
  SgkTerm(
    key: 'tahsis_numarasi',
    title: 'Tahsis Numarası',
    description:
    'Emekli aylığı bağlanan kişiye sistemde verilen özel numara.',
    category: 'Kayıt ve Evrak',
  ),

  // 69 (T.C. Kimlik Numarası ÇIKARILDI)

  // 70
  SgkTerm(
    key: 'sicil_numarasi',
    title: 'Sosyal Güvenlik Sicil Numarası',
    description:
    'Eski sistemde kullanılan, sigortalıyı tanımlayan numara.',
    category: 'Kayıt ve Evrak',
  ),

  // 71 (e-Devlet Kapısı ÇIKARILDI)

  // 72 (e-Devlet Şifresi ÇIKARILDI)

  // 73 (Mobil İmza ÇIKARILDI)

  // 74
  SgkTerm(
    key: 'e_imza',
    title: 'Elektronik İmza',
    description:
    'Elektronik ortamda ıslak imza ile aynı hukuki sonucu doğuran imza türü.',
    category: 'Dijital Hizmetler',
  ),

  // 75
  SgkTerm(
    key: 'sosyal_yardim',
    title: 'Sosyal Yardım',
    description:
    'Gelir testi veya ihtiyaç durumuna göre yapılan karşılıksız destek ve ödemeler.',
    category: 'Sosyal Yardımlar',
  ),

  // 76 (Sosyal Yardım Kartı ÇIKARILDI)

  // 77
  SgkTerm(
    key: 'sosyal_inceleme',
    title: 'Sosyal İnceleme',
    description:
    'Yardım başvurusunda bulunan kişinin gelir ve yaşam koşullarının yerinde değerlendirilmesi.',
    category: 'Sosyal Yardımlar',
  ),

  // 78
  SgkTerm(
    key: 'istihdam',
    title: 'İstihdam',
    description:
    'Çalışan nüfusun iş piyasasında yer alması, iş bulması ve çalışması durumu.',
    category: 'Çalışma Hayatı',
  ),

  // 79
  SgkTerm(
    key: 'issizlik',
    title: 'İşsizlik',
    description:
    'Çalışma isteği ve yeteneği olduğu hâlde iş bulamama durumu.',
    category: 'İşsizlik',
  ),

  // 80
  SgkTerm(
    key: 'issizlik_odenegi',
    title: 'İşsizlik Ödeneği',
    description:
    'Çalışırken işsizlik sigortası primi ödeyenlere, işsiz kaldıklarında belli süreyle ödenen gelir.',
    category: 'İşsizlik',
  ),

  // 81
  SgkTerm(
    key: 'issizlik_sigortasi',
    title: 'İşsizlik Sigortası',
    description:
    'İşsiz kalan sigortalıya belirli süre gelir desteği sağlayan sigorta kolu.',
    category: 'İşsizlik',
  ),

  // 82
  SgkTerm(
    key: 'kisa_calisma_odenegi',
    title: 'Kısa Çalışma Ödeneği',
    description:
    'Çalışma süresi geçici olarak azaltılan veya faaliyeti durdurulan işyerlerindeki sigortalılara ödenen destek.',
    category: 'İşsizlik',
  ),

  // 83
  SgkTerm(
    key: 'istek_ayrilma',
    title: 'İstifa',
    description:
    'Sigortalının kendi isteğiyle iş sözleşmesini sona erdirir',
    category: 'Çalışma Hayatı',
  ),

  // 84
  SgkTerm(
    key: 'fesih',
    title: 'Fesih',
    description:
    'İş sözleşmesinin işçi veya işveren tarafından sona erdirilmesi işlemi.',
    category: 'Çalışma Hayatı',
  ),

  // 85
  SgkTerm(
    key: 'kidem_tazminati',
    title: 'Kıdem Tazminatı',
    description:
    'Belirli koşullarla işten ayrılan işçiye, çalıştığı süreye göre ödenen tazminat.',
    category: 'Çalışma Hayatı',
  ),

  // 86
  SgkTerm(
    key: 'ihbar_tazminati',
    title: 'İhbar Tazminatı',
    description:
    'Bildirim süresine uyulmadan iş sözleşmesi feshedilen tarafa ödenen tazminat.',
    category: 'Çalışma Hayatı',
  ),

  // 87
  SgkTerm(
    key: 'brut_ucret',
    title: 'Brüt Ücret',
    description:
    'Vergi, prim ve diğer kesintiler yapılmadan önceki ücret tutarı.',
    category: 'Çalışma Hayatı',
  ),

  // 88
  SgkTerm(
    key: 'net_ucret',
    title: 'Net Ücret',
    description:
    'Tüm kesintiler yapıldıktan sonra çalışanın eline geçen son ücret.',
    category: 'Çalışma Hayatı',
  ),

  // 89
  SgkTerm(
    key: 'mesai',
    title: 'Mesai',
    description:
    'Normal çalışma süresi veya bu sürenin üzerindeki çalışma saatleri.',
    category: 'Çalışma Hayatı',
  ),

  // 90
  SgkTerm(
    key: 'fazla_mesai',
    title: 'Fazla Mesai',
    description:
    'Kanunda belirlenen haftalık çalışma süresini aşan çalışma saatleri.',
    category: 'Çalışma Hayatı',
  ),

  // 91
  SgkTerm(
    key: 'analik_sigortasi',
    title: 'Analık Sigortası',
    description:
    'Gebelik, doğum ve doğum sonrası dönemler için gelir ve ödenek sağlayan sigorta kolu.',
    category: 'Aile ve Analık',
  ),

  // 92
  SgkTerm(
    key: 'dogum_izni',
    title: 'Doğum İzni',
    description:
    'Doğum öncesi ve sonrası dönemde anneye verilen ücretli izin süresi.',
    category: 'Aile ve Analık',
  ),

  // 93
  SgkTerm(
    key: 'ucretsiz_izin',
    title: 'Ücretsiz İzin',
    description:
    'Belirli süre çalışma yapılmadan, ücret ve prim ödenmeyen izin türü.',
    category: 'Çalışma Hayatı',
  ),

  // 94
  SgkTerm(
    key: 'emzirme_odenegi',
    title: 'Emzirme Ödeneği',
    description:
    'Doğum yapan sigortalıya veya sigortalı eşe bir defaya mahsus ödenen süt parası.',
    category: 'Aile ve Analık',
  ),

  // 95
  SgkTerm(
    key: 'cocuk_parasi',
    title: 'Çocuk Parası',
    description:
    'Çocuk sahibi ailelere, belirli şartlarla sağlanan maddi destek ödemesi.',
    category: 'Aile ve Analık',
  ),

  // 96
  SgkTerm(
    key: 'rapor',
    title: 'Sağlık Raporu',
    description:
    'Çalışılamayacağını veya belirli bir sağlık durumunu gösteren, hekim tarafından düzenlenen belge.',
    category: 'Sağlık',
  ),

  // 97
  SgkTerm(
    key: 'heyet_raporu',
    title: 'Heyet Raporu',
    description:
    'Birden fazla hekimden oluşan kurul tarafından verilen, uzun süreli veya engellilik içeren rapor.',
    category: 'Sağlık',
  ),

  // 98
  SgkTerm(
    key: 'kontrol_muayenesi',
    title: 'Kontrol Muayenesi',
    description:
    'Verilen rapor veya aylığın devamının değerlendirilmesi için yapılan tekrar muayene.',
    category: 'Sağlık',
  ),

  // 99
  SgkTerm(
    key: 'bagkur',
    title: 'Bağ-Kur',
    description:
    'Kendi nam ve hesabına çalışanların eski sosyal güvenlik kurumu; günümüzde 4B statüsü.',
    category: 'Sigortalılık',
  ),

  // 100
  SgkTerm(
    key: 'ssk',
    title: 'SSK',
    description:
    'İşçi statüsündeki çalışanların eski sosyal sigorta kurumu; günümüzde 4A statüsü.',
    category: 'Sigortalılık',
  ),

  // 101
  SgkTerm(
    key: 'emekli_sandigi',
    title: 'Emekli Sandığı',
    description:
    'Kamu görevlilerinin eski emeklilik kurumu; günümüzde 4C statüsü.',
    category: 'Sigortalılık',
  ),

  // 102 (4A ÇIKARILDI)
  // 103 (4B ÇIKARILDI)
  // 104 (4C ÇIKARILDI)

  // 105
  SgkTerm(
    key: 'tescil',
    title: 'Sigortalı Tescili',
    description:
    'Sigortalının SGK sistemine ilk defa kaydedilmesi işlemi.',
    category: 'Sigortalılık',
  ),

  // 106
  SgkTerm(
    key: 'borc_yapilandirma',
    title: 'Borç Yapılandırma',
    description:
    'Gecikmiş prim ve borçların, belirli koşullarla taksitlendirilerek yeniden düzenlenmesi.',
    category: 'Prim ve Gün',
  ),

  // 107 (Af / Yapılandırma Kanunu ÇIKARILDI)

  // 108 (Yeniden Yapılandırma Taksiti ÇIKARILDI)

  // 109
  SgkTerm(
    key: 'mahkeme_karari',
    title: 'Mahkeme Kararıyla Hizmet',
    description:
    'Dava sonucu sigortalı lehine kazanılan ve sisteme eklenen hizmet süresi.',
    category: 'Kayıt ve Evrak',
  ),

  // 110
  SgkTerm(
    key: 'idari_para_cezasi',
    title: 'İdari Para Cezası',
    description:
    'Yükümlülükleri yerine getirmeyen işverenlere veya sigortalılara uygulanan parasal yaptırım.',
    category: 'Kayıt ve Evrak',
  ),

  // 111 (Sosyal Güvenlik Denetmeni ÇIKARILDI)

  // 112 (Müfettiş ÇIKARILDI)

  // 113 (Kurum Alacağı ÇIKARILDI)

  // 114
  SgkTerm(
    key: 'gecikme_zammi',
    title: 'Gecikme Zammı',
    description:
    'Süresinde ödenmeyen prim ve borçlara, geçen gün sayısına göre uygulanan ek tutar.',
    category: 'Prim ve Gün',
  ),

  // 115
  SgkTerm(
    key: 'gecikme_cezasi',
    title: 'Gecikme Cezası',
    description:
    'Yükümlülüğün zamanında yerine getirilmemesi yüzünden uygulanan idari para cezası.',
    category: 'Prim ve Gün',
  ),

  // 116
  SgkTerm(
    key: 'kamu_gorevlisi',
    title: 'Kamu Görevlisi',
    description:
    'Devlet kurumlarında kadrolu veya sözleşmeli statüde çalışan personel.',
    category: 'Çalışma Hayatı',
  ),

  // 117
  SgkTerm(
    key: 'kamu_personel_rejimi',
    title: 'Kamu Personel Rejimi',
    description:
    'Kamu görevlilerinin statü, hak ve yükümlülüklerini düzenleyen sistem.',
    category: 'Çalışma Hayatı',
  ),

  // 118
  SgkTerm(
    key: 'sozlesmeli_personel',
    title: 'Sözleşmeli Personel',
    description:
    'Belirli süreli sözleşme ile çalışan, bazı hakları farklı düzenlenen kamu çalışanı.',
    category: 'Çalışma Hayatı',
  ),

  // 119
  SgkTerm(
    key: 'taseron_isci',
    title: 'Taşeron İşçi',
    description:
    'Asıl işverenin işini, alt işveren şirket üzerinden yapan işçi.',
    category: 'Çalışma Hayatı',
  ),

  // 120
  SgkTerm(
    key: 'alt_isveren',
    title: 'Alt İşveren',
    description:
    'Asıl işverenden belirli işleri veya hizmetleri alan ve kendi işçilerini çalıştıran firma.',
    category: 'Çalışma Hayatı',
  ),

  // 121
  SgkTerm(
    key: 'eski_hukumlu_istihdam',
    title: 'Eski Hükümlü İstihdamı',
    description:
    'Ceza infaz kurumlarından tahliye olmuş kişilerin istihdamını teşvik eden uygulamalar.',
    category: 'İstihdam Teşvikleri',
  ),

  // 122
  SgkTerm(
    key: 'engelli_istihdami',
    title: 'Engelli İstihdamı',
    description:
    'Belirli sayının üzerindeki işyerleri için engelli çalışan çalıştırma zorunluluğu.',
    category: 'İstihdam Teşvikleri',
  ),

  // 123
  SgkTerm(
    key: 'ise_giris_bildirgesi',
    title: 'İşe Giriş Bildirgesi',
    description:
    'Yeni sigortalı için işveren tarafından SGK’ya verilen tescil bildirimi.',
    category: 'Kayıt ve Evrak',
  ),

  // 124
  SgkTerm(
    key: 'is_ayrilis_bildirgesi',
    title: 'İşten Ayrılış Bildirgesi',
    description:
    'Sigortalının işten ayrılması durumunda işverenin SGK’ya verdiği ayrılış bildirimi.',
    category: 'Kayıt ve Evrak',
  ),

  // 125
  SgkTerm(
    key: 'sigorta_kolu',
    title: 'Sigorta Kolu',
    description:
    'Belirli bir riske yönelik kurulan sigorta türü; örneğin yaşlılık veya iş kazası.',
    category: 'Genel',
  ),

  // 126
  SgkTerm(
    key: 'hak_sahibi',
    title: 'Hak Sahibi',
    description:
    'Sigortalının ölümü veya malullüğü hâlinde gelir ve aylık alabilecek yakınları.',
    category: 'Emeklilik',
  ),

  // 127
  SgkTerm(
    key: 'bagli_oldugu_kurum',
    title: 'Bağlı Olduğu Kurum',
    description:
    'Sigortalının statüsüne göre işlemlerini yürüten, SGK’nın ilgili birimi.',
    category: 'Kurum ve Görevli',
  ),

  // 128
  SgkTerm(
    key: 'sosyal_konut',
    title: 'Sosyal Konut',
    description:
    'Düşük gelirli kişiler için devlet destekli olarak sunulan konutlar.',
    category: 'Sosyal Yardımlar',
  ),

  // 129 (Kira Desteği ÇIKARILDI)

  // 130
  SgkTerm(
    key: 'isg',
    title: 'İş Sağlığı ve Güvenliği',
    description:
    'Çalışanların işyerinde sağlık ve güvenliklerini korumaya yönelik tedbirlerin tümü.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 131
  SgkTerm(
    key: 'risk_degerlendirmesi',
    title: 'Risk Değerlendirmesi',
    description:
    'İşyerinde mevcut ve muhtemel tehlikelerin belirlenmesi ve önlem planlanması süreci.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 132
  SgkTerm(
    key: 'isyeri_hekimi',
    title: 'İşyeri Hekimi',
    description:
    'İşyerinde çalışanların sağlık gözetimini yapan hekim.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 133
  SgkTerm(
    key: 'is_guvenligi_uzmani',
    title: 'İş Güvenliği Uzmanı',
    description:
    'İşyerindeki iş sağlığı ve güvenliği önlemlerini planlayan ve takip eden uzman.',
    category: 'İş Kazası ve Meslek Hastalığı',
  ),

  // 134
  SgkTerm(
    key: 'sosyal_dislanma',
    title: 'Sosyal Dışlanma',
    description:
    'Kişi veya grupların ekonomik ve sosyal hayata tam katılamaması durumu.',
    category: 'Genel',
  ),

  // 135
  SgkTerm(
    key: 'sosyal_icerme',
    title: 'Sosyal İçerme',
    description:
    'Dezavantajlı grupların topluma yeniden katılmasını amaçlayan politika ve süreçler.',
    category: 'Genel',
  ),

  // 136
  SgkTerm(
    key: 'cift_emeklilik',
    title: 'Çift Emeklilik',
    description:
    'Birden fazla sigorta statüsünden emeklilik hakkı kazanılması durumu.',
    category: 'Emeklilik',
  ),

  // 137
  SgkTerm(
    key: 'maas_baglanma_orani',
    title: 'Maaş Bağlanma Oranı',
    description:
    'Prim günü ve kazançlara göre emekli aylığı hesabında kullanılan oran.',
    category: 'Emeklilik',
  ),

  // 138
  SgkTerm(
    key: 'indirimli_emeklilik',
    title: 'İndirimli Emeklilik',
    description:
    'Bazı gruplara tanınan, normalden daha düşük yaş ve primle emeklilik imkânı.',
    category: 'Emeklilik',
  ),

  // 139
  SgkTerm(
    key: 'yipranma_payi',
    title: 'Yıpranma Payı',
    description:
    'Bazı ağır ve yıpratıcı işlerde çalışanlara verilen, emeklilikte avantaj sağlayan ek süre.',
    category: 'Emeklilik',
  ),

  // 140
  SgkTerm(
    key: 'fiili_hizmet_zammi',
    title: 'Fiili Hizmet Zammı',
    description:
    'Riskli işlerde çalışılan sürelerin, emeklilik hesabında daha fazla gün olarak sayılması.',
    category: 'Emeklilik',
  ),

  // 141
  SgkTerm(
    key: 'sosyal_guvenlik_sozlesmesi',
    title: 'İkili Sosyal Güvenlik Sözleşmesi',
    description:
    'Türkiye ile başka bir ülke arasında, sigorta haklarını koruyan anlaşma.',
    category: 'Uluslararası',
  ),

  // 142
  SgkTerm(
    key: 'yurt_disi_hizmet',
    title: 'Yurtdışı Hizmeti',
    description:
    'Türk vatandaşının yurt dışında çalıştığı ve belgelendiği süreler.',
    category: 'Uluslararası',
  ),

  // 143
  SgkTerm(
    key: 'sosyal_guvenlik_merkezi',
    title: 'Sosyal Güvenlik Merkezi',
    description:
    'İl ve ilçelerde vatandaşlara hizmet veren SGK birimi.',
    category: 'Kurum ve Görevli',
  ),

  // 144
  SgkTerm(
    key: 'sosyal_guvenlik_il_mudurlugu',
    title: 'Sosyal Güvenlik İl Müdürlüğü',
    description:
    'İldeki sosyal güvenlik işlemlerinden sorumlu SGK birimi.',
    category: 'Kurum ve Görevli',
  ),

  // 145 (Danışma Hattı ÇIKARILDI)

  // 146
  SgkTerm(
    key: 'dilekce',
    title: 'Dilekçe',
    description:
    'Kurumlara yapılan yazılı başvuru metni.',
    category: 'Kayıt ve Evrak',
  ),

  // 147 (İtiraz ÇIKARILDI)

  // 148 (Süresinde Başvuru ÇIKARILDI)

  // 149
  SgkTerm(
    key: 'hak_dusurucu_sure',
    title: 'Hak Düşürücü Süre',
    description:
    'Bu süre geçtikten sonra hak arama imkânının sona erdiği yasal süre.',
    category: 'Kayıt ve Evrak',
  ),

  // 150
  SgkTerm(
    key: 'zamanasimi',
    title: 'Zamanaşımı',
    description:
    'Belirli bir süre sonunda alacak veya hakkın dava edilebilme imkânının ortadan kalkması.',
    category: 'Kayıt ve Evrak',
  ),
];

/// =================== GLOBAL STIL & KNOB’LAR ===================

const double kPageHPad = 16.0;
const double kTextScale = 1.00;
const Color  kTextColor = Colors.black;

// Divider (global)
const double kDividerThickness = 0.2;
const double kDividerSpace     = 2.0;

// Form alanı çerçevesi
const double kFieldBorderWidth   = 0.2;
const double kFieldBorderRadius  = 10.0;
const Color  kFieldBorderColor   = Colors.black87;
const Color  kFieldFocusColor    = Colors.black87;

// İkon genel
const Color  kIconColor = Colors.black87;
const double kIconSize  = 22.0;

/// ===== RAPOR KNOB’LARI =====
const double kReportMaxWidth      = 660.0;
const Color  kResultSheetBg       = Colors.white;
const double kResultSheetCorner   = 22.0;
const double kResultHeaderScale   = 1.00;
// Başlıklar ince (hiçbiri kalın değil)
const FontWeight kResultHeaderWeight = FontWeight.w400;

const Color kReportGood           = Color(0xFF16A34A);
const Color kReportWarn           = Color(0xFFDC2626);

/// ===== YAZILI ÖZET MADDE (BULLET) KNOB’LARI =====
const double     kSumSectionTitleGap   = 8.0;
const double     kSumBetweenItemsGap   = 8.0;
const EdgeInsets kSumItemPadding       = EdgeInsets.symmetric(vertical: 4, horizontal: 0);
const FontWeight kSumItemWeight        = FontWeight.w400;
const double     kSumItemFontScale     = 1.10;
const Color      kSumOkColor           = kReportGood;
const Color      kSumWarnColor         = kReportWarn;

class AppW {
  static const appBarTitle = FontWeight.w700;
  static const heading     = FontWeight.w500;
  static const body        = FontWeight.w300;
  static const minor       = FontWeight.w300;
  static const tableHead   = FontWeight.w600;
}

extension AppText on BuildContext {
  TextStyle get sFormLabel => Theme.of(this).textTheme.titleLarge!;
  TextStyle get sBody      => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get sMinor     => Theme.of(this).textTheme.bodySmall!;
  TextStyle get sTableHead =>
      Theme.of(this).textTheme.bodyMedium!.copyWith(fontWeight: AppW.tableHead);
  TextStyle sEmphasis(Color color) =>
      Theme.of(this).textTheme.titleMedium!.copyWith(
        fontWeight: AppW.heading, color: color,
      );
}

/// ----------------------------------------------
///  TEMA
/// ----------------------------------------------
ThemeData uygulamaTemasi = (() {
  final double sizeTitleLg = 16.5 * kTextScale;
  final double sizeTitleMd = 15 * kTextScale;
  final double sizeBody    = 13.5 * kTextScale;
  final double sizeSmall   = 12.5 * kTextScale;
  final double sizeAppBar  = 20.5 * kTextScale;

  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.indigo[500],
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: sizeAppBar,
        fontWeight: AppW.appBarTitle,
        color: Colors.white,
        letterSpacing: 0.15,
        height: 1.22,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
    ),

    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: sizeTitleLg,
        fontWeight: AppW.heading,
        color: kTextColor,
        height: 1.25,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      titleMedium: TextStyle(
        fontSize: sizeTitleMd,
        fontWeight: AppW.heading,
        color: kTextColor,
        letterSpacing: 0.2,
        height: 1.22,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodyMedium: TextStyle(
        fontSize: sizeBody,
        color: kTextColor,
        fontWeight: AppW.body,
        height: 1.4,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      bodySmall: TextStyle(
        fontSize: sizeSmall,
        color: Colors.black87,
        fontWeight: AppW.minor,
        height: 1.45,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
      labelLarge: TextStyle(
        fontSize: sizeBody,
        fontWeight: AppW.body,
        color: Colors.black87,
        fontFamilyFallback: const ['SF Pro Text', 'Roboto', 'Arial'],
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Colors.black,
      thickness: kDividerThickness,
      space: kDividerSpace,
    ),

    iconTheme: const IconThemeData(
      color: kIconColor,
      size: kIconSize,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldBorderColor, width: kFieldBorderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: kFieldFocusColor, width: kFieldBorderWidth + 0.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(kFieldBorderRadius)),
        borderSide: BorderSide(color: Colors.red, width: kFieldBorderWidth + 0.2),
      ),
      hintStyle: TextStyle(fontSize: 13 * kTextScale, color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
})();

/// ======================
///  VERİ MODELİ (UI İÇİN)
/// ======================
class DictEntry {
  final String head;   // madde başı
  final String def;    // kısa tanım (tam cümle)
  final String? src;   // kaynak (opsiyonel)
  const DictEntry(this.head, this.def, {this.src});
}

/// ======================
///  SÖZLÜK VERİSİ – SGK MOBİL SÖZLÜĞÜ
/// ======================
final List<DictEntry> _allEntries = sgkGlossary
    .map((t) => DictEntry(t.title, t.description))
    .toList();

/// ======================
///  TÜRKÇE SIRALAMA – KARŞILAŞTIRMA
/// ======================
const String _trOrder = 'AÂABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';
String _trUpper(String s) {
  return s
      .replaceAll('i', 'İ')
      .replaceAll('ı', 'I')
      .replaceAll('ş', 'Ş')
      .replaceAll('ğ', 'Ğ')
      .replaceAll('ü', 'Ü')
      .replaceAll('ö', 'Ö')
      .replaceAll('ç', 'Ç')
      .toUpperCase();
}
String _trLower(String s) {
  return s
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .replaceAll('Ş', 'ş')
      .replaceAll('Ğ', 'ğ')
      .replaceAll('Ü', 'ü')
      .replaceAll('Ö', 'ö')
      .replaceAll('Ç', 'ç')
      .toLowerCase();
}
int compareTr(String a, String b) {
  final ua = _trUpper(a);
  final ub = _trUpper(b);
  final int len = math.min(ua.length, ub.length);
  for (int i = 0; i < len; i++) {
    final ca = ua[i];
    final cb = ub[i];
    if (ca == cb) continue;
    final ia = _trOrder.indexOf(ca);
    final ib = _trOrder.indexOf(cb);
    if (ia != -1 && ib != -1) return ia - ib;
    return ca.codeUnitAt(0) - cb.codeUnitAt(0);
  }
  return ua.length - ub.length;
}

/// Başlıkları Title Case + tek boşluk
String trTitleCase(String s) {
  final parts = s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  final mapped = parts.map((token) {
    final leading = RegExp(r'^[^A-Za-zÇĞİÖŞÜçğıöşü]+').stringMatch(token) ?? '';
    final rest1 = token.substring(leading.length);
    final trailing = RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü]+$').stringMatch(rest1) ?? '';
    final core = rest1.substring(0, rest1.length - trailing.length);
    if (core.isEmpty) return token;
    final first = _trUpper(core[0]);
    final tail  = _trLower(core.substring(1));
    return '$leading$first$tail$trailing';
  }).toList();
  return mapped.join(' ');
}

/// ======================
///  ANA UYGULAMA
/// ======================
void main() {
  runApp(const SozlukApp());
}

class SozlukApp extends StatelessWidget {
  const SozlukApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sözlük',
      theme: uygulamaTemasi,
      home: const SozlukHomePage(),
    );
  }
}

class SozlukHomePage extends StatefulWidget {
  const SozlukHomePage({super.key});
  @override
  State<SozlukHomePage> createState() => _SozlukHomePageState();
}

class _SozlukHomePageState extends State<SozlukHomePage> {
  final ScrollController _scrollCtrl = ScrollController();
  String _query = '';

  List<DictEntry> get _filtered {
    if (_query.trim().isEmpty) return _sortedAll;
    final q = _query.toLowerCase();
    // *** SADECE BAŞLIKTA ARAMA ***
    final filtered = _sortedAll.where((e) => _trLower(e.head).contains(q)).toList();
    filtered.sort((a,b)=>compareTr(a.head,b.head));
    return filtered;
  }

  late final List<DictEntry> _sortedAll = (() {
    final copy = [..._allEntries];
    copy.sort((a,b)=>compareTr(a.head,b.head));
    return copy;
  })();

  Map<String, List<DictEntry>> _groupByInitial(List<DictEntry> list) {
    final map = <String, List<DictEntry>>{};
    for (final e in list) {
      final initial = _normalizeInitial(e.head);
      map.putIfAbsent(initial, () => []).add(e);
    }
    for (final k in map.keys) {
      map[k]!.sort((a, b) => compareTr(a.head, b.head));
    }
    final sortedKeys = map.keys.toList()..sort((a,b)=>compareTr(a, b));
    return { for (final k in sortedKeys) k : map[k]! };
  }

  String _normalizeInitial(String s) {
    if (s.trim().isEmpty) return '#';
    return _trUpper(s.trim()[0]);
  }

  void _openDetail(DictEntry e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kResultSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kResultSheetCorner)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.80,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kReportMaxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12, borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      trTitleCase(e.head),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * kResultHeaderScale,
                        fontWeight: kResultHeaderWeight,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          e.def,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: (Theme.of(context).textTheme.bodyMedium!.fontSize ?? 13.5) * 1.05,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByInitial(_filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sözlük',
          style: TextStyle(color: Colors.indigo),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kPageHPad, 12, kPageHPad, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Arama', style: context.sFormLabel),
                    const SizedBox(height: 6),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Madde başı içinde ara…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: kPageHPad),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: 8),
                  for (final entry in grouped.entries) ...[
                    _GroupHeader(letter: entry.key),
                    const SizedBox(height: 6),
                    ...entry.value.map((e) => _DictTile(
                      entry: e,
                      onTap: () => _openDetail(e),
                    )),
                    const SizedBox(height: 10),
                    const Divider(),
                  ],
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String letter;
  const _GroupHeader({required this.letter});
  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w300,
        color: Colors.black87,
      ),
    );
  }
}

class _DictTile extends StatelessWidget {
  final DictEntry entry;
  final VoidCallback onTap;
  const _DictTile({required this.entry, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      title: Text(
        trTitleCase(entry.head),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: AppW.heading,
          height: 1.25,
        ),
      ),
      subtitle: Text(
        entry.def,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}