import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/strings.dart';
import '../data/backup.dart';
import '../state/app_state.dart';

/// Export et restauration de toutes les données (fichier JSON).
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _export() async {
    final st = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final json = await st.exportBackup();
      final d = DateTime.now();
      final name = 'mon_budget_${d.year}-${_two(d.month)}-${_two(d.day)}.json';
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
            name: name,
          ),
        ],
        fileNameOverrides: [name],
      );
    } catch (_) {
      if (mounted) _snack(S.t('backup_error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final st = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final res = await FilePicker.platform
          .pickFiles(type: FileType.any, withData: true);
      final bytes = (res == null || res.files.isEmpty)
          ? null
          : res.files.single.bytes;
      if (bytes == null) return; // annulé (ou fichier illisible)
      if (!mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(S.t('backup_confirm_title')),
          content: Text(S.t('backup_confirm_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.t('backup_restore_btn')),
            ),
          ],
        ),
      );
      if (ok != true) return;

      await st.restoreBackup(utf8.decode(bytes));
      if (mounted) _snack(S.t('backup_restored'));
    } on BackupException {
      if (mounted) _snack(S.t('backup_invalid'));
    } on FormatException {
      if (mounted) _snack(S.t('backup_invalid'));
    } catch (_) {
      if (mounted) _snack(S.t('backup_error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t('backup_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(S.t('backup_hint')),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.upload_file),
            label: Text(S.t('backup_export')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.download),
            label: Text(S.t('backup_import')),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}