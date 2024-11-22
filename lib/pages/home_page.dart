import 'package:caisse/pages/payment_page.dart';
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
  final filterChoice = ["Tous", "Quotidien", "Hebdomadaire", "Mensuel", "Annuel"];

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
          print('Chantiers: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');

          // Chargement du personnel
          await ref.read(personnelStateProvider.notifier).getPersonnel(userId);
          final personnel = ref.read(personnelStateProvider).value ?? [];
          print('Personnel chargé: ${personnel.length}');
          print('Personnel: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');

          // Chargement des méthodes de paiement
          await ref.read(paymentMethodsProvider.notifier).getPaymentMethods();
          final methods = ref.read(paymentMethodsProvider).value ?? [];
          print('Méthodes de paiement chargées: ${methods.length}');
          print('Méthodes: ${methods.map((m) => '${m.id}: ${m.name}').join(', ')}');

          // Chargement des types de paiement
          await ref.read(paymentTypesProvider.notifier).getPaymentTypes();
          final types = ref.read(paymentTypesProvider).value ?? [];
          print('Types de paiement chargés: ${types.length}');
          print('Types: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');

          // Chargement des transactions
          await ref.read(transactionsStateProvider.notifier).loadTransactions(selectedAccount.id);
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
        ref.read(transactionsStateProvider.notifier).loadTransactions(selectedAccount.id);
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
              content: const Text('Une erreur est survenue lors du chargement des données.'),
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
          if (chantiers.isEmpty || personnel.isEmpty || methods.isEmpty || types.isEmpty) {
            return AlertDialog(
              title: const Text('Données manquantes'),
              content: const Text('Certaines données n\'ont pas pu être chargées.'),
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
        _detailRow('Date:', DateFormat('dd/MM/yyyy HH:mm').format(transaction.transactionDate)),
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
                    print('Chantier non trouvé pour l\'ID: ${transaction.chantierId}');
                    print('Chantiers disponibles: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');
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
                    print('Personnel non trouvé pour l\'ID: ${transaction.personnelId}');
                    print('Personnel disponible: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');
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
                    print('Méthode de paiement non trouvée pour l\'ID: ${transaction.paymentMethodId}');
                    print('Méthodes disponibles: ${methods.map((m) => '${m.id}: ${m.name}').join(', ')}');
                    return PaymentMethod(id: '', name: 'Non trouvé', createdAt: null);
                  },
                );
                return _detailRow('Mode de paiement:', method.name);
              },
              loading: () => _detailRow('Mode de paiement:', 'Chargement...'),
              error: (error, stack) {
                print('Erreur lors du chargement des méthodes de paiement: $error');
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
                    print('Type de paiement non trouvé pour l\'ID: ${transaction.paymentTypeId}');
                    print('Types disponibles: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');
                    return PaymentType(id: '', name: 'Non trouvé', category: '');
                  },
                );
                return _detailRow('Type de paiement:', '${type.name} (${type.category})');
              },
              loading: () => _detailRow('Type de paiement:', 'Chargement...'),
              error: (error, stack) {
                print('Erreur lors du chargement des types de paiement: $error');
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
                color:  Color(0xffea6b24),
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


  @override
  Widget build(BuildContext context) {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final transactionsAsync = ref.watch(transactionsStateProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffea6b24),
        title: Expanded(
          child: TextButton(
            onPressed: _showAccountDialog,
            child: Row(
              children: [
                Text(
                  selectedAccount?.name ?? 'Livre de Caisse',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.0),
                ),
                const Icon(Icons.arrow_drop_down_outlined, color: Colors.white),
              ],
            ),
          ),
        ),
        actions: const [
          AppbarActionList(icon: Icons.list_alt_outlined, color: Colors.white),
          AppbarActionList(icon: Icons.search, color: Colors.white),
          AppbarActionList(icon: Icons.more_vert),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xffea6b24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Menu Principal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
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
            //const DrawerListMenu(icon: Icons.list_alt_rounded, texte: "Résumé"),
            //const DrawerListMenu(icon: Icons.list_alt_rounded, texte: "Comptes Résumé"),
            const DrawerListMenu(icon: Icons.list, texte: "Transactions-Tous les"),
            //const DrawerListMenu(icon: Icons.group, texte: "Comptes"),
            const DrawerListMenu(icon: Icons.swap_horiz, texte: "Transférer"),
            //const DrawerListMenu(icon: Icons.save_sharp, texte: "Rapports-Tous les comptes"),
            //const DrawerListMenu(icon: Icons.swap_horiz, texte: "Changer en Revenu Dépenses"),
            const DrawerListMenu(icon: Icons.money_rounded, texte: "Calculatrice de trésorerie"),
            //const DrawerListMenu(icon: Icons.swap_vert, texte: "Sauvegarde et Restauration"),
            const DrawerListMenu(icon: Icons.settings, texte: "Paramètres"),
            const DrawerListMenu(icon: Icons.help_outline, texte: "Aide"),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              height: 60,
              decoration: const BoxDecoration(color: Colors.blue),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterChoice.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      selectedColor: Colors.blue,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: const BorderSide(color: Colors.white),
                      label: Text(
                        filterChoice[index],
                        style: TextStyle(color: _value == index ? Colors.white : Colors.black, fontSize: 14.0),
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune transaction',
                            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/payement'),
                            child: const Text("Ajouter une transaction"),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredTransactions = transactions.where((t) => t.accountId == selectedAccount?.id).toList();
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
                  final totalBalance = balance + (selectedAccount?.solde ?? 0.0);

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
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Date',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Reçu',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Payé',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...filteredTransactions.map((transaction) {
                                  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                                  return InkWell(
                                    onTap: () => _showTransactionDetails(transaction),
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
                                                  if (transaction.description != null && transaction.description!.isNotEmpty)
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
                                            Expanded(
                                              child: Text(
                                                transaction.type == 'reçu'
                                                    ? transaction.amount.toStringAsFixed(2)
                                                    : '',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                transaction.type == 'payé'
                                                    ? transaction.amount.toStringAsFixed(2)
                                                    : '',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
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
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Reçu: ${totalReceived.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  "Total Payé: ${totalPaid.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Solde Total:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  totalBalance.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: totalBalance >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    label: const Text("Réçu", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PaymentPage(initialType: 'reçu'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.remove, color: Colors.white),
                                    label: const Text("Payé", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PaymentPage(initialType: 'payé'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

class DrawerListMenu extends StatelessWidget {
  final IconData icon;
  final String texte;
  final GestureTapCallback? onTap;

  const DrawerListMenu({
    super.key,
    required this.icon,
    required this.texte,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue,
        size: 24,
      ),
      title: Text(
        texte,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      hoverColor: Colors.blue.withOpacity(0.1),
      selectedTileColor: Colors.blue.withOpacity(0.1),
    );
  }
}

class AppbarActionList extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const AppbarActionList({
    super.key,
    required this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: color,
      splashRadius: 24,
      tooltip: 'Action',
      onPressed: () {},
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