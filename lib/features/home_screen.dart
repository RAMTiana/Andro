import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../domain/daily_budget_calculator.dart';
import '../state/app_state.dart';
import 'add_transaction_sheet.dart';
import 'budget_settings_screen.dart';
import 'review_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _alertText(DailyBudget d) {
    if (d.shortfall > 0) return S.t('alert_shortfall');
    return d.status == BudgetStatus.over
        ? S.t('alert_over')
        : S.t('alert_warning');
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final d = st.daily;
    if (d == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cur = st.settings!.homeCurrency;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = switch (d.status) {
      BudgetStatus.ok => AppColors.gold,
      BudgetStatus.warning => AppColors.warning,
      BudgetStatus.over => AppColors.danger,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('app_title')),
        actions: [
          IconButton(
            tooltip: S.t('review'),
            icon: Badge(
              label: Text('${st.pendingReview}'),
              isLabelVisible: st.pendingReview > 0,
              child: const Icon(Icons.inbox_outlined),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReviewScreen())),
          ),
          IconButton(
            tooltip: S.t('settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BudgetSettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: st.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.aubergine, AppColors.aubergineDeep],
                ),
                border: Border.all(color: color.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.aubergine.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(S.t('remaining_prefix'),
                      style: text.titleMedium
                          ?.copyWith(color: AppColors.silver)),
                  const SizedBox(height: 10),
                  FittedBox(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0, end: d.remainingToday.toDouble()),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        Money.format(v.round(), cur),
                        style: text.displayMedium?.copyWith(
                            color: color, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(S.t('remaining_suffix'),
                      style: const TextStyle(color: AppColors.silver)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (d.status != BudgetStatus.ok)
              Card(
                color: color.withValues(alpha: 0.14),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: color),
                  title: Text(_alertText(d)),
                ),
              ),
            Row(
              children: [
                Expanded(
                    child: _Stat(S.t('daily_budget'),
                        Money.format(d.dailyBudget, cur))),
                Expanded(
                    child: _Stat(S.t('spent_today'),
                        Money.format(d.spentToday, cur))),
              ],
            ),
            _Stat(S.t('balance'), Money.format(st.balance, cur),
                footer: S.tr('days_left', {'n': '${d.daysRemaining}'})),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(S.t('transactions'), style: text.titleMedium)),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TransactionsScreen())),
                  child: Text(S.t('see_all')),
                ),
              ],
            ),
            if (st.recent.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text(S.t('no_tx'))),
              ),
            for (final t in st.recent.take(5))
              TxTile(
                  tx: t,
                  categoryName: st.categoryName(t.categoryId),
                  currency: cur),
            const SizedBox(height: 72),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context),
        icon: const Icon(Icons.add),
        label: Text(S.t('add')),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? footer;
  const _Stat(this.label, this.value, {this.footer});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: text.labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 4),
            Text(value,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (footer != null) Text(footer!, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}