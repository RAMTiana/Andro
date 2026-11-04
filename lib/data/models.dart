enum Direction {
  inflow('in'),
  outflow('out');

  final String code;
  const Direction(this.code);

  static Direction fromCode(String c) =>
      c == 'in' ? Direction.inflow : Direction.outflow;
}

enum Recurrence {
  none('none'),
  weekly('weekly'),
  monthly('monthly');

  final String code;
  const Recurrence(this.code);

  static Recurrence fromCode(String? c) => Recurrence.values
      .firstWhere((r) => r.code == c, orElse: () => Recurrence.none);
}

enum PeriodMode {
  month('month'),
  nextIncome('next_income');

  final String code;
  const PeriodMode(this.code);

  static PeriodMode fromCode(String? c) => PeriodMode.values
      .firstWhere((p) => p.code == c, orElse: () => PeriodMode.month);
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Account {
  final String id;
  final String name;
  final String kind; // cash | mobile_money | bank
  final String currency;
  final int openingBalance;

  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.currency,
    this.openingBalance = 0,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'kind': kind,
        'currency': currency,
        'opening_balance': openingBalance,
        'updated_at': _nowMs(),
      };

  factory Account.fromMap(Map<String, Object?> m) => Account(
        id: m['id'] as String,
        name: m['name'] as String,
        kind: m['kind'] as String,
        currency: m['currency'] as String,
        openingBalance: m['opening_balance'] as int,
      );
}

class BudgetCategory {
  final String id;
  final String name;
  final Direction direction;
  final int? limitAmount; // plafond mensuel en unités mineures (null = aucun)

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.direction,
    this.limitAmount,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'direction': direction.code,
        'limit_amount': limitAmount,
        'updated_at': _nowMs(),
      };

  factory BudgetCategory.fromMap(Map<String, Object?> m) => BudgetCategory(
        id: m['id'] as String,
        name: m['name'] as String,
        direction: Direction.fromCode(m['direction'] as String),
        limitAmount: m['limit_amount'] as int?,
      );
}

class TxRec {
  final String id;
  final String accountId;
  final String? categoryId;
  final int amount; // unités mineures, toujours > 0
  final String currency;
  final Direction direction;
  final DateTime occurredAt;
  final String? note;
  final String source; // manual | sms
  final String? smsHash;
  final bool needsReview;

  const TxRec({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.direction,
    required this.occurredAt,
    this.categoryId,
    this.note,
    this.source = 'manual',
    this.smsHash,
    this.needsReview = false,
  });

  TxRec copyWith({String? categoryId, bool? needsReview}) => TxRec(
        id: id,
        accountId: accountId,
        categoryId: categoryId ?? this.categoryId,
        amount: amount,
        currency: currency,
        direction: direction,
        occurredAt: occurredAt,
        note: note,
        source: source,
        smsHash: smsHash,
        needsReview: needsReview ?? this.needsReview,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'account_id': accountId,
        'category_id': categoryId,
        'amount': amount,
        'currency': currency,
        'direction': direction.code,
        'occurred_at': occurredAt.millisecondsSinceEpoch,
        'note': note,
        'source': source,
        'sms_hash': smsHash,
        'needs_review': needsReview ? 1 : 0,
        'updated_at': _nowMs(),
      };

  factory TxRec.fromMap(Map<String, Object?> m) => TxRec(
        id: m['id'] as String,
        accountId: m['account_id'] as String,
        categoryId: m['category_id'] as String?,
        amount: m['amount'] as int,
        currency: m['currency'] as String,
        direction: Direction.fromCode(m['direction'] as String),
        occurredAt:
            DateTime.fromMillisecondsSinceEpoch(m['occurred_at'] as int),
        note: m['note'] as String?,
        source: m['source'] as String,
        smsHash: m['sms_hash'] as String?,
        needsReview: (m['needs_review'] as int) == 1,
      );
}

class PlannedItem {
  final String id;
  final String label;
  final Direction direction;
  final int amount;
  final String currency;
  final DateTime dueDate;
  final Recurrence recurrence;

  const PlannedItem({
    required this.id,
    required this.label,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.dueDate,
    this.recurrence = Recurrence.none,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'direction': direction.code,
        'amount': amount,
        'currency': currency,
        'due_date': _dateStr(dueDate),
        'recurrence': recurrence.code,
        'updated_at': _nowMs(),
      };

  factory PlannedItem.fromMap(Map<String, Object?> m) => PlannedItem(
        id: m['id'] as String,
        label: m['label'] as String,
        direction: Direction.fromCode(m['direction'] as String),
        amount: m['amount'] as int,
        currency: m['currency'] as String,
        dueDate: DateTime.parse(m['due_date'] as String),
        recurrence: Recurrence.fromCode(m['recurrence'] as String?),
      );
}

class BudgetSettings {
  final String homeCurrency;
  final String locale;
  final int savingsGoal;
  final PeriodMode periodMode;
  final int alertThreshold; // en %
  final int? lastSmsImport; // ms epoch

  const BudgetSettings({
    required this.homeCurrency,
    required this.locale,
    this.savingsGoal = 0,
    this.periodMode = PeriodMode.month,
    this.alertThreshold = 80,
    this.lastSmsImport,
  });

  BudgetSettings copyWith({
    String? locale,
    int? savingsGoal,
    PeriodMode? periodMode,
    int? alertThreshold,
    int? lastSmsImport,
  }) =>
      BudgetSettings(
        homeCurrency: homeCurrency,
        locale: locale ?? this.locale,
        savingsGoal: savingsGoal ?? this.savingsGoal,
        periodMode: periodMode ?? this.periodMode,
        alertThreshold: alertThreshold ?? this.alertThreshold,
        lastSmsImport: lastSmsImport ?? this.lastSmsImport,
      );

  Map<String, Object?> toMap() => {
        'id': 1,
        'home_currency': homeCurrency,
        'locale': locale,
        'savings_goal': savingsGoal,
        'period_mode': periodMode.code,
        'alert_threshold': alertThreshold,
        'last_sms_import': lastSmsImport,
      };

  factory BudgetSettings.fromMap(Map<String, Object?> m) => BudgetSettings(
        homeCurrency: m['home_currency'] as String,
        locale: m['locale'] as String,
        savingsGoal: m['savings_goal'] as int,
        periodMode: PeriodMode.fromCode(m['period_mode'] as String?),
        alertThreshold: m['alert_threshold'] as int,
        lastSmsImport: m['last_sms_import'] as int?,
      );
}