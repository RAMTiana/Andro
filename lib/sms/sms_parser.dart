import 'dart:convert';
import 'dart:math';

import '../core/currencies.dart';
import '../core/money.dart';
import '../data/models.dart';

class SmsRule {
  final String carrier;
  final List<String> senders; // en minuscules ; vide = tous les expéditeurs
  final Direction direction;
  final RegExp pattern; // groupe 1 = montant
  final String currency;
  final bool decimal; // montants avec point décimal (ex. 15564.2) -> arrondi
  final RegExp? feePattern; // groupe 1 = frais, ajoutés au montant
  final RegExp? notePattern; // groupe 1 = libellé (ex. nom du site)

  SmsRule({
    required this.carrier,
    required this.senders,
    required this.direction,
    required this.pattern,
    required this.currency,
    this.decimal = false,
    this.feePattern,
    this.notePattern,
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
        decimal: (j['decimal'] as bool?) ?? false,
        feePattern: _opt(j['fee_pattern']),
        notePattern: _opt(j['note_pattern']),
      );

  static RegExp? _opt(Object? v) => v == null
      ? null
      : RegExp(v as String, caseSensitive: false, dotAll: true);

  /// Convertit le texte d'un montant en unités mineures.
  int? parseAmount(String raw) {
    final clean = raw.replaceAll(RegExp(r'[.,\s]+$'), '');
    if (!decimal) return Money.parse(clean, currency);
    final d = double.tryParse(clean.replaceAll(',', '.'));
    if (d == null) return null;
    return (d * pow(10, exponentOf(currency))).round();
  }

  bool matchesSender(String s) =>
      senders.isEmpty || senders.contains(s.trim().toLowerCase());
}

class ParsedSms {
  final int amount;
  final Direction direction;
  final String carrier;
  final String note; // libellé : « Opérateur · site » ou simplement l'opérateur
  final String currency;
  final DateTime date;
  final String hash;
  final String body; // texte du SMS, pour l'aperçu

  const ParsedSms({
    required this.amount,
    required this.direction,
    required this.carrier,
    required this.note,
    required this.currency,
    required this.date,
    required this.hash,
    this.body = '',
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
      var amount = r.parseAmount(m.group(1) ?? '');
      if (amount == null || amount <= 0) continue;
      final feeMatch = r.feePattern?.firstMatch(body);
      if (feeMatch != null && feeMatch.groupCount >= 1) {
        amount += r.parseAmount(feeMatch.group(1) ?? '') ?? 0;
      }
      final label = r.notePattern?.firstMatch(body)?.group(1)?.trim();
      return ParsedSms(
        amount: amount,
        direction: r.direction,
        carrier: r.carrier,
        note: (label == null || label.isEmpty)
            ? r.carrier
            : '${r.carrier} · $label',
        currency: r.currency,
        date: date,
        hash: hashOf(sender, date, body),
        body: body,
      );
    }
    return null;
  }
}