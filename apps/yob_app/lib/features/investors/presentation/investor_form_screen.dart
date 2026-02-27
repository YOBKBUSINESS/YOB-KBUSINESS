import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/investor_provider.dart';

class InvestorFormScreen extends ConsumerStatefulWidget {
  final String? investorId;
  const InvestorFormScreen({super.key, this.investorId});

  bool get isEditing => investorId != null;

  @override
  ConsumerState<InvestorFormScreen> createState() => _InvestorFormScreenState();
}

class _InvestorFormScreenState extends ConsumerState<InvestorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  final _returnCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _amountCtrl.dispose();
    _projectCtrl.dispose();
    _returnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill in edit mode
    if (widget.isEditing && !_loaded) {
      final investorAsync =
          ref.watch(investorDetailProvider(widget.investorId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier investisseur')),
        body: investorAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (inv) {
            if (inv == null) {
              return const Center(child: Text('Introuvable'));
            }
            _prefill(inv);
            return _buildForm(context);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? 'Modifier investisseur'
            : 'Nouvel investisseur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.isEditing
              ? context.go('/investors/${widget.investorId}')
              : context.go('/investors'),
        ),
      ),
      body: _buildForm(context),
    );
  }

  void _prefill(dynamic inv) {
    _fullNameCtrl.text = inv.fullName ?? '';
    _emailCtrl.text = inv.email ?? '';
    _phoneCtrl.text = inv.phone ?? '';
    _companyCtrl.text = inv.company ?? '';
    _amountCtrl.text =
        (inv.totalInvested as num?)?.toStringAsFixed(0) ?? '';
    _projectCtrl.text = inv.projectName ?? '';
    _returnCtrl.text =
        inv.expectedReturn != null ? inv.expectedReturn.toString() : '';
    _loaded = true;
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full name (required)
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Company
            TextFormField(
              controller: _companyCtrl,
              decoration: const InputDecoration(
                labelText: 'Entreprise',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Divider: Investment section
            Text('Investissement',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant investi (FCFA)',
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Project name
            TextFormField(
              controller: _projectCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du projet',
                prefixIcon: Icon(Icons.business_center),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Expected return
            TextFormField(
              controller: _returnCtrl,
              decoration: const InputDecoration(
                labelText: 'Retour attendu (%)',
                prefixIcon: Icon(Icons.trending_up),
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(widget.isEditing ? 'Mettre à jour' : 'Créer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'fullName': _fullNameCtrl.text.trim(),
      'email':
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'phone':
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'company':
          _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      'totalInvested': _amountCtrl.text.isNotEmpty
          ? double.tryParse(_amountCtrl.text) ?? 0
          : 0,
      'projectName': _projectCtrl.text.trim().isEmpty
          ? null
          : _projectCtrl.text.trim(),
      'expectedReturn': _returnCtrl.text.isNotEmpty
          ? double.tryParse(_returnCtrl.text)
          : null,
    };

    try {
      final notifier = ref.read(investorListProvider.notifier);
      if (widget.isEditing) {
        await notifier.updateInvestor(widget.investorId!, data);
      } else {
        await notifier.createInvestor(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Investisseur mis à jour'
                : 'Investisseur créé'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/investors');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
