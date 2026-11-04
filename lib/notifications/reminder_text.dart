import '../core/money.dart';
import '../core/strings.dart';

/// Texte du rappel quotidien (pur, testable sans téléphone).
/// [remaining] = reste du jour au dernier calcul (unités mineures, peut être négatif).
String reminderBody(int? remaining, String currency) {
  if (remaining == null) return S.t('reminder_body_generic');
  if (remaining < 0) {
    return S.tr('reminder_body_over',
        {'x': Money.format(-remaining, currency)});
  }
  return S.tr('reminder_body', {'x': Money.format(remaining, currency)});
}

/// Prochaine occurrence de [hour]:00 (heure locale) à partir de [now].
DateTime nextReminderTime(DateTime now, int hour) {
  var t = DateTime(now.year, now.month, now.day, hour);
  if (!t.isAfter(now)) t = DateTime(now.year, now.month, now.day + 1, hour);
  return t;
}