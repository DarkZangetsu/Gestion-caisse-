import 'package:gestion_caisse_flutter/composants/custom_search_delegate.dart';
import 'package:gestion_caisse_flutter/composants/empty_transaction_view.dart';
import 'package:gestion_caisse_flutter/composants/tab_bottom_resume.dart';
import 'package:gestion_caisse_flutter/composants/tab_header.dart';
import 'package:gestion_caisse_flutter/home_composantes/drawer.dart';
import 'package:gestion_caisse_flutter/home_composantes/transaction_row.dart';
import 'package:gestion_caisse_flutter/imprimer/pdf.dart';
import 'package:gestion_caisse_flutter/pages/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_caisse_flutter/providers/accounts_provider.dart';
import '../models/accounts.dart';
import '../models/chantier.dart';
import '../models/payment_type.dart';
import '../models/personnel.dart';
import '../models/transaction.dart';
import '../providers/chantiers_provider.dart';
import '../providers/payment_types_provider.dart';
import '../providers/personnel_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/compte/dialog_compte.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var filterChoice = ["Tous", "Ce jour", "Cette semaine", "Ce mois", "Cette année"];
  String _searchQuery = '';
  bool isSearching = false;
  FocusNode focusNode = FocusNode();
  Icon actionIcon = const Icon(Icons.search);
  late Widget appBarTitle;
  String _selectedTimeframeFilter = 'Tous';
  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];
  DateTime? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;


  // Extension method to check dates
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final sunday = startOfWeek.add(const Duration(days: 6));
    final endOfWeek =
        DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

    // Check if date falls within the current week
    return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(seconds: 1)));
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final endOfMonth = DateTime(now.year, now.month, lastDay.day, 23, 59, 59);

    return date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
  }

  bool _isThisYear(DateTime date) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return date.isAfter(startOfYear.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfYear.add(const Duration(seconds: 1)));
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
    refreshTransactions();
  }

  Future<void> _initializeData() async {
    final selectedAccount = ref.read(selectedAccountProvider);
    final userId = ref.read(currentUserProvider)?.id;

    _showAccountDialog(context);

    debugPrint('InitState - Selected Account: ${selectedAccount?.id}');
    debugPrint('InitState - UserId: $userId');

    if (selectedAccount != null && userId != null) {
      try {
        await Future.wait([
          _loadChantiers(userId),
          _loadPersonnel(userId),
          _loadPaymentTypes(),
          _loadTransactions(selectedAccount.id),
        ]);
      } catch (e) {
        debugPrint('Erreur lors du chargement des données: $e');
      }
    }
  }

  Future<void> _loadChantiers(String userId) async {
    await ref.read(chantiersStateProvider.notifier).loadChantiers(userId);
    final chantiers = ref.read(chantiersStateProvider).value ?? [];
    debugPrint('Chantiers chargés: ${chantiers.length}');
    debugPrint(
        'Chantiers: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');
  }

  Future<void> _loadPersonnel(String userId) async {
    await ref.read(personnelStateProvider.notifier).getPersonnel(userId);
    final personnel = ref.read(personnelStateProvider).value ?? [];
    debugPrint('Personnel chargé: ${personnel.length}');
    debugPrint(
        'Personnel: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');
  }

  Future<void> _loadPaymentTypes() async {
    await ref.read(paymentTypesProvider.notifier).getPaymentTypes();
    final types = ref.read(paymentTypesProvider).value ?? [];
    debugPrint('Types de paiement chargés: ${types.length}');
    debugPrint('Types: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');
  }

  Future<void> _loadTransactions(String accountId) async {
    await ref
        .read(transactionsStateProvider.notifier).loadTransactions();
        //.loadTransactions(accountId);
    final transactions = ref.read(transactionsStateProvider).value ?? [];
    debugPrint('Transactions chargées: ${transactions.length}');
  }


  Future<void> refreshTransactions() async {
    try {
      final selectedAccount = ref.read(selectedAccountProvider);
      if (selectedAccount != null) {
        // Reset the search query and time frame filter
        setState(() {
          _searchQuery = '';
          _selectedTimeframeFilter = 'Tous';
          _startDate = null;
          _endDate = null;
        });

        // Reload transactions
        await ref.read(transactionsStateProvider.notifier).loadTransactions();

        // Show a success snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transactions actualisées'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'actualisation : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _showAccountDialog(BuildContext context) {
    DialogCompte.show(
      context,
      onCompteSelectionne: (Account selectedAccount) async {
        // Mise à jour de l'ID du compte sélectionné
        ref.read(selectedAccountProvider.notifier).state = selectedAccount;

        try {
          // Chargement des transactions du compte
          await ref
              .read(transactionsStateProvider.notifier).loadTransactions();
              //.loadTransactions(selectedAccount.id);

          // Log des transactions chargées
          final transactions = ref.read(transactionsStateProvider).value ?? [];
          debugPrint('Compte sélectionné: ${selectedAccount.id}');
          debugPrint('Transactions chargées: ${transactions.length}');
        } catch (e) {
          debugPrint('Erreur lors du chargement des transactions: $e');
          _showErrorDialog(
              context, 'Impossible de charger les transactions du compte');
        }
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDetails(Transaction transaction) async {
    // Recharger les données avant d'afficher le dialogue
    final userId = ref.read(currentUserProvider)?.id;

    if (userId != null) {
      try {
        await Future.wait([
          ref.read(chantiersStateProvider.notifier).loadChantiers(userId),
          ref.read(personnelStateProvider.notifier).getPersonnel(userId),
          ref.read(paymentTypesProvider.notifier).getPaymentTypes(),
        ]);
      } catch (e) {
        debugPrint('Erreur lors du chargement des données: $e');
        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur de chargement'),
            content: Text('Impossible de charger les détails : $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Vérifier que le contexte est toujours valide
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // Récupérer les états des providers
          final chantiersState = ref.watch(chantiersStateProvider);
          final personnelState = ref.watch(personnelStateProvider);
          final typesState = ref.watch(paymentTypesProvider);

          // Gestion des états de chargement et d'erreur
          if (chantiersState.isLoading ||
              personnelState.isLoading ||
              typesState.isLoading) {
            return const AlertDialog(
              content: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (chantiersState.hasError ||
              personnelState.hasError ||
              typesState.hasError) {
            return AlertDialog(
              title: const Text('Erreur de chargement'),
              content: Text(
                'Détails non disponibles:\n'
                    'Chantiers: ${chantiersState.error ?? "OK"}\n'
                    'Personnel: ${personnelState.error ?? "OK"}\n'
                    'Types de paiement: ${typesState.error ?? "OK"}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          }

          // Récupérer les données
          final chantiers = chantiersState.value ?? [];
          final personnel = personnelState.value ?? [];
          final types = typesState.value ?? [];

          return AlertDialog(
            title: const Text('Détails de la Transaction'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTransactionDetails(ref, transaction,
                      chantiers: chantiers,
                      personnel: personnel,
                      types: types
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTransactionDialog(transaction);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmationDialog(transaction);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xffea6b24)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  _showEditTransactionDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => PaymentPage(
        isEditing: true,
        transaction: transaction,
        onSave: (updatedTransaction) async {
          try {
            await ref
                .read(transactionsStateProvider.notifier)
                .updateTransaction(updatedTransaction);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Transaction mise à jour avec succès')),
              );
              Navigator.of(context).pop();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildTransactionDetails(
      WidgetRef ref,
      Transaction transaction,
      {
        List<Chantier>? chantiers,
        List<Personnel>? personnel,
        List<PaymentType>? types
      }
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow(
          label: 'Date:',
          value: DateFormat('dd/MM/yyyy HH:mm')
              .format(transaction.transactionDate),
        ),
        DetailRow(
          label: 'Type:',
          value: transaction.type == 'reçu' ? 'Reçu' : 'Payé',
        ),
        DetailRow(
          label: 'Montant:',
          value:
          '${NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar').format(transaction.amount)} Ar',
        ),

        if (transaction.description?.isNotEmpty ?? false)
          DetailRow(
            label: 'Description:',
            value: transaction.description!,
          ),

        // Chantier
        if (transaction.chantierId != null && chantiers != null)
          DetailRow(
            label: 'Chantier:',
            value: chantiers.firstWhere(
                  (c) => c.id == transaction.chantierId,
              orElse: () => Chantier(id: '', name: '', userId: ''),
            ).name,
          ),

        // Personnel
        if (transaction.personnelId != null && personnel != null)
          DetailRow(
            label: 'Personnel:',
            value: personnel.firstWhere(
                  (p) => p.id == transaction.personnelId,
              orElse: () => Personnel(id: '', name: '', userId: ''),
            ).name,
          ),

        // Type de paiement
        if (transaction.paymentTypeId != null && types != null)
          DetailRow(
            label: 'Type de paiement:',
            value: types.firstWhere(
                  (t) => t.id == transaction.paymentTypeId,
              orElse: () => PaymentType(id: '', name: '', category: ''),
            ).name,
          ),
      ],
    );
  }

// Ajouter une méthode pour la confirmation de suppression
  void _showDeleteConfirmationDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment supprimer cette transaction ?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteTransaction(transaction);
              },
            ),
          ],
        );
      },
    );
  }

// Méthode de suppression
  void _deleteTransaction(Transaction transaction) async {
    try {
      await ref.read(transactionsStateProvider.notifier).deleteTransaction(transaction.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Ajoutez cette méthode pour réinitialiser la date
  void _resetDate() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedTimeframeFilter = 'Tous';
    });

    // Afficher un SnackBar pour informer l'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plage de dates réinitialisée')),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2222),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xffea6b24),
                  onPrimary: Colors.white,
                ),
          ),
          child: Column(
            children: [
              Expanded(child: child!),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _resetDate();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Réinitialiser',
                        style: TextStyle(color: Color(0xffea6b24)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        // Réinitialiser le filtre temporel quand une plage de dates est sélectionnée
        _selectedTimeframeFilter = 'Tous';
      });
    }
  }

  // Modifiez la SearchableAppBar pour afficher la date sélectionnée ou un texte par défaut
  Widget buildDateButton() {
    return TextButton.icon(
      onPressed: _showDateRangePicker,
      icon: const Icon(Icons.calendar_today, color: Colors.white),
      label: Text(
        _selectedDate != null
            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
            : 'Toutes les dates',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // recharger les données de type de payement et nom de parsonne après recherche
  Future<void> _refreshData() async {
    final userId = ref.read(currentUserProvider)?.id;
    await ref.read(personnelStateProvider.notifier).getPersonnel(userId!);
    await ref.read(paymentTypesProvider.notifier).getPaymentTypes();
  }

  // Filter transactions based on search query
  // Debug helper method
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final selectedAccountId = ref.read(selectedAccountProvider)?.id;
    _refreshData();

    // Afficher le compte actuel et le nombre total de transactions avant filtrage
    if (selectedAccountId != null) {
      print('Compte actuel: $selectedAccountId');
    }
    print(
        'Nombre total de transactions avant filtrage: ${transactions.length}');

    final startDateTime = _startDate != null
        ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
        : null;
    final endDateTime = _endDate != null
        ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
        : null;

    // Récupération synchrone des données
    final personnel = ref.read(personnelStateProvider).value ?? [];
    final paymentTypes = ref.read(paymentTypesProvider).value ?? [];

    final filtered = transactions.where((transaction) {
      // Vérification du compte
      final matchesAccount = transaction.accountId == selectedAccountId;

      // Vérification de la plage de dates
      final matchesDateRange = startDateTime != null && endDateTime != null
          ? transaction.transactionDate.isAfter(startDateTime) &&
                  transaction.transactionDate.isBefore(endDateTime) ||
              transaction.transactionDate.isAtSameMomentAs(startDateTime) ||
              transaction.transactionDate.isAtSameMomentAs(endDateTime)
          : true;

      // Vérification de la recherche
      bool matchesSearchQuery = _searchQuery.isEmpty;

      if (!matchesSearchQuery) {
        // Recherche par personnel
        final person = personnel.firstWhere(
          (p) => p.id == transaction.personnelId,
          orElse: () => Personnel(id: '', name: 'Non trouvé', userId: ''),
        );

        // Vérifier si le nom du personnel correspond à la requête de recherche
        if (person.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          matchesSearchQuery = true;
        }

        // Vérifier si la description correspond à la requête de recherche
        if (!matchesSearchQuery &&
            transaction.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true) {
          matchesSearchQuery = true;
        }

        // Vérifier le type de paiement
        if (!matchesSearchQuery) {
          final paymentType = paymentTypes.firstWhere(
            (type) => type.id == transaction.paymentTypeId,
            orElse: () => PaymentType(id: '', name: 'Non trouvé', category: ''),
          );

          // Vérifier si le nom du type de paiement correspond à la requête de recherche
          if (paymentType.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
            matchesSearchQuery = true;
          }
        }
      }

      // Vérification du filtre temporel
      final matchesTimeframe = _matchesTimeframe(transaction.transactionDate);

      return matchesAccount &&
          matchesDateRange &&
          matchesSearchQuery &&
          matchesTimeframe;
    }).toList();

    print('Nombre de transactions après filtrage: ${filtered.length}'); // Debug
    return filtered;
  }

  bool _matchesTimeframe(DateTime transactionDate) {
    switch (_selectedTimeframeFilter) {
      case 'Ce jour':
        return _isToday(transactionDate);
      case 'Cette semaine':
        return _isThisWeek(transactionDate);
      case 'Ce mois':
        return _isThisMonth(transactionDate);
      case 'Cette année':
        return _isThisYear(transactionDate);
      case 'Tous':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final transactionsAsync = ref.watch(transactionsStateProvider);

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: SearchableAppBar(
        onTap: _showDateRangePicker,
        selectedAccount: selectedAccount ??
            Account(id: '', name: 'Comptah', solde: 0.0, userId: ''),
        onAccountTap: () {
          _showAccountDialog(context);
        },
        onSearch: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        onDateReset: _resetDate,
        startDate: _startDate,
        endDate: _endDate,
        onTapPdf: () {
          ImpressionParPdf.onTapPdf(
              ref, _selectedTimeframeFilter, _startDate, _endDate);
        },
        onRefresh:refreshTransactions,
      ),
      drawer: const MyDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.02),
              height: 60,
              decoration: const BoxDecoration(color: Color(0xffea6b24)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterChoice.length,
                itemBuilder: (context, index) {
                  return myChoiceChip(index, ref);
                },
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const EmptyTransactionView();
                  }

                  final filteredTransactions = _filterTransactions(
                    transactions
                        .where((t) => t.accountId == selectedAccount?.id)
                        .toList(),
                  );

                  // Show "No results found" when search yields no results
                  if (filteredTransactions.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun résultat trouvé pour "$_searchQuery"',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Calculate totals based on filtered transactions
                  double totalReceived = 0;
                  double totalPaid = 0;

                  for (var transaction in filteredTransactions) {
                    if (transaction.type == 'reçu') {
                      totalReceived += transaction.amount;
                    } else {
                      totalPaid += transaction.amount;
                    }
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            margin: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.02),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: secondary,
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                      MediaQuery.of(context).size.width * 0.04),
                                  decoration: BoxDecoration(
                                    color: secondary,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      TabHeader(flex: 2, text: 'Date'),
                                      TabHeader(
                                          flex: 1,
                                          text: 'Reçu',
                                          textAlign: TextAlign.right),
                                      TabHeader(
                                          flex: 1,
                                          text: 'Payé',
                                          textAlign: TextAlign.right),
                                    ],
                                  ),
                                ),
                                ...filteredTransactions.map((transaction) {
                                  return TransactionRow(
                                    transaction: transaction,
                                    onTap: () =>
                                        _showTransactionDetails(transaction),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Bottom summary
                      bottomSummary(totalReceived, totalPaid),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(
                  child: Text('Erreur lors du chargement des transactions'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Fonction choice chip
  Padding myChoiceChip(int index, WidgetRef ref) {
    final isSelected = _selectedTimeframeFilter == filterChoice[index];

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      child: ChoiceChip(
        backgroundColor: Colors.white,
        selectedColor: const Color(0xffea6b24),
        labelPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.01,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: Colors.white),
        label: Text(
          filterChoice[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: screenWidth * 0.035,
          ),
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedTimeframeFilter = selected ? filterChoice[index] : 'Tous';
          });
        },
      ),
    );
  }

  Container bottomSummary(double totalReceived, double totalPaid) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.primary;
    final shadowColor = theme.colorScheme.secondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: TabBottomResume(
        totalReceived: totalReceived,
        totalPaid: totalPaid,
      ),
    );
  }
}


class DetailRow extends StatefulWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  State<DetailRow> createState() => _DetailRowState();
}

class _DetailRowState extends State<DetailRow> {
  @override
  Widget build(BuildContext context) {
    return _detailRow(widget.label, widget.value);
  }

  Widget _detailRow(String label, String value) {
    final double labelWidth = MediaQuery.of(context).size.width * 0.35;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xffea6b24),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
