import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/services/export_helper.dart';
import '../../../core/services/pdf_export_service.dart';
import '../data/finance_provider.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  final _searchCtrl = TextEditingController();
  String? _typeFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _exportTransactions(
    BuildContext context,
    TransactionListState state,
  ) {
    final txMaps = state.transactions
        .map((t) => t.toJson())
        .toList();

    ExportHelper.showExportDialog(
      context: context,
      title: 'Transactions',
      fileBaseName: 'transactions_yob',
      onPdf: () {
        final headers = [
          'Date', 'Type', 'Catégorie', 'Description', 'Montant (FCFA)',
        ];
        final rows = txMaps.map((t) {
          return [
            t['date']?.toString() ?? '',
            t['type'] == 'income' ? 'Revenu' : 'Dépense',
            t['category']?.toString() ?? '',
            t['description']?.toString() ?? '',
            '${t['amount'] ?? 0}',
          ];
        }).toList();
        return PdfExportService.generateTablePdf(
          title: 'Liste des Transactions',
          subtitle: '${state.total} transaction(s)',
          headers: headers,
          rows: rows,
        );
      },
      onCsv: () async {
        final csv = CsvExportService.exportTransactions(txMaps);
        return CsvExportService.csvToBytes(csv);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final notifier = ref.read(transactionListProvider.notifier);
    final currencyFmt = NumberFormat('#,###', 'fr');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(children: [
              Text('Transactions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => _exportTransactions(context, state),
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Exporter',
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: () => context.go('/finances/dashboard'),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('Tableau de bord'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => context.go('/finances/transactions/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvelle transaction'),
              ),
            ]),
          ),

          // Search + Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              notifier.search('');
                            })
                        : null,
                    isDense: true,
                  ),
                  onChanged: notifier.search,
                ),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Toutes'),
                selected: _typeFilter == null,
                onSelected: (_) {
                  setState(() => _typeFilter = null);
                  notifier.filterByType(null);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: _typeFilter == 'income'
                    ? null
                    : Icon(Icons.arrow_downward,
                        size: 14, color: Colors.green[700]),
                label: const Text('Entrées'),
                selected: _typeFilter == 'income',
                onSelected: (_) {
                  setState(() => _typeFilter = 'income');
                  notifier.filterByType('income');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: _typeFilter == 'expense'
                    ? null
                    : Icon(Icons.arrow_upward,
                        size: 14, color: Colors.red[700]),
                label: const Text('Sorties'),
                selected: _typeFilter == 'expense',
                onSelected: (_) {
                  setState(() => _typeFilter = 'expense');
                  notifier.filterByType('expense');
                },
              ),
            ]),
          ),

          // Treasury banner
          _TreasuryBanner(currencyFmt: currencyFmt),

          // Transaction List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Erreur: ${state.error}'))
                    : state.transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('Aucune transaction',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => notifier.refresh(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              itemCount: state.transactions.length,
                              itemBuilder: (context, i) {
                                final tx = state.transactions[i];
                                final isIncome =
                                    tx.type == TransactionType.income;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () => context.go(
                                        '/finances/transactions/${tx.id}'),
                                    leading: CircleAvatar(
                                      backgroundColor: isIncome
                                          ? AppColors.success
                                              .withValues(alpha: 0.15)
                                          : Colors.red
                                              .withValues(alpha: 0.15),
                                      child: Icon(
                                        isIncome
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isIncome
                                            ? AppColors.success
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(tx.description,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '${dateFmt.format(tx.date)}  •  ${tx.category ?? "—"}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '${isIncome ? "+" : "-"} ${currencyFmt.format(tx.amount)} F',
                                      style: TextStyle(
                                        color: isIncome
                                            ? AppColors.success
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),

          // Pagination
          if (state.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        state.page > 1 ? () => notifier.previousPage() : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page ${state.page} / ${state.totalPages}'),
                  IconButton(
                    onPressed: state.page < state.totalPages
                        ? () => notifier.nextPage()
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Small banner showing current treasury balance.
class _TreasuryBanner extends ConsumerWidget {
  final NumberFormat currencyFmt;
  const _TreasuryBanner({required this.currencyFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(defaultTreasuryProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final balance = (data['balance'] as num?)?.toDouble() ?? 0;
        final isLow = data['isLow'] == true;
        final alertLevel = data['alertLevel'] as String? ?? 'ok';
        final color = alertLevel == 'critical'
            ? Colors.red
            : alertLevel == 'warning'
                ? Colors.orange
                : AppColors.success;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(
              isLow ? Icons.warning_amber_rounded : Icons.account_balance,
              color: color,
            ),
            const SizedBox(width: 12),
            Text('Trésorerie: ',
                style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            Text(
              '${currencyFmt.format(balance)} FCFA',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (isLow) ...[
              const Spacer(),
              Text('Fonds bas !',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ]),
        );
      },
    );
  }
}
