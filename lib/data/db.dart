import 'package:sqflite/sqflite.dart';

// Android / iOS / macOS : sqflite tel quel. Linux / Windows : sqflite_common_ffi.
// Web : sqflite_common_ffi_web. Le bon fichier est choisi à la compilation.
import 'db_factory.dart'
    if (dart.library.io) 'db_factory_io.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';

/// Ouverture de la base SQLite locale et création du schéma.
class AppDb {
  static Database? _db;

  static const List<String> schema = [
    '''CREATE TABLE accounts(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      currency TEXT NOT NULL,
      opening_balance INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER)''',
    '''CREATE TABLE categories(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      direction TEXT NOT NULL,
      icon TEXT,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER)''',
    '''CREATE TABLE transactions(
      id TEXT PRIMARY KEY,
      account_id TEXT NOT NULL,
      category_id TEXT,
      amount INTEGER NOT NULL CHECK (amount > 0),
      currency TEXT NOT NULL,
      direction TEXT NOT NULL CHECK (direction IN ('in','out')),
      occurred_at INTEGER NOT NULL,
      note TEXT,
      source TEXT NOT NULL DEFAULT 'manual',
      sms_hash TEXT,
      needs_review INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER)''',
    'CREATE UNIQUE INDEX idx_tx_sms ON transactions(sms_hash) WHERE sms_hash IS NOT NULL',
    'CREATE INDEX idx_tx_date ON transactions(occurred_at)',
    '''CREATE TABLE planned_items(
      id TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      direction TEXT NOT NULL,
      amount INTEGER NOT NULL,
      currency TEXT NOT NULL,
      due_date TEXT NOT NULL,
      recurrence TEXT NOT NULL DEFAULT 'none',
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER)''',
    '''CREATE TABLE budget_settings(
      id INTEGER PRIMARY KEY CHECK (id = 1),
      home_currency TEXT NOT NULL,
      locale TEXT NOT NULL,
      savings_goal INTEGER NOT NULL DEFAULT 0,
      period_mode TEXT NOT NULL DEFAULT 'month',
      alert_threshold INTEGER NOT NULL DEFAULT 80,
      last_sms_import INTEGER)''',
  ];

  static Future<Database> open() async {
    final existing = _db;
    if (existing != null) return existing;
    await initDbFactory();
    // Android/iOS/macOS : chemin habituel (les données existantes sont conservées).
    final path = await platformDbPath('budget.db') ??
        '${await getDatabasesPath()}/budget.db';
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        for (final stmt in schema) {
          await db.execute(stmt);
        }
      },
    );
    _db = db;
    return db;
  }
}