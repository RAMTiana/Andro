import '../data/models.dart';

enum BudgetStatus { ok, warning, over }

class DailyBudget {
  final int dailyBudget; // budget du jour (unités mineures)
  final int spentToday;
  final int remainingToday; // peut être négatif
  final int daysRemaining;
  final int shortfall; // manque pour couvrir la période (0 si OK)
  final DateTime periodEnd;
  final BudgetStatus status;

  const DailyBudget({
    required this.dailyBudget,
    required this.spentToday,
    required this.remainingToday,
    required this.daysRemaining,
    required this.shortfall,
    required this.periodEnd,
    required this.status,
  });
}

/// Calcul pur (sans base de données ni interface), facile à tester.
///
/// budget_jour = (solde_début_de_journée + rentrées_prévues
///                - charges_prévues - épargne) ÷ jours_restants
class DailyBudgetCalculator {
  static DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime monthEnd(DateTime d) => DateTime.utc(d.year, d.month + 1, 0);

  /// Dates d'occurrence de [it] dans l'intervalle [from, to] (inclus).
  static List<DateTime> occurrences(
      PlannedItem it, DateTime from, DateTime to) {
    final start = _day(it.dueDate);
    final out = <DateTime>[];
    switch (it.recurrence) {
      case Recurrence.none:
        if (!start.isBefore(from) && !start.isAfter(to)) out.add(start);
      case Recurrence.weekly:
        var d = start;
        while (d.isBefore(from)) {
          d = d.add(const Duration(days: 7));
        }
        while (!d.isAfter(to)) {
          out.add(d);
          d = d.add(const Duration(days: 7));
        }
      case Recurrence.monthly:
        for (var k = 0; k < 1200; k++) {
          final m = start.month + k;
          final lastDay = DateTime.utc(start.year, m + 1, 0).day;
          final d =
              DateTime.utc(start.year, m, start.day > lastDay ? lastDay : start.day);
          if (d.isAfter(to)) break;
          if (!d.isBefore(from)) out.add(d);
        }
    }
    return out;
  }

  /// Prochaine rentrée prévue strictement après [today].
  static DateTime? nextIncome(List<PlannedItem> items, DateTime today) {
    DateTime? best;
    final from = today.add(const Duration(days: 1));
    final to = today.add(const Duration(days: 400));
    for (final it in items) {
      if (it.direction != Direction.inflow) continue;
      final occ = occurrences(it, from, to);
      if (occ.isNotEmpty && (best == null || occ.first.isBefore(best))) {
        best = occ.first;
      }
    }
    return best;
  }

  static DailyBudget compute({
    required DateTime today,
    required int balance,
    required int spentToday,
    required List<PlannedItem> planned,
    required BudgetSettings settings,
  }) {
    final t = _day(today);

    var periodEnd = monthEnd(t);
    if (settings.periodMode == PeriodMode.nextIncome) {
      final next = nextIncome(planned, t);
      if (next != null) periodEnd = next.subtract(const Duration(days: 1));
    }
    final days = periodEnd.difference(t).inDays + 1;

    var plannedIn = 0;
    var plannedOut = 0;
    for (final it in planned) {
      final n = occurrences(it, t, periodEnd).length;
      if (it.direction == Direction.inflow) {
        plannedIn += n * it.amount;
      } else {
        plannedOut += n * it.amount;
      }
    }

    // Solde avant les dépenses du jour, pour que le budget du jour reste
    // stable quand on dépense.
    final base = balance + spentToday;
    final pool = base + plannedIn - plannedOut - settings.savingsGoal;
    final daily = pool <= 0 ? 0 : pool ~/ days;
    final remaining = daily - spentToday;

    BudgetStatus status;
    if (daily == 0 || remaining < 0) {
      status = BudgetStatus.over;
    } else if (spentToday * 100 >= daily * settings.alertThreshold) {
      status = BudgetStatus.warning;
    } else {
      status = BudgetStatus.ok;
    }

    return DailyBudget(
      dailyBudget: daily,
      spentToday: spentToday,
      remainingToday: remaining,
      daysRemaining: days,
      shortfall: pool < 0 ? -pool : 0,
      periodEnd: periodEnd,
      status: status,
    );
  }
}
