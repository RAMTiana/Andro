import 'dart:io';

import 'package:budget_app/data/models.dart';
import 'package:budget_app/sms/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// Vrai format de SMS Orange Money (identifiants anonymisés).
const _orangePayment =
    "Vous venez d'effectuer un paiement recurrent de 15564.2 Ar sur le site "
    'Spotify PXXXXXXXXXX. Frais : 1000.0Ar. Nouveau solde : 21920.0Ar. '
    'Trans Id : CO000000.0000.A00000. Pensez a alimenter votre compte avant '
    'le prochain paiement. Orange Money vous remercie.';

void main() {
  // Teste les règles réelles de assets/sms_rules.json.
  final parser =
      SmsParser.fromJsonString(File('assets/sms_rules.json').readAsStringSync());
  final date = DateTime(2026, 11, 3, 21, 4);

  test('paiement Orange Money : montant + frais, libellé du site', () {
    final p =
        parser.parse(sender: 'OrangeMoney', body: _orangePayment, date: date);
    expect(p, isNotNull);
    expect(p!.amount, 16564); // 15564,2 arrondi + 1 000 de frais
    expect(p.direction, Direction.outflow);
    expect(p.note, 'Orange Money · Spotify');
  });

  test("ne dépend pas du nom d'expéditeur", () {
    final p = parser.parse(sender: '0321234567', body: _orangePayment, date: date);
    expect(p?.amount, 16564);
  });

  test('montant décimal sans frais ni site', () {
    final p = parser.parse(
      sender: 'OrangeMoney',
      body: 'Paiement de 1000.0 Ar effectue. Orange Money vous remercie.',
      date: date,
    );
    expect(p?.amount, 1000);
    expect(p?.note, 'Orange Money');
  });

  test('un SMS sans la signature Orange Money est ignoré', () {
    final p = parser.parse(
      sender: 'Maman',
      body: 'Ton paiement de 5000 Ar est bien recu.',
      date: date,
    );
    expect(p, isNull);
  });
}