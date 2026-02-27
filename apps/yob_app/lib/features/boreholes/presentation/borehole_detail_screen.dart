import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/borehole_provider.dart';

class BoreholeDetailScreen extends ConsumerWidget {
  final String boreholeId;
  const BoreholeDetailScreen({super.key, required this.boreholeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(boreholeDetailProvider(boreholeId));
    final currencyFmt = NumberFormat('#,###', 'fr');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (borehole) {
        if (borehole == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.water_drop_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Forage non trouvé'),
                const SizedBox(height: 16),
                OutlinedButton(
                    onPressed: () => context.go('/boreholes'),
                    child: const Text('Retour')),
              ]),
            ),
          );
        }

        final statusColor = switch (borehole.status) {
          ProjectStatus.completed => AppColors.success,
          ProjectStatus.inProgress => AppColors.info,
          ProjectStatus.planned => AppColors.warning,
          ProjectStatus.onHold => Colors.grey,
        };

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/boreholes')),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/boreholes/${borehole.id}/edit'),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(borehole.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Progress
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(children: [
                        Text('Avancement',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${borehole.progressPercent}%',
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: borehole.progressPercent / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        _InfoRow('Localisation', borehole.location),
                        _InfoRow('Prestataire', borehole.contractor),
                        _InfoRow('Coût',
                            '${currencyFmt.format(borehole.cost)} FCFA'),
                        _InfoRow('Statut', borehole.status.label),
                        _InfoRow('Début',
                            dateFmt.format(borehole.startDate)),
                        if (borehole.endDate != null)
                          _InfoRow(
                              'Fin', dateFmt.format(borehole.endDate!)),
                        if (borehole.maintenanceNotes != null)
                          _InfoRow(
                              'Notes maintenance', borehole.maintenanceNotes!),
                        if (borehole.lastMaintenanceDate != null)
                          _InfoRow('Dernière maintenance',
                              dateFmt.format(borehole.lastMaintenanceDate!)),
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 160,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14))),
        Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
      ]),
    );
  }
}
