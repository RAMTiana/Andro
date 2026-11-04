import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/currencies.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _cash = TextEditingController();
  final _mobile = TextEditingController();
  late String _cur = _guessCurrency();
  String _error = '';

  static String _guessCurrency() =>
      currencyForCountry(PlatformDispatcher.instance.locale.countryCode) ??
      'USD';

  @override
  void dispose() {
    _cash.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final cash = Money.parse(_cash.text.isEmpty ? '0' : _cash.text, _cur);
    final mobile =
        Money.parse(_mobile.text.isEmpty ? '0' : _mobile.text, _cur);
    if (cash == null || mobile == null) {
      setState(() => _error = S.t('invalid_amount'));
      return;
    }
    await context.read<AppState>().completeOnboarding(
          homeCurrency: _cur,
          cashBalance: cash,
          mobileBalance: mobile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fr', label: Text('Français')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {S.lang},
              onSelectionChanged: (s) => setState(() => S.setLang(s.first)),
            ),
            const SizedBox(height: 32),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.aubergine, AppColors.aubergineLight],
                ),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.gold, size: 32),
            ),
            const SizedBox(height: 20),
            Text(S.t('welcome'), style: text.headlineLarge),
            const SizedBox(height: 8),
            Text(S.t('onb_intro'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 24),
            DropdownMenu<String>(
              label: Text(S.t('currency')),
              initialSelection: _cur,
              expandedInsets: EdgeInsets.zero,
              enableFilter: true,
              requestFocusOnTap: true,
              menuHeight: 320,
              dropdownMenuEntries: [
                for (final c in kSupportedCurrencies)
                  DropdownMenuEntry(
                      value: c, label: currencyLabel(c, S.lang)),
              ],
              onSelected: (v) => setState(() => _cur = v ?? _cur),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cash,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: S.t('cash_balance'), suffixText: symbolOf(_cur)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobile,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: S.t('mobile_balance'),
                  suffixText: symbolOf(_cur),
                  errorText: _error.isEmpty ? null : _error),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _start, child: Text(S.t('start'))),
          ],
        ),
      ),
    );
  }
}