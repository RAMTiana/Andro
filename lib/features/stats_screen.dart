import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/currencies.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// Statistiques : dépenses du mois, 7 derniers jours, plafonds par catégorie.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Future<void> _editLimit(
      BuildContext context, BudgetCategory c, String cur) async {
    final st = context.read<AppState>();
    final ctrl = TextEditingController(
        text: c.limitAmount == null
            ? ''
            : Money.format(c.limitAmount!, cur, withSymbol: false));
    final result = await showDialog<_LimitResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${S.t('category_limit')} · ${c.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              helperText: S.t('limit_hint'), suffixText: symbolOf(cur)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.t('cancel'))),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) {
                Navigator.pop(ctx, const _LimitResult(null));
                return;
              }
              final v = Money.parse(text, cur);
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, _LimitResult(v));
            },
            child: Text(S.t('save')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) await st.setCategoryLimit(c.id, result.amount);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cur = st.settings!.homeCurrency;
    final threshold = st.settings!.alertThreshold / 100;

    final outCats = st.categories
        .where((c) => c.direction == Direction.outflow)
        .toList();
    final uncategorized = st.monthByCategory[''] ?? 0;
    final maxDay = st.last7Days.fold<int>(0, (a, b) => a > b ? a : b);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(S.t('stats_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.t('month_spending'),
                      style: text.labelLarge?.copyWith(color: cs.secondary)),
                  const SizedBox(height: 6),
                  Text(Money.format(st.monthSpent, cur),
                      style: text.headlineMedium?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(S.t('last_7_days'), style: text.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < st.last7Days.length; i++)
                      Expanded(
                        child: _DayBar(
                          value: st.last7Days[i],
                          max: maxDay,
                          day: DateTime(now.year, now.month,
                                  now.day - (st.last7Days.length - 1 - i))
                              .day,
                          highlight: i == st.last7Days.length - 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(S.t('by_category'), style: text.titleMedium),
          const SizedBox(height: 8),
          if (st.monthSpent == 0 && outCats.every((c) => c.limitAmount == null))
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(S.t('no_data'))),
            ),
          for (final c in outCats)
            if ((st.monthByCategory[c.id] ?? 0) > 0 || c.limitAmount != null)
              _CategoryRow(
                name: c.name,
                spent: st.monthByCategory[c.id] ?? 0,
                limit: c.limitAmount,
                total: st.monthSpent,
                currency: cur,
                threshold: threshold,
                onTap: () => _editLimit(context, c, cur),
              ),
          if (uncategorized > 0)
            _CategoryRow(
              name: S.t('cat_other'),
              spent: uncategorized,
              limit: null,
              total: st.monthSpent,
              currency: cur,
              threshold: threshold,
            ),
        ],
      ),
    );
  }
}

class _LimitResult {
  final int? amount;
  const _LimitResult(this.amount);
}

class _DayBar extends StatelessWidget {
  final int value;
  final int max;
  final int day;
  final bool highlight;
  const _DayBar({
    required this.value,
    required this.max,
    required this.day,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = max == 0 ? 0.0 : value / max;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FractionallySizedBox(
                heightFactor: v < 0.03 ? 0.03 : v,
                widthFactor: 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: highlight ? AppColors.gold : AppColors.aubergineLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('$day',
            style: TextStyle(
                fontSize: 12,
                color: highlight ? AppColors.gold : cs.secondary)),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final int spent;
  final int? limit;
  final int total;
  final String currency;
  final double threshold;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.name,
    required this.spent,
    required this.limit,
    required this.total,
    required this.currency,
    required this.threshold,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double ratio;
    Color color;
    if (limit != null && limit! > 0) {
      ratio = spent / limit!;
      color = ratio >= 1
          ? AppColors.danger
          : ratio >= threshold
              ? AppColors.warning
              : AppColors.gold;
    } else {
      ratio = total == 0 ? 0 : spent / total;
      color = cs.secondary;
    }
    final amountText = limit == null
        ? Money.format(spent, currency)
        : '${Money.format(spent, currency)} ${S.tr('limit_of', {
                'max': Money.format(limit!, currency)
              })}';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
                  if (onTap != null)
                    Icon(Icons.edit_outlined, size: 16, color: cs.secondary),
                ],
              ),
              const SizedBox(height: 4),
              Text(amountText, style: TextStyle(color: cs.secondary)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  color: color,
                  backgroundColor: cs.surfaceContainerHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}