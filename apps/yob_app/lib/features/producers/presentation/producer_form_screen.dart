import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/theme/app_theme.dart';
import '../data/producer_provider.dart';

class ProducerFormScreen extends ConsumerStatefulWidget {
  final String? producerId; // null = create, non-null = edit

  const ProducerFormScreen({super.key, this.producerId});

  @override
  ConsumerState<ProducerFormScreen> createState() => _ProducerFormScreenState();
}

class _ProducerFormScreenState extends ConsumerState<ProducerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _localityController = TextEditingController();
  final _areaController = TextEditingController();
  final _productionController = TextEditingController();
  ProducerStatus _status = ProducerStatus.actif;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.producerId != null) {
      _isEdit = true;
      _loadProducer();
    }
  }

  Future<void> _loadProducer() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(producerApiProvider);
      final data = await api.getById(widget.producerId!);
      _nameController.text = data['fullName'] as String? ?? '';
      _phoneController.text = data['phone'] as String? ?? '';
      _localityController.text = data['locality'] as String? ?? '';
      _areaController.text = (data['cultivatedArea'] ?? 0).toString();
      _productionController.text =
          data['productionLevel']?.toString() ?? '';
      final statusStr = data['status'] as String? ?? 'actif';
      _status = ProducerStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => ProducerStatus.actif,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de chargement')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _localityController.dispose();
    _areaController.dispose();
    _productionController.dispose();
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
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/producers'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEdit
                            ? 'Modifier le producteur'
                            : 'Nouveau producteur',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nom complet *',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Le nom est requis'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _localityController,
                              decoration: const InputDecoration(
                                labelText: 'Localité *',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'La localité est requise'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _areaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Surface cultivée (ha)',
                                      prefixIcon: Icon(Icons.landscape),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _productionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Niveau production (t)',
                                      prefixIcon: Icon(Icons.trending_up),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ProducerStatus>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Statut',
                                prefixIcon: Icon(Icons.flag),
                              ),
                              items: ProducerStatus.values
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s.label)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _submit,
                                child: Text(_isEdit
                                    ? 'Enregistrer les modifications'
                                    : 'Créer le producteur'),
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
      final api = ref.read(producerApiProvider);
      final data = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'locality': _localityController.text.trim(),
        'cultivated_area':
            double.tryParse(_areaController.text.trim()) ?? 0,
        'production_level': _productionController.text.trim().isEmpty
            ? null
            : double.tryParse(_productionController.text.trim()),
        'status': _status.name,
      };

      if (_isEdit) {
        await api.update(widget.producerId!, data);
      } else {
        await api.create(data);
      }

      // Refresh list
      ref.invalidate(producerListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Producteur modifié avec succès'
                : 'Producteur créé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/producers');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }
}
