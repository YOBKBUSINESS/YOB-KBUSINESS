import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/borehole_provider.dart';

class BoreholeFormScreen extends ConsumerStatefulWidget {
  final String? boreholeId;
  const BoreholeFormScreen({super.key, this.boreholeId});

  @override
  ConsumerState<BoreholeFormScreen> createState() => _BoreholeFormScreenState();
}

class _BoreholeFormScreenState extends ConsumerState<BoreholeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _contractorCtrl = TextEditingController();
  final _progressCtrl = TextEditingController(text: '0');
  final _maintenanceCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  ProjectStatus _status = ProjectStatus.planned;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.boreholeId != null) {
      _isEdit = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(boreholeApiProvider);
      final data = await api.getById(widget.boreholeId!);
      _nameCtrl.text = data['name'] as String? ?? '';
      _locationCtrl.text = data['location'] as String? ?? '';
      _costCtrl.text = (data['cost'] ?? 0).toString();
      _contractorCtrl.text = data['contractor'] as String? ?? '';
      _progressCtrl.text = (data['progressPercent'] ?? 0).toString();
      _maintenanceCtrl.text = data['maintenanceNotes'] as String? ?? '';
      if (data['startDate'] != null) {
        _startDate = DateTime.tryParse(data['startDate'] as String) ?? DateTime.now();
      }
      if (data['endDate'] != null) {
        _endDate = DateTime.tryParse(data['endDate'] as String);
      }
      _status = ProjectStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'planned'),
        orElse: () => ProjectStatus.planned,
      );
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _costCtrl.dispose();
    _contractorCtrl.dispose();
    _progressCtrl.dispose();
    _maintenanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/boreholes')),
                    const SizedBox(width: 8),
                    Text(
                      _isEdit ? 'Modifier le forage' : 'Nouveau forage',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Nom *',
                                prefixIcon: Icon(Icons.water_drop)),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Localisation *',
                                prefixIcon: Icon(Icons.location_on)),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _contractorCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Prestataire *',
                                    prefixIcon: Icon(Icons.engineering)),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _costCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Coût (FCFA)',
                                    prefixIcon: Icon(Icons.payments)),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Date début'),
                                subtitle: Text(dateFmt.format(_startDate)),
                                trailing:
                                    const Icon(Icons.calendar_today, size: 20),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (d != null) {
                                    setState(() => _startDate = d);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Date fin'),
                                subtitle: Text(
                                    _endDate != null
                                        ? dateFmt.format(_endDate!)
                                        : 'Non définie'),
                                trailing:
                                    const Icon(Icons.calendar_today, size: 20),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (d != null) {
                                    setState(() => _endDate = d);
                                  }
                                },
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: DropdownButtonFormField<ProjectStatus>(
                                value: _status,
                                decoration: const InputDecoration(
                                    labelText: 'Statut',
                                    prefixIcon: Icon(Icons.flag)),
                                items: ProjectStatus.values
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s.label)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _status = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _progressCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Avancement (%)',
                                    prefixIcon: Icon(Icons.trending_up)),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _maintenanceCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Notes de maintenance',
                                prefixIcon: Icon(Icons.build)),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _submit,
                              child: Text(
                                  _isEdit ? 'Enregistrer' : 'Créer le forage'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(boreholeApiProvider);
      final data = {
        'name': _nameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'cost': double.tryParse(_costCtrl.text.trim()) ?? 0,
        'contractor': _contractorCtrl.text.trim(),
        'start_date': _startDate.toIso8601String().split('T').first,
        'end_date': _endDate?.toIso8601String().split('T').first,
        'progress_percent':
            int.tryParse(_progressCtrl.text.trim())?.clamp(0, 100) ?? 0,
        'status': _status.name,
        'maintenance_notes': _maintenanceCtrl.text.trim().isEmpty
            ? null
            : _maintenanceCtrl.text.trim(),
      };
      if (_isEdit) {
        await api.update(widget.boreholeId!, data);
      } else {
        await api.create(data);
      }
      ref.invalidate(boreholeListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Forage modifié' : 'Forage créé'),
          backgroundColor: AppColors.success,
        ));
        context.go('/boreholes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }
}
