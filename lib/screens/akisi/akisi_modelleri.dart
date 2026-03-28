/// Çalışan / işveren seçimi için akış modeli.
enum AkisiProfilTipi {
  calisan,
  isveren,
}

AkisiProfilTipi? akisiProfilTipiParse(String? raw) {
  if (raw == null) return null;
  for (final v in AkisiProfilTipi.values) {
    if (v.name == raw) return v;
  }
  return null;
}
