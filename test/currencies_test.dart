import 'package:budget_app/core/currencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('codes uniques et exposants valides', () {
    final codes = kSupportedCurrencies;
    expect(codes.toSet().length, codes.length);
    for (final c in kCurrencies) {
      expect(c.exponent, inInclusiveRange(0, 3), reason: c.code);
      expect(c.code.length, 3);
    }
  });

  test('exposants et symboles', () {
    expect(exponentOf('MGA'), 0);
    expect(exponentOf('KWD'), 3);
    expect(exponentOf('EUR'), 2);
    expect(exponentOf('XXX'), 2);
    expect(symbolOf('USD'), '\$');
    expect(symbolOf('XXX'), 'XXX');
  });

  test('noms et libellés', () {
    expect(currencyName('EUR', 'fr'), 'Euro');
    expect(currencyName('MGA', 'en'), 'Malagasy ariary');
    expect(currencyLabel('MGA', 'fr'), 'MGA · Ariary malgache');
  });

  test('devise selon le pays', () {
    expect(currencyForCountry('mg'), 'MGA');
    expect(currencyForCountry('FR'), 'EUR');
    expect(currencyForCountry('ZZ'), isNull);
    expect(currencyForCountry(null), isNull);
    for (final v in kCountryCurrency.values) {
      expect(kSupportedCurrencies, contains(v));
    }
  });
}