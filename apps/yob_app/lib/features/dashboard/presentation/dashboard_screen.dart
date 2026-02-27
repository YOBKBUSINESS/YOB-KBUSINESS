import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardDataProvider);
    final isWide = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (data) => _buildDashboard(context, ref, data, isWide),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(error, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(dashboardDataProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    bool isWide,
  ) {
    final kpis = data['kpis'] as Map<String, dynamic>? ?? {};
    final alerts = (data['alerts'] as List<dynamic>?) ?? [];
    final projects = (data['activeProjects'] as List<dynamic>?) ?? [];
    final modules = data['moduleSummary'] as Map<String, dynamic>? ?? {};
    final activity = (data['recentActivity'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardDataProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tableau de Bord Stratégique',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vue d\'ensemble — YOB K BUSINESS',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                  onPressed: () => ref.invalidate(dashboardDataProvider),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── KPI Cards ──
            _buildKpiGrid(context, kpis, isWide),
            const SizedBox(height: 24),

            // ── Alerts + Quick Actions (side by side on wide) ──
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildAlertsCard(context, alerts),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildQuickActions(context),
                  ),
                ],
              )
            else ...[
              _buildAlertsCard(context, alerts),
              const SizedBox(height: 16),
              _buildQuickActions(context),
            ],
            const SizedBox(height: 24),

            // ── Active Projects ──
            _buildActiveProjects(context, projects),
            const SizedBox(height: 24),

            // ── Module Summary + Recent Activity ──
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildModuleSummary(context, modules),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRecentActivity(context, activity),
                  ),
                ],
              )
            else ...[
              _buildModuleSummary(context, modules),
              const SizedBox(height: 16),
              _buildRecentActivity(context, activity),
            ],
          ],
        ),
      ),
    );
  }

  // ── KPI Grid ──

  Widget _buildKpiGrid(
    BuildContext context,
    Map<String, dynamic> kpis,
    bool isWide,
  ) {
    final cards = [
      _KpiData(
        'Producteurs actifs',
        '${kpis['activeProducers'] ?? 0} / ${kpis['totalProducers'] ?? 0}',
        'enregistrés',
        Icons.people_rounded,
        const Color(0xFF2196F3),
      ),
      _KpiData(
        'Hectares',
        _formatNum(kpis['totalHectares'] ?? 0),
        'exploités',
        Icons.map_rounded,
        AppColors.primaryLight,
      ),
      _KpiData(
        'Production est.',
        '${_formatNum(kpis['estimatedProduction'] ?? 0)} T',
        'tonnes estimées',
        Icons.agriculture_rounded,
        const Color(0xFF8D6E63),
      ),
      _KpiData(
        'Trésorerie',
        _formatFcfa((kpis['availableCash'] as num?)?.toDouble() ?? 0),
        'disponible',
        Icons.account_balance_wallet_rounded,
        (kpis['availableCash'] as num? ?? 0) < 500000
            ? Colors.red
            : AppColors.secondary,
      ),
      _KpiData(
        'Projets actifs',
        '${kpis['activeProjects'] ?? 0}',
        'en cours / planifiés',
        Icons.water_drop_rounded,
        const Color(0xFF9C27B0),
      ),
      _KpiData(
        'Investisseurs',
        '${kpis['investorCount'] ?? 0}',
        _formatFcfa((kpis['totalInvested'] as num?)?.toDouble() ?? 0),
        Icons.handshake_rounded,
        Colors.indigo,
      ),
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 6 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 1.3 : 1.4,
      ),
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (ctx, i) => _buildKpiCard(ctx, cards[i]),
    );
  }

  Widget _buildKpiCard(BuildContext context, _KpiData kpi) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    kpi.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kpi.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(kpi.icon, color: kpi.color, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kpi.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  kpi.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Alerts Card ──

  Widget _buildAlertsCard(BuildContext context, List<dynamic> alerts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alerts.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: alerts.isEmpty ? AppColors.success : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alertes Urgentes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucune alerte pour le moment',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...alerts.map((alert) {
                final a = alert as Map<String, dynamic>;
                final severity = a['severity'] as String? ?? 'info';
                Color severityColor;
                IconData severityIcon;
                switch (severity) {
                  case 'critical':
                    severityColor = Colors.red;
                    severityIcon = Icons.error;
                  case 'warning':
                    severityColor = Colors.orange;
                    severityIcon = Icons.warning;
                  default:
                    severityColor = Colors.blue;
                    severityIcon = Icons.info_outline;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: severityColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(severityIcon,
                            color: severityColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['title'] as String? ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: severityColor,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                a['message'] as String? ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ──

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Nouveau producteur', Icons.person_add, '/producers/new'),
      _QuickAction('Nouvelle transaction', Icons.add_card,
          '/finances/transactions/new'),
      _QuickAction('Nouvel investisseur', Icons.handshake, '/investors/new'),
      _QuickAction(
          'Tableau finances', Icons.bar_chart, '/finances/dashboard'),
      _QuickAction('Rapport mensuel', Icons.summarize, '/finances/report'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions Rapides',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...actions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton.icon(
                  onPressed: () => context.go(a.route),
                  icon: Icon(a.icon, size: 18),
                  label: Text(a.label),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(double.infinity, 42),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Projects ──

  Widget _buildActiveProjects(BuildContext context, List<dynamic> projects) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded, color: Color(0xFF9C27B0)),
                const SizedBox(width: 8),
                Text(
                  'Projets Actifs (Forages)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucun projet actif',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...projects.map((p) {
                final proj = p as Map<String, dynamic>;
                final progress = (proj['progress'] as num?) ?? 0;
                final cost =
                    (proj['cost'] as num?)?.toDouble() ?? 0;
                final status = proj['status'] as String? ?? '';
                final isInProgress = status == 'inProgress';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () =>
                        context.go('/boreholes/${proj['id']}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  proj['name'] as String? ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isInProgress
                                      ? Colors.blue.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isInProgress ? 'En cours' : 'Planifié',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isInProgress
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  proj['location'] as String? ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Text(
                                _formatFcfa(cost),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    color: progress >= 100
                                        ? AppColors.success
                                        : progress >= 50
                                            ? Colors.blue
                                            : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$progress%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Module Summary ──

  Widget _buildModuleSummary(
    BuildContext context,
    Map<String, dynamic> modules,
  ) {
    final items = [
      _ModuleItem('Producteurs', modules['producers'] as int? ?? 0,
          Icons.people, Colors.blue, '/producers'),
      _ModuleItem('Parcelles', modules['parcels'] as int? ?? 0,
          Icons.map, AppColors.primaryLight, '/parcels'),
      _ModuleItem('Forages', modules['boreholes'] as int? ?? 0,
          Icons.water_drop, const Color(0xFF9C27B0), '/boreholes'),
      _ModuleItem('Kits', modules['kits'] as int? ?? 0,
          Icons.inventory_2, Colors.teal, '/kits'),
      _ModuleItem('Formations', modules['trainings'] as int? ?? 0,
          Icons.school, Colors.orange, '/trainings'),
      _ModuleItem('Transactions', modules['transactions'] as int? ?? 0,
          Icons.receipt_long, AppColors.secondary, '/finances'),
      _ModuleItem('Investisseurs', modules['investors'] as int? ?? 0,
          Icons.handshake, Colors.indigo, '/investors'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé des Modules',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => InkWell(
                onTap: () => context.go(item.route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: item.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.count}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Activity ──

  Widget _buildRecentActivity(BuildContext context, List<dynamic> activity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activité Récente',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (activity.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucune activité récente',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...activity.take(10).map((a) {
                final tx = a as Map<String, dynamic>;
                final isIncome = tx['type'] == 'income';
                final amount =
                    (tx['amount'] as num?)?.toDouble() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? AppColors.success.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color:
                              isIncome ? AppColors.success : Colors.red,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['description'] as String? ?? '',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              tx['category'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${_formatFcfa(amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isIncome
                              ? AppColors.success
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  static String _formatFcfa(double amount) {
    final formatted = amount.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    final sign = amount < 0 ? '-' : '';
    return '$sign$formatted F';
  }

  static String _formatNum(dynamic v) {
    final d = (v is num) ? v.toDouble() : 0.0;
    if (d == d.toInt()) return d.toInt().toString();
    return d.toStringAsFixed(1);
  }
}

// ── Data classes ──

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _KpiData(this.title, this.value, this.subtitle, this.icon, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  const _QuickAction(this.label, this.icon, this.route);
}

class _ModuleItem {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final String route;
  const _ModuleItem(
      this.label, this.count, this.icon, this.color, this.route);
}
