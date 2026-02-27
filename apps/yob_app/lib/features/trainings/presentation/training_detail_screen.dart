import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/training_provider.dart';

class TrainingDetailScreen extends ConsumerWidget {
  final String trainingId;
  const TrainingDetailScreen({super.key, required this.trainingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trainingDetailProvider(trainingId));
    final dateFmt = DateFormat('dd/MM/yyyy');

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (training) {
        if (training == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Formation non trouvée'),
                const SizedBox(height: 16),
                OutlinedButton(
                    onPressed: () => context.go('/trainings'),
                    child: const Text('Retour')),
              ]),
            ),
          );
        }

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
                      onPressed: () => context.go('/trainings')),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/trainings/${training.id}/edit'),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ]),
                const SizedBox(height: 16),

                // Title + certification badge
                Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: training.certificationIssued
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    child: Icon(
                      training.certificationIssued
                          ? Icons.verified
                          : Icons.school,
                      color: training.certificationIssued
                          ? AppColors.success
                          : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(training.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          training.certificationIssued
                              ? 'Certification délivrée'
                              : 'Sans certification',
                          style: TextStyle(
                            color: training.certificationIssued
                                ? AppColors.success
                                : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Info chips
                Wrap(spacing: 12, runSpacing: 8, children: [
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dateFmt.format(training.date)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.location_on, size: 16),
                    label: Text(training.location),
                  ),
                  Chip(
                    avatar: const Icon(Icons.people, size: 16),
                    label: Text('${training.attendeeCount} participant(s)'),
                  ),
                ]),
                const SizedBox(height: 24),

                // Description
                if (training.description != null &&
                    training.description!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24),
                          Text(training.description!,
                              style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Evaluation notes
                if (training.evaluationNotes != null &&
                    training.evaluationNotes!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes d\'évaluation',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24),
                          Text(training.evaluationNotes!,
                              style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Attendees list
                if (training.attendeeIds.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Participants (${training.attendeeIds.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24),
                          ...training.attendeeIds.map((id) => ListTile(
                                leading: const CircleAvatar(
                                    child: Icon(Icons.person, size: 20)),
                                title: Text(id,
                                    style: const TextStyle(fontSize: 14)),
                                dense: true,
                              )),
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
