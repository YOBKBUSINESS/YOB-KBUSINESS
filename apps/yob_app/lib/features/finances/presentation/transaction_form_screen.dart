import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yob_core/yob_core.dart';
import '../data/finance_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  const TransactionFormScreen({super.key, this.transactionId});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  TransactionType _type = TransactionType.income;
  String? _category;
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool _isEdit = false;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  static const _incomeCategories = [
    'investissement',
    'cotisation',
    'vente',
    'subvention',
    'autre',
  ];

  static const _expenseCategories = [
    'forage',
    'salaire',
    'equipement',
    'transport',
    'formation',
    'autre',
  ];

  List<String> get _categories =>
      _type == TransactionType.income ? _incomeCategories : _expenseCategories;

  String _categoryLabel(String cat) {
    return switch (cat) {
      'investissement' => 'Investissement',
      'cotisation' => 'Cotisation',
      'vente' => 'Vente',
      'subvention' => 'Subvention',
      'forage' => 'Forage',
      'salaire' => 'Salaire',
      'equipement' => 'Équipement',
      'transport' => 'Transport',
      'formation' => 'Formation',
      'autre' => 'Autre',
      _ => cat,
    };
  }

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _isEdit = widget.transactionId != null;
  }

  void _populateFromTransaction(Transaction tx) {
    _descCtrl.text = tx.description;
    _amountCtrl.text = tx.amount.toString();
    _type = tx.type;
    _category = tx.category;
    _date = tx.date;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'type': _type.name,
        'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'category': _category,
        'date': _date.toIso8601String(),
      };

      final notifier = ref.read(transactionListProvider.notifier);
      if (_isEdit) {
        await notifier.updateTransaction(widget.transactionId!, data);
      } else {
        await notifier.createTransaction(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEdit
                ? 'Transaction mise à jour'
                : 'Transaction créée')));
        context.go('/finances');
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
      final async =
          ref.watch(transactionDetailProvider(widget.transactionId!));
      return async.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
        data: (tx) {
          if (tx != null && _descCtrl.text.isEmpty) {
            _populateFromTransaction(tx);
          }
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
                  onPressed: () => context.go('/finances')),
              const SizedBox(width: 8),
              Text(
                  _isEdit
                      ? 'Modifier la transaction'
                      : 'Nouvelle transaction',
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
                      // Type selector
                      Text('Type de transaction',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.income,
                            icon: Icon(Icons.arrow_downward),
                            label: Text('Entrée'),
                          ),
                          ButtonSegment(
                            value: TransactionType.expense,
                            icon: Icon(Icons.arrow_upward),
                            label: Text('Sortie'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (v) {
                          setState(() {
                            _type = v.first;
                            // Reset category when switching type
                            if (_category != null &&
                                !_categories.contains(_category)) {
                              _category = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Montant (FCFA) *',
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (double.tryParse(v.trim()) == null) {
                            return 'Montant invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Ex: Paiement forage Korhogo',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(_categoryLabel(c))))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date *',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_dateFmt.format(_date)),
                        ),
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
