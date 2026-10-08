import 'package:src/utils/app_design.dart';
import 'package:flutter/material.dart';

class KvkkEkrani extends StatelessWidget {
  const KvkkEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMenuBar(
        title: Text(
          'KVKK',
          style: TextStyle(
              color: AppDesign.activeInk,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppDesign.activeInk),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
          child: AppContent(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppDesign.activeBackground,
                Theme.of(context).primaryColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KVKK Aydınlatma Metni',
                    style: TextStyle(
                        color: AppDesign.activeInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Text(
                  '''1. Veri Sorumlusu ve İletişim
İş & SGK Asistan uygulamasına ilişkin veri sorumlusu, uygulamanın yayıncısı Sosyal Güvenlik Mobil'dir. Veri işleme ve hak talepleriniz için sosyalguvenlikmobil@gmail.com adresinden iletişime geçebilirsiniz.

2. Cihazınızda Kalan Bilgiler
Çalışma Bilgilerim alanına girdiğiniz ad soyad, doğum tarihi, cinsiyet, sigorta statüsü, işe giriş tarihleri, prim günü ve aylık brüt ücretler cihazınızın yerel depolamasında tutulur. Hesaplama geçmişi ve kişisel bildirim tercihleri de cihazda saklanır. Bu bilgiler kişisel hesaplamalar, Çalışma Hayatım, Haklarım ve cihazda planlanan hatırlatmalar için kullanılır; bu işlevler kapsamında uygulama sunucusuna otomatik yüklenmez.

Uygulamadan çıkış yapmak cihazdaki çalışma bilgilerini silmez. Uygulamayı kaldırmak veya cihaz değiştirmek bu bilgilere erişiminizi kaybettirebilir; cihazın işletim sistemi yedekleme ayarları ayrıca geçerli olabilir. Hesabınızı silme işlemi sırasında bu cihazdaki çalışma bilgileri de kaldırılır.

3. Çevrim İçi Hizmetlerde İşlenen Bilgiler
• Üyelik ve giriş: E-posta adresi, görünen ad, kullanıcı kimliği ve giriş yöntemi Firebase Authentication üzerinden işlenir. Şifreyle girişte doğrulama Firebase tarafından yapılır; uygulama geliştiricisinin ayrı bir şifre veritabanı bulunmaz.
• Topluluk: Yazdığınız soru ve yanıtlar, seçtiğiniz görünen ad veya “Anonim Üye” etiketi, kullanıcı kimliği, oylar ve bildirim/şikâyet kayıtları Cloud Firestore'da tutulur. Anonim paylaşımda adınız diğer kullanıcılara gösterilmez; kayıt sistemde hesabınızla ilişkilidir.
• İletişim: Gönderdiğiniz mesaj, e-posta adresiniz, kullanıcı kimliğiniz ve gönderim zamanı destek talebini yanıtlamak için Cloud Firestore'da tutulur.
• Premium deneme: Hesabınızın kullanıcı kimliği ve 7 günlük denemenin başlangıç zamanı, denemenin bir kez kullanılmasını ve süresinin izlenmesini sağlamak için Cloud Firestore'da tutulur.
• Teknik hizmetler: Firebase Analytics kullanım olaylarını, Crashlytics hata kayıtlarını, Cloud Messaging bildirim için gerekli cihaz/kurulum tanımlayıcılarını işleyebilir. Kişisel hatırlatma hesapları cihazda yapılır; genel duyurular için bildirim tercihiniz kullanılabilir.

Topluluk veya iletişim alanına çalışma, sağlık ya da başka kişisel bilgilerinizi kendiniz yazarsanız bu içerik çevrim içi hizmete gönderilir.

4. Amaçlar, Toplama Yöntemi ve Hukuki Sebepler
Bilgiler, uygulamaya yazdığınız alanlardan ve kullanılan hizmetlerin teknik kayıtlarından otomatik yollarla elde edilir. Yerel profilin hesaplamalarda kullanılması; üyelik, Topluluk, destek ve deneme işlemlerinin yürütülmesi, talep ettiğiniz uygulama hizmetinin sunulması amacıyla KVKK m.5/2(c) kapsamındaki sözleşmenin kurulması veya ifasıyla doğrudan ilgili olma şartına dayanır. Hizmet güvenliğinin sağlanması, teknik hataların giderilmesi ve kullanım istatistikleriyle özelliklerin iyileştirilmesi için gereken teknik kayıtlar, temel hak ve özgürlüklerinize zarar vermemek kaydıyla KVKK m.5/2(f) kapsamındaki meşru menfaat şartına dayanır. Gerekli olan ayrı bir açık rıza işlemi varsa bu metin onun yerine geçmez.

5. Aktarım ve Hizmet Sağlayıcılar
Cihazdaki çalışma ve maaş bilgileriniz normal kullanımda Firebase'e aktarılmaz. Üyelik, Topluluk, iletişim, Premium deneme ve teknik hizmetlerin verileri, bu hizmetleri sağlayan Google Firebase altyapısında işlenir. Firebase Authentication ABD'de çalışır; diğer Firebase hizmetlerinde seçilen veya kullanılan altyapı konumuna göre Türkiye dışındaki konumlarda işleme söz konusu olabilir. Toplulukta yayımladığınız içerik diğer kullanıcılara görünür. PDF'leri paylaşmayı seçerseniz aktarım, seçtiğiniz paylaşım uygulaması üzerinden gerçekleşir.

6. Saklama ve Silme
Hesabı silme işlemi Firebase üyeliğinizi ve bu cihazdaki çalışma bilgilerinizi kaldırır; daha önce gönderilmiş Topluluk içerikleri, iletişim mesajları ve deneme kaydı otomatik olarak silinmeyebilir. Bu kayıtlarla ilgili silme veya bilgi taleplerinizi aşağıdaki iletişim adresine iletebilirsiniz.

7. KVKK Kapsamındaki Haklarınız
KVKK'nın 11. maddesi kapsamında verilerinizin işlenip işlenmediğini öğrenme, bilgi isteme, düzeltme veya silme talep etme, aktarım yapılan üçüncü kişileri öğrenme ve kanundaki diğer haklarınızı kullanabilirsiniz. Taleplerinizi sosyalguvenlikmobil@gmail.com adresine gönderebilirsiniz.

8. Güvenlik ve Güncellemeler
Cihazdaki verilerin korunması cihazınızın kilidi ve işletim sistemi güvenliğine de bağlıdır. Firebase'deki kayıtlara erişim için kimlik doğrulama ve güvenlik kuralları kullanılır. Bu metin veri akışları değiştiğinde güncellenir.

Bu metin bilgilendirme amaçlıdır; açık rıza veya üyelik sözleşmesi onayı yerine geçmez.''',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppDesign.activeInk,
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              color: AppDesign.activeInk, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'İletişim:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppDesign.activeInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'sosyalguvenlikmobil@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppDesign.activeInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
