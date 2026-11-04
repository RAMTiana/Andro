import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/date_fmt.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../sms/sms_parser.dart';
import '../state/app_state.dart';
import 'sms_preview_screen.dart';

/// Transactions importées par SMS, à valider en 1 tap.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  /// Lecture automatique de la boîte SMS (Android uniquement).
  Future<void> _import(BuildContext context, AppState st) async {
    final found = await st.scanSms();
    if (!context.mounted) return;
    if (found == null) {
      _snack(context, S.t('sms_denied'));
      return;
    }
    await _preview(context, found, S.t('import_none'));
  }

  /// Texte collé à la main (Android et iPhone).
  Future<void> _paste(BuildContext context, AppState st) async {
    final text = await showDialog<String>(
        context: context, builder: (_) => const _PasteDialog());
    if (text == null || text.trim().isEmpty) return;
    final found = await st.parsePasted(text);
    if (!context.mounted) return;
    await _preview(context, found, S.t('paste_none'));
  }

  /// Rien n'est enregistré avant la confirmation dans l'aperçu.
  Future<void> _preview(
      BuildContext context, List<ParsedSms> found, String emptyMsg) async {
    if (found.isEmpty) {
      _snack(context, emptyMsg);
      return;
    }
    final n = await Navigator.of(context).push<int>(
        MaterialPageRoute(builder: (_) => SmsPreviewScreen(items: found)));
    if (!context.mounted || n == null) return;
    _snack(context, S.tr('import_done', {'n': '$n'}));
  }

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final cur = st.settings!.homeCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('review'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // iOS interdit aux applications de lire les SMS : bouton réservé à Android.
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            FilledButton.icon(
              onPressed: () => _import(context, st),
              icon: const Icon(Icons.sms_outlined),
              label: Text(S.t('import_sms')),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => _paste(context, st),
            icon: const Icon(Icons.content_paste),
            label: Text(S.t('paste_sms')),
          ),
          const SizedBox(height: 12),
          Text(S.t('review_hint')),
          const SizedBox(height: 8),
          for (final t in st.pending) _PendingCard(tx: t, currency: cur),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final TxRec tx;
  final String currency;
  const _PendingCard({required this.tx, required this.currency});

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    final income = tx.direction == Direction.inflow;
    final cats = st.categories.where((c) => c.direction == tx.direction);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(income ? Icons.south_west : Icons.north_east),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${income ? '+' : '-'}${Money.format(tx.amount, currency)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${tx.note ?? ''} · ${fmtDateTime(tx.occurredAt)}'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in cats)
                  ActionChip(
                    label: Text(c.name),
                    onPressed: () => st.confirmTx(tx, categoryId: c.id),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => st.deleteTx(tx.id),
                  child: Text(S.t('delete')),
                ),
                TextButton(
                  onPressed: () => st.confirmTx(tx),
                  child: Text(S.t('validate')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog();

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.t('paste_title')),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        minLines: 4,
        maxLines: 10,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: S.t('paste_hint'),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: Text(S.t('paste_analyze')),
        ),
      ],
    );
  }
}
