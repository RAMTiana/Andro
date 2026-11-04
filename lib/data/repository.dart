import 'dart:math';

import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Accès aux données (SQLite). Aucune logique métier ici.
class Repository {
  final Database db;
  Repository(this.db);

  int _now() => DateTime.now().millisecondsSinceEpoch;

  // ---- Paramètres ----
  Future<BudgetSettings?> loadSettings() async {
    final rows = await db.query('budget_settings', where: 'id = 1');
    return rows.isEmpty ? null : BudgetSettings.fromMap(rows.first);
  }

  Future<void> saveSettings(BudgetSettings s) => db.insert(
        'budget_settings',
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  // ---- Comptes ----
  Future<List<Account>> listAccounts() async {
    final rows =
        await db.query('accounts', where: 'deleted_at IS NULL', orderBy: 'rowid');
    return rows.map(Account.fromMap).toList();
  }

  Future<void> insertAccount(Account a) => db.insert('accounts', a.toMap());

  // ---- Catégories ----
  Future<List<BudgetCategory>> listCategories() async {
    final rows = await db.query('categories',
        where: 'deleted_at IS NULL', orderBy: 'rowid');
    return rows.map(BudgetCategory.fromMap).toList();
  }

  Future<void> insertCategories(List<BudgetCategory> cats) async {
    final batch = db.batch();
    for (final c in cats) {
      batch.insert('categories', c.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ---- Transactions ----
  Future<void> insertTx(TxRec t) => db.insert('transactions', t.toMap());

  Future<void> updateTx(TxRec t) =>
      db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  Future<void> softDeleteTx(String id) => db.update(
        'transactions',
        {'deleted_at': _now(), 'updated_at': _now()},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<TxRec>> listTx({int limit = 200, bool? review}) async {
    final where = StringBuffer('deleted_at IS NULL');
    if (review != null) where.write(' AND needs_review = ${review ? 1 : 0}');
    final rows = await db.query(
      'transactions',
      where: where.toString(),
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
    return rows.map(TxRec.fromMap).toList();
  }

  Future<bool> hasSmsHash(String hash) async {
    final r = await db.query('transactions',
        columns: ['id'], where: 'sms_hash = ?', whereArgs: [hash], limit: 1);
    return r.isNotEmpty;
  }

  /// Somme des sorties validées entre [from] (inclus) et [to] (exclu).
  /// Les transactions « à valider » (needs_review = 1) ne comptent pas.
  Future<int> spentBetween(DateTime from, DateTime to) async {
    final r = await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) FROM transactions "
      "WHERE deleted_at IS NULL AND needs_review = 0 AND direction = 'out' "
      "AND occurred_at >= ? AND occurred_at < ?",
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Sorties validées par catégorie entre [from] et [to] (clé '' = sans catégorie).
  Future<Map<String, int>> spentByCategory(DateTime from, DateTime to) async {
    final rows = await db.rawQuery(
      "SELECT category_id, SUM(amount) AS total FROM transactions "
      "WHERE deleted_at IS NULL AND needs_review = 0 AND direction = 'out' "
      "AND occurred_at >= ? AND occurred_at < ? GROUP BY category_id",
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return {
      for (final row in rows)
        (row['category_id'] as String? ?? ''):
            (row['total'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> setCategoryLimit(String id, int? amount) => db.update(
        'categories',
        {'limit_amount': amount, 'updated_at': _now()},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// Solde = soldes d'ouverture + entrées - sorties validées (tous comptes).
  Future<int> balance() async {
    final opening = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COALESCE(SUM(opening_balance),0) FROM accounts '
            'WHERE deleted_at IS NULL')) ??
        0;
    final flow = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COALESCE(SUM(CASE WHEN direction='in' THEN amount "
            "ELSE -amount END),0) FROM transactions "
            "WHERE deleted_at IS NULL AND needs_review = 0")) ??
        0;
    return opening + flow;
  }

  // ---- Charges / rentrées prévues ----
  Future<List<PlannedItem>> listPlanned() async {
    final rows = await db.query('planned_items',
        where: 'deleted_at IS NULL', orderBy: 'due_date');
    return rows.map(PlannedItem.fromMap).toList();
  }

  Future<void> insertPlanned(PlannedItem p) =>
      db.insert('planned_items', p.toMap());

  Future<void> softDeletePlanned(String id) => db.update(
        'planned_items',
        {'deleted_at': _now(), 'updated_at': _now()},
        where: 'id = ?',
        whereArgs: [id],
      );

  // ---- Changement de devise ----
  /// Convertit tous les montants vers [newCurrency] dans une seule
  /// transaction SQL (tout ou rien). [rate] = valeur de 1 ancienne devise.
  Future<void> convertCurrency({
    required String newCurrency,
    required double rate,
    required int oldExp,
    required int newExp,
  }) async {
    final factor = rate * pow(10, newExp - oldExp);
    final now = _now();
    await db.transaction((txn) async {
      await txn.rawUpdate(
          'UPDATE accounts SET opening_balance = '
          'CAST(ROUND(opening_balance * ?) AS INTEGER), '
          'currency = ?, updated_at = ?',
          [factor, newCurrency, now]);
      await txn.rawUpdate(
          'UPDATE transactions SET amount = '
          'MAX(1, CAST(ROUND(amount * ?) AS INTEGER)), '
          'currency = ?, updated_at = ?',
          [factor, newCurrency, now]);
      await txn.rawUpdate(
          'UPDATE planned_items SET amount = '
          'MAX(1, CAST(ROUND(amount * ?) AS INTEGER)), '
          'currency = ?, updated_at = ?',
          [factor, newCurrency, now]);
      await txn.rawUpdate(
          'UPDATE budget_settings SET savings_goal = '
          'CAST(ROUND(savings_goal * ?) AS INTEGER), home_currency = ? '
          'WHERE id = 1',
          [factor, newCurrency]);
    });
  }
}