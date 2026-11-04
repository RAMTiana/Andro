import 'package:budget_app/core/strings.dart';
import 'package:budget_app/notifications/reminder_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => S.setLang('fr'));

  test('rappel : reste positif', () {
    expect(reminderBody(12000, 'MGA'),
        "Il te reste 12\u00A0000\u00A0Ar à dépenser aujourd'hui.");
  });

  test('rappel : budget dépassé', () {
    expect(reminderBody(-500, 'MGA'),
        "Budget du jour dépassé de 500\u00A0Ar.");
  });

  test('prochain rappel : plus tard aujourd\'hui', () {
    final t = nextReminderTime(DateTime(2026, 11, 4, 10), 19);
    expect(t, DateTime(2026, 11, 4, 19));
  });

  test('prochain rappel : heure passée -> demain', () {
    final t = nextReminderTime(DateTime(2026, 11, 4, 20), 19);
    expect(t, DateTime(2026, 11, 5, 19));
  });
}