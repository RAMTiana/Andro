import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/currencies.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../state/app_state.dart';

Future<void> showAddTransactionSheet(BuildContext context,
    {Direction initialDirection = Direction.outflow}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AddTransactionSheet(initialDirection: initialDirection),
  );
}

class AddTransactionSheet extends StatefulWidget {
  final Direction initialDirection;
  const AddTransactionSheet(
      {super.key, this.initialDirection = Direction.outflow});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late Direction _dir = widget.initialDirection;
  String? _categoryId;
  String? _accountId;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final st = context.read<AppState>();
    final amt = Money.parse(_amount.text, st.settings!.homeCurrency);
    if (amt == null || amt <= 0) {
      setState(() => _error = S.t('invalid_amount'));
      return;
    }
    final note = _note.text.trim();
    await st.addTransaction(
      amount: amt,
      direction: _dir,
      accountId: _accountId!,
      categoryId: _categoryId,
      note: note.isEmpty ? null : note,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    final cur = st.settings!.homeCurrency;
    final cats = st.categories.where((c) => c.direction == _dir).toList();
    _accountId ??= st.accounts.first.id;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
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
              onSelectionChanged: (s) => setState(() {
                _dir = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: InputDecoration(
                labelText: S.t('amount'),
                suffixText: symbolOf(cur),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            Text(S.t('category')),
            Wrap(
              spacing: 8,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            if (st.accounts.length > 1) ...[
              const SizedBox(height: 12),
              Text(S.t('account')),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in st.accounts)
                    ChoiceChip(
                      label: Text(a.name),
                      selected: _accountId == a.id,
                      onSelected: (_) => setState(() => _accountId = a.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: S.t('note')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _save, child: Text(S.t('save'))),
            ),
          ],
        ),
      ),
    );
  }
}