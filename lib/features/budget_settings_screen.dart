import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/currencies.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'backup_screen.dart';
import 'change_currency_screen.dart';
import 'planned_items_screen.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  late final TextEditingController _savings;
  late PeriodMode _mode;
  late double _threshold;
  late String _lang;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings!;
    _savings = TextEditingController(
        text: s.savingsGoal == 0
            ? ''
            : Money.format(s.savingsGoal, s.homeCurrency, withSymbol: false));
    _mode = s.periodMode;
    _threshold = s.alertThreshold.toDouble();
    _lang = s.locale;
  }

  @override
  void dispose() {
    _savings.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final st = context.read<AppState>();
    final cur = st.settings!.homeCurrency;
    final goal =
        Money.parse(_savings.text.isEmpty ? '0' : _savings.text, cur);
    if (goal == null) {
      setState(() => _error = S.t('invalid_amount'));
      return;
    }
    await st.updateSettings(st.settings!.copyWith(
      savingsGoal: goal,
      periodMode: _mode,
      alertThreshold: _threshold.round(),
      locale: _lang,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.read<AppState>().settings!.homeCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _savings,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: S.t('savings_goal'),
              suffixText: symbolOf(cur),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
          Text(S.t('period_mode')),
          const SizedBox(height: 8),
          SegmentedButton<PeriodMode>(
            segments: [
              ButtonSegment(
                  value: PeriodMode.month, label: Text(S.t('period_month'))),
              ButtonSegment(
                  value: PeriodMode.nextIncome,
                  label: Text(S.t('period_next_income'))),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 20),
          Text(S.tr('alert_threshold', {'n': '${_threshold.round()}'})),
          Slider(
            min: 50,
            max: 100,
            divisions: 10,
            value: _threshold,
            label: '${_threshold.round()} %',
            onChanged: (v) => setState(() => _threshold = v),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat),
            title: Text(S.t('planned_items')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlannedItemsScreen())),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.currency_exchange),
            title: Text(S.t('currency_change')),
            subtitle: Text(currencyLabel(cur, S.lang)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChangeCurrencyScreen())),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.backup_outlined),
            title: Text(S.t('backup_title')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BackupScreen())),
          ),
          const SizedBox(height: 12),
          Text(S.t('language')),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fr', label: Text('Français')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {_lang},
            onSelectionChanged: (s) => setState(() => _lang = s.first),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(S.t('save'))),
        ],
      ),
    );
  }
}