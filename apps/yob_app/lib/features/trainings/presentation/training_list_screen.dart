import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/training_provider.dart';

class TrainingListScreen extends ConsumerStatefulWidget {
  const TrainingListScreen({super.key});

  @override
  ConsumerState<TrainingListScreen> createState() => _TrainingListScreenState();
}

class _TrainingListScreenState extends ConsumerState<TrainingListScreen> {
  final _searchCtrl = TextEditingController();
  bool? _certFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingListProvider);
    final notifier = ref.read(trainingListProvider.notifier);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(children: [
              Text('Formations',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/trainings/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvelle formation'),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              notifier.search('');
                            })
                        : null,
                    isDense: true,
                  ),
                  onChanged: notifier.search,
                ),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Toutes'),
                selected: _certFilter == null,
                onSelected: (_) =>
                    setState(() => _certFilter = null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Certifiée'),
                selected: _certFilter == true,
                onSelected: (_) =>
                    setState(() => _certFilter = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Non certifiée'),
                selected: _certFilter == false,
                onSelected: (_) =>
                    setState(() => _certFilter = false),
              ),
            ]),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Erreur: ${state.error}'))
                    : _buildList(state, notifier, dateFmt),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      TrainingListState state, TrainingListNotifier notifier, DateFormat fmt) {
    var items = state.trainings;
    if (_certFilter != null) {
      items = items
          .where((t) => t.certificationIssued == _certFilter)
          .toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucune formation',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: items.length + (state.page < state.totalPages ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            notifier.loadMore();
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          final t = items[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => context.go('/trainings/${t.id}'),
              leading: CircleAvatar(
                backgroundColor: t.certificationIssued
                    ? AppColors.success.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                child: Icon(
                  t.certificationIssued ? Icons.verified : Icons.school,
                  color:
                      t.certificationIssued ? AppColors.success : Colors.orange,
                ),
              ),
              title: Text(t.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${fmt.format(t.date)}  •  ${t.location}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('${t.attendeeCount} participant(s)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') context.go('/trainings/${t.id}/edit');
                  if (v == 'delete') {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Supprimer'),
                        content: Text('Supprimer "${t.title}" ?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler')),
                          FilledButton(
                              onPressed: () {
                                notifier.deleteTraining(t.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Supprimer')),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
