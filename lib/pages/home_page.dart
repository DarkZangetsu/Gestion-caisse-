import 'package:caisse/composants/custom_search_delegate.dart';
import 'package:caisse/composants/drawer_list_menu.dart';
import 'package:caisse/composants/empty_transaction_view.dart';
import 'package:caisse/composants/tab_bottom_resume.dart';
import 'package:caisse/composants/tab_header.dart';
import 'package:caisse/composants/text_transaction.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accounts.dart';
import '../models/chantier.dart';
import '../models/payment_method.dart';
import '../models/payment_type.dart';
import '../models/personnel.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
import '../providers/chantiers_provider.dart';
import '../providers/payment_methods_provider.dart';
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

          // Chargement des méthodes de paiement
          await ref.read(paymentMethodsProvider.notifier).getPaymentMethods();
          final methods = ref.read(paymentMethodsProvider).value ?? [];
          print('Méthodes de paiement chargées: ${methods.length}');
          print(
              'Méthodes: ${methods.map((m) => '${m.id}: ${m.name}').join(', ')}');

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
        ref.read(paymentMethodsProvider.notifier).getPaymentMethods(),
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
          final methodsState = ref.watch(paymentMethodsProvider);
          final typesState = ref.watch(paymentTypesProvider);

          // Afficher un indicateur de chargement si les données ne sont pas prêtes
          if (chantiersState.isLoading ||
              personnelState.isLoading ||
              methodsState.isLoading ||
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
              methodsState.hasError ||
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
          final methods = methodsState.value ?? [];
          final types = typesState.value ?? [];

          // Vérifier que toutes les données sont chargées
          if (chantiers.isEmpty ||
              personnel.isEmpty ||
              methods.isEmpty ||
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

        // Méthode de paiement
        Consumer(
          builder: (context, ref, _) {
            final methodsAsync = ref.watch(paymentMethodsProvider);
            return methodsAsync.when(
              data: (methods) {
                final method = methods.firstWhere(
                  (m) => m.id == transaction.paymentMethodId,
                  orElse: () {
                    print(
                        'Méthode de paiement non trouvée pour l\'ID: ${transaction.paymentMethodId}');
                    print(
                        'Méthodes disponibles: ${methods.map((m) => '${m.id}: ${m.name}').join(', ')}');
                    return PaymentMethod(
                        id: '', name: 'Non trouvé', createdAt: null);
                  },
                );
                return _detailRow('Mode de paiement:', method.name);
              },
              loading: () => _detailRow('Mode de paiement:', 'Chargement...'),
              error: (error, stack) {
                print(
                    'Erreur lors du chargement des méthodes de paiement: $error');
                print(stack);
                return _detailRow('Mode de paiement:', 'Erreur de chargement');
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
    if (_searchQuery.isEmpty && _selectedTimeframeFilter == 'Tous') {
      return transactions;
    }

    // Debug print for date ranges
    _printDateRange(_selectedTimeframeFilter);

    final String query = _searchQuery.toLowerCase();
    return transactions.where((transaction) {
      // First apply date filter
      bool passesDateFilter = true;
      if (_selectedTimeframeFilter != 'Tous') {
        final DateTime transactionDate = transaction.transactionDate;
        switch (_selectedTimeframeFilter) {
          case 'Quotidien':
            passesDateFilter = _isToday(transactionDate);
            break;
          case 'Hebdomadaire':
            passesDateFilter = _isThisWeek(transactionDate);
            break;
          case 'Mensuel':
            passesDateFilter = _isThisMonth(transactionDate);
            break;
          case 'Annuel':
            passesDateFilter = _isThisYear(transactionDate);
            break;
          default:
            passesDateFilter = true;
        }
      }

      // If doesn't pass date filter, no need to check search query
      if (!passesDateFilter) return false;

      // If there's no search query, return date filter result
      if (_searchQuery.isEmpty) return true;

      // Apply search filter
      final String description = transaction.description?.toLowerCase() ?? '';
      final String date = DateFormat('dd/MM/yyyy HH:mm')
          .format(transaction.transactionDate)
          .toLowerCase();
      final String amount = transaction.amount.toString();

      return description.contains(query) ||
          date.contains(query) ||
          amount.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final transactionsAsync = ref.watch(transactionsStateProvider);

    return Scaffold(
      appBar: SearchableAppBar(
        selectedAccount: selectedAccount,
        onAccountTap: _showAccountDialog,
        onSearch: (query) {
          setState(() {
            _searchQuery = query;
          });
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      avatar: null,
                      selectedColor: const Color(0xffea6b24),
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      side: const BorderSide(color: Colors.white),
                      label: Text(
                        filterChoice[index],
                        style: TextStyle(
                            color:
                                _value == index ? Colors.white : Colors.black,
                            fontSize: 14.0),
                      ),
                      //selected: _value == index,
                      selected: _selectedTimeframeFilter == filterChoice[index],
                      onSelected: (bool selected) {
                        setState(() {
                          _value = selected ? index : 0;
                          _selectedTimeframeFilter =
                              selected ? filterChoice[index] : 'Tous';
                        });
                      },
                    ),
                  );
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

                  final List<Transaction> filteredTransactions =
                      _filterTransactions(
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
                  final List<Transaction> visibleTransactions =
                      filteredTransactions;

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
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom summary
                      Container(
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
                      ),
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
}

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xffea6b24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 80,
                  child: Image.asset(
                    'img/Logo.png',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const MyText(
                  texte: "Menu Principal",
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          DrawerListMenu(
            icon: Icons.business,
            texte: "Chantier",
            onTap: () => Navigator.pushNamed(context, '/chantier'),
          ),
          DrawerListMenu(
            icon: Icons.people,
            texte: "Personnel",
            onTap: () => Navigator.pushNamed(context, '/personnel'),
          ),
          DrawerListMenu(
            icon: Icons.checklist,
            texte: "ToDo List",
            onTap: () => Navigator.pushNamed(context, '/todos'),
          ),
          const DrawerListMenu(icon: Icons.settings, texte: "Paramètres"),
          const DrawerListMenu(icon: Icons.help_outline, texte: "Aide"),
        ],
      ),
    );
  }
}

class MyPopupMenuButton extends StatelessWidget {
  const MyPopupMenuButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      color: Colors.white,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: "Recherche par mot clé",
          child: Text("Recherche par mot clé"),
        ),
        const PopupMenuItem(
          value: "Tous",
          child: Text("Tous"),
        ),
        const PopupMenuItem(
          value: "Quotidien",
          child: Text("Quotidien"),
        ),
        const PopupMenuItem(
          value: "Hebdomadaire",
          child: Text("Hebdomadaire"),
        ),
        const PopupMenuItem(
          value: "Mensuel",
          child: Text("Mensuel"),
        ),
        const PopupMenuItem(
          value: "Annuel",
          child: Text("Annuel"),
        ),
        const PopupMenuItem(
          value: "Date",
          child: Text("Date"),
        ),
        const PopupMenuItem(
          value: "Sélectionnez une période",
          child: Text("Sélectionnez une période"),
        ),
        const PopupMenuItem(
          value: "Rapports",
          child: Text("Rapports"),
        ),
        const PopupMenuItem(
          value: "Date Ascendant",
          child: Text("Date Ascendant"),
        ),
        const PopupMenuItem(
          value: "Date Descendant",
          child: Text("Date Descendant"),
        ),
      ],
      onSelected: (String newValue) {},
    );
  }
}

class AppbarActionList extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final void Function()? onPressed;

  const AppbarActionList({
    super.key,
    required this.icon,
    this.color = Colors.white,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: color,
      splashRadius: 24,
      tooltip: 'Action',
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.1),
    );
  }
}

class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(transaction.transactionDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty)
                      Text(
                        transaction.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text_transaction(
                text: 'reçu',
                transaction: transaction,
                color: Colors.green,
              ),
              Text_transaction(
                text: 'payé',
                transaction: transaction,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
