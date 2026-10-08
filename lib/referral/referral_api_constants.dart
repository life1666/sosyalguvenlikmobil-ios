/// sgk_app ile aynı JSON yapısını sunan HTTPS uç nokta (CDN / Hosting / API).
/// Boş bırakılırsa yalnızca [assets/referral_ui_config.json] kullanılır.
///
/// Derleme: `--dart-define=REFERRAL_UI_URL=https://.../referral_ui.json`
///
/// Beklenen gövde (alanlar opsiyonel; boş kalan metin/adımlar asset ile tamamlanır):
/// ```json
/// {
///   "heroImageUrl": "https://.../davet_hero.png",
///   "title": "Arkadaşını davet et",
///   "subtitle": "...",
///   "steps": [
///     { "iconUrl": "https://.../adim1.png", "title": "...", "subtitle": "..." }
///   ]
/// }
/// ```
/// Türkçe anahtarlar: `gorsel_hero`, `baslik`, `aciklama`, `adimlar`, `ikonUrl`.
const String kReferralUiConfigUrl = String.fromEnvironment(
  'REFERRAL_UI_URL',
  defaultValue: '',
);
