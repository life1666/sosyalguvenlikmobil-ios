import 'package:flutter/material.dart';

class SozlesmeEkrani extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kullanım Sözleşmesi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sosyal Güvenlik Mobil Uygulaması Kullanıcı Sözleşmesi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '''⚠️ Bu uygulama herhangi bir kamu kurumu, devlet dairesi veya resmi kuruluş tarafından geliştirilmemiştir ve bu tür kuruluşları temsil etmez. Uygulama yalnızca bilgilendirme amaçlıdır. Sunulan hesaplamalar resmi belge niteliği taşımaz.

Sosyal Güvenlik Mobil Uygulama Kullanıcı Sözleşmesi
Madde 1 – Taraflar
Bu sözleşme, bir tarafta Sosyal Güvenlik Mobil Uygulaması’nı geliştiren özel girişim ile diğer tarafta uygulamayı yükleyerek kullanmaya başlayan birey (bundan böyle “Kullanıcı” olarak anılacaktır) arasında elektronik ortamda kabul edilerek yürürlüğe girmiştir.
Madde 2 – Tanımlar
2.1. Uygulama: “Sosyal Güvenlik Mobil” adıyla yayımlanan ve kullanıcıya sosyal güvenlik alanına ilişkin çeşitli konularda dijital içerikler, hatırlatıcılar ve yönlendirici bilgiler sunan mobil yazılımı ifade eder. Bu yazılım aracılığıyla yapılan işlemler yalnızca bilgilendirme niteliği taşımakta olup, resmi ya da bağlayıcı bir işlem veya başvuru anlamı taşımaz.
2.2. Geliştirici: Uygulamanın tüm haklarına sahip olan ve dijital hizmetleri sunan gerçek veya tüzel kişidir.
2.3. Kullanıcı: Uygulamayı indiren, kaydolan veya hizmetlerden herhangi bir şekilde yararlanan gerçek kişidir.
2.4. Erişim Bilgileri: Kullanıcının uygulamaya giriş yaptığı kullanıcı adı, şifre, doğrulama kodu gibi kişisel ve gizli bilgiler.
2.5. İletişim Kanalları: Geliştirici tarafından Kullanıcıya ulaşmak için kullanılan e-posta, SMS, anlık bildirim, çağrı gibi yöntemlerdir.
2.6. Mesajlar: Geliştirici tarafından bilgi, tanıtım, duyuru veya anket gibi amaçlarla Kullanıcılara gönderilen içeriklerdir.
2.7. Yönetim Paneli: Kullanıcının uygulama içindeki hesap bilgilerini ve işlemlerini yönettiği kişisel alanı ifade eder.
Madde 3 – Konu ve Kapsam
Bu sözleşme, Kullanıcının Uygulama'dan faydalanma koşullarını ve tarafların karşılıklı hak ve yükümlülüklerini düzenler.
Madde 4 – Kullanım Koşulları
4.1. 18 yaş altı kişiler ile temsil yetkisi olmayan bireylerin adına açılan hesaplar geçersiz sayılır.
4.2. Geliştirici, herhangi bir sebep göstermeksizin Kullanıcının hesabını askıya alma veya erişimi sonlandırma hakkını saklı tutar.
4.3. Her birey yalnızca bir kullanıcı hesabı açabilir. Aynı kişi adına birden fazla hesap açıldığı tespit edilirse hesaplar kapatılabilir.
4.4. Uygulama içerisindeki dijital içerikler sadece bireysel kullanım içindir; üçüncü kişilerle paylaşılamaz, satılamaz, kopyalanamaz.
4.5. Uygulamadaki bağlantılarla yönlendirilen üçüncü taraf internet sitelerindeki içerik ve işlemlerden yalnızca Kullanıcı sorumludur.
Madde 5 – Tarafların Hak ve Yükümlülükleri
Taraflar sözleşme kapsamında belirtilen tüm yükümlülüklere uymayı kabul eder. Kullanıcı; bilgilerini doğru sunmak, erişim bilgilerini korumak ve uygulamayı yasal amaçlarla kullanmakla yükümlüdür. Geliştirici; hizmet içeriğini değiştirme, askıya alma veya sonlandırma hakkını saklı tutar. Her iki taraf da bu sözleşmenin hükümleriyle bağlıdır.
Madde 6 – Hizmetler
Uygulama, sosyal güvenlik alanına dair bilgi, belge hatırlatma, dijital içerik düzenleme ve kullanıcı yönlendirme gibi kolaylıklar sağlar. Geliştirici, hizmetlerde değişiklik yapma hakkını saklı tutar.
Madde 7 – Gizlilik
Kullanıcılara ait bilgiler yalnızca Gizlilik Sözleşmesi (EK-1) kapsamında ve açık rıza, yasal zorunluluk veya hizmetin gereği olan durumlarda işlenir ya da paylaşılır.
Madde 8 – Uygulanacak Hukuk
Bu sözleşmenin yorumlanmasında Türkiye Cumhuriyeti yasaları esas alınacaktır.
Madde 9 – Fikri Mülkiyet Hakları
Uygulamanın tüm içeriği, yazılım altyapısı, görselleri ve teknik yapısı Geliştiriciye aittir. Kaynak gösterilmeden kopyalanamaz, çoğaltılamaz, satılamaz.
Madde 10 – Sözleşme Değişiklikleri
Geliştirici, bu sözleşmenin herhangi bir maddesini tek taraflı olarak değiştirebilir. Yapılan değişiklikler Uygulama üzerinden yayımlandığında yürürlüğe girer.
Madde 11 – Mücbir Sebepler
Doğal afetler, teknik arızalar, yasal düzenlemeler gibi kontrol dışı sebeplerden kaynaklanan aksaklıklarda taraflar sorumluluk kabul etmez.
Madde 12 – Fesih
Bu sözleşme, Kullanıcının uygulamayı kullanmaya devam ettiği sürece yürürlükte kalır. Kullanıcılığın sona ermesi veya hesabın silinmesiyle birlikte sona erer.
Madde 13 – Yürürlük
Kullanıcı, bu sözleşmedeki tüm hükümleri okuyup anladığını, kabul ettiğini ve doğru bilgi verdiğini beyan eder. Sözleşme, Kullanıcının uygulamayı kullanmasıyla birlikte yürürlüğe girer.
Madde 14 – Sorumluluk Reddi
Uygulama, kullanıcıya yalnızca bilgilendirme, hatırlatma ve dijital kolaylık sağlama amacıyla sunulmaktadır. Uygulama üzerinden sunulan içeriklerin doğruluğu ve güncelliği konusunda azami özen gösterilmekle birlikte, bunların herhangi bir yasal bağlayıcılığı veya resmi işlem niteliği yoktur. Kullanıcı, uygulamada sunulan bilgilerin kesin ve resmi dayanak olmadığını kabul eder. Uygulama geliştiricisi; kullanıcıların uygulamadaki bilgiler doğrultusunda yaptığı işlemlerden, uğrayabilecekleri zararlardan, eksik veya hatalı yönlendirmelerden hiçbir şekilde sorumlu tutulamaz.
EK – GİZLİLİK SÖZLEŞMESİ
1.  Kullanıcılara ait kişisel bilgiler gizli tutulur ve gerekli koruma tedbirleri uygulanır.
2. Bu gizlilik taahhüdü, Uygulamanın tüm bölümleri için geçerlidir.
3. Kullanıcı bilgileri; pazarlama, analiz, hizmet geliştirme gibi açık amaçlar dışında paylaşılmaz.
4. Geliştirici, iletişim kanalları aracılığıyla Kullanıcıya ulaşabilir.
5. Teknik sorunların tespiti için IP bilgileri ve cihaz verileri kaydedilebilir.
6. Toplanan bilgiler anonimleştirilerek istatistiksel değerlendirmelerde kullanılabilir.
7. Uygulama dışındaki bağlantılar ve reklamlardan kaynaklı gizlilik ihlallerinden Geliştirici sorumlu değildir.
8. Aşağıdaki durumlarda kullanıcı bilgileri açıklanabilir:
i. Yasal yükümlülükler
ii. Hizmetin sağlanabilmesi için gereken bilgiler
iii. Resmi kurum talepleri
iv. Kullanıcının güvenliğini sağlama amacı
9. Geliştirici, gizli bilgilerin korunması için her türlü teknik ve idari tedbiri almayı taahhüt eder.
10. Anket ve etkileşimler aracılığıyla toplanan veriler, Kullanıcının kimliği ifşa edilmeden analiz amaçlı kullanılabilir.
11. Uygulamada yalnızca kullanıcı kaydı ve giriş işlemleri için e-posta adresi ile şifre bilgisi talep edilmektedir. Bu bilgiler, Google tarafından sunulan Firebase Authentication hizmeti aracılığıyla işlenmekte olup, geliştirici bu bilgilere doğrudan erişmemekte, herhangi bir şekilde saklamamaktadır. Firebase’in kullanıcı verilerini nasıl işlediğine ilişkin ayrıntılı bilgi için Google Gizlilik Politikası sayfasını ziyaret edebilirsiniz:
https://firebase.google.com/support/privacy
12. Gizlilik koşulları gerektiğinde uygulama içinde yayımlanarak güncellenebilir.
13. Bu gizlilik metni, Kullanıcı Sözleşmesi’nin ayrılmaz bir parçasıdır.
©2025 Sosyal Güvenlik Mobil Uygulaması. Tüm hakları saklıdır.''',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
