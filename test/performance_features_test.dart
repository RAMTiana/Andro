import 'package:budget_app/data/db.dart';
import 'package:budget_app/data/models.dart';
import 'package:budget_app/data/repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Repository> _newRepo() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      singleInstance: false,
      onCreate: (db, _) async {
        for (final stmt in AppDb.schema) {
          await db.execute(stmt);
        }
      },
    ),
  );
  return Repository(db);
}

TxRec _tx(String id, int amount, DateTime at,
        {String? hash, bool review = false}) =>
    TxRec(
      id: id,
      accountId: 'a1',
      amount: amount,
      currency: 'MGA',
      direction: Direction.outflow,
      occurredAt: at,
      source: hash == null ? 'manual' : 'sms',
      smsHash: hash,
      needsReview: review,
    );

void main() {
  sqfliteFfiInit();

  test('spentPerDay regroupe les 7 jours en une requête', () async {
    final repo = await _newRepo();
    final today = DateTime(2026, 11, 4, 15);
    await repo.insertTx(_tx('t1', 1000, DateTime(2026, 11, 4, 9)));
    await repo.insertTx(_tx('t2', 500, DateTime(2026, 11, 4, 20)));
    await repo.insertTx(_tx('t3', 300, DateTime(2026, 10, 29, 8)));
    await repo.insertTx(_tx('t4', 999, DateTime(2026, 10, 28, 8))); // hors fenêtre
    final days = await repo.spentPerDay(today, 7);
    expect(days, [300, 0, 0, 0, 0, 0, 1500]);
  });

  test('existingSmsHashes et insertTxBatch ignorent les doublons', () async {
    final repo = await _newRepo();
    final d = DateTime(2026, 11, 4);
    await repo.insertTxBatch([
      _tx('a', 100, d, hash: 'h1', review: true),
      _tx('b', 200, d, hash: 'h1', review: true), // même SMS
      _tx('c', 300, d, hash: 'h2', review: true),
    ]);
    expect(await repo.existingSmsHashes(['h1', 'h2', 'h3']), {'h1', 'h2'});
    expect((await repo.listTx(review: true)).length, 2);
  });

  test('la catégorie retenue est retrouvée pour le même commerçant', () async {
    final repo = await _newRepo();
    await repo.rememberMerchant('Orange Money · Jumia 123', 'cat_food');
    final rules = await repo.loadMerchantRules();
    expect(rules[Repository.merchantKey('Orange Money · Jumia 456')],
        'cat_food');
  });

  test('balance en une requête = ouverture + entrées - sorties', () async {
    final repo = await _newRepo();
    await repo.insertAccount(const Account(
        id: 'a1', name: 'Cash', kind: 'cash', currency: 'MGA',
        openingBalance: 10000));
    await repo.insertTx(_tx('t1', 2500, DateTime(2026, 11, 4)));
    await repo.insertTx(_tx('t2', 9999, DateTime(2026, 11, 4),
        hash: 'x', review: true)); // à valider : ne compte pas
    expect(await repo.balance(), 7500);
  });
}