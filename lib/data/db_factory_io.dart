import 'dart:io' show Directory, Platform;

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool get _isDesktopFfi => Platform.isLinux || Platform.isWindows;

/// Android, iOS et macOS utilisent sqflite directement.
/// Linux et Windows passent par sqflite_common_ffi.
Future<void> initDbFactory() async {
  if (_isDesktopFfi) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

/// Linux / Windows : dossier de données de l'application.
/// Ailleurs : null (chemin habituel de sqflite).
Future<String?> platformDbPath(String name) async {
  if (!_isDesktopFfi) return null;
  final dir = await getApplicationSupportDirectory();
  await Directory(dir.path).create(recursive: true);
  return '${dir.path}/$name';
}
