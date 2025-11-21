// lib/cv/cv_sablon.dart
import 'package:flutter/material.dart';
import 'cv_olustur.dart' show CvData;
import 'cv_helpers.dart';
import 'cv_sablon2.dart';

/* -------------------------------------------------------------------------- */
/*  1) MINIMAL WHITE                                                           */
/* -------------------------------------------------------------------------- */

Widget _t1MinimalWhite(BuildContext c, CvData cv) {
  return A4Shell(
    child: ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                if (cv.photoUrl != null && cv.photoUrl!.isNotEmpty) ...[
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: NetworkImage(cv.photoUrl!),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  cv.title.isEmpty ? 'Pozisyon / Ünvan' : cv.title,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),
          if (cv.summary.trim().isNotEmpty) ...[
            sectionTitle(c, 'Öz Geçmiş', fontSize: 13),
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
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.experiences.isNotEmpty) ...[
            sectionTitle(c, 'Deneyimler', fontSize: 13),
            expList(c, cv),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.educations.isNotEmpty) ...[
            sectionTitle(c, 'Eğitim', fontSize: 13),
            eduList(c, cv),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.skills.isNotEmpty) ...[
            sectionTitle(c, 'Yetenekler', fontSize: 13),
            ...cv.skills.map((raw) {
              final data = parseSkillMeter(raw);
              final levelText = data.levelLabel ?? '';
              final displayText = levelText.isNotEmpty 
                  ? '${data.label} — $levelText'
                  : data.label;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                ),
              );
            }),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.languages.isNotEmpty) ...[
            sectionTitle(c, 'Diller', fontSize: 13),
            langList(c, cv),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.projects.isNotEmpty) ...[
            sectionTitle(c, 'Projeler', fontSize: 13),
            ...buildProjectEntries(c, cv, accent: Colors.black87, textColor: Colors.black87),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.certificates.isNotEmpty) ...[
            sectionTitle(c, 'Sertifikalar', fontSize: 13),
            ...buildCertificateEntries(c, cv),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.volunteering.isNotEmpty) ...[
            sectionTitle(c, 'Gönüllülük Faaliyetleri', fontSize: 13),
            ...buildVolunteeringEntries(c, cv, textColor: Colors.black87),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.hobbies.isNotEmpty) ...[
            sectionTitle(c, 'Hobiler / İlgi Alanları', fontSize: 13),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: cv.hobbies.map((h) => Text(
                '• $h',
                style: const TextStyle(fontSize: 11, decoration: TextDecoration.none),
              )).toList(),
            ),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.licenses.isNotEmpty) ...[
            sectionTitle(c, 'Sürücü Belgesi', fontSize: 13),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: cv.licenses.map((license) => Text(
                '• $license',
                style: const TextStyle(fontSize: 11, decoration: TextDecoration.none),
              )).toList(),
            ),
            Divider(color: Colors.grey.shade300),
          ],
          if (cv.references.isNotEmpty) ...[
            sectionTitle(c, 'Referanslar', fontSize: 13),
            ...buildReferenceEntries(c, cv, bulletColor: Colors.black26, showBullet: false),
          ],
        ],
      ),
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  2) MINIMAL PRO (GRADYANLI SOL PANEL)                                      */
/* -------------------------------------------------------------------------- */

Widget _t2MinimalPro(BuildContext c, CvData cv) {
  const gradientColors = [Color(0xFF2440D7), Color(0xFF6A24E6)];
  const accentColor = Color(0xFF1D64FF);
  const nameAccent = Color(0xFF8EE7FF);

  final theme = Theme.of(c);
  final displayName = (cv.name.isEmpty ? 'Adı Soyadı' : cv.name).trim();
  final parts = displayName.split(RegExp(r'\s+'));
  final firstName = parts.isNotEmpty ? parts.first : displayName;
  final restName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

  Widget sidebarHeading(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
      );

  final educationItems = cv.educations.map((edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.level.trim().isNotEmpty 
                ? '${edu.level} • ${edu.school}'
                : edu.school,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.normal,
              fontSize: 11.5,
              decoration: TextDecoration.none,
            ),
          ),
          if (edu.department.trim().isNotEmpty)
            Text(edu.department, style: const TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.none)),
          Text(
            '${edu.start} — ${edu.end}',
            style: const TextStyle(color: Colors.white60, fontSize: 10.5, decoration: TextDecoration.none),
          ),
          if (edu.note.trim().isNotEmpty)
            Text(
              edu.note,
              style: const TextStyle(color: Colors.white60, fontSize: 10.5, decoration: TextDecoration.none),
            ),
        ],
      ),
    );
  }).toList();

  final certificateItems = cv.certificates.map((cert) {
    final info = [cert.org, cert.year].where((el) => el.trim().isNotEmpty).join(' • ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cert.title,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.normal, fontSize: 11.5, decoration: TextDecoration.none)),
          if (info.isNotEmpty)
            Text(info, style: const TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.none)),
        ],
      ),
    );
  }).toList();

  final languageItems = cv.languages.map((lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '${lang.name} — ${lang.level}',
        style: const TextStyle(color: Colors.white70, fontSize: 11.5, decoration: TextDecoration.none),
      ),
    );
  }).toList();

  final referenceItems = cv.references.map((ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.name,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.normal, fontSize: 11.5, decoration: TextDecoration.none)),
          if (ref.position.trim().isNotEmpty)
            Text(ref.position, style: const TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.none)),
          if (ref.contact.trim().isNotEmpty)
            Text(ref.contact, style: const TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.none)),
        ],
      ),
    );
  }).toList();

  final rightSections = <Widget>[];

  void addSection(String title, List<Widget> children) {
    if (children.isEmpty) return;
    if (rightSections.isNotEmpty) {
      rightSections.add(const SizedBox(height: 22));
      rightSections.add(
        dottedDivider(color: const Color(0xFFE5EAFB), dashWidth: 8, gap: 5, thickness: 1),
      );
      rightSections.add(const SizedBox(height: 22));
    }
    rightSections.add(
      Text(
        title.toUpperCase(),
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: accentColor,
          letterSpacing: 0.8,
        ),
      ),
    );
    rightSections.add(const SizedBox(height: 10));
    rightSections.addAll(children);
  }

  if (cv.summary.trim().isNotEmpty) {
    addSection('ÖZGEÇMİŞ', [
      RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          children: [
            const WidgetSpan(child: SizedBox(width: 24.0)),
            TextSpan(
              text: cv.summary,
              style: theme.textTheme.bodyMedium!.copyWith(height: 1.5, fontSize: 11),
            ),
          ],
        ),
      ),
    ]);
  }

  final expWidgets = buildExperienceEntries(
    c,
    cv,
    accent: accentColor,
    bulletColor: accentColor.withValues(alpha: 0.85),
  );
  if (expWidgets.isNotEmpty) {
    addSection('DENEYİMLER', expWidgets);
  }

  final eduWidgets = cv.educations.map((edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.level.trim().isNotEmpty 
                      ? '${edu.level} • ${edu.department}'
                      : edu.department,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  '${edu.school} • ${edu.start} — ${edu.end}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (edu.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    edu.note,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black87,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }).toList();
  if (eduWidgets.isNotEmpty) {
    addSection('EĞİTİM', eduWidgets);
  }

  if (rightSections.isEmpty) {
    rightSections.add(
      Text(
        'Henüz içerik eklenmedi.',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  return A4Shell(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.fromLTRB(28, 32, 24, 34),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (cv.photoUrl != null && cv.photoUrl!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(cv.photoUrl!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              RichText(
                text: TextSpan(
                  text: firstName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  children: restName.isNotEmpty
                      ? [
                          TextSpan(
                            text: ' $restName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ]
                      : const [],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cv.title.isEmpty ? 'Pozisyon/Ünvan' : cv.title,
                style: const TextStyle(color: Colors.white70, fontSize: 11.5, decoration: TextDecoration.none),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white24),
              if (cv.email.trim().isNotEmpty ||
                  cv.phone.trim().isNotEmpty ||
                  cv.address.trim().isNotEmpty) ...[
                sidebarHeading('İLETİŞİM'),
                contactBlock(
                  c,
                  cv,
                  iconColor: Colors.white,
                  textColor: Colors.white,
                ),
              ],
              if (cv.skills.isNotEmpty) ...[
                sidebarHeading('YETENEKLER'),
                const SizedBox(height: 8),
                ...cv.skills.map((raw) {
                  final data = parseSkillMeter(raw);
                  final levelText = data.levelLabel ?? '';
                  final displayText = levelText.isNotEmpty 
                      ? '${data.label} — $levelText'
                      : data.label;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      displayText,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5, decoration: TextDecoration.none),
                    ),
                  );
                }),
              ],
              if (cv.projects.isNotEmpty) ...[
                sidebarHeading('PROJELER'),
                const SizedBox(height: 8),
                ...cv.projects.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.normal,
                            fontSize: 11.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (p.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            p.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
              if (certificateItems.isNotEmpty) ...[
                sidebarHeading('SERTİFİKALAR'),
                ...certificateItems,
              ],
              if (languageItems.isNotEmpty) ...[
                sidebarHeading('DİLLER'),
                ...languageItems,
              ],
              if (referenceItems.isNotEmpty) ...[
                sidebarHeading('Referanslar'),
                ...referenceItems,
              ],
              if (cv.hobbies.isNotEmpty) ...[
                sidebarHeading('HOBİLER'),
                ...cv.hobbies.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
              if (cv.licenses.isNotEmpty) ...[
                sidebarHeading('EHLİYET'),
                ...cv.licenses.map(
                  (license) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      license,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
              if (cv.volunteering.isNotEmpty) ...[
                sidebarHeading('GÖNÜLLÜLÜK FAALİYETLERİ'),
                ...cv.volunteering.map((v) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.role,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.normal,
                            fontSize: 11.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (v.organization.trim().isNotEmpty)
                          Text(
                            v.organization,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        if (v.start.trim().isNotEmpty || v.end.trim().isNotEmpty)
                          Text(
                            '${v.start} — ${v.end}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(36, 34, 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: rightSections,
            ),
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  3) CREATIVE (MODERN GRADYANLI)                                            */
/* -------------------------------------------------------------------------- */

Widget _t3Creative(BuildContext c, CvData cv) {
  const gradientColors = [Color(0xFF005CFF), Color(0xFF29C4FF)];
  const accentColor = Color(0xFF0B4CE3);
  final theme = Theme.of(c);

  final summaryText = cv.summary.isEmpty
      ? 'Kariyer hedefinizi ve öne çıkan başarılarınızı kısa ve çarpıcı biçimde yazın.'
      : cv.summary;

  Widget buildSectionTitle(String title) => sectionTitle(c, title, color: accentColor);

  final certificationWidgets = buildCertificateEntries(c, cv);
  final projectWidgets = buildProjectEntries(c, cv, accent: accentColor);
  final experienceWidgets = buildExperienceEntries(c, cv, accent: accentColor);
  final referenceWidgets =
      buildReferenceEntries(c, cv, bulletColor: accentColor.withValues(alpha: 0.4));
  final volunteerWidgets = buildVolunteeringEntries(c, cv, accent: accentColor);

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 34),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(14),
            ),
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
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Pozisyon / Ünvan' : cv.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(child: SizedBox(width: 24.0)),
                          TextSpan(
                            text: summaryText,
                            style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 11, decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cv.email.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.mail_outline, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    cv.email,
                                    style: const TextStyle(color: Colors.white, height: 1.3, fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (cv.phone.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    cv.phone,
                                    style: const TextStyle(color: Colors.white, height: 1.3, fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (cv.address.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    cv.address,
                                    style: const TextStyle(color: Colors.white, height: 1.3, fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundImage: (cv.photoUrl != null && cv.photoUrl!.isNotEmpty)
                      ? NetworkImage(cv.photoUrl!)
                      : null,
                  backgroundColor: Colors.white24,
                  child: (cv.photoUrl == null || cv.photoUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 48, color: Colors.white70)
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(30, 26, 30, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (experienceWidgets.isNotEmpty) ...[
                          buildSectionTitle('Deneyimler'),
                          ...experienceWidgets,
                        ],
                        if (projectWidgets.isNotEmpty) ...[
                          buildSectionTitle('Projeler'),
                          ...projectWidgets,
                        ],
                        if (volunteerWidgets.isNotEmpty) ...[
                          buildSectionTitle('Gönüllülük Faaliyetleri'),
                          ...volunteerWidgets,
                        ],
                        if (cv.educations.isNotEmpty) ...[
                          buildSectionTitle('Eğitim'),
                          eduList(c, cv, titleColor: accentColor),
                        ],
                        if (referenceWidgets.isNotEmpty) ...[
                          buildSectionTitle('Referanslar'),
                          ...referenceWidgets,
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
                          buildSectionTitle('Yetenekler'),
                          skillProgressList(
                            c,
                            cv,
                            barColor: accentColor,
                            backgroundColor: const Color(0xFFE4EBFF),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (cv.languages.isNotEmpty) ...[
                          buildSectionTitle('Diller'),
                          languageChipWrap(
                            c,
                            cv,
                            bgColor: const Color(0xFFF1F5FF),
                            textColor: const Color(0xFF1F2E55),
                            borderColor: const Color(0xFFDDE5FF),
                          ),
                        ],
                        if (certificationWidgets.isNotEmpty) ...[
                          buildSectionTitle('Sertifikalar'),
                          ...certificationWidgets,
                        ],
                        if (cv.hobbies.isNotEmpty) ...[
                          buildSectionTitle('Hobiler'),
                          hobbyChipWrap(
                            c,
                            cv,
                            bgColor: const Color(0xFFF1F5FF),
                            textColor: const Color(0xFF1F2E55),
                            borderColor: const Color(0xFFDDE5FF),
                          ),
                        ],
                        if (cv.licenses.isNotEmpty) ...[
                          buildSectionTitle('Ehliyet'),
                          ...buildLicenseEntries(c, cv),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  4) ANALYST (KIRMIZI ÇİZGİLİ)                                               */
/* -------------------------------------------------------------------------- */

Widget _t4Analyst(BuildContext c, CvData cv) {
  const accent = Color(0xFFE53935);
  final theme = Theme.of(c);
  final summaryText = cv.summary.isEmpty
      ? 'Analitik becerilerinizi ve ölçülebilir başarınızı vurgulayan kısa bir özet ekleyin.'
      : cv.summary;

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5F6D), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(24)),
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
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Kıdemli Analist' : cv.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(child: SizedBox(width: 24.0)),
                          TextSpan(
                            text: summaryText,
                            style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 11, decoration: TextDecoration.none),
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
                          Icon(Icons.mail_outline, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(cv.email, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  if (cv.phone.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(cv.phone, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  if (cv.address.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(cv.address, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
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
                    sectionTitle(c, 'Deneyimler', color: accent),
                    ...buildExperienceEntries(c, cv, accent: accent),
                  ],
                  if (cv.projects.isNotEmpty) ...[
                    sectionTitle(c, 'Projeler', color: accent),
                    ...buildProjectEntries(c, cv, accent: accent),
                  ],
                  if (cv.volunteering.isNotEmpty) ...[
                    sectionTitle(c, 'Gönüllülük Faaliyetleri', color: accent),
                    ...buildVolunteeringEntries(c, cv, accent: accent),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    sectionTitle(c, 'Eğitim', color: accent),
                    eduList(c, cv, titleColor: accent),
                  ],
                  if (cv.references.isNotEmpty) ...[
                    sectionTitle(c, 'Referanslar', color: accent),
                    ...buildReferenceEntries(c, cv, bulletColor: accent.withValues(alpha: 0.45)),
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
                    sectionTitle(c, 'Teknik Yetkinlikler', color: accent),
                    skillProgressList(
                      c,
                      cv,
                      barColor: accent,
                      backgroundColor: const Color(0xFFFFE0E0),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFFFF2F2),
                      textColor: const Color(0xFF861B2A),
                      borderColor: const Color(0xFFFFD0D0),
                    ),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFFFF2F2),
                      textColor: const Color(0xFF861B2A),
                      borderColor: const Color(0xFFFFD0D0),
                    ),
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
/*  5) DEVELOPER DARK (KOYU)                                                   */
/* -------------------------------------------------------------------------- */

Widget _t5DeveloperDark(BuildContext c, CvData cv) {
  return A4Shell(
    bg: const Color(0xFF101722),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 230,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2430),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cv.photoUrl != null && cv.photoUrl!.isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: NetworkImage(cv.photoUrl!),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              Text(
                cv.title.isEmpty ? 'Flutter Developer' : cv.title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text('İLETİŞİM',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      letterSpacing: 0.2)),
              const SizedBox(height: 6),
              contactBlock(c, cv, iconColor: Colors.white, textColor: Colors.white),
              if (cv.skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Yetenekler',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 6),
                skillWrap(c, cv, chipColor: Colors.white10, textColor: Colors.white),
              ],
              if (cv.languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Diller',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 6),
                langList(c, cv, textColor: Colors.white70),
              ],
              if (cv.licenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Ehliyet',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 6),
                ...cv.licenses.map((l) => Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10.5, decoration: TextDecoration.none))),
              ],
              if (cv.hobbies.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Hobiler',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 6),
                ...cv.hobbies.map((h) => Text(h, style: const TextStyle(color: Colors.white70, fontSize: 10.5, decoration: TextDecoration.none))),
              ],
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cv.summary.trim().isNotEmpty) ...[
                const Text('Özet',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      const WidgetSpan(child: SizedBox(width: 24.0)),
                      TextSpan(
                        text: cv.summary,
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.5, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (cv.experiences.isNotEmpty) ...[
                const Text('Deneyimler',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                expList(c, cv, titleColor: Colors.white, textColor: Colors.white),
              ],
              if (cv.educations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Eğitim',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                eduList(c, cv, titleColor: Colors.white, textColor: Colors.white),
              ],
              if (cv.projects.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Projeler',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                ...buildProjectEntries(c, cv, accent: Colors.blue.shade200, textColor: Colors.white),
              ],
              if (cv.volunteering.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Gönüllülük',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                ...buildVolunteeringEntries(c, cv, accent: Colors.blue.shade200, textColor: Colors.white),
              ],
              if (cv.certificates.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Sertifikalar',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                ...buildCertificateEntries(c, cv, textColor: Colors.white),
              ],
              if (cv.references.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Referanslar',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                ...buildReferenceEntries(c, cv, bulletColor: Colors.blue.shade100, textColor: Colors.white),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  6) MODERN LINE (İNCE MAVİ ÇİZGİ)                                           */
/* -------------------------------------------------------------------------- */
Widget _t6ModernLine(BuildContext c, CvData cv) {
  return A4Shell(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 4, color: Colors.indigo, height: double.infinity),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
              Text(cv.title.isEmpty ? 'Pozisyon / Rol' : cv.title,
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 16),
              if (cv.summary.isNotEmpty) ...[
                sectionTitle(c, 'Özet', color: Colors.indigo),
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
                sectionTitle(c, 'Deneyimler', color: Colors.indigo),
                expList(c, cv),
                const SizedBox(height: 12),
              ],
              if (cv.educations.isNotEmpty) ...[
                sectionTitle(c, 'Eğitim', color: Colors.indigo),
                eduList(c, cv),
                const SizedBox(height: 12),
              ],
              if (cv.projects.isNotEmpty) ...[
                sectionTitle(c, 'Projeler', color: Colors.indigo),
                ...buildProjectEntries(c, cv, accent: Colors.indigo),
                const SizedBox(height: 12),
              ],
              if (cv.volunteering.isNotEmpty) ...[
                sectionTitle(c, 'Gönüllülük Faaliyetleri', color: Colors.indigo),
                ...buildVolunteeringEntries(c, cv, accent: Colors.indigo),
                const SizedBox(height: 12),
              ],
              if (cv.skills.isNotEmpty) ...[
                sectionTitle(c, 'Yetenekler', color: Colors.indigo),
                skillWrap(c, cv),
                const SizedBox(height: 12),
              ],
              if (cv.languages.isNotEmpty) ...[
                sectionTitle(c, 'Diller', color: Colors.indigo),
                langList(c, cv),
                const SizedBox(height: 12),
              ],
              if (cv.certificates.isNotEmpty) ...[
                sectionTitle(c, 'Sertifikalar', color: Colors.indigo),
                ...buildCertificateEntries(c, cv),
                const SizedBox(height: 12),
              ],
              if (cv.hobbies.isNotEmpty) ...[
                sectionTitle(c, 'Hobiler', color: Colors.indigo),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: cv.hobbies.map((h) => Text(
                    '• $h',
                    style: const TextStyle(fontSize: 11, decoration: TextDecoration.none),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (cv.licenses.isNotEmpty) ...[
                sectionTitle(c, 'Ehliyet', color: Colors.indigo),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: cv.licenses.map((l) => Text(
                    '• $l',
                    style: const TextStyle(fontSize: 11, decoration: TextDecoration.none),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (cv.references.isNotEmpty) ...[
                sectionTitle(c, 'Referanslar', color: Colors.indigo),
                ...buildReferenceEntries(c, cv),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  7) ELEGANT PURPLE (ÜSTTE KAVİSLİ BLOK)                                    */
/* -------------------------------------------------------------------------- */
Widget _t7ElegantPurple(BuildContext c, CvData cv) {
  const accent = Color(0xFF5E60CE);
  final theme = Theme.of(c);
  final subtitleStyle = theme.textTheme.bodySmall!.copyWith(color: Colors.black54);

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5E60CE), Color(0xFF6930C3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundImage: (cv.photoUrl != null && cv.photoUrl!.isNotEmpty)
                    ? NetworkImage(cv.photoUrl!)
                    : null,
                backgroundColor: Colors.white24,
                child: (cv.photoUrl == null || cv.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Pozisyon' : cv.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    if (cv.email.trim().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.mail_outline, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(cv.email,
                                style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                    if (cv.phone.trim().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(cv.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
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
          const SizedBox(height: 18),
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
                    expList(c, cv, titleColor: const Color(0xFF5337A6)),
                  ],
                  if (cv.educations.isNotEmpty) ...[
                    sectionTitle(c, 'Eğitim', color: accent),
                    eduList(c, cv, titleColor: const Color(0xFF5337A6)),
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
                    ...buildReferenceEntries(c, cv),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cv.skills.isNotEmpty) ...[
                    sectionTitle(c, 'Yetenekler', color: accent),
                    skillWrap(c, cv, chipColor: const Color(0xFFEAECFF)),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    langList(c, cv),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(c, cv, bgColor: const Color(0xFFEAECFF), textColor: const Color(0xFF5337A6)),
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
/*  8) PROFESSIONAL GRAY                                                       */
/* -------------------------------------------------------------------------- */
Widget _t8ProfessionalGray(BuildContext c, CvData cv) {
  const accent = Color(0xFF546E7A);
  final theme = Theme.of(c);
  final summaryText = cv.summary.isEmpty
      ? 'Profesyonel deneyiminizi öne çıkaran kısa bir özet ekleyin.'
      : cv.summary;

  return A4Shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(30, 26, 30, 26),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(22),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Profesyonel Ünvan' : cv.title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cv.email.trim().isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mail_outline, size: 14, color: accent),
                        const SizedBox(width: 6),
                        Text(cv.email,
                            style: const TextStyle(color: Colors.black87, fontSize: 10.5)),
                      ],
                    ),
                  if (cv.phone.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
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
                  if (cv.address.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(cv.address,
                                style: const TextStyle(color: Colors.black87, fontSize: 10.5)),
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
                    ...buildReferenceEntries(c, cv, bulletColor: accent.withValues(alpha: 0.4)),
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
                    sectionTitle(c, 'Yetenekler', color: accent),
                    skillProgressList(
                      c,
                      cv,
                      barColor: accent,
                      backgroundColor: const Color(0xFFE0E5E9),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFF0F3F5),
                      textColor: const Color(0xFF37474F),
                      borderColor: const Color(0xFFE1E5E8),
                    ),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(c, cv,
                        bgColor: const Color(0xFFF0F3F5),
                        textColor: const Color(0xFF37474F),
                        borderColor: const Color(0xFFE1E5E8)),
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
/*  9) SIDEBAR ICONIC                                                          */
/* -------------------------------------------------------------------------- */
Widget _t9SidebarIconic(BuildContext c, CvData cv) {
  const accent = Color(0xFF5E35B1);
  final theme = Theme.of(c);

  return A4Shell(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 230,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white24,
                  backgroundImage: (cv.photoUrl != null && cv.photoUrl!.isNotEmpty)
                      ? NetworkImage(cv.photoUrl!)
                      : null,
                  child: (cv.photoUrl == null || cv.photoUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 52, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                cv.name.isEmpty ? 'Ad Soyad' : cv.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                cv.title.isEmpty ? 'Uzman Pozisyon' : cv.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              dottedDivider(width: 170.0, thickness: 1.0, color: Colors.white30),
              const SizedBox(height: 16),
              if (cv.email.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_outline, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(cv.email,
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
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
                      const Icon(Icons.phone_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(cv.phone,
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
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
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(cv.address,
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              if (cv.skills.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'YETKİNLİKLER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
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
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
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
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...cv.hobbies.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(h,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, decoration: TextDecoration.none)),
                  ),
                ),
              ],
              if (cv.licenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'EHLİYET',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...cv.licenses.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, decoration: TextDecoration.none)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (cv.certificates.isNotEmpty) ...[
                sectionTitle(c, 'Sertifikalar', color: accent),
                ...buildCertificateEntries(c, cv),
              ],
              if (cv.references.isNotEmpty) ...[
                sectionTitle(c, 'Referanslar', color: accent),
                ...buildReferenceEntries(c, cv, bulletColor: accent.withValues(alpha: 0.45)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  10) CORPORATE NAVY                                                         */
/* -------------------------------------------------------------------------- */
Widget _t10CorporateNavy(BuildContext c, CvData cv) {
  const accent = Color(0xFF0F3A56);
  final theme = Theme.of(c);
  final summaryText = cv.summary.isEmpty
      ? 'Kurumsal hedeflere katkınızı gösteren kısa bir özet paylaşın.'
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
              colors: [Color(0xFF0F3A56), Color(0xFF174C6F)],
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
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cv.title.isEmpty ? 'Kurumsal Lider' : cv.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(child: SizedBox(width: 24.0)),
                          TextSpan(
                            text: summaryText,
                            style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 11, decoration: TextDecoration.none),
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
                          Icon(Icons.mail_outline, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(cv.email, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  if (cv.phone.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(cv.phone, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  if (cv.address.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(cv.address, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
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
                    ...buildReferenceEntries(c, cv, bulletColor: accent.withValues(alpha: 0.4)),
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
                    sectionTitle(c, 'Yetenekler', color: accent),
                    skillProgressList(
                      c,
                      cv,
                      barColor: accent,
                      backgroundColor: const Color(0xFFDFE8EE),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    sectionTitle(c, 'Diller', color: accent),
                    languageChipWrap(
                      c,
                      cv,
                      bgColor: const Color(0xFFE9F1F6),
                      textColor: const Color(0xFF27445C),
                      borderColor: const Color(0xFFD0E0E8),
                    ),
                  ],
                  if (cv.certificates.isNotEmpty) ...[
                    sectionTitle(c, 'Sertifikalar', color: accent),
                    ...buildCertificateEntries(c, cv),
                  ],
                  if (cv.hobbies.isNotEmpty) ...[
                    sectionTitle(c, 'Hobiler', color: accent),
                    hobbyChipWrap(c, cv,
                        bgColor: const Color(0xFFE9F1F6),
                        textColor: const Color(0xFF27445C),
                        borderColor: const Color(0xFFD0E0E8)),
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
/*  ŞABLON KAYDI                                                               */
/* -------------------------------------------------------------------------- */

/// Tüm şablonları CvTemplates.all listesine kaydeder
void registerTemplates() {
  CvTemplates.all
    ..clear()
    ..addAll([
      _t2MinimalPro,
      _t1MinimalWhite,
      _t4Analyst,
      _t3Creative,
      _t5DeveloperDark,
      _t6ModernLine,
      _t7ElegantPurple,
      _t8ProfessionalGray,
      _t9SidebarIconic,
      _t10CorporateNavy,
      t11AcademicStyle,
      t12PhotoFocus,
      t13TimelinePro,
      t14GeometricBlocks,
      t15ModernTwoColumn,
      t16Monochrome,
      t17GradientEdge,
      t18CreativePink,
      t19ExecutiveGold,
      t20CompactResume,
    ]);
}
