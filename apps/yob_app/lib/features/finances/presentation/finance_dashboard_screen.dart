import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/finance_provider.dart';

/// Financial Dashboard — 1-click health overview.
class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends ConsumerState<FinanceDashboardScreen> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financeSummaryProvider(_selectedYear));
    final treasuryAsync = ref.watch(defaultTreasuryProvider);
    final currencyFmt = NumberFormat('#,###', 'fr');

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/finances')),
              const SizedBox(width: 8),
              Text('Tableau de bord financier',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              // Year selector
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(5, (i) {
                  final y = DateTime.now().year - i;
                  return DropdownMenuItem(
                      value: y, child: Text(y.toString()));
                }),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedYear = v);
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/finances/report'),
                icon: const Icon(Icons.article_outlined, size: 18),
                label: const Text('Rapport mensuel'),
              ),
            ]),
            const SizedBox(height: 24),

            // Treasury health cards
            treasuryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur trésorerie: $e'),
              data: (treasury) {
                final balance =
                    (treasury['balance'] as num?)?.toDouble() ?? 0;
                final income =
                    (treasury['totalIncome'] as num?)?.toDouble() ?? 0;
                final expense =
                    (treasury['totalExpense'] as num?)?.toDouble() ?? 0;
                final alertLevel =
                    treasury['alertLevel'] as String? ?? 'ok';

                return Column(
                  children: [
                    // Main balance card
                    _BalanceCard(
                      balance: balance,
                      alertLevel: alertLevel,
                      currencyFmt: currencyFmt,
                    ),
                    const SizedBox(height: 16),
                    // Income/Expense summary row
                    Row(children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Entrées',
                          value: '${currencyFmt.format(income)} F',
                          icon: Icons.arrow_downward,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Sorties',
                          value: '${currencyFmt.format(expense)} F',
                          icon: Icons.arrow_upward,
                          color: Colors.red,
                        ),
                      ),
                    ]),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Annual summary
            summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur résumé: $e'),
              data: (summary) {
                final monthly =
                    (summary['monthly'] as List<dynamic>?) ?? [];
                final incomeBreakdown =
                    (summary['incomeBreakdown'] as List<dynamic>?) ?? [];
                final expenseBreakdown =
                    (summary['expenseBreakdown'] as List<dynamic>?) ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly chart
                    Text('Évolution mensuelle $_selectedYear',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _MonthlyBarChart(
                        months: monthly, currencyFmt: currencyFmt),
                    const SizedBox(height: 24),

                    // Category breakdowns side by side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            title: 'Entrées par catégorie',
                            items: incomeBreakdown,
                            color: AppColors.success,
                            currencyFmt: currencyFmt,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CategoryCard(
                            title: 'Sorties par catégorie',
                            items: expenseBreakdown,
                            color: Colors.red,
                            currencyFmt: currencyFmt,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Large balance card with alert coloring.
class _BalanceCard extends StatelessWidget {
  final double balance;
  final String alertLevel;
  final NumberFormat currencyFmt;

  const _BalanceCard({
    required this.balance,
    required this.alertLevel,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (alertLevel) {
      'critical' => Colors.red,
      'warning' => Colors.orange,
      _ => AppColors.success,
    };
    final icon = switch (alertLevel) {
      'critical' => Icons.error,
      'warning' => Icons.warning_amber_rounded,
      _ => Icons.account_balance,
    };
    final label = switch (alertLevel) {
      'critical' => 'Situation critique',
      'warning' => 'Fonds bas',
      _ => 'Santé financière OK',
    };

    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solde Trésorerie',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${currencyFmt.format(balance)} FCFA',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

/// Simplified monthly bar chart using containers.
class _MonthlyBarChart extends StatelessWidget {
  final List<dynamic> months;
  final NumberFormat currencyFmt;

  const _MonthlyBarChart({required this.months, required this.currencyFmt});

  static const _monthLabels = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  @override
  Widget build(BuildContext context) {
    double maxVal = 1;
    for (final m in months) {
      final map = m as Map<String, dynamic>;
      final inc = (map['income'] as num?)?.toDouble() ?? 0;
      final exp = (map['expense'] as num?)?.toDouble() ?? 0;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Legend
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _LegendDot(color: AppColors.success, label: 'Entrées'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red, label: 'Sorties'),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (i) {
                  final map = (i < months.length)
                      ? months[i] as Map<String, dynamic>
                      : <String, dynamic>{};
                  final inc = (map['income'] as num?)?.toDouble() ?? 0;
                  final exp = (map['expense'] as num?)?.toDouble() ?? 0;
                  final incH = (inc / maxVal) * 140;
                  final expH = (exp / maxVal) * 140;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 6,
                                height: incH.clamp(2, 140),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 6,
                                height: expH.clamp(2, 140),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_monthLabels[i],
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]);
  }
}

/// Category breakdown card.
class _CategoryCard extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final Color color;
  final NumberFormat currencyFmt;

  const _CategoryCard({
    required this.title,
    required this.items,
    required this.color,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) {
      final map = item as Map<String, dynamic>;
      return sum + ((map['total'] as num?)?.toDouble() ?? 0);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            if (items.isEmpty)
              Text('Aucune donnée',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13))
            else
              ...items.map((item) {
                final map = item as Map<String, dynamic>;
                final cat = map['category'] as String? ?? 'Autre';
                final val = (map['total'] as num?)?.toDouble() ?? 0;
                final pct = total > 0 ? (val / total) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(cat,
                                style: const TextStyle(fontSize: 13))),
                        Text('${currencyFmt.format(val)} F',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: color)),
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                            color.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
