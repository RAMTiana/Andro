import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/date_fmt.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../state/app_state.dart';

class TxTile extends StatelessWidget {
  final TxRec tx;
  final String? categoryName;
  final String currency;

  const TxTile({
    super.key,
    required this.tx,
    required this.categoryName,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final income = tx.direction == Direction.inflow;
    final note = (tx.note == null || tx.note!.isEmpty) ? '' : ' · ${tx.note}';
    final cs = Theme.of(context).colorScheme;
    final accent = income ? AppColors.gold : cs.secondary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(income ? Icons.south_west : Icons.north_east,
            color: accent, size: 20),
      ),
      title: Text(categoryName ?? S.t('cat_other'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${fmtDateTime(tx.occurredAt)}$note'),
      trailing: Text(
        '${income ? '+' : '-'}${Money.format(tx.amount, currency)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: income ? AppColors.gold : cs.onSurface,
        ),
      ),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final cur = st.settings!.homeCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('transactions'))),
      body: st.recent.isEmpty
          ? Center(child: Text(S.t('no_tx')))
          : ListView.builder(
              itemCount: st.recent.length,
              itemBuilder: (context, i) {
                final t = st.recent[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => st.deleteTx(t.id),
                  child: TxTile(
                    tx: t,
                    categoryName: st.categoryName(t.categoryId),
                    currency: cur,
                  ),
                );
              },
            ),
    );
  }
}