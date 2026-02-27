import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/investor_provider.dart';

class InvestorListScreen extends ConsumerStatefulWidget {
  const InvestorListScreen({super.key});

  @override
  ConsumerState<InvestorListScreen> createState() => _InvestorListScreenState();
}

class _InvestorListScreenState extends ConsumerState<InvestorListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(investorListProvider);
    final notifier = ref.read(investorListProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investisseurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/investors/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Portfolio summary banner
          _buildPortfolioBanner(),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un investisseur...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: notifier.search,
            ),
          ),
          // List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.error!,
                                style: TextStyle(color: theme.colorScheme.error)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                                onPressed: notifier.refresh,
                                child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : state.investors.isEmpty
                        ? const Center(
                            child: Text('Aucun investisseur trouvé'))
                        : RefreshIndicator(
                            onRefresh: notifier.refresh,
                            child: ListView.builder(
                              itemCount: state.investors.length,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemBuilder: (ctx, i) {
                                final inv = state.investors[i];
                                return _InvestorCard(investor: inv);
                              },
                            ),
                          ),
          ),
          // Pagination
          if (state.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: state.page > 1 ? notifier.previousPage : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Précédent'),
                  ),
                  Text('${state.page} / ${state.totalPages}',
                      style: theme.textTheme.bodyMedium),
                  TextButton.icon(
                    onPressed: state.page < state.totalPages
                        ? notifier.nextPage
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Suivant'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioBanner() {
    final portfolio = ref.watch(portfolioSummaryProvider);
    return portfolio.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final totalInvested = (data['totalInvested'] as num?)?.toDouble() ?? 0;
        final count = data['investorCount'] as int? ?? 0;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count investisseur${count > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFcfa(totalInvested),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Total investi',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFcfa(double amount) {
    final formatted =
        amount.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            );
    return '$formatted FCFA';
  }
}

/// Single investor card in the list.
class _InvestorCard extends StatelessWidget {
  final dynamic investor;
  const _InvestorCard({required this.investor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invested = (investor.totalInvested as num?)?.toDouble() ?? 0;
    final formatted = invested
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            investor.fullName.isNotEmpty
                ? investor.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(investor.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (investor.company != null && investor.company!.isNotEmpty)
              Text(investor.company!,
                  style: TextStyle(color: theme.hintColor, fontSize: 12)),
            Text('$formatted FCFA',
                style: TextStyle(
                    color: Colors.indigo.shade600,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: investor.expectedReturn != null
            ? Chip(
                label: Text('${investor.expectedReturn}%'),
                backgroundColor: Colors.green.shade50,
                labelStyle: TextStyle(
                    color: Colors.green.shade700, fontSize: 12),
              )
            : null,
        onTap: () => context.go('/investors/${investor.id}'),
      ),
    );
  }
}
