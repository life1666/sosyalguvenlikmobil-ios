import '../hesaplamalar/4a_hesapla.dart' show emeklilikHesapla4a;
import '../hesaplamalar/emeklilik_motorlari.dart'
    show emeklilikHesapla4b, emeklilikHesapla4c;

/// Uses the same calculation functions as the free retirement calculators.
Map<String, dynamic>? emeklilikHesaplaStatulu({
  required String sigortaKolu,
  required DateTime dogumTarihi,
  required String cinsiyet,
  required DateTime sigortaBaslangici,
  required int primGunu,
}) {
  final status = sigortaKolu.trim().toLowerCase();
  if (status.startsWith('4/a')) {
    return emeklilikHesapla4a(
        dogumTarihi, cinsiyet, sigortaBaslangici, primGunu);
  }
  if (status.startsWith('4/b')) {
    return emeklilikHesapla4b(
        dogumTarihi, cinsiyet, sigortaBaslangici, primGunu);
  }
  if (status.startsWith('4/c')) {
    return emeklilikHesapla4c(
        dogumTarihi, cinsiyet, sigortaBaslangici, primGunu);
  }
  return null;
}
