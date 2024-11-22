import 'package:gestion_caisse_flutter/composants/custom_search_delegate.dart';
import 'package:gestion_caisse_flutter/composants/empty_transaction_view.dart';
import 'package:gestion_caisse_flutter/composants/tab_bottom_resume.dart';
import 'package:gestion_caisse_flutter/composants/tab_header.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/home_composantes/drawer.dart';
import 'package:gestion_caisse_flutter/home_composantes/transaction_row.dart';
import 'package:gestion_caisse_flutter/imprimer/pdf.dart';
import 'package:gestion_caisse_flutter/pages/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  var filterChoice = ["Tous", "Quotidien", "Hebdomadaire", "Mensuel", "Annuel"];
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
        .read(transactionsStateProvider.notifier)
        .loadTransactions(accountId);
    final transactions = ref.read(transactionsStateProvider).value ?? [];
    debugPrint('Transactions chargées: ${transactions.length}');
  }

  final selectedAccountProvider = StateProvider<Account?>((ref) => null);

  void _showAccountDialog(BuildContext context) {
    DialogCompte.show(
      context,
      onCompteSelectionne: (Account selectedAccount) async {
        debugPrint('Compte sélectionné: ${selectedAccount.id}');
        ref.read(selectedAccountProvider.notifier).state = selectedAccount;

        try {
          await ref
              .read(transactionsStateProvider.notifier)
              .loadTransactions(selectedAccount.id);
          debugPrint(
              'Transactions chargées pour le compte ${selectedAccount.solde}');

          // Vérifiez le nombre de transactions chargées
          final transactions = ref.read(transactionsStateProvider).value ?? [];
          debugPrint('Nombre de transactions chargées: ${transactions.length}');
        } catch (e) {
          debugPrint('Erreur lors du chargement des transactions: $e');
          _showErrorDialog(
              context, 'Erreur lors du chargement des transactions');
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
      // Charger toutes les données nécessaires
      await Future.wait([
        ref.read(chantiersStateProvider.notifier).loadChantiers(userId),
        ref.read(personnelStateProvider.notifier).getPersonnel(userId),
        ref.read(paymentTypesProvider.notifier).getPaymentTypes(),
      ]);
    }

    // Vérifier que le contexte est toujours valide
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // Vérifions l'état de chaque provider
          final chantiersState = ref.watch(chantiersStateProvider);
          final personnelState = ref.watch(personnelStateProvider);
          final typesState = ref.watch(paymentTypesProvider);

          // Afficher un indicateur de chargement si les données ne sont pas prêtes
          if (chantiersState.isLoading ||
              personnelState.isLoading ||
              typesState.isLoading) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              content: const Center(child: CircularProgressIndicator()),
            );
          }

          // Afficher une erreur si le chargement a échoué
          if (chantiersState.hasError ||
              personnelState.hasError ||
              typesState.hasError) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              title: const Text('Erreur'),
              content: const Text(
                  'Une erreur est survenue lors du chargement des données.'),
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

          // Vérifier que toutes les données sont chargées
          if (chantiers.isEmpty || personnel.isEmpty || types.isEmpty) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              title: const Text('Données manquantes'),
              content:
                  const Text('Certaines données n\'ont pas pu être chargées.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            title: const Text('Détails de la Transaction'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTransactionDetails(ref, transaction),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const MyText(
                  texte: 'Modifier',
                  color: Colors.white,
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditTransactionDialog(transaction);
                },
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: const Color(0xffea6b24)),
                onPressed: () => Navigator.of(context).pop(),
                child: const MyText(
                  texte: 'Fermer',
                  color: Colors.white,
                ),
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

  Widget _buildTransactionDetails(WidgetRef ref, Transaction transaction) {
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
        Consumer(
          builder: (context, ref, _) {
            final chantiersAsync = ref.watch(chantiersStateProvider);
            return chantiersAsync.when(
              data: (chantiers) {
                final chantier = chantiers.firstWhere(
                  (c) => c.id == transaction.chantierId,
                  orElse: () {
                    debugPrint(
                        'Chantier non trouvé pour l\'ID: ${transaction.chantierId}');
                    debugPrint(
                        'Chantiers disponibles: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');
                    return Chantier(id: '', name: 'Non trouvé', userId: '');
                  },
                );
                return DetailRow(
                  label: 'Chantier:',
                  value: chantier.name,
                );
              },
              loading: () => const DetailRow(
                label: 'Chantier:',
                value: 'Chargement...',
              ),
              error: (error, stack) {
                debugPrint('Erreur lors du chargement des chantiers: $error');
                debugPrint('$stack');
                return const DetailRow(
                  label: 'Chantier:',
                  value: 'Erreur de chargement',
                );
              },
            );
          },
        ),

        // Personnel
        Consumer(
          builder: (context, ref, _) {
            final personnelAsync = ref.watch(personnelStateProvider);
            return personnelAsync.when(
              data: (personnel) {
                final person = personnel.firstWhere(
                  (p) => p.id == transaction.personnelId,
                  orElse: () {
                    debugPrint(
                        'Personnel non trouvé pour l\'ID: ${transaction.personnelId}');
                    debugPrint(
                        'Personnel disponible: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');
                    return Personnel(id: '', name: 'Non trouvé', userId: '');
                  },
                );
                return DetailRow(
                  label: 'Personnel:',
                  value: person.name,
                );
              },
              loading: () => const DetailRow(
                label: 'Personnel:',
                value: 'Chargement...',
              ),
              error: (error, stack) {
                debugPrint('Erreur lors du chargement du personnel: $error');
                debugPrint('$stack');
                return const DetailRow(
                  label: 'Personnel:',
                  value: 'Erreur de chargement',
                );
              },
            );
          },
        ),

        // Type de paiement
        Consumer(
          builder: (context, ref, _) {
            final typesAsync = ref.watch(paymentTypesProvider);
            return typesAsync.when(
              data: (types) {
                final type = types.firstWhere(
                  (t) => t.id == transaction.paymentTypeId,
                  orElse: () {
                    debugPrint(
                        'Type de paiement non trouvé pour l\'ID: ${transaction.paymentTypeId}');
                    debugPrint(
                        'Types disponibles: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');
                    return PaymentType(
                        id: '', name: 'Non trouvé', category: '');
                  },
                );
                return DetailRow(
                  label: 'Type de paiement:',
                  value: '${type.name} (${type.category})',
                );
              },
              loading: () => const DetailRow(
                label: 'Type de paiement:',
                value: 'Chargement...',
              ),
              error: (error, stack) {
                debugPrint(
                    'Erreur lors du chargement des types de paiement: $error');
                debugPrint('$stack');
                return const DetailRow(
                  label: 'Type de paiement:',
                  value: 'Erreur de chargement',
                );
              },
            );
          },
        ),
      ],
    );
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

  // Filter transactions based on search query
  // Debug helper method
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final selectedAccountId = ref.read(selectedAccountProvider)?.id;

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
      final matchesSearchQuery = _searchQuery.isEmpty ||
          transaction.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true;

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
      case 'Quotidien':
        return _isToday(transactionDate);
      case 'Hebdomadaire':
        return _isThisWeek(transactionDate);
      case 'Mensuel':
        return _isThisMonth(transactionDate);
      case 'Annuel':
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
                fontSize:
                    16, // Augmenter la taille de la police pour une meilleure lisibilité
              ),
            ),
          ),
          const SizedBox(width: 8.0), // Espace entre le label et la valeur
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors
                    .black, // Assurez-vous que la couleur est suffisamment contrastée
              ),
            ),
          ),
        ],
      ),
    );
  }
}
