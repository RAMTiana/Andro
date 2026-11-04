import 'dart:math';

import 'currencies.dart';

/// Montants en unités mineures (entiers). MGA : 1000 = 1 000 Ar.
/// EUR : 1250 = 12,50 €.
class Money {
  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  static String _group(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00A0');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String format(int minor, String currency, {bool withSymbol = true}) {
    final exp = exponentOf(currency);
    final abs = minor.abs();
    final div = _pow10(exp);
    final whole = _group(abs ~/ div);
    final body = exp == 0
        ? whole
        : '$whole,${(abs % div).toString().padLeft(exp, '0')}';
    final sign = minor < 0 ? '-' : '';
    return withSymbol
        ? '$sign$body\u00A0${symbolOf(currency)}'
        : '$sign$body';
  }

  /// Convertit une saisie ("12 000", "12,50", "1.234,56") en unités mineures.
  /// Retourne null si la saisie est invalide.
  static int? parse(String input, String currency) {
    final exp = exponentOf(currency);
    final s = input.replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
    if (s.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(s)) return null;

    var whole = s;
    var frac = '';
    if (exp > 0) {
      final idx = max(s.lastIndexOf('.'), s.lastIndexOf(','));
      final digitsAfter = s.length - idx - 1;
      if (idx >= 0 && digitsAfter > 0 && digitsAfter <= exp) {
        whole = s.substring(0, idx);
        frac = s.substring(idx + 1);
      }
    }
    whole = whole.replaceAll(RegExp(r'[.,]'), '');
    if (whole.isEmpty) whole = '0';
    if (!RegExp(r'^[0-9]+$').hasMatch(whole)) return null;

    final fracPadded = frac.padRight(exp, '0');
    final fracValue = fracPadded.isEmpty ? 0 : int.parse(fracPadded);
    return int.parse(whole) * _pow10(exp) + fracValue;
  }

  /// Convertit un montant (unités mineures) de [from] vers [to].
  /// [rate] = combien de [to] valent 1 [from]. Rate 1 = mêmes chiffres.
  static int convert(int minor, double rate, String from, String to) {
    final shift = exponentOf(to) - exponentOf(from);
    return (minor * rate * pow(10, shift)).round();
  }
}