import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/parcel_provider.dart';

class ParcelListScreen extends ConsumerStatefulWidget {
  const ParcelListScreen({super.key});

  @override
  ConsumerState<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends ConsumerState<ParcelListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parcelListProvider);

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
                        Text(
                          'Parcelles',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.total} parcelle${state.total > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/parcels/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une parcelle...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (v) =>
                      ref.read(parcelListProvider.notifier).search(v),
                ),
              ],
            ),
          ),
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
                                  .read(parcelListProvider.notifier)
                                  .loadParcels(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : state.parcels.isEmpty
                        ? const Center(child: Text('Aucune parcelle trouvée'))
                        : _buildGrid(state),
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
                          ? () => ref
                              .read(parcelListProvider.notifier)
                              .previousPage()
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: state.page < state.totalPages
                          ? () =>
                              ref.read(parcelListProvider.notifier).nextPage()
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

  Widget _buildGrid(ParcelListState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: state.parcels.length,
          itemBuilder: (context, idx) {
            final p = state.parcels[idx];
            return _ParcelCard(
              parcel: p,
              onTap: () => context.go('/parcels/${p.id}'),
              onDelete: () => _confirmDelete(p),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Parcel parcel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer la parcelle "${parcel.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(parcelListProvider.notifier).deleteParcel(parcel.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ParcelCard extends StatelessWidget {
  final Parcel parcel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ParcelCard({
    required this.parcel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tenureColor = switch (parcel.tenureStatus) {
      LandTenureStatus.secured => AppColors.success,
      LandTenureStatus.pending => AppColors.warning,
      LandTenureStatus.disputed => AppColors.error,
      LandTenureStatus.unknown => Colors.grey,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.map, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parcel.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') context.go('/parcels/${parcel.id}/edit');
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Modifier')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${parcel.surfaceArea} ha · ${parcel.cropType}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tenureColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      parcel.tenureStatus.label,
                      style: TextStyle(
                          color: tenureColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (parcel.commodeSurveyDone) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text('Bornage',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600])),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
