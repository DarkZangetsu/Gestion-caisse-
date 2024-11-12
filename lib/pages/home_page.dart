import 'package:caisse/composants/boutons.dart';
import 'package:caisse/composants/custom_search_delegate.dart';
import 'package:caisse/composants/drawer_list_menu.dart';
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
  final filterChoice = [
    "Tous",
    "Quotidien",
    "Hebdomadaire",
    "Mensuel",
    "Annuel"
  ];
  String _searchQuery = '';
  bool isSearching = false;
  FocusNode focusNode = FocusNode();

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
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          // Afficher une erreur si le chargement a échoué
          if (chantiersState.hasError ||
              personnelState.hasError ||
              methodsState.hasError ||
              typesState.hasError) {
            return AlertDialog(
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
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
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }

    final query = _searchQuery.toLowerCase();
    return transactions.where((transaction) {
      final description = transaction.description?.toLowerCase() ?? '';
      final date = DateFormat('dd/MM/yyyy HH:mm')
          .format(transaction.transactionDate)
          .toLowerCase();
      final amount = transaction.amount.toString();

      return description.contains(query) ||
          date.contains(query) ||
          amount.contains(query);
    }).toList();
  }

  Icon actionIcon = Icon(Icons.search);
  late Widget appBarTitle;

  void _handleSearch(String query) {
    // Implement search logic here
    print('Searching for: $query');
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
                      selected: _value == index,
                      onSelected: (bool selected) {
                        setState(() {
                          _value = selected ? index : null;
                        });
                      },
                    ),
                  );
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
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
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
                                ...filteredTransactions.map((transaction) {
                                  final dateFormat =
                                      DateFormat('dd/MM/yyyy HH:mm');
                                  return InkWell(
                                    onTap: () =>
                                        _showTransactionDetails(transaction),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey[200]!),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    dateFormat.format(
                                                        transaction
                                                            .transactionDate),
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                  if (transaction.description !=
                                                          null &&
                                                      transaction.description!
                                                          .isNotEmpty)
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

// Extracted widgets for better organization
class EmptyTransactionView extends StatelessWidget {
  const EmptyTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune transaction',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          MyButtons(
            backgroundColor: const Color(0xffea6b24),
            onPressed: () => Navigator.pushNamed(context, '/payement'),
            child: const MyText(
              texte: "Ajouter une transaction",
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
