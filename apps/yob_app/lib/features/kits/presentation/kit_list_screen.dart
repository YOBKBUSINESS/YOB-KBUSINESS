import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/kit_provider.dart';

class KitListScreen extends ConsumerStatefulWidget {
  const KitListScreen({super.key});

  @override
  ConsumerState<KitListScreen> createState() => _KitListScreenState();
}

class _KitListScreenState extends ConsumerState<KitListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitListProvider);
    final currencyFmt = NumberFormat('#,###', 'fr');

    return Scaffold(
      body: Column(
        children: [
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
                        Text('Kits Agricoles',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${state.total} kit${state.total > 1 ? 's' : ''} distribué${state.total > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/kits/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Distribuer'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un kit...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onSubmitted: (v) =>
                          ref.read(kitListProvider.notifier).search(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _KitStatusFilter(
                    current: state.statusFilter,
                    onChanged: (v) =>
                        ref.read(kitListProvider.notifier).filterByStatus(v),
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : state.kits.isEmpty
                        ? const Center(child: Text('Aucun kit distribué'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: state.kits.length,
                            itemBuilder: (context, idx) {
                              final k = state.kits[idx];
                              return _KitCard(
                                kit: k,
                                currencyFmt: currencyFmt,
                                onTap: () => context.go('/kits/${k.id}'),
                                onDelete: () => _confirmDelete(k),
                              );
                            },
                          ),
          ),
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
                  Text('Page ${state.page} / ${state.totalPages}',
                      style: TextStyle(color: Colors.grey[600])),
                  Row(children: [
                    IconButton(
                      onPressed: state.page > 1
                          ? () =>
                              ref.read(kitListProvider.notifier).previousPage()
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: state.page < state.totalPages
                          ? () =>
                              ref.read(kitListProvider.notifier).nextPage()
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(AgriculturalKit kit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce kit ?'),
        content: Text('"${kit.kitType}" — ${kit.beneficiaryName ?? kit.beneficiaryId}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(kitListProvider.notifier).deleteKit(kit.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _KitCard extends StatelessWidget {
  final AgriculturalKit kit;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _KitCard({
    required this.kit,
    required this.currencyFmt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (kit.status) {
      KitStatus.rembourse => AppColors.success,
      KitStatus.subventionne => AppColors.info,
    };
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.inventory_2, color: statusColor, size: 22),
        ),
        title: Text(kit.kitType,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${kit.beneficiaryName ?? 'N/A'} · ${dateFmt.format(kit.distributionDate)} · ${currencyFmt.format(kit.value)} F',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(kit.status.label,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') context.go('/kits/${kit.id}/edit');
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
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

class _KitStatusFilter extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _KitStatusFilter({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: current,
      onSelected: onChanged,
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(current != null
            ? KitStatus.values
                .firstWhere((e) => e.name == current,
                    orElse: () => KitStatus.subventionne)
                .label
            : 'Tous'),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Tous')),
        ...KitStatus.values
            .map((s) => PopupMenuItem(value: s.name, child: Text(s.label))),
      ],
    );
  }
}
