import 'dart:convert';

import '../core/money.dart';
import '../data/models.dart';

class SmsRule {
  final String carrier;
  final List<String> senders; // en minuscules ; vide = tous les expéditeurs
  final Direction direction;
  final RegExp pattern; // groupe 1 = montant
  final String currency;

  SmsRule({
    required this.carrier,
    required this.senders,
    required this.direction,
    required this.pattern,
    required this.currency,
  });

  factory SmsRule.fromJson(Map<String, dynamic> j) => SmsRule(
        carrier: j['carrier'] as String,
        senders: (j['senders'] as List)
            .map((e) => (e as String).toLowerCase())
            .toList(),
        direction: Direction.fromCode(j['direction'] as String),
        pattern: RegExp(j['pattern'] as String,
            caseSensitive: false, dotAll: true),
        currency: (j['currency'] as String?) ?? 'MGA',
      );

  bool matchesSender(String s) =>
      senders.isEmpty || senders.contains(s.trim().toLowerCase());
}

class ParsedSms {
  final int amount;
  final Direction direction;
  final String carrier;
  final String currency;
  final DateTime date;
  final String hash;

  const ParsedSms({
    required this.amount,
    required this.direction,
    required this.carrier,
    required this.currency,
    required this.date,
    required this.hash,
  });
}

class SmsParser {
  final List<SmsRule> rules;
  SmsParser(this.rules);

  factory SmsParser.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final rules = (j['rules'] as List)
        .map((e) => SmsRule.fromJson(e as Map<String, dynamic>))
        .toList();
    return SmsParser(rules);
  }

  /// Hash stable (FNV-1a) pour éviter d'importer deux fois le même SMS.
  static String hashOf(String sender, DateTime date, String body) {
    var h = 0x811C9DC5;
    for (final c in body.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return '${sender.toLowerCase()}|${date.millisecondsSinceEpoch}|${h.toRadixString(16)}';
  }

  ParsedSms? parse({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    for (final r in rules) {
      if (!r.matchesSender(sender)) continue;
      final m = r.pattern.firstMatch(body);
      if (m == null || m.groupCount < 1) continue;
      final raw = (m.group(1) ?? '').replaceAll(RegExp(r'[.,\s]+$'), '');
      final amount = Money.parse(raw, r.currency);
      if (amount == null || amount <= 0) continue;
      return ParsedSms(
        amount: amount,
        direction: r.direction,
        carrier: r.carrier,
        currency: r.currency,
        date: date,
        hash: hashOf(sender, date, body),
      );
    }
    return null;
  }
}
