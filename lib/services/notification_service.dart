import 'dart:async';
import 'dart:convert';
import 'personal_profile_store.dart';
import 'account_scoped_local_store.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/emeklilik_statulu_hesap.dart';
import '../mesaitakip/mesaihesaplama.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const preferencesKey = 'personal_notification_preferences';
  static const announcementTopic = 'sgk_duyurulari';

  static const Map<String, bool> defaultPreferences = {
    'emeklilik': true,
    'izin': true,
    'vergi': true,
    'kidem': true,
    'takvim': true,
    'duyuru': true,
  };

  static const _retirementId = 4101;
  static const _leaveId = 4102;
  static const _taxId = 4103;
  static const _severanceId = 4104;
  static const _calendarId = 4105;
  static const _foregroundMessageId = 4199;
  static const _personalIds = <int>[
    _retirementId,
    _leaveId,
    _taxId,
    _severanceId,
    _calendarId,
  ];

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _firebaseAvailable = false;

  static const _personalDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'calisma_hayatim_hatirlatmalari',
      'Çalışma Hayatım Hatırlatmaları',
      icon: 'ic_notification',
      channelDescription:
          'İzin, kıdem, emeklilik ve maaş takibi hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _announcementDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'mevzuat_duyurulari',
      'Mevzuat ve Uygulama Duyuruları',
      icon: 'ic_notification',
      channelDescription: 'SGK mevzuatı, oran ve uygulama duyuruları',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> initialize({required bool firebaseAvailable}) async {
    if (_initialized) return;
    _firebaseAvailable = firebaseAvailable;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const android = AndroidInitializationSettings('ic_notification');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'calisma_hayatim_hatirlatmalari',
        'Çalışma Hayatım Hatırlatmaları',
        description: 'İzin, kıdem, emeklilik ve maaş takibi hatırlatmaları',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'mevzuat_duyurulari',
        'Mevzuat ve Uygulama Duyuruları',
        description: 'SGK mevzuatı, oran ve uygulama duyuruları',
        importance: Importance.high,
      ),
    );

    if (_firebaseAvailable) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      if (kDebugMode) {
        FirebaseMessaging.instance.getToken().then((token) {
          debugPrint('FCM test tokenı: $token');
        }).catchError((error) {
          debugPrint('FCM tokenı alınamadı: $error');
        });
      }
    }

    _initialized = true;
    await syncFromStoredPreferences();
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final result = await android?.requestNotificationsPermission();
      await syncFromStoredPreferences();
      return result ?? true;
    }
    if (_firebaseAvailable) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await syncFromStoredPreferences();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return true;
  }

  Future<bool> notificationsEnabled() async {
    if (!_initialized) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? true;
    }
    if (_firebaseAvailable) {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return true;
  }

  Future<int> pendingPersonalCount() async {
    if (!_initialized) return 0;
    final pending = await _local.pendingNotificationRequests();
    return pending.where((item) => _personalIds.contains(item.id)).length;
  }

  Future<void> showTestNotification() async {
    await _local.show(
      id: 4198,
      title: 'Bildirimler aktif',
      body: 'Çalışma Hayatım hatırlatmaları bu cihazda çalışıyor.',
      notificationDetails: _personalDetails,
      payload: 'test',
    );
  }

  Future<void> applyPreferences(Map<String, bool> preferences) async {
    if (!_initialized) return;
    final uid = AccountScopedLocalStore().currentUid;
    await _cancelPersonalNotifications();
    if (AccountScopedLocalStore().currentUid != uid) return;
    await _scheduleFromProfile(preferences, uid);
    unawaited(_syncAnnouncementTopic(preferences['duyuru'] ?? true));
  }

  Future<void> syncFromStoredPreferences() async {
    if (!_initialized) return;
    final store = AccountScopedLocalStore();
    final uid = store.currentUid;
    final raw = await AccountScopedLocalStore(uidProvider: () => uid)
        .read(preferencesKey);
    if (store.currentUid != uid) return;
    var values = Map<String, bool>.from(defaultPreferences);
    if (raw != null && raw.isNotEmpty) {
      try {
        values = {
          ...values,
          ...Map<String, dynamic>.from(jsonDecode(raw) as Map)
              .map((key, value) => MapEntry(key, value == true)),
        };
      } catch (_) {}
    }
    await applyPreferences(values);
  }

  Future<void> _syncAnnouncementTopic(bool enabled) async {
    if (!_firebaseAvailable) return;
    try {
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic(announcementTopic);
      } else {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic(announcementTopic);
      }
    } catch (error) {
      debugPrint('FCM konu aboneliği güncellenemedi: $error');
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final rawTitle = notification.title?.trim() ?? '';
    final normalizedTitle = rawTitle.toLowerCase().replaceAll('ı', 'i');
    final title = rawTitle.isEmpty ||
            normalizedTitle == announcementTopic ||
            normalizedTitle == 'mevzuat_duyurulari'
        ? 'İş & Sosyal Güvenlik Mobil'
        : rawTitle;
    await _local.show(
      id: message.messageId?.hashCode ?? _foregroundMessageId,
      title: title,
      body: notification.body,
      notificationDetails: _announcementDetails,
      payload: message.data['route']?.toString(),
    );
  }

  Future<void> _cancelPersonalNotifications() async {
    for (final id in _personalIds) {
      await _local.cancel(id: id);
    }
  }

  Future<void> _scheduleFromProfile(
      Map<String, bool> preferences, String? uid) async {
    if (uid == null) return;
    final raw = await PersonalProfileStore(uidProvider: () => uid).readRaw();
    if (AccountScopedLocalStore().currentUid != uid) return;
    if (raw == null || raw.isEmpty) return;

    late final Map<String, dynamic> profile;
    try {
      profile = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    final jobStart = _date(profile['mevcutIsyeriBaslangic']);
    if (jobStart != null) {
      if (preferences['izin'] ?? true) {
        final next = _nextAnniversary(jobStart, now, hour: 9);
        await _schedule(
          id: _leaveId,
          date: next,
          title: 'Yıllık izin hakkınızı kontrol edin',
          body:
              'Mevcut işyerinizde yeni hizmet yılınız tamamlandı. İzin kaydınızı kontrol edebilirsiniz.',
          payload: 'haklarim',
        );
      }
      if ((preferences['kidem'] ?? true) &&
          now.isBefore(_addYears(jobStart, 1))) {
        await _schedule(
          id: _severanceId,
          date: DateTime(jobStart.year + 1, jobStart.month, jobStart.day, 10),
          title: 'Bir yıllık çalışma eşiğiniz tamamlandı',
          body:
              'Kıdem ve yıllık izin durumunuzu Haklarım bölümünden kontrol edebilirsiniz.',
          payload: 'haklarim',
        );
      }
    }

    if (preferences['emeklilik'] ?? true) {
      await _scheduleRetirement(profile, now);
    }
    if (preferences['vergi'] ?? true) {
      await _scheduleTaxBracket(profile, now);
    }
    if (preferences['takvim'] ?? true) {
      final nextMonth = DateTime(now.year, now.month + 1, 1, 10);
      await _schedule(
        id: _calendarId,
        date: nextMonth,
        title: 'Aylık çalışma bilgilerinizi kontrol edin',
        body:
            'Yeni ay için brüt maaşınızı ve toplam prim gününüzü güncelleyebilirsiniz.',
        payload: 'calisma_bilgilerim',
        repeatMonthly: true,
      );
    }
  }

  Future<void> _scheduleRetirement(
      Map<String, dynamic> profile, DateTime now) async {
    final birth = _date(profile['dogumTarihi']);
    final insurance = _date(profile['ilkIseGirisTarihi']);
    final premium = int.tryParse('${profile['toplamPrimGun']}');
    final gender = profile['cinsiyet']?.toString();
    if (birth == null ||
        insurance == null ||
        premium == null ||
        gender == null) {
      return;
    }
    try {
      final result = emeklilikHesaplaStatulu(
        sigortaKolu: '${profile['sigortaKolu']}',
        dogumTarihi: birth,
        cinsiyet: gender,
        sigortaBaslangici: insurance,
        primGunu: premium,
      );
      if (result == null) return;
      final normal =
          (result['tahminiSonuclar'] as Map?)?['Normal Emeklilik'] as Map?;
      final target = _date(normal?['tahminiTarih']);
      if (target == null || !target.isAfter(now)) return;
      var reminder = target.subtract(const Duration(days: 30));
      if (!reminder.isAfter(now)) {
        reminder = DateTime(now.year, now.month, now.day + 1, 9);
      } else {
        reminder = DateTime(reminder.year, reminder.month, reminder.day, 9);
      }
      await _schedule(
        id: _retirementId,
        date: reminder,
        title: 'Emeklilik koşullarınıza yaklaşıyorsunuz',
        body:
            'Tahmini emeklilik tarihinize 30 gün kaldı. Güncel hizmet dökümünüzü kontrol edin.',
        payload: 'calisma_hayatim',
      );
    } catch (_) {}
  }

  Future<void> _scheduleTaxBracket(
      Map<String, dynamic> profile, DateTime now) async {
    final currentSalary = (profile['guncelBrutMaas'] as num?)?.toDouble();
    if (currentSalary == null || currentSalary <= 0 || now.month >= 12) return;
    final monthly = <int, double>{};
    final rawMonthly = profile['aylikBrutMaaslar'];
    if (rawMonthly is Map) {
      final prefix = '${now.year}-';
      for (final entry in Map<String, dynamic>.from(rawMonthly).entries) {
        if (!entry.key.startsWith(prefix) || entry.value is! num) continue;
        final month = int.tryParse(entry.key.substring(prefix.length));
        if (month != null && month >= 1 && month <= 12) {
          monthly[month] = (entry.value as num).toDouble();
        }
      }
    }
    final jobStart = _date(profile['mevcutIsyeriBaslangic']);
    final firstMonth = jobStart?.year == now.year ? jobStart!.month - 1 : 0;
    final engine = SalaryEngine(
      year: now.year,
      status: EmployeeStatus.normal,
      incentive: Incentive.none,
    );
    var cumulative = 0.0;
    int? currentBracket;
    for (var index = firstMonth; index < 12; index++) {
      final gross = monthly[index + 1] ?? currentSalary;
      final result = engine.calculateNetFromGross(
        grossMonthly: gross,
        monthIndex: index,
        cumulativeTaxBasePrev: cumulative,
      );
      cumulative = result.cumulativeTaxBase;
      if (index == now.month - 1) {
        currentBracket = result.incomeTaxBracketPercent;
      } else if (index >= now.month &&
          currentBracket != null &&
          result.incomeTaxBracketPercent > currentBracket) {
        await _schedule(
          id: _taxId,
          date: DateTime(now.year, index + 1, 1, 9),
          title: 'Vergi diliminiz değişiyor',
          body:
              '${index + 1}. ay maaş hesabınızda gelir vergisi oranı %${result.incomeTaxBracketPercent} olarak tahmin ediliyor.',
          payload: 'calisma_hayatim',
        );
        return;
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime date,
    required String title,
    required String body,
    required String payload,
    bool repeatMonthly = false,
  }) async {
    if (!date.isAfter(DateTime.now())) return;
    await _local.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(date, tz.local),
      notificationDetails: _personalDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents:
          repeatMonthly ? DateTimeComponents.dayOfMonthAndTime : null,
    );
  }

  DateTime _nextAnniversary(DateTime start, DateTime now, {required int hour}) {
    var candidate = DateTime(now.year, start.month, start.day, hour);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year + 1, start.month, start.day, hour);
    }
    return candidate;
  }

  DateTime _addYears(DateTime value, int years) {
    final year = value.year + years;
    final lastDay = DateTime(year, value.month + 1, 0).day;
    return DateTime(year, value.month, value.day.clamp(1, lastDay));
  }

  DateTime? _date(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
