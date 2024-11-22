import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/payment_type.dart';
import '../models/personnel.dart';
import '../models/chantier.dart';
import '../providers/accounts_provider.dart';
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
  final TextEditingController? controller; // Nouveau paramètre

  const SearchableDropdown({
    Key? key,
    required this.items,
    required this.value,
    required this.getLabel,
    required this.getSearchString,
    required this.onChanged,
    required this.label,
    this.validator,
    this.controller,
  }) : super(key: key);

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  late TextEditingController _searchController;
  bool _isExpanded = false;
  List<T> _filteredItems = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchController = widget.controller ?? TextEditingController();
    _filteredItems = widget.items;

    // Initialiser le texte si une valeur est déjà sélectionnée
    if (widget.value != null) {
      _searchController.text = widget.getLabel(widget.value!);
    }
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour le texte si la valeur change
    if (widget.value != null && widget.value != oldWidget.value) {
      _searchController.text = widget.getLabel(widget.value!);
    }
  }

  @override
  void dispose() {
    // Ne disposer le controller que s'il n'a pas été fourni de l'extérieur
    if (widget.controller == null) {
      _searchController.dispose();
    }
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
    final primary = Theme.of(context).colorScheme.primary;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              constraints: BoxConstraints(
                maxHeight: 200,
                minWidth: size.width,
              ),
              decoration: BoxDecoration(
                color: primary,
                border: Border.all(color: primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      widget.getLabel(item),
                    ),
                    hoverColor: primary,
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
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    //final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return FormField<T>(
      validator: widget.validator,
      builder: (FormFieldState<T> field) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondary.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: secondary),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.value != null)
                          IconButton(
                            icon: Icon(Icons.clear, color: secondary),
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
                            color: secondary,
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
  final bool isEditing;
  final Transaction? transaction;
  final Function(Transaction)? onSave;

  const PaymentPage({
    super.key,
    this.initialType = 'reçu',
    this.isEditing = false,
    this.transaction,
    this.onSave,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _transactionDate;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPaymentTypeId;
  String? _selectedChantierId;
  String? _selectedPersonnelId;
  late String _type;
  final TextEditingController _chantierSearchController =
      TextEditingController();
  final TextEditingController _personnelSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize with existing transaction data if editing
    if (widget.isEditing && widget.transaction != null) {
      final transaction = widget.transaction!;
      _type = transaction.type;
      _transactionDate = transaction.transactionDate;
      _amountController.text = transaction.amount.toString();
      _descriptionController.text = transaction.description ?? '';
      _selectedPaymentTypeId = transaction.paymentTypeId;
      _selectedChantierId = transaction.chantierId;
      _selectedPersonnelId = transaction.personnelId;

      // Charger les données initiales pour le chantier et le personnel
      Future.microtask(() {
        final userId = ref.read(currentUserProvider)?.id ?? '';

        // Chargement du chantier
        ref
            .read(chantiersStateProvider.notifier)
            .loadChantiers(userId)
            .then((_) {
          if (_selectedChantierId != null) {
            final chantiers = ref.read(chantiersProvider(userId)).value ?? [];
            final selectedChantier =
                chantiers.where((c) => c.id == _selectedChantierId).firstOrNull;
            if (selectedChantier != null) {
              _chantierSearchController.text = selectedChantier.name;
            }
          }
        });

        // Chargement du personnel
        ref
            .read(personnelStateProvider.notifier)
            .getPersonnel(userId)
            .then((_) {
          if (_selectedPersonnelId != null) {
            final personnel = ref.read(personnelStateProvider).value ?? [];
            final selectedPersonnel = personnel
                .where((p) => p.id == _selectedPersonnelId)
                .firstOrNull;
            if (selectedPersonnel != null) {
              _personnelSearchController.text = selectedPersonnel.name;
            }
          }
        });
      });
    } else {
      _type = widget.initialType;
      _transactionDate = DateTime.now();
    }

    // Load required data
    Future.microtask(() {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      ref.read(paymentTypesProvider.notifier).getPaymentTypes();
      ref.read(personnelStateProvider.notifier).getPersonnel(userId);
      ref.read(chantiersStateProvider.notifier).loadChantiers(userId);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _chantierSearchController.dispose();
    _personnelSearchController.dispose();
    super.dispose();
  }

  bool shouldShowPersonnelField() {
    final selectedType = ref.read(paymentTypesProvider).when(
          data: (types) =>
              types.where((t) => t.id == _selectedPaymentTypeId).firstOrNull,
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

    final now = DateTime.now();
    final transaction = widget.isEditing && widget.transaction != null
        ? widget.transaction!.copyWith(
            accountId: selectedAccount.id,
            chantierId: _selectedChantierId,
            personnelId: _selectedPersonnelId,
            paymentTypeId: _selectedPaymentTypeId,
            description: _descriptionController.text,
            amount: double.parse(_amountController.text),
            transactionDate: _transactionDate,
            type: _type,
            updatedAt: now,
          )
        : Transaction(
            id: const Uuid().v4(),
            accountId: selectedAccount.id,
            chantierId: _selectedChantierId,
            personnelId: _selectedPersonnelId,
            paymentTypeId: _selectedPaymentTypeId,
            description: _descriptionController.text,
            amount: double.parse(_amountController.text),
            transactionDate: _transactionDate,
            type: _type,
            createdAt: now,
            updatedAt: now,
          );

    try {
      if (widget.isEditing && widget.onSave != null) {
        await widget.onSave!(transaction);
      } else {
        await ref
            .read(transactionsStateProvider.notifier)
            .addTransaction(transaction);
        await ref
            .read(transactionsStateProvider.notifier)
            .loadTransactions(selectedAccount.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Transaction mise à jour avec succès'
                : 'Transaction enregistrée avec succès'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
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
        title: Text(widget.isEditing
            ? 'Modifier la transaction'
            : (_type == 'reçu' ? 'Reçu' : 'Payé')),
        backgroundColor: _type == 'reçu' ? Colors.green : Colors.red,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!widget.isEditing) ...[
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
            ],
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
            ListTile(
              title: const Text('Date de transaction'),
              subtitle:
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(_transactionDate)),
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
            chantiersAsync.when(
              data: (chantiers) => SearchableDropdown<Chantier>(
                items: chantiers,
                value: chantiers
                    .where((c) => c.id == _selectedChantierId)
                    .firstOrNull,
                getLabel: (chantier) => chantier.name,
                getSearchString: (chantier) => chantier.name,
                onChanged: (chantier) =>
                    setState(() => _selectedChantierId = chantier?.id),
                label: 'Chantier (optionnel)',
                controller: _chantierSearchController,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, __) =>
                  Text('Erreur de chargement des chantiers: $error'),
            ),
            const SizedBox(height: 16),
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
                onChanged: (value) =>
                    setState(() => _selectedPaymentTypeId = value),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Text('Erreur de chargement des types de paiement'),
            ),
            const SizedBox(height: 16),
            if (shouldShowPersonnelField()) ...[
              personnelAsync.when(
                data: (personnelList) => SearchableDropdown<Personnel>(
                  items: personnelList,
                  value: personnelList
                      .where((p) => p.id == _selectedPersonnelId)
                      .firstOrNull,
                  getLabel: (personnel) => personnel.name,
                  getSearchString: (personnel) => personnel.name,
                  onChanged: (personnel) =>
                      setState(() => _selectedPersonnelId = personnel?.id),
                  label: 'Personnel (optionnel)',
                  controller: _personnelSearchController,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Text('Erreur de chargement du personnel'),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'reçu' ? Colors.green : Colors.red,
                ),
                child: Text(
                  widget.isEditing ? 'Mettre à jour' : 'Sauvegarder',
                  style: const TextStyle(
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
