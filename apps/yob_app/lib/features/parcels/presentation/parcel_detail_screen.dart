import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/parcel_provider.dart';

class ParcelDetailScreen extends ConsumerWidget {
  final String parcelId;
  const ParcelDetailScreen({super.key, required this.parcelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncParcel = ref.watch(parcelDetailProvider(parcelId));

    return asyncParcel.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (parcel) {
        if (parcel == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Parcelle non trouvée'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go('/parcels'),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/parcels'),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/parcels/${parcel.id}/edit'),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  parcel.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _InfoChip(Icons.landscape, '${parcel.surfaceArea} ha'),
                    _InfoChip(Icons.agriculture, parcel.cropType),
                    _InfoChip(Icons.gps_fixed,
                        '${parcel.latitude.toStringAsFixed(4)}, ${parcel.longitude.toStringAsFixed(4)}'),
                  ],
                ),
                const SizedBox(height: 24),
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
                        _InfoRow('Statut foncier', parcel.tenureStatus.label),
                        _InfoRow(
                          'Bornage effectué',
                          parcel.commodeSurveyDone ? 'Oui' : 'Non',
                        ),
                        _InfoRow(
                          'Producteur',
                          parcel.producerId ?? 'Non assigné',
                        ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
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
      child: Row(
        children: [
          SizedBox(
              width: 160,
              child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14))),
        ],
      ),
    );
  }
}
