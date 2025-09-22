import 'package:flutter/material.dart';

class KvkkEkrani extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KVKK',
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
              'Sosyal Güvenlik Mobil Uygulaması KVKK Metni',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 10),
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
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),

          ],
        ),
      ),
    );
  }
}
