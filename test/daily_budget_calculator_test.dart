import 'package:budget_app/data/models.dart';
import 'package:budget_app/domain/daily_budget_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

BudgetSettings _settings({
  int savings = 0,
  PeriodMode mode = PeriodMode.month,
  int threshold = 80,
}) =>
    BudgetSettings(
      homeCurrency: 'MGA',
      locale: 'fr',
      savingsGoal: savings,
      periodMode: mode,
      alertThreshold: threshold,
    );

void main() {
  final today = DateTime(2026, 11, 10); // 21 jours jusqu'au 30 novembre inclus

  final rent = PlannedItem(
    id: 'r',
    label: 'Loyer',
    direction: Direction.outflow,
    amount: 100000,
    currency: 'MGA',
    dueDate: DateTime(2026, 11, 25),
    recurrence: Recurrence.monthly,
  );

  test('budget du jour en mode fin de mois', () {
    final d = DailyBudgetCalculator.compute(
      today: today,
      balance: 400000,
      spentToday: 0,
      planned: [rent],
      settings: _settings(savings: 50000),
    );
    expect(d.daysRemaining, 21);
    expect(d.dailyBudget, 11904); // (400000-100000-50000) ~/ 21
    expect(d.remainingToday, 11904);
    expect(d.status, BudgetStatus.ok);
  });

  test('le budget du jour reste stable quand on dépense', () {
    final d = DailyBudgetCalculator.compute(
      today: today,
      balance: 392000, // 400000 - 8000 dépensés aujourd'hui
      spentToday: 8000,
      planned: [rent],
      settings: _settings(savings: 50000),
    );
    expect(d.dailyBudget, 11904);
    expect(d.remainingToday, 3904);
  });

  test('alerte puis dépassement', () {
    DailyBudget at(int spent) => DailyBudgetCalculator.compute(
          today: today,
          balance: 400000 - spent,
          spentToday: spent,
          planned: [rent],
          settings: _settings(savings: 50000),
        );
    expect(at(10000).status, BudgetStatus.warning);
    expect(at(12000).status, BudgetStatus.over);
  });

  test('mode prochaine rentrée', () {
    final salary = PlannedItem(
      id: 's',
      label: 'Paiement client',
      direction: Direction.inflow,
      amount: 500000,
      currency: 'MGA',
      dueDate: DateTime(2026, 11, 15),
    );
    final d = DailyBudgetCalculator.compute(
      today: today,
      balance: 100000,
      spentToday: 0,
      planned: [salary],
      settings: _settings(mode: PeriodMode.nextIncome),
    );
    expect(d.daysRemaining, 5); // du 10 au 14
    expect(d.dailyBudget, 20000);
  });

  test('fonds insuffisants', () {
    final d = DailyBudgetCalculator.compute(
      today: today,
      balance: 50000,
      spentToday: 0,
      planned: [rent],
      settings: _settings(),
    );
    expect(d.dailyBudget, 0);
    expect(d.shortfall, 50000);
    expect(d.status, BudgetStatus.over);
  });
}
