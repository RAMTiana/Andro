import 'package:budget_app/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.parse', () {
    test('MGA (sans décimales)', () {
      expect(Money.parse('12 000', 'MGA'), 12000);
      expect(Money.parse('12.000', 'MGA'), 12000);
      expect(Money.parse('500', 'MGA'), 500);
    });
    test('EUR (2 décimales)', () {
      expect(Money.parse('12,50', 'EUR'), 1250);
      expect(Money.parse('12.5', 'EUR'), 1250);
      expect(Money.parse('1.234,56', 'EUR'), 123456);
      expect(Money.parse('12', 'EUR'), 1200);
    });
    test('saisies invalides', () {
      expect(Money.parse('', 'MGA'), isNull);
      expect(Money.parse('abc', 'MGA'), isNull);
    });
  });

  group('Money.format', () {
    test('MGA', () {
      expect(Money.format(12000, 'MGA'), '12\u00A0000\u00A0Ar');
      expect(Money.format(0, 'MGA'), '0\u00A0Ar');
    });
    test('EUR', () {
      expect(Money.format(1250, 'EUR'), '12,50\u00A0€');
      expect(Money.format(5, 'EUR'), '0,05\u00A0€');
    });
    test('négatif', () {
      expect(Money.format(-3000, 'MGA'), '-3\u00A0000\u00A0Ar');
    });
  });

  group('Autres devises', () {
    test('JPY sans décimales', () {
      expect(Money.parse('1 500', 'JPY'), 1500);
      expect(Money.format(1500, 'JPY'), '1\u00A0500\u00A0¥');
    });
    test('KWD / TND avec 3 décimales', () {
      expect(Money.parse('12,500', 'KWD'), 12500);
      expect(Money.parse('12.5', 'KWD'), 12500);
      expect(Money.format(12500, 'KWD'), '12,500\u00A0KD');
      expect(Money.format(5, 'TND'), '0,005\u00A0DT');
    });
    test('USD', () {
      expect(Money.format(999, 'USD'), '9,99\u00A0\$');
    });
  });
}