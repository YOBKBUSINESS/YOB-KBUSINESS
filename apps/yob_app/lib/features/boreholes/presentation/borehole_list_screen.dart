import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/borehole_provider.dart';

class BoreholeListScreen extends ConsumerStatefulWidget {
  const BoreholeListScreen({super.key});

  @override
  ConsumerState<BoreholeListScreen> createState() => _BoreholeListScreenState();
}

class _BoreholeListScreenState extends ConsumerState<BoreholeListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boreholeListProvider);
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
                        Text('Forages',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${state.total} forage${state.total > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/boreholes/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onSubmitted: (v) =>
                          ref.read(boreholeListProvider.notifier).search(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusFilter(
                    current: state.statusFilter,
                    onChanged: (v) =>
                        ref.read(boreholeListProvider.notifier).filterByStatus(v),
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
                    : state.boreholes.isEmpty
                        ? const Center(child: Text('Aucun forage'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: state.boreholes.length,
                            itemBuilder: (context, index) {
                              final b = state.boreholes[index];
                              return _BoreholeCard(
                                borehole: b,
                                currencyFmt: currencyFmt,
                                onTap: () => context.go('/boreholes/${b.id}'),
                                onDelete: () => _confirmDelete(b),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Borehole b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce forage ?'),
        content: Text('"${b.name}"'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(boreholeListProvider.notifier).deleteBorehole(b.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _BoreholeCard extends StatelessWidget {
  final Borehole borehole;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BoreholeCard({
    required this.borehole,
    required this.currencyFmt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (borehole.status) {
      ProjectStatus.completed => AppColors.success,
      ProjectStatus.inProgress => AppColors.info,
      ProjectStatus.planned => AppColors.warning,
      ProjectStatus.onHold => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.water_drop, color: AppColors.info, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(borehole.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    borehole.status.label,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      context.go('/boreholes/${borehole.id}/edit');
                    }
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ]),
              const SizedBox(height: 10),
              // Progress bar
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: borehole.progressPercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${borehole.progressPercent}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(
                '${borehole.location} · ${borehole.contractor} · ${currencyFmt.format(borehole.cost)} FCFA',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _StatusFilter({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: current,
      onSelected: onChanged,
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(current != null
            ? ProjectStatus.values
                .firstWhere((e) => e.name == current,
                    orElse: () => ProjectStatus.planned)
                .label
            : 'Tous'),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Tous')),
        ...ProjectStatus.values
            .map((s) => PopupMenuItem(value: s.name, child: Text(s.label))),
      ],
    );
  }
}
