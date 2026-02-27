import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/producer_provider.dart';

class ProducerListScreen extends ConsumerStatefulWidget {
  const ProducerListScreen({super.key});

  @override
  ConsumerState<ProducerListScreen> createState() => _ProducerListScreenState();
}

class _ProducerListScreenState extends ConsumerState<ProducerListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(producerListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Producteurs',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.total} producteur${state.total > 1 ? 's' : ''} enregistré${state.total > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/producers/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search & filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un producteur...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onSubmitted: (v) =>
                            ref.read(producerListProvider.notifier).search(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusFilterChip(
                      currentFilter: state.statusFilter,
                      onChanged: (v) => ref
                          .read(producerListProvider.notifier)
                          .filterByStatus(v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red[300]),
                            const SizedBox(height: 8),
                            Text(state.error!),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => ref
                                  .read(producerListProvider.notifier)
                                  .loadProducers(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : state.producers.isEmpty
                        ? const Center(
                            child: Text('Aucun producteur trouvé'))
                        : _buildList(state),
          ),
          // Pagination
          if (state.totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${state.page} / ${state.totalPages}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: state.page > 1
                            ? () => ref
                                .read(producerListProvider.notifier)
                                .previousPage()
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: state.page < state.totalPages
                            ? () => ref
                                .read(producerListProvider.notifier)
                                .nextPage()
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(ProducerListState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: state.producers.length,
      itemBuilder: (context, index) {
        final p = state.producers[index];
        return _ProducerCard(
          producer: p,
          onTap: () => context.go('/producers/${p.id}'),
          onDelete: () => _confirmDelete(p),
        );
      },
    );
  }

  void _confirmDelete(Producer producer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content:
            Text('Supprimer le producteur "${producer.fullName}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref
                  .read(producerListProvider.notifier)
                  .deleteProducer(producer.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ProducerCard extends StatelessWidget {
  final Producer producer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProducerCard({
    required this.producer,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: Text(
            producer.fullName.isNotEmpty
                ? producer.fullName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          producer.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${producer.locality} · ${producer.cultivatedArea} ha',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(status: producer.status),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  context.go('/producers/${producer.id}/edit');
                } else if (v == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('Modifier')),
                const PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('Supprimer', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProducerStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProducerStatus.actif => AppColors.success,
      ProducerStatus.enFormation => AppColors.warning,
      ProducerStatus.suspendu => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String? currentFilter;
  final ValueChanged<String?> onChanged;

  const _StatusFilterChip({
    required this.currentFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: currentFilter,
      onSelected: onChanged,
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(currentFilter != null
            ? ProducerStatus.values
                .firstWhere(
                  (e) => e.name == currentFilter,
                  orElse: () => ProducerStatus.actif,
                )
                .label
            : 'Tous'),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Tous')),
        ...ProducerStatus.values.map(
          (s) => PopupMenuItem(value: s.name, child: Text(s.label)),
        ),
      ],
    );
  }
}
