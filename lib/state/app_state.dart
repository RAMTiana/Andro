import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import '../core/strings.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../domain/daily_budget_calculator.dart';
import '../sms/sms_parser.dart';
import '../sms/sms_reader.dart';

class AppState extends ChangeNotifier {
  late Repository repo;
  final SmsReader _sms = SmsReader();
  SmsParser? _parser;
  final Uuid _uuid = const Uuid();

  BudgetSettings? settings;
  List<Account> accounts = [];
  List<BudgetCategory> categories = [];
  List<PlannedItem> planned = [];
  List<TxRec> recent = [];
  List<TxRec> pending = [];
  int balance = 0;
  int spentToday = 0;
  DailyBudget? daily;

  bool get onboarded => settings != null;
  int get pendingReview => pending.length;

  Future<void> init() async {
    S.setLang(PlatformDispatcher.instance.locale.languageCode);
    repo = Repository(await AppDb.open());
    settings = await repo.loadSettings();
    if (settings != null) S.setLang(settings!.locale);
    final rules = await rootBundle.loadString('assets/sms_rules.json');
    _parser = SmsParser.fromJsonString(rules);
    await refresh(notify: false);
  }

  String? categoryName(String? id) {
    if (id == null) return null;
    return categories.where((c) => c.id == id).map((c) => c.name).firstOrNull;
  }

  Future<void> refresh({bool notify = true}) async {
    final s = settings;
    if (s != null) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day + 1);
      accounts = await repo.listAccounts();
      categories = await repo.listCategories();
      planned = await repo.listPlanned();
      recent = await repo.listTx(limit: 200);
      pending = await repo.listTx(limit: 500, review: true);
      balance = await repo.balance();
      spentToday = await repo.spentBetween(start, end);
      daily = DailyBudgetCalculator.compute(
        today: now,
        balance: balance,
        spentToday: spentToday,
        planned: planned,
        settings: s,
      );
    }
    if (notify) notifyListeners();
  }

  Future<void> completeOnboarding({
    required String homeCurrency,
    required int cashBalance,
    required int mobileBalance,
  }) async {
    final s = BudgetSettings(homeCurrency: homeCurrency, locale: S.lang);
    await repo.saveSettings(s);
    await repo.insertAccount(Account(
        id: _uuid.v4(),
        name: S.t('acc_cash'),
        kind: 'cash',
        currency: homeCurrency,
        openingBalance: cashBalance));
    await repo.insertAccount(Account(
        id: _uuid.v4(),
        name: S.t('acc_mobile'),
        kind: 'mobile_money',
        currency: homeCurrency,
        openingBalance: mobileBalance));
    BudgetCategory cat(String key, Direction d) =>
        BudgetCategory(id: _uuid.v4(), name: S.t(key), direction: d);
    await repo.insertCategories([
      cat('cat_food', Direction.outflow),
      cat('cat_transport', Direction.outflow),
      cat('cat_phone', Direction.outflow),
      cat('cat_bills', Direction.outflow),
      cat('cat_health', Direction.outflow),
      cat('cat_school', Direction.outflow),
      cat('cat_leisure', Direction.outflow),
      cat('cat_other', Direction.outflow),
      cat('cat_salary', Direction.inflow),
      cat('cat_business', Direction.inflow),
      cat('cat_income_other', Direction.inflow),
    ]);
    settings = s;
    await refresh();
  }

  Future<void> updateSettings(BudgetSettings s) async {
    settings = s;
    S.setLang(s.locale);
    await repo.saveSettings(s);
    await refresh();
  }

  Future<void> addTransaction({
    required int amount,
    required Direction direction,
    required String accountId,
    String? categoryId,
    String? note,
  }) async {
    await repo.insertTx(TxRec(
      id: _uuid.v4(),
      accountId: accountId,
      categoryId: categoryId,
      amount: amount,
      currency: settings!.homeCurrency,
      direction: direction,
      occurredAt: DateTime.now(),
      note: note,
    ));
    await refresh();
  }

  Future<void> confirmTx(TxRec t, {String? categoryId}) async {
    await repo.updateTx(t.copyWith(categoryId: categoryId, needsReview: false));
    await refresh();
  }

  Future<void> deleteTx(String id) async {
    await repo.softDeleteTx(id);
    await refresh();
  }

  Future<void> addPlanned(PlannedItem p) async {
    await repo.insertPlanned(p);
    await refresh();
  }

  Future<void> removePlanned(String id) async {
    await repo.softDeletePlanned(id);
    await refresh();
  }

  /// Importe les SMS Mobile Money. Retourne le nombre de transactions
  /// importées, ou -1 si la lecture des SMS est impossible.
  Future<int> importSms() async {
    if (!await _sms.ensurePermission()) return -1;
    final s = settings!;
    final last = s.lastSmsImport;
    final since = last != null
        ? DateTime.fromMillisecondsSinceEpoch(last)
            .subtract(const Duration(days: 1))
        : DateTime.now().subtract(const Duration(days: 30));
    final messages = await _sms.readInbox(since: since);
    final acc = accounts.firstWhere((a) => a.kind == 'mobile_money',
        orElse: () => accounts.first);

    var imported = 0;
    for (final m in messages) {
      final p =
          _parser!.parse(sender: m.sender, body: m.body, date: m.date);
      if (p == null || p.currency != s.homeCurrency) continue;
      if (await repo.hasSmsHash(p.hash)) continue;
      await repo.insertTx(TxRec(
        id: _uuid.v4(),
        accountId: acc.id,
        amount: p.amount,
        currency: p.currency,
        direction: p.direction,
        occurredAt: p.date,
        note: p.carrier,
        source: 'sms',
        smsHash: p.hash,
        needsReview: true,
      ));
      imported++;
    }
    settings = s.copyWith(lastSmsImport: DateTime.now().millisecondsSinceEpoch);
    await repo.saveSettings(settings!);
    await refresh();
    return imported;
  }
}
