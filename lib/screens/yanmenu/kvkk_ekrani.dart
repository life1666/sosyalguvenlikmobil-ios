import 'package:flutter/material.dart';

class KvkkEkrani extends StatelessWidget {
  const KvkkEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KVKK',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.indigo.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        size: 64,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'KVKK Aydınlatma Metni',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kişisel Verilerin Korunması Kanunu',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
              '''1. Veri Sorumlusunun Kimliği
Bu uygulama kapsamında işlenen kişisel veriler, Sosyal Güvenlik Mobil uygulaması geliştiricisi (Veri Sorumlusu) tarafından, 6698 sayılı Kişisel Verilerin Korunması Kanunu (“KVKK”) kapsamında işlenmektedir.

2. Kişisel Verilerin İşlenme Amaçları
Toplanan kişisel verileriniz aşağıdaki amaçlarla işlenmektedir:
• Hesaplama modüllerinin çalıştırılması (emeklilik, tazminat vb.)
• Kullanıcı destek taleplerinin karşılanması
• Giriş ve kimlik doğrulama işlemleri (e-posta, şifre)
• Kullanıcı deneyiminin teknik olarak iyileştirilmesi
• Yasal yükümlülüklerin yerine getirilmesi

3. İşlenen Kişisel Veriler
• Uygulamada yalnızca kullanıcı kaydı ve
giriş işlemleri için e-posta adresi ve 
şifre bilgisi talep edilmektedir. 
Bu bilgiler, doğrudan Google Firebase Authentication 
hizmeti aracılığıyla işlenmekte ve 
geliştirici tarafından doğrudan 
erişilmemekte veya saklanmamaktadır.
Firebase’in kullanıcı bilgilerini işlemesine
ilişkin detaylı bilgiler için 
Google Gizlilik Politikası’na göz atabilirsiniz:
https://firebase.google.com/support/privacy 

4. Kişisel Verilerin Aktarımı
Kişisel verileriniz, açık rızanız olmaksızın üçüncü taraflara aktarılmaz. Yalnızca hukuken zorunlu hallerde ve resmi talepler doğrultusunda ilgili mercilerle paylaşılabilir.

5. Toplama Yöntemi
Veriler, mobil uygulama üzerinden doğrudan siz kullanıcılar tarafından sağlanmakta ve uygulama altyapısı ile otomatik yollarla toplanmaktadır.

6. KVKK Kapsamındaki Haklarınız
KVKK’nın 11. maddesi kapsamında aşağıdaki haklara sahipsiniz:
• Kişisel verilerinizin işlenip işlenmediğini öğrenme
• İşlenmişse buna ilişkin bilgi talep etme
• Verilerin düzeltilmesini veya silinmesini isteme
• Verilerin aktarıldığı üçüncü kişileri bilme
• İşlemeye itiraz etme

Bu haklarınızı kullanmak için bize sosyalguvenlikmobil@gmail.com adresinden ulaşabilirsiniz.

7. Veri Güvenliği
Kişisel verileriniz güvenli sunucularda saklanır. Yetkisiz erişim, değiştirme veya sızmalara karşı idari ve teknik tüm önlemler alınmıştır.

8. Güncellemeler
İşbu KVKK Aydınlatma Metni zaman zaman güncellenebilir. Güncellemeler uygulama içinde veya geliştirici kanallarıyla duyurulacaktır.

Uygulamayı kullanarak bu metni okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan etmiş olursunuz.''',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
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
                      Icon(Icons.email_outlined, color: Colors.indigo, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'İletişim:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'sosyalguvenlikmobil@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo,
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
    );
  }
}
