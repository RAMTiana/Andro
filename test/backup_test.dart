import 'package:budget_app/data/backup.dart';
import 'package:budget_app/data/db.dart';
import 'package:budget_app/data/models.dart';
import 'package:budget_app/data/repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Base SQLite en mémoire avec le vrai schéma de l'appli.
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

Future<void> _fill(Repository repo) async {
  await repo.saveSettings(
      const BudgetSettings(homeCurrency: 'MGA', locale: 'fr', savingsGoal: 5000));
  await repo.insertAccount(const Account(
      id: 'a1', name: 'Espèces', kind: 'cash', currency: 'MGA', openingBalance: 10000));
  await repo.insertCategories(const [
    BudgetCategory(id: 'c1', name: 'Nourriture', direction: Direction.outflow),
  ]);
  await repo.insertTx(TxRec(
    id: 't1',
    accountId: 'a1',
    categoryId: 'c1',
    amount: 2500,
    currency: 'MGA',
    direction: Direction.outflow,
    occurredAt: DateTime(2026, 11, 3, 12),
    note: 'riz',
  ));
  // SMS importé puis supprimé : son hash doit survivre à la restauration.
  await repo.insertTx(TxRec(
    id: 't2',
    accountId: 'a1',
    amount: 1000,
    currency: 'MGA',
    direction: Direction.outflow,
    occurredAt: DateTime(2026, 11, 3, 13),
    source: 'sms',
    smsHash: 'hash-supprime',
  ));
  await repo.softDeleteTx('t2');
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('export puis restauration dans une base vide : mêmes données', () async {
    final a = await _newRepo();
    await _fill(a);
    final json = await BackupService.export(a.db);

    final b = await _newRepo();
    await BackupService.restore(b.db, json);

    expect(await b.balance(), await a.balance()); // 10000 - 2500
    expect(await b.balance(), 7500);
    expect((await b.loadSettings())!.savingsGoal, 5000);
    expect((await b.listTx()).length, 1); // t2 est supprimée
    expect(await b.hasSmsHash('hash-supprime'), isTrue);
  });

  test('la restauration remplace les données existantes', () async {
    final a = await _newRepo();
    await _fill(a);
    final json = await BackupService.export(a.db);

    final b = await _newRepo();
    await _fill(b);
    await b.insertTx(TxRec(
      id: 't3',
      accountId: 'a1',
      amount: 999,
      currency: 'MGA',
      direction: Direction.outflow,
      occurredAt: DateTime(2026, 11, 4),
    ));
    await BackupService.restore(b.db, json);
    expect((await b.listTx()).map((t) => t.id), ['t1']);
  });

  test('fichier invalide : exception et base inchangée', () async {
    final a = await _newRepo();
    await _fill(a);
    for (final bad in [
      'pas du json',
      '{"format":"autre","version":1,"tables":{}}',
      '{"format":"mon_budget_backup","version":99,"tables":{}}',
      '{"format":"mon_budget_backup","version":1,"tables":{}}',
    ]) {
      await expectLater(BackupService.restore(a.db, bad),
          throwsA(isA<BackupException>()));
    }
    expect(await a.balance(), 7500);
  });

  test('ligne corrompue : tout est annulé (rollback)', () async {
    final a = await _newRepo();
    await _fill(a);
    final good = await BackupService.export(a.db);
    // colonne inexistante dans une transaction -> l'insertion échoue
    final broken = good.replaceFirst('"amount":2500', '"montant_inconnu":2500');
    expect(broken, isNot(good));

    await expectLater(BackupService.restore(a.db, broken), throwsA(anything));
    expect(await a.balance(), 7500); // données d'origine intactes
    expect((await a.listTx()).length, 1);
  });
}