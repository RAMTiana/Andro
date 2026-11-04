import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/date_fmt.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'add_transaction_sheet.dart';
import 'transactions_screen.dart';

/// Page des rentrées d'argent : total du mois, répartition par catégorie,
/// rentrées prévues et dernières entrées.
class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cur = st.settings!.homeCurrency;

    final incomes =
        st.recent.where((t) => t.direction == Direction.inflow).toList();
    final planned = st.planned
        .where((p) => p.direction == Direction.inflow)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final inCats =
        st.categories.where((c) => c.direction == Direction.inflow).toList();

    return Scaffold(
      appBar: AppBar(title: Text(S.t('income_title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context,
            initialDirection: Direction.inflow),
        icon: const Icon(Icons.add),
        label: Text(S.t('income_add')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.aubergine, AppColors.aubergineDeep],
              ),
              border:
                  Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.t('income_month'),
                    style: text.titleMedium
                        ?.copyWith(color: AppColors.silver)),
                const SizedBox(height: 8),
                FittedBox(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: st.monthIncome.toDouble()),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      '+${Money.format(v.round(), cur)}',
                      style: text.displaySmall?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (st.monthIncome > 0) ...[
            for (final c in inCats)
              if ((st.monthIncomeByCategory[c.id] ?? 0) > 0)
                _IncomeCategoryRow(
                  name: c.name,
                  amount: st.monthIncomeByCategory[c.id]!,
                  total: st.monthIncome,
                  currency: cur,
                ),
            if ((st.monthIncomeByCategory[''] ?? 0) > 0)
              _IncomeCategoryRow(
                name: S.t('cat_income_other'),
                amount: st.monthIncomeByCategory['']!,
                total: st.monthIncome,
                currency: cur,
              ),
            const SizedBox(height: 8),
          ],
          if (planned.isNotEmpty) ...[
            Text(S.t('income_planned'), style: text.titleMedium),
            const SizedBox(height: 4),
            for (final p in planned)
              Card(
                child: ListTile(
                  leading: Icon(Icons.event_available, color: cs.secondary),
                  title: Text(p.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(fmtDate(p.dueDate)),
                  trailing: Text(
                    '+${Money.format(p.amount, cur)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.gold),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
          Text(S.t('income_recent'), style: text.titleMedium),
          const SizedBox(height: 4),
          if (incomes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.savings_outlined, size: 56, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(S.t('income_empty'), style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(S.t('income_empty_hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.secondary)),
                ],
              ),
            ),
          for (final t in incomes.take(30))
            Dismissible(
              key: ValueKey('inc_${t.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: cs.error,
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
            ),
        ],
      ),
    );
  }
}

class _IncomeCategoryRow extends StatelessWidget {
  final String name;
  final int amount;
  final int total;
  final String currency;
  const _IncomeCategoryRow({
    required this.name,
    required this.amount,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = total == 0 ? 0.0 : amount / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(Money.format(amount, currency),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                color: AppColors.gold,
                backgroundColor: cs.surfaceContainerHigh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}