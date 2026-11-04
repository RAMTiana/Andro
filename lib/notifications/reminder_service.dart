import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/strings.dart';
import 'reminder_text.dart';

/// Rappel quotidien « Il te reste X aujourd'hui » (Android / iOS).
/// Préférences stockées à part (shared_preferences) : pas de migration SQLite.
class ReminderService {
  static const _kEnabled = 'reminder_enabled';
  static const _kHour = 'reminder_hour';
  static const _id = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool enabled = false;
  int hour = 19;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_kEnabled) ?? false;
    hour = prefs.getInt(_kHour) ?? 19;
    if (!supported) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// Demande l'autorisation (Android 13+, iOS). Retourne false si refusée.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  Future<void> save({required bool enabled, required int hour}) async {
    this.enabled = enabled;
    this.hour = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, enabled);
    await prefs.setInt(_kHour, hour);
  }

  /// (Re)programme le rappel avec le reste du jour actuel.
  /// Appelé après chaque mise à jour des chiffres.
  Future<void> reschedule(int? remaining, String currency) async {
    if (!_ready) return;
    await _plugin.cancel(_id);
    if (!enabled) return;
    final local = nextReminderTime(DateTime.now(), hour);
    // Heure fixe en UTC : correct pour les pays sans heure d'été (ex. Madagascar).
    final when = tz.TZDateTime.from(local.toUtc(), tz.UTC);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        'Rappel quotidien',
        channelDescription: 'Rappel du budget du jour',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      _id,
      S.t('reminder_title'),
      reminderBody(remaining, currency),
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}