import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/date_fmt.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// Transactions importées par SMS, à valider en 1 tap.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  Future<void> _import(BuildContext context, AppState st) async {
    final n = await st.importSms();
    if (!context.mounted) return;
    final msg =
        n < 0 ? S.t('sms_denied') : S.tr('import_done', {'n': '$n'});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final cur = st.settings!.homeCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('review'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () => _import(context, st),
            icon: const Icon(Icons.sms_outlined),
            label: Text(S.t('import_sms')),
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
