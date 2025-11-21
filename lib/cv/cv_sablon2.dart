// lib/cv/cv_sablon2.dart
import 'package:flutter/material.dart';
import 'cv_olustur.dart' show CvData;
import 'cv_helpers.dart';

/* -------------------------------------------------------------------------- */
/*  11) ACADEMIC STYLE                                                         */
/* -------------------------------------------------------------------------- */

Widget t11AcademicStyle(BuildContext c, CvData cv) {
  const accent = Color(0xFF1565C0);
  final theme = Theme.of(c);

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cv.photoUrl != null && cv.photoUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: NetworkImage(cv.photoUrl!),
                ),
              ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  Text(
                    cv.title.isEmpty ? 'Akademisyen / Araştırmacı' : cv.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (cv.email.trim().isNotEmpty) ...[
                        Icon(Icons.mail_outline, size: 14, color: accent),
                        const SizedBox(width: 4),
                        Text(cv.email, style: const TextStyle(fontSize: 10.5)),
                        const SizedBox(width: 16),
                      ],
                      if (cv.phone.trim().isNotEmpty) ...[
                        Icon(Icons.phone_outlined, size: 14, color: accent),
                        const SizedBox(width: 4),
                        Text(cv.phone, style: const TextStyle(fontSize: 10.5)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        dottedDivider(width: 600.0, thickness: 1.5, color: accent.withOpacity(0.3)),
        const SizedBox(height: 16),
        if (cv.summary.isNotEmpty) ...[
          sectionTitle(c, 'Araştırma İlgi Alanları', color: accent),
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: [
                const WidgetSpan(child: SizedBox(width: 24.0)),
                TextSpan(
                  text: cv.summary,
                  style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.projects.isNotEmpty) ...[
                    sectionTitle(c, 'Yayınlar ve Projeler', color: accent),
                    ...buildProjectEntries(c, cv, accent: accent),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    sectionTitle(c, 'Eğitim', color: accent),
                    eduList(c, cv, titleColor: accent),
                  ],
                  if (cv.experiences.isNotEmpty) ...[
                    sectionTitle(c, 'Deneyimler', color: accent),
                    ...buildExperienceEntries(c, cv, accent: accent),
                  ],
                  if (cv.volunteering.isNotEmpty) ...[
                    sectionTitle(c, 'Gönüllülük', color: accent),
                    ...buildVolunteeringEntries(c, cv, accent: accent),
                  ],
                  if (cv.references.isNotEmpty) ...[
                    sectionTitle(c, 'Referanslar', color: accent),
                    ...buildReferenceEntries(c, cv, bulletColor: accent.withOpacity(0.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 210,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty) ...[
                    sectionTitle(c, 'Yetenekler', color: accent),
                    skillWrap(c, cv),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFE3F2FD),
                      textColor: const Color(0xFF0D47A1),
                      borderColor: const Color(0xFFBBDEFB),
                    ),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(c, cv,
                        bgColor: const Color(0xFFE3F2FD),
                        textColor: const Color(0xFF0D47A1),
                        borderColor: const Color(0xFFBBDEFB)),
                  ],
                  if (cv.licenses.isNotEmpty) ...[
                    sectionTitle(c, 'Ehliyet', color: accent),
                    ...buildLicenseEntries(c, cv),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  12) PHOTO FOCUS                                                            */
/* -------------------------------------------------------------------------- */
Widget t12PhotoFocus(BuildContext c, CvData cv) {
  const accent = Color(0xFFE91E63);
  final theme = Theme.of(c);

  return A4Shell(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: cv.photoUrl != null && cv.photoUrl!.isNotEmpty
                      ? Image.network(cv.photoUrl!, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Center(
                            child: Icon(Icons.person, size: 76, color: Colors.black26),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'İLETİŞİM',
                      style: const TextStyle(
                        color: accent,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (cv.email.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mail_outline, size: 13, color: accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(cv.email,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 10)),
                            ),
                          ],
                        ),
                      ),
                    if (cv.phone.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_outlined, size: 13, color: accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(cv.phone,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 10)),
                            ),
                          ],
                        ),
                      ),
                    if (cv.address.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_outlined, size: 13, color: accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(cv.address,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 10)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (cv.skills.isNotEmpty) ...[
                const SizedBox(height: 18),
                sectionTitle(c, 'Yetenekler', color: accent),
                skillProgressList(
                  c,
                  cv,
                  barColor: accent,
                  backgroundColor: const Color(0xFFFCE4EC),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ],
              if (cv.languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Diller', color: accent),
                languageChipWrap(
                  c,
                  cv,
                  bgColor: const Color(0xFFFCE4EC),
                  textColor: const Color(0xFF880E4F),
                  borderColor: const Color(0xFFF8BBD0),
                ),
              ],
              if (cv.certificates.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Sertifikalar', color: accent),
                ...buildCertificateEntries(c, cv),
              ],
              if (cv.hobbies.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Hobiler', color: accent),
                hobbyChipWrap(c, cv,
                    bgColor: const Color(0xFFFCE4EC),
                    textColor: const Color(0xFF880E4F),
                    borderColor: const Color(0xFFF8BBD0)),
              ],
              if (cv.licenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Ehliyet', color: accent),
                ...buildLicenseEntries(c, cv),
              ],
            ],
          ),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              Text(
                cv.title.isEmpty ? 'Profesyonel Pozisyon' : cv.title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (cv.summary.isNotEmpty) ...[
                sectionTitle(c, 'Profil', color: accent),
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      const WidgetSpan(child: SizedBox(width: 24.0)),
                      TextSpan(
                        text: cv.summary,
                        style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
              ],
              if (cv.experiences.isNotEmpty) ...[
                sectionTitle(c, 'Deneyimler', color: accent),
                ...buildExperienceEntries(c, cv, accent: accent),
              ],
              if (cv.educations.isNotEmpty) ...[
                sectionTitle(c, 'Eğitim', color: accent),
                eduList(c, cv, titleColor: accent),
              ],
              if (cv.projects.isNotEmpty) ...[
                sectionTitle(c, 'Projeler', color: accent),
                ...buildProjectEntries(c, cv, accent: accent),
              ],
              if (cv.volunteering.isNotEmpty) ...[
                sectionTitle(c, 'Gönüllülük', color: accent),
                ...buildVolunteeringEntries(c, cv, accent: accent),
              ],
              if (cv.references.isNotEmpty) ...[
                sectionTitle(c, 'Referanslar', color: accent),
                ...buildReferenceEntries(c, cv, bulletColor: accent.withOpacity(0.4)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  13) TIMELINE PRO (BASİT ÇİZGİ)                                             */
/* -------------------------------------------------------------------------- */
Widget t13TimelinePro(BuildContext c, CvData cv) {
  const accent = Color(0xFF00897B);
  final theme = Theme.of(c);

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Pozisyon' : cv.title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cv.email.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mail_outline, size: 14, color: accent),
                          const SizedBox(width: 6),
                          Text(cv.email,
                              style: const TextStyle(color: Colors.black87, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  if (cv.phone.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: accent),
                          const SizedBox(width: 6),
                          Text(cv.phone,
                              style: const TextStyle(color: Colors.black87, fontSize: 10.5)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (cv.summary.isNotEmpty) ...[
          sectionTitle(c, 'Profil Özeti', color: accent),
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: [
                const WidgetSpan(child: SizedBox(width: 24.0)),
                TextSpan(
                  text: cv.summary,
                  style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.experiences.isNotEmpty) ...[
                    sectionTitle(c, 'Deneyimler', color: accent),
                    Column(
                      children: cv.experiences.asMap().entries.map((entry) {
                        final isLast = entry.key == cv.experiences.length - 1;
                        final hasEducation = cv.educations.isNotEmpty;
                        final e = entry.value;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withOpacity(0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast || hasEducation)
                                  Container(
                                    width: 2,
                                    height: 55,
                                    color: accent.withOpacity(0.25),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.position,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    Text(
                                      e.company,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '${e.start} — ${(e.isCurrent || e.end.isEmpty) ? "Güncel" : e.end}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (e.desc.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(e.desc, style: const TextStyle(fontSize: 10.5)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    if (cv.experiences.isNotEmpty) ...[
                      const SizedBox(height: 14),
                    ],
                    sectionTitle(c, 'Eğitim', color: accent),
                    Column(
                      children: cv.educations.asMap().entries.map((entry) {
                        final isLast = entry.key == cv.educations.length - 1;
                        final e = entry.value;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withOpacity(0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 55,
                                    color: accent.withOpacity(0.25),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.level.trim().isNotEmpty 
                                          ? '${e.school} · ${e.level} · ${e.department}'
                                          : '${e.school} · ${e.department}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    Text(
                                      '${e.start} — ${e.end}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (e.note.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(e.note, style: const TextStyle(fontSize: 10.5)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                  if (cv.volunteering.isNotEmpty) ...[
                    sectionTitle(c, 'Gönüllülük', color: accent),
                    ...buildVolunteeringEntries(c, cv, accent: accent),
                  ],
                  if (cv.references.isNotEmpty) ...[
                    sectionTitle(c, 'Referanslar', color: accent),
                    ...buildReferenceEntries(c, cv, bulletColor: accent.withOpacity(0.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 210,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty) ...[
                    sectionTitle(c, 'Yetenekler', color: accent),
                    skillProgressList(
                      c,
                      cv,
                      barColor: accent,
                      backgroundColor: const Color(0xFFB2DFDB),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFE0F2F1),
                      textColor: const Color(0xFF004D40),
                      borderColor: const Color(0xFFB2DFDB),
                    ),
                  ],
                  if (cv.projects.isNotEmpty) ...[
                    sectionTitle(c, 'Projeler', color: accent),
                    ...buildProjectEntries(c, cv, accent: accent),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(c, cv,
                        bgColor: const Color(0xFFE0F2F1),
                        textColor: const Color(0xFF004D40),
                        borderColor: const Color(0xFFB2DFDB)),
                  ],
                  if (cv.licenses.isNotEmpty) ...[
                    sectionTitle(c, 'Ehliyet', color: accent),
                    ...buildLicenseEntries(c, cv),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  14) GEOMETRIC BLOCKS                                                       */
/* -------------------------------------------------------------------------- */
Widget t14GeometricBlocks(BuildContext c, CvData cv) {
  const accent = Color(0xFFF9A826);
  final theme = Theme.of(c);

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9A826), Color(0xFFFFC947)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Yaratıcı Pozisyon' : cv.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFE082), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cv.email.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mail_outline, size: 13, color: accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(cv.email,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                  if (cv.phone.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 13, color: accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(cv.phone,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                  if (cv.address.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(cv.address,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (cv.summary.isNotEmpty) ...[
          sectionTitle(c, 'Profil', color: accent),
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: [
                const WidgetSpan(child: SizedBox(width: 24.0)),
                TextSpan(
                  text: cv.summary,
                  style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.experiences.isNotEmpty) ...[
                    sectionTitle(c, 'Deneyimler', color: accent),
                    ...buildExperienceEntries(c, cv, accent: accent),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    sectionTitle(c, 'Eğitim', color: accent),
                    eduList(c, cv, titleColor: accent),
                  ],
                  if (cv.projects.isNotEmpty) ...[
                    sectionTitle(c, 'Projeler', color: accent),
                    ...buildProjectEntries(c, cv, accent: accent),
                  ],
                  if (cv.volunteering.isNotEmpty) ...[
                    sectionTitle(c, 'Gönüllülük', color: accent),
                    ...buildVolunteeringEntries(c, cv, accent: accent),
                  ],
                  if (cv.references.isNotEmpty) ...[
                    sectionTitle(c, 'Referanslar', color: accent),
                    ...buildReferenceEntries(c, cv, bulletColor: accent.withOpacity(0.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 22),
            SizedBox(
              width: 210,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty) ...[
                    sectionTitle(c, 'Yetkinlikler', color: accent),
                    skillProgressList(
                      c,
                      cv,
                      barColor: accent,
                      backgroundColor: const Color(0xFFFFE082),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFFFF8E1),
                      textColor: const Color(0xFF6D4C00),
                      borderColor: const Color(0xFFFFE082),
                    ),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(c, cv,
                        bgColor: const Color(0xFFFFF8E1),
                        textColor: const Color(0xFF6D4C00),
                        borderColor: const Color(0xFFFFE082)),
                  ],
                  if (cv.licenses.isNotEmpty) ...[
                    sectionTitle(c, 'Ehliyet', color: accent),
                    ...buildLicenseEntries(c, cv),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  15) MODERN TWO-COLUMN                                                      */
/* -------------------------------------------------------------------------- */
Widget t15ModernTwoColumn(BuildContext c, CvData cv) {
  const accent = Color(0xFF6C63FF);
  final theme = Theme.of(c);

  return A4Shell(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              Text(
                cv.title.isEmpty ? 'Modern Profesyonel' : cv.title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (cv.summary.isNotEmpty) ...[
                sectionTitle(c, 'Profil', color: accent),
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      const WidgetSpan(child: SizedBox(width: 24.0)),
                      TextSpan(
                        text: cv.summary,
                        style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
              ],
              if (cv.experiences.isNotEmpty) ...[
                sectionTitle(c, 'Deneyimler', color: accent),
                ...buildExperienceEntries(c, cv, accent: accent),
              ],
              if (cv.projects.isNotEmpty) ...[
                sectionTitle(c, 'Projeler', color: accent),
                ...buildProjectEntries(c, cv, accent: accent),
              ],
              if (cv.volunteering.isNotEmpty) ...[
                sectionTitle(c, 'Gönüllülük', color: accent),
                ...buildVolunteeringEntries(c, cv, accent: accent),
              ],
              if (cv.references.isNotEmpty) ...[
                sectionTitle(c, 'Referanslar', color: accent),
                ...buildReferenceEntries(c, cv, bulletColor: accent.withOpacity(0.4)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 26),
        Container(
          width: 230,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F4FF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'İLETİŞİM',
                style: const TextStyle(
                  color: accent,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 12),
              if (cv.email.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline, size: 13, color: accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(cv.email,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              if (cv.phone.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_outlined, size: 13, color: accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(cv.phone,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              if (cv.address.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(cv.address,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              if (cv.skills.isNotEmpty) ...[
                const SizedBox(height: 18),
                sectionTitle(c, 'Yetkinlikler', color: accent),
                skillProgressList(
                  c,
                  cv,
                  barColor: accent,
                  backgroundColor: const Color(0xFFE0DFFF),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ],
              if (cv.languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Diller', color: accent),
                languageChipWrap(
                  c,
                  cv,
                  bgColor: const Color(0xFFE0DFFF),
                  textColor: const Color(0xFF4038CC),
                  borderColor: const Color(0xFFC5C3FF),
                ),
              ],
              if (cv.educations.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Eğitim', color: accent),
                eduList(c, cv, titleColor: accent),
              ],
              if (cv.certificates.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Sertifikalar', color: accent),
                ...buildCertificateEntries(c, cv),
              ],
              if (cv.hobbies.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Hobiler', color: accent),
                hobbyChipWrap(c, cv,
                    bgColor: const Color(0xFFE0DFFF),
                    textColor: const Color(0xFF4038CC),
                    borderColor: const Color(0xFFC5C3FF)),
              ],
              if (cv.licenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                sectionTitle(c, 'Ehliyet', color: accent),
                ...buildLicenseEntries(c, cv),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  16) MONOCHROME                                                             */
/* -------------------------------------------------------------------------- */
Widget t16Monochrome(BuildContext c, CvData cv) {
  final theme = Theme.of(c);

  return A4Shell(
    bg: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 2.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Profesyonel' : cv.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        letterSpacing: 1.8,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (cv.email.trim().isNotEmpty)
                    Text(cv.email, style: const TextStyle(fontSize: 10.5)),
                  if (cv.phone.trim().isNotEmpty)
                    Text(cv.phone, style: const TextStyle(fontSize: 10.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.summary.isNotEmpty) ...[
                    const Text(
                      'PROFIL',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 55, color: Colors.black),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(child: SizedBox(width: 24.0)),
                          TextSpan(
                            text: cv.summary,
                            style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (cv.experiences.isNotEmpty) ...[
                    const Text(
                      'DENEYİM',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 55, color: Colors.black),
                    const SizedBox(height: 8),
                    ...buildExperienceEntries(c, cv, accent: Colors.black87),
                    const SizedBox(height: 14),
                  ],
                  if (cv.projects.isNotEmpty) ...[
                    const Text(
                      'PROJELER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 55, color: Colors.black),
                    const SizedBox(height: 8),
                    ...buildProjectEntries(c, cv, accent: Colors.black87),
                    const SizedBox(height: 14),
                  ],
                  if (cv.volunteering.isNotEmpty) ...[
                    const Text(
                      'GÖNÜLLÜLÜK',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 55, color: Colors.black),
                    const SizedBox(height: 8),
                    ...buildVolunteeringEntries(c, cv, accent: Colors.black87),
                    const SizedBox(height: 14),
                  ],
                  if (cv.references.isNotEmpty) ...[
                    const Text(
                      'REFERANSLAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 55, color: Colors.black),
                    const SizedBox(height: 8),
                    ...buildReferenceEntries(c, cv, bulletColor: Colors.black87),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 22),
            SizedBox(
              width: 210,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty) ...[
                    const Text(
                      'YETKİNLİKLER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 38, color: Colors.black),
                    const SizedBox(height: 8),
                    skillWrap(c, cv, chipColor: Colors.black12),
                    const SizedBox(height: 14),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    const Text(
                      'EĞİTİM',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 38, color: Colors.black),
                    const SizedBox(height: 8),
                    eduList(c, cv, titleColor: Colors.black87),
                    const SizedBox(height: 14),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    const Text(
                      'SERTİFİKALAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 38, color: Colors.black),
                    const SizedBox(height: 8),
                    ...buildCertificateEntries(c, cv),
                    const SizedBox(height: 14),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    const Text(
                      'DİLLER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 38, color: Colors.black),
                    const SizedBox(height: 8),
                    langList(c, cv),
                    const SizedBox(height: 14),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    const Text(
                      'HOBİLER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 38, color: Colors.black),
                    const SizedBox(height: 8),
                    ...cv.hobbies.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(h, style: const TextStyle(fontSize: 10.5, decoration: TextDecoration.none)),
                        )),
                    const SizedBox(height: 14),
                  ],
                  if (cv.licenses.isNotEmpty) ...[
                    const Text(
                      'EHLİYET',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 2, width: 38, color: Colors.black),
                    const SizedBox(height: 8),
                    ...buildLicenseEntries(c, cv),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  17) GRADIENT EDGE                                                          */
/* -------------------------------------------------------------------------- */
Widget t17GradientEdge(BuildContext c, CvData cv) {
  const gradientColors = [Color(0xFF36D1DC), Color(0xFF5B86E5)];
  const accentColor = Color(0xFF3572E5);

  return A4Shell(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                cv.title.isEmpty ? 'Pozisyon / Ünvan' : cv.title,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              if (cv.summary.isNotEmpty) ...[
                sectionTitle(c, 'Profil', color: accentColor),
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      const WidgetSpan(child: SizedBox(width: 24.0)),
                      TextSpan(
                        text: cv.summary,
                        style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
              ],
              if (cv.experiences.isNotEmpty) ...[
                sectionTitle(c, 'Deneyimler', color: accentColor),
                ...buildExperienceEntries(c, cv, accent: accentColor),
              ],
              if (cv.educations.isNotEmpty) ...[
                sectionTitle(c, 'Eğitim', color: accentColor),
                eduList(c, cv, titleColor: accentColor),
              ],
              if (cv.projects.isNotEmpty) ...[
                sectionTitle(c, 'Projeler', color: accentColor),
                ...buildProjectEntries(c, cv, accent: accentColor),
              ],
              if (cv.volunteering.isNotEmpty) ...[
                sectionTitle(c, 'Gönüllülük', color: accentColor),
                ...buildVolunteeringEntries(c, cv, accent: accentColor),
              ],
              if (cv.certificates.isNotEmpty) ...[
                sectionTitle(c, 'Sertifikalar', color: accentColor),
                ...buildCertificateEntries(c, cv),
              ],
              if (cv.references.isNotEmpty) ...[
                sectionTitle(c, 'Referanslar', color: accentColor),
                ...buildReferenceEntries(c, cv, bulletColor: accentColor.withOpacity(0.4)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 26),
        Container(
          width: 230,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'İLETİŞİM',
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 0.6,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              contactBlock(c, cv, iconColor: Colors.white, textColor: Colors.white),
              if (cv.skills.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'YETENEKLER',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 0.6,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                skillProgressList(
                  c,
                  cv,
                  barColor: Colors.white,
                  backgroundColor: Colors.white24,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                  levelStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
              ],
              if (cv.languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'DİLLER',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 0.6,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                languageChipWrap(
                  c,
                  cv,
                  bgColor: Colors.white24,
                  textColor: Colors.white,
                  borderColor: Colors.white30,
                ),
              ],
              if (cv.hobbies.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'HOBİLER',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 0.6,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...cv.hobbies.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(h,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, decoration: TextDecoration.none)),
                    )),
              ],
              if (cv.licenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'EHLİYET',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 0.6,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...cv.licenses.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(l,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, decoration: TextDecoration.none)),
                    )),
              ],
              if (cv.references.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'REFERANSLAR',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 0.6,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...cv.references.map((ref) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ref.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5)),
                          if (ref.position.trim().isNotEmpty)
                            Text(ref.position,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 9.5)),
                          if (ref.contact.trim().isNotEmpty)
                            Text(ref.contact,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 9.5)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  18) CREATIVE PINK                                                          */
/* -------------------------------------------------------------------------- */
Widget t18CreativePink(BuildContext c, CvData cv) {
  const gradientColors = [Color(0xFFFF758C), Color(0xFFFF7EB3)];
  const accentColor = Color(0xFFFE5BA0);

  final summaryText = cv.summary.isEmpty
      ? 'Deneyiminizi parlak örneklerle anlatın; ölçülebilir başarı eklemeyi unutmayın.'
      : cv.summary;

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 30, 32, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              cv.title.isEmpty ? 'Yaratıcı Uzman' : cv.title,
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                            ),
                            const SizedBox(height: 16),
                            if (cv.email.trim().isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.mail_outline, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(cv.email,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10.5)),
                                  ),
                                ],
                              ),
                            if (cv.phone.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(cv.phone,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10.5)),
                                  ],
                                ),
                              ),
                            if (cv.address.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(cv.address,
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 10.5)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 22),
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.7), width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          backgroundImage: (cv.photoUrl != null && cv.photoUrl!.isNotEmpty)
                              ? NetworkImage(cv.photoUrl!)
                              : null,
                          child: (cv.photoUrl == null || cv.photoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 44, color: Colors.white70)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 30, 32, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kısa Özet',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          children: [
                            const WidgetSpan(child: SizedBox(width: 24.0)),
                            TextSpan(
                              text: summaryText,
                              style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                            ),
                          ],
                        ),
                      ),
                      if (cv.hobbies.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('Öne Çıkan İlgi Alanları',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                              fontSize: 11.5,
                            )),
                        const SizedBox(height: 8),
                        hobbyChipWrap(
                          c,
                          cv,
                          bgColor: const Color(0xFFFFEEF5),
                          textColor: const Color(0xFF85425A),
                          borderColor: const Color(0xFFFFC6D9),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.experiences.isNotEmpty) ...[
                    sectionTitle(c, 'Deneyimler', color: accentColor),
                    ...buildExperienceEntries(c, cv, accent: accentColor),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    sectionTitle(c, 'Eğitim', color: accentColor),
                    eduList(c, cv, titleColor: accentColor),
                  ],
                  if (cv.projects.isNotEmpty) ...[
                    sectionTitle(c, 'Projeler', color: accentColor),
                    ...buildProjectEntries(c, cv, accent: accentColor),
                  ],
                  if (cv.volunteering.isNotEmpty) ...[
                    sectionTitle(c, 'Gönüllülük', color: accentColor),
                    ...buildVolunteeringEntries(c, cv, accent: accentColor),
                  ],
                  if (cv.references.isNotEmpty) ...[
                    sectionTitle(c, 'Referanslar', color: accentColor),
                    ...buildReferenceEntries(c, cv,
                        bulletColor: accentColor.withOpacity(0.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 230,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty) ...[
                    sectionTitle(c, 'Yetkinlikler', color: accentColor),
                    skillProgressList(
                      c,
                      cv,
                      barColor: accentColor,
                      backgroundColor: const Color(0xFFFFD3E3),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accentColor),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFFFEEF5),
                      textColor: const Color(0xFF5A1F38),
                      borderColor: const Color(0xFFFFC6D9),
                    ),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accentColor),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.licenses.isNotEmpty) ...[
                    sectionTitle(c, 'Ehliyet', color: accentColor),
                    ...buildLicenseEntries(c, cv),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  19) EXECUTIVE GOLD                                                         */
/* -------------------------------------------------------------------------- */
Widget t19ExecutiveGold(BuildContext c, CvData cv) {
  const accent = Color(0xFFC08200);
  final theme = Theme.of(c);
  final summaryText = cv.summary.isEmpty
      ? 'Liderlik başarılarınızı ve stratejik katkınızı kısa, güçlü cümlelerle aktarın.'
      : cv.summary;

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 26),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFE6B800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Üst Düzey Yönetici' : cv.title,
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(child: SizedBox(width: 24.0)),
                          TextSpan(
                            text: summaryText,
                            style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 11, decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cv.email.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mail_outline, size: 14, color: Colors.black87),
                          const SizedBox(width: 6),
                          Text(cv.email,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  if (cv.phone.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.black87),
                          const SizedBox(width: 6),
                          Text(cv.phone,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  if (cv.address.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.black87),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(cv.address,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 10.5)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.experiences.isNotEmpty) ...[
                    sectionTitle(c, 'Liderlik Deneyimi', color: accent),
                    ...buildExperienceEntries(c, cv, accent: accent),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    sectionTitle(c, 'Eğitim', color: accent),
                    eduList(c, cv, titleColor: accent),
                  ],
                  if (cv.projects.isNotEmpty) ...[
                    sectionTitle(c, 'Stratejik Projeler', color: accent),
                    ...buildProjectEntries(c, cv, accent: accent),
                  ],
                  if (cv.volunteering.isNotEmpty) ...[
                    sectionTitle(c, 'Gönüllülük', color: accent),
                    ...buildVolunteeringEntries(c, cv, accent: accent),
                  ],
                  if (cv.references.isNotEmpty) ...[
                    sectionTitle(c, 'Referanslar', color: accent),
                    ...buildReferenceEntries(c, cv, bulletColor: accent.withOpacity(0.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 26),
            SizedBox(
              width: 230,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty) ...[
                    sectionTitle(c, 'Yönetim Yetkinlikleri', color: accent),
                    skillProgressList(
                      c,
                      cv,
                      barColor: accent,
                      backgroundColor: const Color(0xFFFFF2C6),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFFFF7E0),
                      textColor: const Color(0xFF5B4100),
                      borderColor: const Color(0xFFFFE5A6),
                    ),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(c, cv,
                        bgColor: const Color(0xFFFFF7E0),
                        textColor: const Color(0xFF5B4100),
                        borderColor: const Color(0xFFFFE5A6)),
                  ],
                  if (cv.licenses.isNotEmpty) ...[
                    sectionTitle(c, 'Ehliyet', color: accent),
                    ...buildLicenseEntries(c, cv),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  20) COMPACT RESUME (KISA FORM)                                             */
/* -------------------------------------------------------------------------- */
Widget t20CompactResume(BuildContext c, CvData cv) {
  const accent = Color(0xFF009688);
  final theme = Theme.of(c);

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Pozisyon' : cv.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (cv.email.trim().isNotEmpty)
                    Text(cv.email, style: const TextStyle(fontSize: 10.5)),
                  if (cv.phone.trim().isNotEmpty)
                    Text(cv.phone, style: const TextStyle(fontSize: 10.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (cv.summary.isNotEmpty) ...[
          sectionTitle(c, 'Özet', color: accent),
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: [
                const WidgetSpan(child: SizedBox(width: 24.0)),
                TextSpan(
                  text: cv.summary,
                  style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (cv.experiences.isNotEmpty) ...[
          sectionTitle(c, 'Deneyimler', color: accent),
          ...cv.experiences.take(3).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${e.position} · ${e.company} (${e.start} – ${e.end.isEmpty ? "Güncel" : e.end})',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
        ],
        if (cv.educations.isNotEmpty) ...[
          sectionTitle(c, 'Eğitim', color: accent),
          eduList(c, cv, titleColor: accent),
          const SizedBox(height: 12),
        ],
        if (cv.projects.isNotEmpty) ...[
          sectionTitle(c, 'Projeler', color: accent),
          ...buildProjectEntries(c, cv, accent: accent),
          const SizedBox(height: 12),
        ],
        if (cv.certificates.isNotEmpty) ...[
          sectionTitle(c, 'Sertifikalar', color: accent),
          ...buildCertificateEntries(c, cv),
          const SizedBox(height: 12),
        ],
        if (cv.volunteering.isNotEmpty) ...[
          sectionTitle(c, 'Gönüllülük', color: accent),
          ...buildVolunteeringEntries(c, cv, accent: accent),
          const SizedBox(height: 12),
        ],
        if (cv.skills.isNotEmpty) ...[
          sectionTitle(c, 'Yetenekler', color: accent),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: cv.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2DFDB),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00695C),
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (cv.languages.isNotEmpty) ...[
          sectionTitle(c, 'Diller', color: accent),
          langList(c, cv),
          const SizedBox(height: 12),
        ],
        if (cv.hobbies.isNotEmpty) ...[
          sectionTitle(c, 'Hobiler', color: accent),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: cv.hobbies.map((h) => Text(
              '• $h',
              style: const TextStyle(fontSize: 10.5, decoration: TextDecoration.none),
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (cv.licenses.isNotEmpty) ...[
          sectionTitle(c, 'Ehliyet', color: accent),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: cv.licenses.map((l) => Text(
              '• $l',
              style: const TextStyle(fontSize: 10.5, decoration: TextDecoration.none),
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (cv.references.isNotEmpty) ...[
          sectionTitle(c, 'Referanslar', color: accent),
          ...buildReferenceEntries(c, cv, bulletColor: accent.withOpacity(0.4)),
        ],
      ],
    ),
  );
}
