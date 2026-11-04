import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/date_fmt.dart';
import '../core/money.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../sms/sms_parser.dart';
import '../state/app_state.dart';

/// Aperçu des SMS détectés : l'utilisateur coche ce qu'il veut importer.
/// Rien n'est écrit en base avant l'appui sur « Importer ».
/// Se ferme avec le nombre de transactions ajoutées (null si annulé).
class SmsPreviewScreen extends StatefulWidget {
  final List<ParsedSms> items;
  const SmsPreviewScreen({super.key, required this.items});

  @override
  State<SmsPreviewScreen> createState() => _SmsPreviewScreenState();
}

class _SmsPreviewScreenState extends State<SmsPreviewScreen> {
  late final Set<String> _selected =
      widget.items.map((p) => p.hash).toSet(); // tout coché par défaut
  bool _busy = false;

  bool get _allSelected => _selected.length == widget.items.length;

  void _toggleAll(bool? v) => setState(() {
        if (v == true) {
          _selected.addAll(widget.items.map((p) => p.hash));
        } else {
          _selected.clear();
        }
      });

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final chosen =
        widget.items.where((p) => _selected.contains(p.hash)).toList();
    final n = await context.read<AppState>().importParsed(chosen);
    if (!mounted) return;
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.read<AppState>().settings!.homeCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('sms_preview'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(S.t('sms_preview_hint')),
          ),
          CheckboxListTile(
            value: _allSelected,
            onChanged: _busy ? null : _toggleAll,
            title: Text(S.t('select_all')),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, i) {
                final p = widget.items[i];
                final income = p.direction == Direction.inflow;
                return CheckboxListTile(
                  value: _selected.contains(p.hash),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                            if (v == true) {
                              _selected.add(p.hash);
                            } else {
                              _selected.remove(p.hash);
                            }
                          }),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    '${income ? '+' : '-'}${Money.format(p.amount, cur)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: income ? AppColors.gold : null,
                    ),
                  ),
                  subtitle: Text(
                    '${fmtDateTime(p.date)} · ${p.note}\n${p.body}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_busy || _selected.isEmpty) ? null : _confirm,
                child: Text(
                    S.tr('import_selected', {'n': '${_selected.length}'})),
              ),
            ),
          ),
        ],
      ),
    );
  }
}