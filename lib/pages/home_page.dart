import 'package:caisse/composants/custom_search_delegate.dart';
import 'package:caisse/composants/empty_transaction_view.dart';
import 'package:caisse/composants/tab_bottom_resume.dart';
import 'package:caisse/composants/tab_header.dart';
import 'package:caisse/composants/texts.dart';
import 'package:caisse/home_composantes/drawer.dart';
import 'package:caisse/home_composantes/transaction_row.dart';
import 'package:caisse/imprimer/pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accounts.dart';
import '../models/chantier.dart';
import '../models/payment_type.dart';
import '../models/personnel.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
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
  int? _value = 1;
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
    // Find the most recent Monday (beginning of week)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    // Set time to start of day (00:00:00)
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    // Find the next Sunday (end of week)
    final sunday = startOfWeek.add(const Duration(days: 6));
    // Set time to end of day (23:59:59)
    final endOfWeek =
        DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

    // Check if date falls within the current week
    return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(seconds: 1)));
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    // First day of current month
    final startOfMonth = DateTime(now.year, now.month, 1);
    // Calculate last day of current month
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final endOfMonth = DateTime(now.year, now.month, lastDay.day, 23, 59, 59);

    return date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
  }

  bool _isThisYear(DateTime date) {
    final now = DateTime.now();
    // First day of current year
    final startOfYear = DateTime(now.year, 1, 1);
    // Last day of current year
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return date.isAfter(startOfYear.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfYear.add(const Duration(seconds: 1)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selectedAccount = ref.read(selectedAccountProvider);
      final userId = ref.read(currentUserProvider)?.id;

      print('InitState - Selected Account: ${selectedAccount?.id}');
      print('InitState - UserId: $userId');

      if (selectedAccount != null && userId != null) {
        try {
          // Chargement des chantiers
          await ref.read(chantiersStateProvider.notifier).loadChantiers(userId);
          final chantiers = ref.read(chantiersStateProvider).value ?? [];
          print('Chantiers chargés: ${chantiers.length}');
          print(
              'Chantiers: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');

          // Chargement du personnel
          await ref.read(personnelStateProvider.notifier).getPersonnel(userId);
          final personnel = ref.read(personnelStateProvider).value ?? [];
          print('Personnel chargé: ${personnel.length}');
          print(
              'Personnel: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');

          // Chargement des types de paiement
          await ref.read(paymentTypesProvider.notifier).getPaymentTypes();
          final types = ref.read(paymentTypesProvider).value ?? [];
          print('Types de paiement chargés: ${types.length}');
          print('Types: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');

          // Chargement des transactions
          await ref
              .read(transactionsStateProvider.notifier)
              .loadTransactions(selectedAccount.id);
          final transactions = ref.read(transactionsStateProvider).value ?? [];
          print('Transactions chargées: ${transactions.length}');
        } catch (e) {
          print('Erreur lors du chargement des données: $e');
        }
      }
    });
  }

  void _showAccountDialog() {
    DialogCompte.show(
      context,
      onCompteSelectionne: (Account selectedAccount) {
        ref.read(selectedAccountProvider.notifier).state = selectedAccount;
        ref
            .read(transactionsStateProvider.notifier)
            .loadTransactions(selectedAccount.id);
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
          if (chantiers.isEmpty ||
              personnel.isEmpty ||
              types.isEmpty) {
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

  Widget _buildTransactionDetails(WidgetRef ref, Transaction transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Date:',
            DateFormat('dd/MM/yyyy HH:mm').format(transaction.transactionDate)),
        _detailRow('Type:', transaction.type == 'reçu' ? 'Reçu' : 'Payé'),
        _detailRow('Montant:', '${transaction.amount.toStringAsFixed(2)} \Ar'),
        if (transaction.description?.isNotEmpty ?? false)
          _detailRow('Description:', transaction.description!),

        // Chantier
        Consumer(
          builder: (context, ref, _) {
            final chantiersAsync = ref.watch(chantiersStateProvider);
            return chantiersAsync.when(
              data: (chantiers) {
                final chantier = chantiers.firstWhere(
                  (c) => c.id == transaction.chantierId,
                  orElse: () {
                    print(
                        'Chantier non trouvé pour l\'ID: ${transaction.chantierId}');
                    print(
                        'Chantiers disponibles: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');
                    return Chantier(id: '', name: 'Non trouvé', userId: '');
                  },
                );
                return _detailRow('Chantier:', chantier.name);
              },
              loading: () => _detailRow('Chantier:', 'Chargement...'),
              error: (error, stack) {
                print('Erreur lors du chargement des chantiers: $error');
                print(stack);
                return _detailRow('Chantier:', 'Erreur de chargement');
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
                    print(
                        'Personnel non trouvé pour l\'ID: ${transaction.personnelId}');
                    print(
                        'Personnel disponible: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');
                    return Personnel(id: '', name: 'Non trouvé', userId: '');
                  },
                );
                return _detailRow('Personnel:', person.name);
              },
              loading: () => _detailRow('Personnel:', 'Chargement...'),
              error: (error, stack) {
                print('Erreur lors du chargement du personnel: $error');
                print(stack);
                return _detailRow('Personnel:', 'Erreur de chargement');
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
                    print(
                        'Type de paiement non trouvé pour l\'ID: ${transaction.paymentTypeId}');
                    print(
                        'Types disponibles: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');
                    return PaymentType(
                        id: '', name: 'Non trouvé', category: '');
                  },
                );
                return _detailRow(
                    'Type de paiement:', '${type.name} (${type.category})');
              },
              loading: () => _detailRow('Type de paiement:', 'Chargement...'),
              error: (error, stack) {
                print(
                    'Erreur lors du chargement des types de paiement: $error');
                print(stack);
                return _detailRow('Type de paiement:', 'Erreur de chargement');
              },
            );
          },
        ),
      ],
    );
  }

// Widget helper pour l'affichage des détails
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xffea6b24),
              ),
            ),
          ),
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

  // Ajoutez cette méthode pour réinitialiser la date
  void _resetDate() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedTimeframeFilter = 'Tous';
      _value = 0;
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
      initialDateRange: _startDate != null && _endDate != null
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        _value = 0;
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
  void _printDateRange(String filterType) {
    final now = DateTime.now();
    switch (filterType) {
      case 'Hebdomadaire':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeek = DateTime(monday.year, monday.month, monday.day);
        final sunday = startOfWeek.add(const Duration(days: 6));
        print(
            'Week range: ${DateFormat('yyyy-MM-dd').format(startOfWeek)} to ${DateFormat('yyyy-MM-dd').format(sunday)}');
        break;
      case 'Mensuel':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        print(
            'Month range: ${DateFormat('yyyy-MM-dd').format(startOfMonth)} to ${DateFormat('yyyy-MM-dd').format(lastDay)}');
        break;
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((transaction) {
      // Vérification de la plage de dates
      bool matchesDateRange = true;
      if (_startDate != null && _endDate != null) {
        // Créer des DateTime pour le début et la fin de la journée
        final startDateTime =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final endDateTime = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

        matchesDateRange =
            transaction.transactionDate.isAtSameMomentAs(startDateTime) ||
                transaction.transactionDate.isAtSameMomentAs(endDateTime) ||
                (transaction.transactionDate.isAfter(startDateTime) &&
                    transaction.transactionDate.isBefore(endDateTime));
      }

      // Vérification de la recherche
      bool matchesSearchQuery = _searchQuery.isEmpty ||
          transaction.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true;

      // Vérification du filtre temporel
      bool matchesTimeframe = true;
      switch (_selectedTimeframeFilter) {
        case 'Quotidien':
          matchesTimeframe = _isToday(transaction.transactionDate);
          break;
        case 'Hebdomadaire':
          matchesTimeframe = _isThisWeek(transaction.transactionDate);
          break;
        case 'Mensuel':
          matchesTimeframe = _isThisMonth(transaction.transactionDate);
          break;
        case 'Annuel':
          matchesTimeframe = _isThisYear(transaction.transactionDate);
          break;
        case 'Tous':
        default:
          matchesTimeframe = true;
      }

      return matchesDateRange && matchesSearchQuery && matchesTimeframe;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final transactionsAsync = ref.watch(transactionsStateProvider);

    return Scaffold(
      appBar: SearchableAppBar(
        onTap: _showDateRangePicker,
        selectedAccount: selectedAccount,
        onAccountTap: _showAccountDialog,
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
              padding: const EdgeInsets.all(8.0),
              height: 60,
              decoration: const BoxDecoration(color: Color(0xffea6b24)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterChoice.length,
                itemBuilder: (context, index) {
                  return myChoiceChip(index);
                },
              ),
            ),
            //Container de resultat de filtre par chip
            Container(
              width: double.infinity,
              height: 40.0,
              decoration: const BoxDecoration(
                  color: Color(0xffea6b24),
                  border:
                      Border(top: BorderSide(width: 0.5, color: Colors.white))),
              child: Center(
                child: MyText(
                  texte: _selectedTimeframeFilter,
                  color: Colors.white,
                  fontSize: 16.0,
                ),
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
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter transactions based on selected filter
                  final visibleTransactions = filteredTransactions;

                  // Calculate totals based on filtered transactions
                  double totalReceived = 0;
                  double totalPaid = 0;

                  for (var transaction in visibleTransactions) {
                    if (transaction.type == 'reçu') {
                      totalReceived += transaction.amount;
                    } else {
                      totalPaid += transaction.amount;
                    }
                  }

                  final balance = totalReceived - totalPaid;
                  final totalBalance =
                      balance + (selectedAccount?.solde ?? 0.0);

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      TabHeader(
                                        flex: 2,
                                        text: 'Date',
                                      ),
                                      TabHeader(
                                        flex: 1,
                                        text: 'Reçu',
                                        textAlign: TextAlign.right,
                                      ),
                                      TabHeader(
                                        flex: 1,
                                        text: 'Payé',
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                                ...visibleTransactions.map((transaction) {
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
                      bottomSummary(totalReceived, totalPaid, totalBalance),
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
  Padding myChoiceChip(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        avatar: null,
        selectedColor: const Color(0xffea6b24),
        labelPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: Colors.white),
        label: Text(
          filterChoice[index],
          style: TextStyle(
              color: _value == index ? Colors.white : Colors.black,
              fontSize: 14.0),
        ),
        //selected: _value == index,
        selected: _selectedTimeframeFilter == filterChoice[index],
        onSelected: (bool selected) {
          setState(() {
            _value = selected ? index : 0;
            _selectedTimeframeFilter = selected ? filterChoice[index] : 'Tous';
          });
        },
      ),
    );
  }

  Container bottomSummary(
      double totalReceived, double totalPaid, double totalBalance) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: TabBottomResume(
          totalReceived: totalReceived,
          totalPaid: totalPaid,
          totalBalance: totalBalance),
    );
  }
}
