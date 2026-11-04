import '../core/currencies.dart';
import '../core/strings.dart';
import 'models.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Montant en unités mineures -> « 1234.50 » (sans séparateur de milliers).
String plainAmount(int minor, String currency) {
  final exp = exponentOf(currency);
  if (exp == 0) return minor.toString();
  var div = 1;
  for (var i = 0; i < exp; i++) {
    div *= 10;
  }
  return '${minor ~/ div}.${(minor % div).toString().padLeft(exp, '0')}';
}

String _cell(String? v) {
  final s = v ?? '';
  if (s.contains(';') ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

/// Transactions -> CSV (séparateur « ; », ouvre bien dans Excel en français).
/// Colonnes : date, type, montant, devise, catégorie, note, source.
String transactionsToCsv(
  List<TxRec> txs, {
  required String? Function(String? categoryId) categoryName,
}) {
  final b = StringBuffer('\uFEFF');
  b.writeln('date;type;amount;currency;category;note;source');
  for (final t in txs) {
    final d = t.occurredAt;
    final date =
        '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
    b.writeln([
      date,
      t.direction == Direction.inflow ? 'in' : 'out',
      plainAmount(t.amount, t.currency),
      t.currency,
      categoryName(t.categoryId) ?? S.t('cat_other'),
      t.note,
      t.source,
    ].map((e) => _cell(e)).join(';'));
  }
  return b.toString();
}