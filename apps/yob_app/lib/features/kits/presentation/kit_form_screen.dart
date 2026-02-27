import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../data/kit_provider.dart';

class KitFormScreen extends ConsumerStatefulWidget {
  final String? kitId;
  const KitFormScreen({super.key, this.kitId});

  @override
  ConsumerState<KitFormScreen> createState() => _KitFormScreenState();
}

class _KitFormScreenState extends ConsumerState<KitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kitTypeCtrl;
  late final TextEditingController _beneficiaryIdCtrl;
  late final TextEditingController _valueCtrl;
  DateTime _distributionDate = DateTime.now();
  KitStatus _status = KitStatus.subventionne;
  bool _isLoading = false;
  bool _isEdit = false;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _kitTypeCtrl = TextEditingController();
    _beneficiaryIdCtrl = TextEditingController();
    _valueCtrl = TextEditingController();
    _isEdit = widget.kitId != null;
  }

  void _populateFromKit(AgriculturalKit kit) {
    _kitTypeCtrl.text = kit.kitType;
    _beneficiaryIdCtrl.text = kit.beneficiaryId;
    _valueCtrl.text = kit.value.toString();
    _distributionDate = kit.distributionDate;
    _status = kit.status;
  }

  @override
  void dispose() {
    _kitTypeCtrl.dispose();
    _beneficiaryIdCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _distributionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _distributionDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'kitType': _kitTypeCtrl.text.trim(),
        'beneficiaryId': _beneficiaryIdCtrl.text.trim(),
        'distributionDate': _distributionDate.toIso8601String(),
        'value': double.tryParse(_valueCtrl.text.trim()) ?? 0,
        'status': _status.name,
      };

      final notifier = ref.read(kitListProvider.notifier);
      if (_isEdit) {
        await notifier.updateKit(widget.kitId!, data);
      } else {
        await notifier.createKit(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(_isEdit ? 'Kit mis à jour' : 'Kit créé avec succès')));
        context.go('/kits');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final async = ref.watch(kitDetailProvider(widget.kitId!));
      return async.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
        data: (kit) {
          if (kit != null && _kitTypeCtrl.text.isEmpty) _populateFromKit(kit);
          return _buildForm();
        },
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
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
              const SizedBox(width: 8),
              Text(_isEdit ? 'Modifier le kit' : 'Nouveau kit',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _kitTypeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Type de kit *',
                          hintText: 'Ex: Kit semences, Kit outils',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _beneficiaryIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ID Bénéficiaire *',
                          hintText: 'Identifiant du producteur',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de distribution *',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_dateFmt.format(_distributionDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valueCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Valeur (FCFA) *',
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (double.tryParse(v.trim()) == null) {
                            return 'Nombre invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<KitStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: KitStatus.values
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s.label)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_isEdit ? 'Mettre à jour' : 'Créer'),
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
}
