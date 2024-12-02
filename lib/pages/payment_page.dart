import 'dart:math';

import 'package:gestion_caisse_flutter/mode/dark_mode.dart';
import 'package:gestion_caisse_flutter/mode/light_mode.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
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
    if (widget.value != null && widget.value != oldWidget.value) {
      _searchController.text = widget.getLabel(widget.value!);
    }
  }

  @override
  void dispose() {
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
    if (_overlayEntry == null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: Offset(0, size.height + 5),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: _buildDropdownList(),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  Widget _buildDropdownList() {
    if (_filteredItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "No results found",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredItems.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Colors.grey),
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return ListTile(
            dense: true,
            title: Text(
              widget.getLabel(item),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onTap: () {
              widget.onChanged(item);
              _removeOverlay();
              setState(() {
                _isExpanded = false;
                _searchController.text = widget.getLabel(item);
              });
            },
            visualDensity: VisualDensity.compact,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          );
        },
      ),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final responsive = MediaQuery.of(context);

    return FormField<T>(
      validator: widget.validator,
      builder: (FormFieldState<T> field) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: min(constraints.maxWidth, 600),
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: widget.label,
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: responsive.size.width > 600 ? 16 : 12,
                          vertical: responsive.size.width > 600 ? 16 : 12,
                        ),
                        border: _buildOutlineBorder(colorScheme.secondary),
                        enabledBorder: _buildOutlineBorder(
                          colorScheme.secondary.withOpacity(0.5),
                        ),
                        focusedBorder:
                            _buildOutlineBorder(colorScheme.secondary),
                        suffixIcon: _buildSuffixIcons(colorScheme.secondary),
                      ),
                      onTap: _handleTap,
                      onChanged: _filterItems,
                      style: TextStyle(
                        fontSize: responsive.textScaleFactor * 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (field.hasError) _buildErrorText(context, field),
                ],
              );
            },
          ),
        );
      },
    );
  }

  OutlineInputBorder _buildOutlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }

  Widget _buildSuffixIcons(Color secondary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.value != null) _buildClearButton(secondary),
        _buildExpandCollapseButton(secondary),
      ],
    );
  }

  IconButton _buildClearButton(Color secondary) {
    return IconButton(
      icon: Icon(Icons.clear, color: secondary),
      onPressed: () {
        widget.onChanged(null);
        _searchController.clear();
        _filterItems('');
      },
      tooltip: 'Clear search',
    );
  }

  IconButton _buildExpandCollapseButton(Color secondary) {
    return IconButton(
      icon: Icon(
        _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
        color: secondary,
      ),
      onPressed: _toggleExpand,
      tooltip: _isExpanded ? 'Collapse' : 'Expand',
    );
  }

  void _handleTap() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
        _showOverlay();
      });
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _showOverlay() : _removeOverlay();
    });
  }

  Widget _buildErrorText(BuildContext context, FormFieldState<T> field) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8),
      child: Text(
        field.errorText!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
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

      debugPrint("selected *****: ${ref.read(selectedAccountProvider)}");

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
    // Form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Account selection validation
    final selectedAccount = ref.watch(selectedAccountProvider);
    if (selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un compte')),
      );
      return;
    }

    // Additional validations
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La description est obligatoire')),
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
            description: description,
            amount: amount,
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
            description: description,
            amount: amount,
            transactionDate: _transactionDate,
            type: _type,
            createdAt: now,
            updatedAt: now,
          );

    try {
      final transactionsNotifier = ref.read(transactionsStateProvider.notifier);

      if (widget.isEditing && widget.onSave != null) {
        // If a custom save handler is provided (for external editing)
        await widget.onSave!(transaction);
      } else {
        // Standard transaction saving process
        if (widget.isEditing) {
          // Update existing transaction
          await transactionsNotifier.updateTransaction(transaction);
        } else {
          // Add new transaction
          await transactionsNotifier.addTransaction(transaction);
        }

        // Reload transactions for the selected account
        //await transactionsNotifier.loadTransactions(selectedAccount.id);
        await transactionsNotifier.loadTransactions();
      }

      if (mounted) {
        debugPrint("selectedAccount: $selectedAccount");
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
        debugPrint('Transaction save error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue lors de l\'enregistrement'),
          ),
        );
      }
    }
  }

  /*Future<void> _saveTransaction() async {
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
        debugPrint(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Une erreur est survenue lors de l\'enregistrement')),
        );
      }
    }
  }*/

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildTransactionDateField(),
              const SizedBox(height: 16),
              _buildChantierDropdown(chantiersAsync),
              const SizedBox(height: 16),
              _buildPaymentTypeDropdown(filteredPaymentTypes),
              const SizedBox(height: 16),
              if (shouldShowPersonnelField()) ...[
                _buildPersonnelDropdown(personnelAsync),
                const SizedBox(height: 16),
              ],
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
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
    );
  }

  Widget _buildTransactionDateField() {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    return ListTile(
      title: const Text('Date de transaction'),
      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_transactionDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _transactionDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          cancelText: 'Annuler',
          confirmText: 'Confirmer',
          builder: (context, Widget? child) {
            return Theme(
              data: isDarkMode
                  ? darkTheme.copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : lightTheme.copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
              child: child ?? const SizedBox(),
            );
          },
        );

        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_transactionDate),
            builder: (context, Widget? child) {
              return Theme(
                data: isDarkMode
                    ? darkTheme.copyWith(
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      )
                    : lightTheme.copyWith(
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                child: child ?? const SizedBox(),
              );
            },
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
    );
  }

  Widget _buildChantierDropdown(AsyncValue<List<Chantier>> chantiersAsync) {
    return chantiersAsync.when(
      data: (chantiers) => DropdownButtonFormField<String>(
        value: _selectedChantierId,
        decoration: const InputDecoration(
          labelText: 'Chantier (optionnel)',
          labelStyle: TextStyle(color: Colors.grey),
        ),
        items: chantiers
            .map((chantier) => DropdownMenuItem(
                  value: chantier.id,
                  child: Text(chantier.name),
                ))
            .toList(),
        onChanged: (value) => setState(() => _selectedChantierId = value),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, __) => const Text('Erreur de chargement des chantiers'),
    );
  }

  Widget _buildPaymentTypeDropdown(List<PaymentType> filteredPaymentTypes) {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentTypeId,
      decoration: const InputDecoration(
        labelText: 'Type de paiement (optionnel)',
        labelStyle: TextStyle(color: Colors.grey),
      ),
      items: filteredPaymentTypes
          .map((type) => DropdownMenuItem(
                value: type.id,
                child: Text(type.name),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedPaymentTypeId = value),
    );
  }

  Widget _buildPersonnelDropdown(AsyncValue<List<Personnel>> personnelAsync) {
    return personnelAsync.when(
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
      error: (_, __) => const Text('Erreur de chargement du personnel'),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (optionnelle)',
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
    );
  }
}
