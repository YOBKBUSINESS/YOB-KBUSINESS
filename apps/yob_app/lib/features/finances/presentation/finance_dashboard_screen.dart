import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/finance_provider.dart';

class FinanceDashboardScreen extends ConsumerWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final summaryAsync = ref.watch(financeSummaryProvider(year));
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
              OutlinedButton.icon(
                onPressed: () => context.go('/finances/report'),
                icon: const Icon(Icons.summarize_outlined, size: 18),
                label: const Text('Rapport mensuel'),
              ),
            ]),
            const SizedBox(height: 24),

            // Treasury card
            treasuryAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur: $e'),
              data: (data) {
                final balance = (data['balance'] as num).toDouble();
                final income = (data['totalIncome'] as num).toDouble();
                final expense = (data['totalExpense'] as num).toDouble();
                final alertLevel = data['alertLevel'] as String;
                final color = alertLevel == 'critical'
                    ? Colors.red
                    : alertLevel == 'warning'
                        ? Colors.orange
                        : AppColors.success;

                return Column(children: [
                  // Balance card
                  Card(
                    color: color.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        Icon(
                          alertLevel == 'ok'
                              ? Icons.account_balance
                              : Icons.warning_amber_rounded,
                          color: color,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text('Solde de trésorerie',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${currencyFmt.format(balance)} FCFA',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (alertLevel != 'ok') ...[
                          const SizedBox(height: 8),
                          Chip(
                            avatar: const Icon(Icons.warning,
                                size: 16, color: Colors.white),
                            label: Text(
                              alertLevel == 'critical'
                                  ? 'Solde critique !'
                                  : 'Fonds bas',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: color,
                          ),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Income / Expense summary cards
                  Row(children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Entrées',
                        amount: income,
                        icon: Icons.arrow_downward,
                        color: AppColors.success,
                        currencyFmt: currencyFmt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Sorties',
                        amount: expense,
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                        currencyFmt: currencyFmt,
                      ),
                    ),
                  ]),
                ]);
              },
            ),
            const SizedBox(height: 24),

            // Monthly chart
            Text('Évolution mensuelle $year',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Erreur: $e'),
              data: (data) {
                final monthly =
                    (data['monthly'] as List<dynamic>).cast<Map<String, dynamic>>();
                return _MonthlyChart(monthly: monthly, currencyFmt: currencyFmt);
              },
            ),
            const SizedBox(height: 24),

            // Category breakdowns
            summaryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final incomeBreakdown =
                    (data['incomeBreakdown'] as List<dynamic>)
                        .cast<Map<String, dynamic>>();
                final expenseBreakdown =
                    (data['expenseBreakdown'] as List<dynamic>)
                        .cast<Map<String, dynamic>>();

                return Row(
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final NumberFormat currencyFmt;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.currencyFmt,
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
            Text(
              '${currencyFmt.format(amount)} FCFA',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  final NumberFormat currencyFmt;

  const _MonthlyChart({required this.monthly, required this.currencyFmt});

  static const _monthNames = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  @override
  Widget build(BuildContext context) {
    // Find max value for scaling
    double maxVal = 0;
    for (final m in monthly) {
      final inc = (m['income'] as num).toDouble();
      final exp = (m['expense'] as num).toDouble();
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    if (maxVal == 0) maxVal = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Legend
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _LegendDot(color: AppColors.success, label: 'Entrées'),
              const SizedBox(width: 24),
              _LegendDot(color: Colors.red, label: 'Sorties'),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (i) {
                  final inc = (monthly[i]['income'] as num).toDouble();
                  final exp = (monthly[i]['expense'] as num).toDouble();
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
                                width: 8,
                                height: incH.clamp(2, 140),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 8,
                                height: expH.clamp(2, 140),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_monthNames[i],
                              style: const TextStyle(fontSize: 10)),
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
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
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
    final total =
        items.fold<double>(0, (s, i) => s + (i['total'] as num).toDouble());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            if (items.isEmpty)
              const Text('Aucune donnée', style: TextStyle(color: Colors.grey))
            else
              ...items.map((item) {
                final amt = (item['total'] as num).toDouble();
                final pct = total > 0 ? (amt / total) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(item['category'] as String,
                                style: const TextStyle(fontSize: 13))),
                        Text('${currencyFmt.format(amt)} F',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: color,
                                fontSize: 13)),
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey[200],
                        color: color,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
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
