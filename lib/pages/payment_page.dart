import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/payment_type.dart';
import '../models/personnel.dart';
import '../models/chantier.dart';
import '../providers/accounts_provider.dart';
import '../providers/payment_methods_provider.dart';
import '../providers/payment_types_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/personnel_provider.dart';
import '../providers/chantiers_provider.dart';
import '../providers/users_provider.dart';

// Widget SearchableDropdown personnalisé
class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String Function(T) getLabel;
  final String Function(T) getSearchString;
  final void Function(T?) onChanged;
  final String label;
  final String? Function(T?)? validator;

  const SearchableDropdown({
    Key? key,
    required this.items,
    required this.value,
    required this.getLabel,
    required this.getSearchString,
    required this.onChanged,
    required this.label,
    this.validator,
  }) : super(key: key);

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;
  List<T> _filteredItems = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              constraints: BoxConstraints(
                maxHeight: 200,
                minWidth: size.width,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    dense: true,
                    title: Text(widget.getLabel(item)),
                    onTap: () {
                      widget.onChanged(item);
                      _removeOverlay();
                      setState(() {
                        _isExpanded = false;
                        _searchController.text = widget.getLabel(item);
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => widget
              .getSearchString(item)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });

    if (_isExpanded) {
      _removeOverlay();
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      validator: widget.validator,
      builder: (FormFieldState<T> field) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: widget.label,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.value != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.onChanged(null);
                            _searchController.clear();
                            _filterItems('');
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _isExpanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                            if (_isExpanded) {
                              _showOverlay();
                            } else {
                              _removeOverlay();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  if (!_isExpanded) {
                    setState(() {
                      _isExpanded = true;
                      _showOverlay();
                    });
                  }
                },
                onChanged: _filterItems,
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PaymentPage extends ConsumerStatefulWidget {
  final String initialType;

  const PaymentPage({
    super.key,
    this.initialType = 'reçu',
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _transactionDate = DateTime.now();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPaymentMethodId;
  String? _selectedPaymentTypeId;
  String? _selectedChantierId;
  String? _selectedPersonnelId;

  late String _type;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    Future.microtask(() {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      ref.read(paymentMethodsProvider.notifier).getPaymentMethods();
      ref.read(paymentTypesProvider.notifier).getPaymentTypes();
      ref.read(personnelStateProvider.notifier).getPersonnel(userId);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool shouldShowPersonnelField() {
    final selectedType = ref.read(paymentTypesProvider).when(
      data: (types) => types.where((t) => t.id == _selectedPaymentTypeId).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    if (selectedType == null) return false;

    final typeName = selectedType.name.toLowerCase();
    return typeName.contains('salaire') || typeName.contains('karama');
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedAccount = ref.read(selectedAccountProvider);
    if (selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un compte')),
      );
      return;
    }

    final uuid = Uuid();
    final transaction = Transaction(
      id: uuid.v4(),
      accountId: selectedAccount.id,
      chantierId: _selectedChantierId,
      personnelId: _selectedPersonnelId,
      paymentMethodId: _selectedPaymentMethodId,
      paymentTypeId: _selectedPaymentTypeId,
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      transactionDate: _transactionDate,
      type: _type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(transactionsStateProvider.notifier).addTransaction(transaction);
      await ref.read(transactionsStateProvider.notifier).loadTransactions(selectedAccount.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction enregistrée avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id ?? '';
    final paymentTypesAsync = ref.watch(paymentTypesProvider);
    final personnelAsync = ref.watch(personnelStateProvider);
    final chantiersAsync = ref.watch(chantiersProvider(userId));

    List<PaymentType> filteredPaymentTypes = paymentTypesAsync.when(
      data: (types) => types
          .where((type) => _type == 'reçu'
          ? type.category == 'revenu'
          : type.category == 'dépense')
          .toList(),
      loading: () => [],
      error: (_, __) => [],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_type == 'reçu' ? 'Reçu' : 'Payé'),
        backgroundColor: _type == 'reçu' ? Colors.green : Colors.red,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type de transaction
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'reçu', label: Text('Reçu')),
                ButtonSegment(value: 'payé', label: Text('Payé')),
              ],
              selected: {_type},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _type = selection.first;
                  _selectedPaymentTypeId = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Montant
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant',
                prefixText: 'Ar ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                if (double.tryParse(value) == null) {
                  return 'Veuillez entrer un montant valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date et heure
            ListTile(
              title: const Text('Date de transaction'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_transactionDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _transactionDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_transactionDate),
                  );
                  if (time != null) {
                    setState(() {
                      _transactionDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Chantier Dropdown (optionnel)
            chantiersAsync.when(
              data: (chantiers) => SearchableDropdown<Chantier>(
                items: chantiers,
                value: chantiers.where((c) => c.id == _selectedChantierId).firstOrNull,
                getLabel: (chantier) => chantier.name,
                getSearchString: (chantier) => chantier.name,
                onChanged: (chantier) => setState(() => _selectedChantierId = chantier?.id),
                label: 'Chantier (optionnel)',
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, __) => Text('Erreur de chargement des chantiers: $error'),
            ),
            const SizedBox(height: 16),

            // Type de paiement (optionnel)
            paymentTypesAsync.when(
              data: (_) => DropdownButtonFormField<String>(
                value: _selectedPaymentTypeId,
                decoration: const InputDecoration(
                  labelText: 'Type de paiement (optionnel)',
                ),
                items: filteredPaymentTypes
                    .map((type) => DropdownMenuItem(
                  value: type.id,
                  child: Text(type.name),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPaymentTypeId = value),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Erreur de chargement des types de paiement'),
            ),
            const SizedBox(height: 16),

            // Personnel Dropdown (conditionnel et optionnel)
            if (shouldShowPersonnelField()) ...[
              personnelAsync.when(
                data: (personnelList) => SearchableDropdown<Personnel>(
                  items: personnelList,
                  value: personnelList.where((p) => p.id == _selectedPersonnelId).firstOrNull,
                  getLabel: (personnel) => personnel.name,
                  getSearchString: (personnel) => personnel.name,
                  onChanged: (personnel) => setState(() => _selectedPersonnelId = personnel?.id),
                  label: 'Personnel (optionnel)',
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement du personnel'),
              ),
              const SizedBox(height: 16),
            ],

            // Description (optionnelle)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Bouton de sauvegarde
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'reçu' ? Colors.green : Colors.red,
                ),
                child: const Text(
                  'Sauvegarder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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