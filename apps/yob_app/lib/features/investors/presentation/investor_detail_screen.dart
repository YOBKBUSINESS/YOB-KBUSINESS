import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/investor_provider.dart';

class InvestorDetailScreen extends ConsumerWidget {
  final String investorId;
  const InvestorDetailScreen({super.key, required this.investorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investorAsync = ref.watch(investorDetailProvider(investorId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail Investisseur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/investors'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/investors/$investorId/edit'),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: theme.colorScheme.error),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: investorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (investor) {
          if (investor == null) {
            return const Center(child: Text('Investisseur introuvable'));
          }
          return _buildContent(context, investor);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic investor) {
    final invested = (investor.totalInvested as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          _buildProfileCard(context, investor, invested),
          const SizedBox(height: 16),
          // Investment details
          _buildInfoSection(context, 'Investissement', [
            _infoRow(Icons.monetization_on, 'Montant investi',
                _formatFcfa(invested)),
            if (investor.expectedReturn != null)
              _infoRow(Icons.trending_up, 'Retour attendu',
                  '${investor.expectedReturn}%'),
            if (investor.projectName != null &&
                investor.projectName!.isNotEmpty)
              _infoRow(Icons.business_center, 'Projet', investor.projectName!),
          ]),
          const SizedBox(height: 16),
          // Contact details
          _buildInfoSection(context, 'Contact', [
            if (investor.email != null && investor.email!.isNotEmpty)
              _infoRow(Icons.email, 'Email', investor.email!),
            if (investor.phone != null && investor.phone!.isNotEmpty)
              _infoRow(Icons.phone, 'Téléphone', investor.phone!),
            if (investor.company != null && investor.company!.isNotEmpty)
              _infoRow(Icons.business, 'Entreprise', investor.company!),
          ]),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, dynamic investor, double invested) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo.shade100,
              child: Text(
                investor.fullName.isNotEmpty
                    ? investor.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(investor.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
            if (investor.company != null && investor.company!.isNotEmpty)
              Text(investor.company!,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatFcfa(invested),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFcfa(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return '$formatted FCFA';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet investisseur ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(investorListProvider.notifier)
                  .deleteInvestor(investorId);
              if (context.mounted) context.go('/investors');
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
