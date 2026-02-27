import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/finance_provider.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late int _year;
  late int _month;
  final _currencyFmt = NumberFormat('#,###', 'fr');
  final _dateFmt = DateFormat('dd/MM/yyyy');

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

  void _prev() {
    setState(() {
      _month--;
      if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
  }

  void _next() {
    setState(() {
      _month++;
      if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync =
        ref.watch(monthlyReportProvider((year: _year, month: _month)));

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
            ]),
            const SizedBox(height: 16),

            // Month selector
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _prev),
                    const SizedBox(width: 12),
                    Text(
                      '${_monthNames[_month - 1]} $_year',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _next),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report body
            reportAsync.when(
              loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (report) => _buildReport(context, report),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(BuildContext context, Map<String, dynamic> report) {
    final income = (report['income'] as num).toDouble();
    final expense = (report['expense'] as num).toDouble();
    final net = (report['net'] as num).toDouble();
    final txCount = report['transactionCount'] as int;
    final categories =
        (report['categoryBreakdown'] as List<dynamic>).cast<Map<String, dynamic>>();
    final topTx =
        (report['topTransactions'] as List<dynamic>).cast<Map<String, dynamic>>();
    final treasury = report['treasury'] as Map<String, dynamic>;
    final balance = (treasury['balance'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(children: [
          Expanded(
              child: _statCard('Entrées', income, AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Sorties', expense, Colors.red)),
          const SizedBox(width: 12),
          Expanded(
              child: _statCard(
                  'Résultat net',
                  net,
                  net >= 0 ? AppColors.success : Colors.red)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text('$txCount',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('transactions',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              color: balance < 0
                  ? Colors.red.withValues(alpha: 0.05)
                  : AppColors.success.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text('${_currencyFmt.format(balance)} F',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: balance < 0 ? Colors.red : AppColors.success,
                      )),
                  Text('trésorerie globale',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ]),
              ),
            ),
          ),
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
                children: categories.map((cat) {
                  final type = cat['type'] as String;
                  final isIncome = type == 'income';
                  final color = isIncome ? AppColors.success : Colors.red;
                  final total = (cat['total'] as num).toDouble();

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 18,
                    ),
                    title: Text(cat['category'] as String,
                        style: const TextStyle(fontSize: 14)),
                    trailing: Text(
                      '${_currencyFmt.format(total)} F',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
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
          Text('Principales transactions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: topTx.map((tx) {
                  final isIncome = tx['type'] == 'income';
                  final color = isIncome ? AppColors.success : Colors.red;
                  final amount = (tx['amount'] as num).toDouble();
                  final dateStr = tx['date'] as String?;
                  final date = dateStr != null
                      ? DateTime.tryParse(dateStr)
                      : null;

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 14,
                        color: color,
                      ),
                    ),
                    title: Text(tx['description'] as String? ?? '',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: date != null
                        ? Text(_dateFmt.format(date),
                            style: const TextStyle(fontSize: 11))
                        : null,
                    trailing: Text(
                      '${_currencyFmt.format(amount)} F',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statCard(String label, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_currencyFmt.format(amount)} F',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
