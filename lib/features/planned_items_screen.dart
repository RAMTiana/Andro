import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/currencies.dart';
import '../core/date_fmt.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// Charges fixes et rentrées prévues : elles alimentent le calcul du jour.
class PlannedItemsScreen extends StatelessWidget {
  const PlannedItemsScreen({super.key});

  String _recText(Recurrence r) => switch (r) {
        Recurrence.none => S.t('rec_none'),
        Recurrence.weekly => S.t('rec_weekly'),
        Recurrence.monthly => S.t('rec_monthly'),
      };

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final cur = st.settings!.homeCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('planned_items'))),
      body: ListView(
        children: [
          for (final p in st.planned)
            ListTile(
              leading: Icon(p.direction == Direction.inflow
                  ? Icons.south_west
                  : Icons.north_east),
              title: Text(p.label),
              subtitle:
                  Text('${fmtDate(p.dueDate)} · ${_recText(p.recurrence)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Money.format(p.amount, cur)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => st.removePlanned(p.id),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(S.t('add_planned')),
        onPressed: () async {
          final item = await showDialog<PlannedItem>(
            context: context,
            builder: (_) => _PlannedDialog(currency: cur),
          );
          if (item != null) await st.addPlanned(item);
        },
      ),
    );
  }
}

class _PlannedDialog extends StatefulWidget {
  final String currency;
  const _PlannedDialog({required this.currency});

  @override
  State<_PlannedDialog> createState() => _PlannedDialogState();
}

class _PlannedDialogState extends State<_PlannedDialog> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  Direction _dir = Direction.outflow;
  DateTime _date = DateTime.now();
  Recurrence _rec = Recurrence.monthly;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amt = Money.parse(_amount.text, widget.currency);
    if (amt == null || amt <= 0) {
      setState(() => _error = S.t('invalid_amount'));
      return;
    }
    Navigator.pop(
      context,
      PlannedItem(
        id: const Uuid().v4(),
        label: _label.text.trim().isEmpty ? '—' : _label.text.trim(),
        direction: _dir,
        amount: amt,
        currency: widget.currency,
        dueDate: DateTime(_date.year, _date.month, _date.day),
        recurrence: _rec,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.t('add_planned')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<Direction>(
              segments: [
                ButtonSegment(
                    value: Direction.outflow, label: Text(S.t('expense'))),
                ButtonSegment(
                    value: Direction.inflow, label: Text(S.t('income'))),
              ],
              selected: {_dir},
              onSelectionChanged: (s) => setState(() => _dir = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              decoration: InputDecoration(labelText: S.t('label')),
            ),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: S.t('amount'),
                suffixText: symbolOf(widget.currency),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(fmtDate(_date)),
              onPressed: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (p != null) setState(() => _date = p);
              },
            ),
            const SizedBox(height: 12),
            Text(S.t('recurrence')),
            Wrap(
              spacing: 8,
              children: [
                for (final r in Recurrence.values)
                  ChoiceChip(
                    label: Text(switch (r) {
                      Recurrence.none => S.t('rec_none'),
                      Recurrence.weekly => S.t('rec_weekly'),
                      Recurrence.monthly => S.t('rec_monthly'),
                    }),
                    selected: _rec == r,
                    onSelected: (_) => setState(() => _rec = r),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.t('cancel'))),
        FilledButton(onPressed: _submit, child: Text(S.t('save'))),
      ],
    );
  }
}
