import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/finance_provider.dart';

/// Monthly financial report screen — auto-generated summary.
class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late int _year;
  late int _month;

  static const _monthNames = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(
        monthlyReportProvider((year: _year, month: _month)));
    final currencyFmt = NumberFormat('#,###', 'fr');
    final dateFmt = DateFormat('dd/MM/yyyy');

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
                  onPressed: () => context.go('/finances/dashboard')),
              const SizedBox(width: 8),
              Text('Rapport mensuel',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
            ]),
            const SizedBox(height: 16),

            // Month/Year selector
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_monthNames[_month - 1]} $_year',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Report content
            reportAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (report) {
                final income =
                    (report['income'] as num?)?.toDouble() ?? 0;
                final expense =
                    (report['expense'] as num?)?.toDouble() ?? 0;
                final net = (report['net'] as num?)?.toDouble() ?? 0;
                final txCount = report['transactionCount'] as int? ?? 0;
                final categories =
                    (report['categoryBreakdown'] as List<dynamic>?) ?? [];
                final topTx =
                    (report['topTransactions'] as List<dynamic>?) ?? [];
                final treasury =
                    report['treasury'] as Map<String, dynamic>? ?? {};
                final treasuryBalance =
                    (treasury['balance'] as num?)?.toDouble() ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    Row(children: [
                      Expanded(
                        child: _ReportCard(
                          title: 'Entrées',
                          value: '${currencyFmt.format(income)} F',
                          icon: Icons.arrow_downward,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: 'Sorties',
                          value: '${currencyFmt.format(expense)} F',
                          icon: Icons.arrow_upward,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: 'Résultat net',
                          value: '${currencyFmt.format(net)} F',
                          icon: net >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: net >= 0 ? AppColors.success : Colors.red,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _ReportCard(
                          title: 'Transactions',
                          value: txCount.toString(),
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: 'Solde trésorerie',
                          value: '${currencyFmt.format(treasuryBalance)} F',
                          icon: Icons.account_balance,
                          color: treasuryBalance >= 0
                              ? AppColors.success
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ]),
                    const SizedBox(height: 24),

                    // Category breakdown
                    if (categories.isNotEmpty) ...[
                      Text('Répartition par catégorie',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: categories.map((item) {
                              final map =
                                  item as Map<String, dynamic>;
                              final type = map['type'] as String?;
                              final cat = map['category'] as String? ??
                                  'Autre';
                              final total =
                                  (map['total'] as num?)?.toDouble() ??
                                      0;
                              final isInc = type == 'income';
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isInc
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 18,
                                  color: isInc
                                      ? AppColors.success
                                      : Colors.red,
                                ),
                                title: Text(cat,
                                    style: const TextStyle(fontSize: 14)),
                                trailing: Text(
                                  '${currencyFmt.format(total)} F',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isInc
                                        ? AppColors.success
                                        : Colors.red,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Top transactions
                    if (topTx.isNotEmpty) ...[
                      Text('Transactions principales',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: topTx.map((item) {
                              final map =
                                  item as Map<String, dynamic>;
                              final desc =
                                  map['description'] as String? ?? '';
                              final amount =
                                  (map['amount'] as num?)?.toDouble() ??
                                      0;
                              final type = map['type'] as String?;
                              final dateStr = map['date'] as String?;
                              final isInc = type == 'income';
                              DateTime? txDate;
                              if (dateStr != null) {
                                txDate = DateTime.tryParse(dateStr);
                              }
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isInc
                                      ? AppColors.success
                                          .withValues(alpha: 0.15)
                                      : Colors.red
                                          .withValues(alpha: 0.15),
                                  child: Icon(
                                    isInc
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    size: 14,
                                    color: isInc
                                        ? AppColors.success
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(desc,
                                    style:
                                        const TextStyle(fontSize: 13)),
                                subtitle: txDate != null
                                    ? Text(dateFmt.format(txDate),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500]))
                                    : null,
                                trailing: Text(
                                  '${currencyFmt.format(amount)} F',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isInc
                                        ? AppColors.success
                                        : Colors.red,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    if (txCount == 0)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune transaction pour ${_monthNames[_month - 1]} $_year',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
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

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) {
        _month = 1;
        _year++;
      } else if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(title,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
