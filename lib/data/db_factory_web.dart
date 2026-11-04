import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web : base stockée dans IndexedDB du navigateur.
/// Nécessite web/sqlite3.wasm et web/sqflite_sw.js
/// (générés par : dart run sqflite_common_ffi_web:setup).
Future<void> initDbFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}

Future<String?> platformDbPath(String name) async => name;
