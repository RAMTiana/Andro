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
}
