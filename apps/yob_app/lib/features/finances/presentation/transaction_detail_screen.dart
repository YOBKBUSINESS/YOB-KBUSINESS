import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../data/finance_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionDetailProvider(transactionId));
    final currencyFmt = NumberFormat('#,###', 'fr');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (tx) {
        if (tx == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Transaction non trouvée'),
                const SizedBox(height: 16),
                OutlinedButton(
                    onPressed: () => context.go('/finances'),
                    child: const Text('Retour')),
              ]),
            ),
          );
        }

        final isIncome = tx.type == TransactionType.income;

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
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .go('/finances/transactions/${tx.id}/edit'),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ]),
                const SizedBox(height: 16),

                // Amount card
                Card(
                  color: isIncome
                      ? Colors.green.withValues(alpha: 0.05)
                      : Colors.red.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isIncome
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${isIncome ? "+" : "-"} ${currencyFmt.format(tx.amount)} FCFA',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isIncome ? 'Entrée' : 'Sortie',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Détails',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        _InfoRow('Description', tx.description),
                        _InfoRow('Catégorie', tx.category ?? '—'),
                        _InfoRow('Date', dateFmt.format(tx.date)),
                        _InfoRow('Créé le',
                            dateFmt.format(tx.createdAt)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14))),
      ]),
    );
  }
}
