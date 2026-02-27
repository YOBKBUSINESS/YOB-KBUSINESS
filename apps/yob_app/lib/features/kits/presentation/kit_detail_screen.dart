import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/kit_provider.dart';

class KitDetailScreen extends ConsumerWidget {
  final String kitId;
  const KitDetailScreen({super.key, required this.kitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kitDetailProvider(kitId));
    final currencyFmt = NumberFormat('#,###', 'fr');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (kit) {
        if (kit == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Kit non trouvé'),
                const SizedBox(height: 16),
                OutlinedButton(
                    onPressed: () => context.go('/kits'),
                    child: const Text('Retour')),
              ]),
            ),
          );
        }

        final statusColor = switch (kit.status) {
          KitStatus.rembourse => AppColors.success,
          KitStatus.subventionne => AppColors.info,
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
                      onPressed: () => context.go('/kits')),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/kits/${kit.id}/edit'),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Icon(Icons.inventory_2, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kit.kitType,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(kit.status.label,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ]),
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
                        _InfoRow('Bénéficiaire',
                            kit.beneficiaryName ?? kit.beneficiaryId),
                        _InfoRow('Distribution',
                            dateFmt.format(kit.distributionDate)),
                        _InfoRow('Valeur',
                            '${currencyFmt.format(kit.value)} FCFA'),
                        _InfoRow('Statut', kit.status.label),
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
