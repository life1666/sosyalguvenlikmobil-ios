/// Tahmini emeklilik tarihini, gerçekten eksik olan koşula göre açıklar.
String emeklilikTahminAciklamasi({
  required String tur,
  required DateTime tahminiTarih,
  required int mevcutPrim,
  required int gerekliPrim,
  required int mevcutSigortalilikYili,
  required int gerekliSigortalilikYili,
  required int mevcutYas,
  required int gerekliYas,
}) {
  final tarih =
      '${tahminiTarih.day.toString().padLeft(2, '0')}.${tahminiTarih.month.toString().padLeft(2, '0')}.${tahminiTarih.year}';

  if (gerekliPrim > 0 && mevcutPrim < gerekliPrim) {
    return 'Eksik prim günlerinizin düzenli bildirilmesi ve diğer koşulların sağlanması varsayımıyla, $tarih tarihinde $tur koşullarını tamamlayabilirsiniz.';
  }
  if (gerekliSigortalilikYili > 0 &&
      mevcutSigortalilikYili < gerekliSigortalilikYili) {
    final primDurumu = gerekliPrim > 0 ? 'Prim günü koşulunuz tamam. ' : '';
    return '${primDurumu}Sigortalılık süresi ve diğer koşullar da sağlandığında $tur koşullarını tamamlayabilirsiniz.';
  }
  if (gerekliYas > 0 && mevcutYas < gerekliYas) {
    return 'Kayıtlı bilgilerinize göre yaş dışındaki koşullarınız tamam. $tarih tarihinde yaş şartını doldurduğunuzda $tur koşullarını sağlayabilirsiniz.';
  }
  return 'Kayıtlı bilgilerinize göre $tarih tarihinde $tur koşullarını sağlayabilirsiniz.';
}
