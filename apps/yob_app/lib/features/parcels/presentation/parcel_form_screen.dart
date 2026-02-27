import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/parcel_provider.dart';

class ParcelFormScreen extends ConsumerStatefulWidget {
  final String? parcelId;
  const ParcelFormScreen({super.key, this.parcelId});

  @override
  ConsumerState<ParcelFormScreen> createState() => _ParcelFormScreenState();
}

class _ParcelFormScreenState extends ConsumerState<ParcelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cropCtrl = TextEditingController();
  LandTenureStatus _tenure = LandTenureStatus.unknown;
  bool _surveyDone = false;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.parcelId != null) {
      _isEdit = true;
      _loadParcel();
    }
  }

  Future<void> _loadParcel() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(parcelApiProvider);
      final data = await api.getById(widget.parcelId!);
      _nameCtrl.text = data['name'] as String? ?? '';
      _latCtrl.text = (data['latitude'] ?? 0).toString();
      _lonCtrl.text = (data['longitude'] ?? 0).toString();
      _areaCtrl.text = (data['surfaceArea'] ?? 0).toString();
      _cropCtrl.text = data['cropType'] as String? ?? '';
      _tenure = LandTenureStatus.values.firstWhere(
        (e) => e.name == (data['tenureStatus'] as String? ?? 'unknown'),
        orElse: () => LandTenureStatus.unknown,
      );
      _surveyDone = data['commodeSurveyDone'] as bool? ?? false;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _areaCtrl.dispose();
    _cropCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () => context.go('/parcels')),
                    const SizedBox(width: 8),
                    Text(
                      _isEdit ? 'Modifier la parcelle' : 'Nouvelle parcelle',
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
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Nom *',
                                  prefixIcon: Icon(Icons.label)),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Requis'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cropCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Type de culture *',
                                  prefixIcon: Icon(Icons.agriculture)),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Requis'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _areaCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Surface (ha)',
                                      prefixIcon: Icon(Icons.landscape)),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Latitude',
                                      prefixIcon: Icon(Icons.gps_fixed)),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _lonCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Longitude',
                                      prefixIcon: Icon(Icons.gps_fixed)),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<LandTenureStatus>(
                              value: _tenure,
                              decoration: const InputDecoration(
                                  labelText: 'Statut foncier',
                                  prefixIcon: Icon(Icons.security)),
                              items: LandTenureStatus.values
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s.label)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _tenure = v);
                              },
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Bornage effectué'),
                              value: _surveyDone,
                              onChanged: (v) =>
                                  setState(() => _surveyDone = v),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _submit,
                                child: Text(_isEdit
                                    ? 'Enregistrer'
                                    : 'Créer la parcelle'),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(parcelApiProvider);
      final data = {
        'name': _nameCtrl.text.trim(),
        'latitude': double.tryParse(_latCtrl.text.trim()) ?? 0,
        'longitude': double.tryParse(_lonCtrl.text.trim()) ?? 0,
        'surface_area': double.tryParse(_areaCtrl.text.trim()) ?? 0,
        'crop_type': _cropCtrl.text.trim(),
        'tenure_status': _tenure.name,
        'commode_survey_done': _surveyDone,
      };
      if (_isEdit) {
        await api.update(widget.parcelId!, data);
      } else {
        await api.create(data);
      }
      ref.invalidate(parcelListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Parcelle modifiée' : 'Parcelle créée'),
          backgroundColor: AppColors.success,
        ));
        context.go('/parcels');
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
