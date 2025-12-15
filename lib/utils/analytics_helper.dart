import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logCalculation(String calculationType, {Map<String, dynamic>? parameters}) async {
    try {
      final Map<String, Object> eventParams = {
        'calculation_type': calculationType,
      };
      if (parameters != null) {
        parameters.forEach((key, value) {
          eventParams[key] = value.toString();
        });
      }
      await _analytics.logEvent(
        name: 'calculation_performed',
        parameters: eventParams,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logScreenOpen(String eventName) async {
    try {
      await _analytics.logEvent(
        name: eventName,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logArticleRead(String articleTitle) async {
    try {
      await _analytics.logEvent(
        name: 'article_read',
        parameters: {
          'article_title': articleTitle,
        },
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logLegislationView(String legislationName) async {
    try {
      await _analytics.logEvent(
        name: 'legislation_viewed',
        parameters: {
          'legislation_name': legislationName,
        },
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logDictionarySearch(String searchTerm) async {
    try {
      await _analytics.logEvent(
        name: 'dictionary_search',
        parameters: {
          'search_term': searchTerm,
        },
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logCVCreated(String templateName) async {
    try {
      await _analytics.logEvent(
        name: 'cv_created',
        parameters: {
          'template_name': templateName,
        },
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logOvertimeAction(String action, {Map<String, dynamic>? parameters}) async {
    try {
      final Map<String, Object> eventParams = {
        'action': action,
      };
      if (parameters != null) {
        parameters.forEach((key, value) {
          eventParams[key] = value.toString();
        });
      }
      await _analytics.logEvent(
        name: 'overtime_action',
        parameters: eventParams,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logRetirementAction(String action, {Map<String, dynamic>? parameters}) async {
    try {
      final Map<String, Object> eventParams = {
        'action': action,
      };
      if (parameters != null) {
        parameters.forEach((key, value) {
          eventParams[key] = value.toString();
        });
      }
      await _analytics.logEvent(
        name: 'retirement_action',
        parameters: eventParams,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  static Future<void> logCustomEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      final Map<String, Object>? eventParams = parameters?.map((key, value) => MapEntry(key, value.toString()));
      await _analytics.logEvent(
        name: eventName,
        parameters: eventParams,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }
}

