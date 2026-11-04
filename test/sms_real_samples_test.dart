import 'dart:io';

import 'package:budget_app/data/models.dart';
import 'package:budget_app/sms/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un cas = un VRAI SMS (anonymisé) + ce que l'appli doit en tirer.
/// expectAmount = null  ->  le SMS doit être IGNORÉ (pas une transaction).
class _Case {
  final String name;
  final String sender;
  final String body;
  final int? expectAmount; // frais inclus, en Ar
  final Direction? expectDirection;
  const _Case(this.name, this.sender, this.body,
      {this.expectAmount, this.expectDirection});
}

const _cases = <_Case>[
  _Case(
    'Orange Money : retrait (frais à ta charge)',
    'OrangeMoney',
    'Le retrait de 120000 Ar sur votre compte aupres du 0328326000 est reussi. '
        'Frais : 3400 Ar. Nouveau solde : 98520 Ar. '
        'Trans Id : CO261104.1028.D36959 . Orange Money vous remercie',
    expectAmount: 123400, // 120000 + 3400
    expectDirection: Direction.outflow,
  ),
  _Case(
    'Orange Money : dépôt (frais payés par le déposant, pas par toi)',
    'OrangeMoney',
    'Votre dépot de 63900 Ar par le 0324547883 est réussi. '
        'Nouveau solde: 67684 Ar . Frais payé par le déposant : 1000 Ar. '
        'Trans Id :CI261028.1638.B95280. Orange Money vous remercie.',
    expectAmount: 63900,
    expectDirection: Direction.inflow,
  ),
  _Case(
    'MVola : argent reçu',
    'MVola',
    '2 000 Ar recu de livaharilalaosahondra 0349855241 le 26/10/26 a 19:26. '
        'Raison: io. Solde: 2 070 Ar. Ref 9711206956',
    expectAmount: 2000,
    expectDirection: Direction.inflow,
  ),
  _Case(
    'Orange Money : transfert reçu (avec pub à la fin)',
    'OrangeMoney',
    'Vous avez recu un transfert de 5150Ar venant du 0328880543 '
        'Nouveau Solde: 5784Ar.  Trans Id: PP261027.1545.B92013. '
        'Orange Money vous remercie. Beneficiez de 20 pourcent de bonus en '
        "achetant votre credit ou offre Orange via OrangeMoney sur USSD ou sur "
        "l'App Max it. Rdv sur Playstore ou Appstore.",
    expectAmount: 5150,
    expectDirection: Direction.inflow,
  ),
  _Case(
    'MVola : achat de crédit YAS (le « 20 pourcent » du bonus est ignoré)',
    'MVola',
    'Achat de credit YAS reussi: 500 Ar. Bonus: 20 pourcent sur ce dernier '
        'rechargement. Solde MVola : 20 Ar. Ref: 8081931434',
    expectAmount: 500,
    expectDirection: Direction.outflow,
  ),
  _Case(
    'SMS ordinaire à ignorer',
    '0321234567',
    'Bonjour, votre forfait expire demain. Solde: 2 000 Ar',
  ),
];

void main() {
  final parser =
      SmsParser.fromJsonString(File('assets/sms_rules.json').readAsStringSync());
  final date = DateTime(2026, 11, 4, 10, 28);

  for (final c in _cases) {
    test(c.name, () {
      final p = parser.parse(sender: c.sender, body: c.body, date: date);
      if (c.expectAmount == null) {
        expect(p, isNull, reason: 'devrait être ignoré');
      } else {
        expect(p, isNotNull, reason: 'SMS non reconnu');
        expect(p!.amount, c.expectAmount, reason: 'montant (frais inclus)');
        expect(p.direction, c.expectDirection, reason: 'sens entrée/sortie');
      }
    });
  }
}