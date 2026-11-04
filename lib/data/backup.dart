import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Fichier de sauvegarde invalide ou incompatible.
class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => 'BackupException: $message';
}

/// Export / restauration de toute la base en un fichier JSON.
/// Les lignes supprimées (deleted_at) sont conservées : un SMS refusé ne
/// reviendra donc pas après une restauration.
class BackupService {
  static const String format = 'mon_budget_backup';
  static const int version = 1;

  /// Ordre d'insertion (la restauration supprime dans l'ordre inverse).
  static const List<String> tables = [
    'accounts',
    'categories',
    'transactions',
    'planned_items',
    'budget_settings',
  ];

  static Future<String> export(Database db) async {
    final data = <String, Object?>{};
    for (final t in tables) {
      data[t] = await db.query(t);
    }
    return jsonEncode({
      'format': format,
      'version': version,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': data,
    });
  }

  /// Remplace TOUTES les données par celles de [source].
  /// Tout ou rien : si une ligne est invalide, la base reste inchangée.
  static Future<void> restore(Database db, String source) async {
    final rows = _validate(source);
    await db.transaction((txn) async {
      for (final t in tables.reversed) {
        await txn.delete(t);
      }
      final batch = txn.batch();
      for (final t in tables) {
        for (final row in rows[t]!) {
          batch.insert(t, row);
        }
      }
      await batch.commit(noResult: true);
    });
  }

  /// Vérifie le fichier et renvoie les lignes de chaque table.
  static Map<String, List<Map<String, Object?>>> _validate(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BackupException('not json');
    }
    if (decoded is! Map || decoded['format'] != format) {
      throw const BackupException('wrong format');
    }
    final v = decoded['version'];
    if (v is! int || v < 1 || v > version) {
      throw const BackupException('unsupported version');
    }
    final tablesJson = decoded['tables'];
    if (tablesJson is! Map) throw const BackupException('no tables');

    final out = <String, List<Map<String, Object?>>>{};
    for (final t in tables) {
      final list = tablesJson[t];
      if (list is! List) throw BackupException('missing table $t');
      out[t] = [
        for (final r in list)
          if (r is Map)
            Map<String, Object?>.from(r)
          else
            throw BackupException('bad row in $t'),
      ];
    }
    if (out['budget_settings']!.length != 1) {
      throw const BackupException('settings missing');
    }
    if (out['accounts']!.isEmpty) throw const BackupException('no account');
    return out;
  }
}