import 'package:budget_app/data/csv_export.dart';
import 'package:budget_app/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plainAmount : MGA sans décimales, EUR avec 2 décimales', () {
    expect(plainAmount(12000, 'MGA'), '12000');
    expect(plainAmount(1250, 'EUR'), '12.50');
    expect(plainAmount(5, 'EUR'), '0.05');
  });

  test('transactionsToCsv : en-tête, BOM et échappement', () {
    final csv = transactionsToCsv(
      [
        TxRec(
          id: '1',
          accountId: 'a',
          categoryId: 'c1',
          amount: 5000,
          currency: 'MGA',
          direction: Direction.outflow,
          occurredAt: DateTime(2026, 11, 4, 9, 5),
          note: 'riz; "bon"',
        ),
      ],
      categoryName: (id) => id == 'c1' ? 'Alimentation' : null,
    );
    expect(csv.startsWith('\uFEFFdate;type;amount'), isTrue);
    expect(csv,
        contains('2026-11-04 09:05;out;5000;MGA;Alimentation;"riz; ""bon""";manual'));
  });
}