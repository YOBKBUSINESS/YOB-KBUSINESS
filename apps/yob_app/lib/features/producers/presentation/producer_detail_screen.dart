import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/producer_provider.dart';

class ProducerDetailScreen extends ConsumerWidget {
  final String producerId;
  const ProducerDetailScreen({super.key, required this.producerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducer = ref.watch(producerDetailProvider(producerId));
    final dateFmt = DateFormat('dd/MM/yyyy', 'fr');

    return asyncProducer.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (producer) {
        if (producer == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Producteur non trouvé'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go('/producers'),
                    child: const Text('Retour à la liste'),
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
                // Back + actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/producers'),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/producers/${producer.id}/edit'),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Profile header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.2),
                      child: Text(
                        producer.fullName.isNotEmpty
                            ? producer.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producer.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            producer.locality,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(producer.status),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats cards
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _StatCard(
                      icon: Icons.landscape,
                      label: 'Surface cultivée',
                      value: '${producer.cultivatedArea} ha',
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      icon: Icons.trending_up,
                      label: 'Production',
                      value: producer.productionLevel != null
                          ? '${producer.productionLevel} t'
                          : 'N/A',
                      color: AppColors.info,
                    ),
                    _StatCard(
                      icon: Icons.payments,
                      label: 'Contributions',
                      value:
                          '${NumberFormat('#,###').format(producer.totalContributions)} F',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info grid
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _InfoRow('Téléphone', producer.phone ?? 'Non renseigné'),
                        _InfoRow('Statut', producer.status.label),
                        _InfoRow(
                          'Inscrit le',
                          dateFmt.format(producer.createdAt),
                        ),
                        if (producer.cropHistory.isNotEmpty)
                          _InfoRow(
                            'Historique cultures',
                            producer.cropHistory.join(', '),
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

  Widget _statusBadge(ProducerStatus status) {
    final color = switch (status) {
      ProducerStatus.actif => AppColors.success,
      ProducerStatus.enFormation => AppColors.warning,
      ProducerStatus.suspendu => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
