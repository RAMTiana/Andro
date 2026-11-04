import 'package:budget_app/data/models.dart';
import 'package:budget_app/sms/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// Règles et SMS FICTIFS pour tester le mécanisme. Remplace-les par de vrais
// exemples de tes opérateurs.
const _rules = r'''
{"rules": [
  {"carrier": "TestPay", "senders": ["TestPay"], "direction": "out", "currency": "MGA",
   "pattern": "(?:envoy|transf|pay|retrait|achat)[^0-9]{0,60}?([0-9][0-9\\s.,]*)\\s*Ar"},
  {"carrier": "TestPay", "senders": ["TestPay"], "direction": "in", "currency": "MGA",
   "pattern": "(?:re[cç]u|d[eé]p[oô]t)[^0-9]{0,60}?([0-9][0-9\\s.,]*)\\s*Ar"}
]}
''';

void main() {
  final parser = SmsParser.fromJsonString(_rules);
  final date = DateTime(2026, 11, 2, 10, 30);

  test('reconnaît une entrée', () {
    final p = parser.parse(
      sender: 'TestPay',
      body: 'Vous avez recu 10 000 Ar de 0341234567. Nouveau solde: 25 000 Ar.',
      date: date,
    );
    expect(p, isNotNull);
    expect(p!.amount, 10000);
    expect(p.direction, Direction.inflow);
  });

  test('reconnaît une sortie', () {
    final p = parser.parse(
      sender: 'testpay',
      body: 'Vous avez envoye 5 000 Ar a 0321234567.',
      date: date,
    );
    expect(p!.amount, 5000);
    expect(p.direction, Direction.outflow);
  });

  test('ignore un expéditeur inconnu ou un SMS sans montant', () {
    expect(
        parser.parse(
            sender: 'Maman', body: 'Tu as recu 5 000 Ar ?', date: date),
        isNull);
    expect(
        parser.parse(sender: 'TestPay', body: 'Bienvenue !', date: date),
        isNull);
  });

  test('le hash est stable et distingue les SMS', () {
    final a = SmsParser.hashOf('TestPay', date, 'abc');
    expect(a, SmsParser.hashOf('TestPay', date, 'abc'));
    expect(a, isNot(SmsParser.hashOf('TestPay', date, 'abd')));
  });
}
