import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/currencies.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../state/app_state.dart';

/// Change la devise de l'application et convertit tous les montants
/// avec un taux saisi par l'utilisateur (taux 1 = on garde les chiffres).
class ChangeCurrencyScreen extends StatefulWidget {
  const ChangeCurrencyScreen({super.key});

  @override
  State<ChangeCurrencyScreen> createState() => _ChangeCurrencyScreenState();
}

class _ChangeCurrencyScreenState extends State<ChangeCurrencyScreen> {
  final _rate = TextEditingController(text: '1');
  String? _newCur;
  String? _error;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  double? get _rateValue {
    final v = double.tryParse(_rate.text.trim().replaceAll(',', '.'));
    return (v != null && v.isFinite && v > 0) ? v : null;
  }

  Future<void> _convert() async {
    final st = context.read<AppState>();
    final to = _newCur;
    final rate = _rateValue;
    if (to == null || to == st.settings!.homeCurrency) {
      setState(() => _error = S.t('same_currency'));
      return;
    }
    if (rate == null) {
      setState(() => _error = S.t('invalid_rate'));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t('confirm_title')),
        content: Text(S.t('confirm_body')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.t('convert'))),
        ],
      ),
    );
    if (ok != true) return;
    await st.changeCurrency(to, rate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.tr('currency_changed', {'cur': to}))),
    );
    // Retour à l'accueil : l'écran des paramètres afficherait d'anciens montants.
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final from = st.settings!.homeCurrency;
    final to = _newCur;
    final rate = _rateValue;
    final text = Theme.of(context).textTheme;

    String? preview;
    if (to != null && rate != null && to != from) {
      final converted = Money.convert(st.balance, rate, from, to);
      preview =
          '${Money.format(st.balance, from)}  →  ${Money.format(converted, to)}';
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.t('currency_change'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${S.t('current_currency')} : ${currencyLabel(from, S.lang)}'),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            label: Text(S.t('new_currency')),
            expandedInsets: EdgeInsets.zero,
            enableFilter: true,
            requestFocusOnTap: true,
            menuHeight: 320,
            dropdownMenuEntries: [
              for (final c in kSupportedCurrencies)
                if (c != from)
                  DropdownMenuEntry(value: c, label: currencyLabel(c, S.lang)),
            ],
            onSelected: (v) => setState(() {
              _newCur = v;
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: to == null
                  ? S.t('rate')
                  : S.tr('rate_label', {'from': from, 'to': to}),
              helperText: S.t('rate_hint'),
              helperMaxLines: 3,
              errorText: _error,
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 16),
            Text(S.t('preview'), style: text.titleSmall),
            Text(preview,
                style:
                    text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _convert, child: Text(S.t('convert'))),
        ],
      ),
    );
  }
}