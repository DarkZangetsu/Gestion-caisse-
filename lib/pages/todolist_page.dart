import 'package:caisse/composants/texts.dart';
import 'package:caisse/models/chantier.dart';
import 'package:caisse/models/payment_type.dart';
import 'package:caisse/models/personnel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../providers/accounts_provider.dart';
import '../providers/chantiers_provider.dart';
import '../providers/personnel_provider.dart';
import '../providers/payment_methods_provider.dart';
import '../providers/payment_types_provider.dart';
import '../providers/todos_provider.dart';
import '../providers/users_provider.dart';
import 'package:intl/intl.dart';

class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();

  String? selectedChantierId;
  String? selectedPersonnelId;
  String? description;
  String? selectedPaymentMethodId;
  String? selectedPaymentTypeId;
  double? estimatedAmount;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final selectedAccount = ref.read(selectedAccountProvider);
    final userId = ref.read(currentUserProvider)?.id;

    if (selectedAccount != null && userId != null) {
      try {
        // Charger les chantiers en premier
        await ref
            .read(chantiersStateProvider.notifier)
            .getChantiers(selectedAccount.id);

        // Charger les autres données en parallèle
        await Future.wait([
          ref
              .read(personnelStateProvider.notifier)
              .getPersonnel(selectedAccount.id),
          ref.read(paymentMethodsProvider.notifier).getPaymentMethods(),
          ref.read(paymentTypesProvider.notifier).getPaymentTypes(),
          ref.read(todosStateProvider.notifier).getTodos(selectedAccount.id),
        ]);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du chargement des données'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddTodoDialog() {
    setState(() {
      selectedChantierId = null;
      selectedPersonnelId = null;
      description = null;
      selectedPaymentMethodId = null;
      selectedPaymentTypeId = null;
      estimatedAmount = null;
      dueDate = null;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Nouvelle tâche'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final chantiersAsync = ref.watch(chantiersStateProvider);
                    return chantiersAsync.when(
                      data: (chantiers) => myDropdownButtonFormField<Chantier>(
                          items: chantiers,
                          labelText: 'Chantier',
                          placeholderText: 'Sélectionner un chantier',
                          selectedValue: selectedChantierId,
                          onChanged: (value) =>
                              setState(() => selectedChantierId = value),
                          getItemId: (chantier) => chantier.id,
                          getItemName: (chantier) => chantier.name),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Erreur: $error'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final personnelAsync = ref.watch(personnelStateProvider);
                    return personnelAsync.when(
                      data: (personnel) => myDropdownButtonFormField<Personnel>(
                        items: personnel,
                        labelText: "Personnel",
                        placeholderText: "Sélectionner un personnel",
                        selectedValue: selectedPersonnelId,
                        onChanged: (value) {
                          setState(() => selectedPersonnelId = value);
                        },
                        getItemId: (person) => person.id,
                        getItemName: (person) => person.name,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Erreur: $error'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.description,
                      color: Colors.grey,
                    ),
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Description requise' : null,
                  onChanged: (value) => setState(() => description = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.wallet,
                      color: Colors.grey,
                    ),
                    labelText: 'Montant estimé',
                    prefixText: 'Ar ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final number = double.tryParse(value);
                      if (number == null) {
                        return 'Montant invalide';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() => estimatedAmount = double.tryParse(value));
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final typesAsync = ref.watch(paymentTypesProvider);
                    return typesAsync.when(
                      data: (types) => myDropdownButtonFormField<PaymentType>(
                          items: types,
                          labelText: 'Type de paiement',
                          placeholderText: 'Sélectionner un type',
                          selectedValue: selectedPaymentTypeId,
                          onChanged: (value) =>
                              setState(() => selectedPaymentTypeId = value),
                          getItemId: (type) => type.id,
                          getItemName: (type) => type.name),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Erreur: $error'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    dueDate == null
                        ? 'Sélectionner une échéance'
                        : 'Échéance: ${DateFormat('dd/MM/yyyy').format(dueDate!)}',
                    style: TextStyle(
                      color:
                          dueDate == null ? Colors.grey[600] : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing:
                      const Icon(Icons.calendar_today, color: Colors.grey),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => dueDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const MyText(
              texte: 'Annuler',
              color: Colors.black54,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffea6b24)),
            onPressed: _saveTodo,
            child: const MyText(
              texte: 'Enregistrer',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  DropdownButtonFormField<String> myDropdownButtonFormField<T>({
    required List<T> items,
    required String labelText,
    required String placeholderText,
    required String? selectedValue,
    required void Function(String?) onChanged,
    required String Function(T) getItemId,
    required String Function(T) getItemName,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: secondary,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xffea6b24)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          //borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      icon: const Icon(Icons.payment, color: Colors.grey),
      value: selectedValue,
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            placeholderText,
            style: TextStyle(color: Colors.grey[800]),
          ),
        ),
        ...items.map((item) {
          return DropdownMenuItem(
            value: getItemId(item),
            child: Text(getItemName(item)),
          );
        }).toList(),
      ],
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      dropdownColor: Colors.white,
    );
  }

  void _printDebugInfo(String message) {
    if (mounted) {
      print('DEBUG: $message');
    }
  }

  Future<void> _saveTodo() async {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedAccount = ref.read(selectedAccountProvider);
      if (selectedAccount != null && description != null) {
        try {
          // Utilisez Uuid() pour générer un UUID v4 valide
          final uuid = Uuid();
          final uniqueId = uuid.v4();

          final todo = Todo(
            id: uniqueId, // Maintenant c'est un UUID v4 valide
            accountId: selectedAccount.id,
            chantierId: selectedChantierId,
            personnelId: selectedPersonnelId,
            description: description!,
            estimatedAmount: estimatedAmount,
            dueDate: dueDate,
            paymentMethodId: selectedPaymentMethodId,
            paymentTypeId: selectedPaymentTypeId,
            completed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await ref.read(todosStateProvider.notifier).createTodo(todo);

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tâche créée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la création de la tâche: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const MyText(
          texte: 'Liste des tâches',
          color: Colors.white,
        ),
        backgroundColor: const Color(0xffea6b24),
        bottom: TabBar(
          labelColor: Colors.white,
          controller: _tabController,
          tabs: const [
            Tab(text: 'À faire'),
            Tab(text: 'Terminées'),
          ],
        ),
        actions: [
          // Ajouter un bouton de rafraîchissement manuel
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final todosAsync = ref.watch(todosStateProvider);
          return todosAsync.when(
            data: (todos) {
              final pendingTodos =
                  todos.where((todo) => !todo.completed).toList();
              final completedTodos =
                  todos.where((todo) => todo.completed).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTodoList(pendingTodos, false),
                  _buildTodoList(completedTodos, true),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur lors du chargement des tâches',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffea6b24),
        onPressed: _showAddTodoDialog,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos, bool isCompleted) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle_outline
                  : Icons.assignment_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? 'Aucune tâche terminée' : 'Aucune tâche en cours',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: todos.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Dismissible(
          key: Key(todo.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                title: const Text('Confirmation'),
                content:
                    const Text('Voulez-vous vraiment supprimer cette tâche ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const MyText(texte: 'Non', color: Colors.black54),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffea6b24)),
                    child: const MyText(texte: 'Oui', color: Colors.white),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) async {
            try {
              await ref.read(todosStateProvider.notifier).deleteTodo(todo.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Tâche "${todo.description}" supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la suppression de la tâche'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Card(
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              title: Text(
                todo.description,
                style: TextStyle(
                  decoration: todo.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Row(
                children: [
                  if (todo.dueDate != null) ...[
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(todo.dueDate!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (todo.estimatedAmount != null) ...[
                    //const Icon(Icons.attach_money, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat('#,###').format(todo.estimatedAmount)} Ar',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              trailing: todo.completed
                  ? null
                  : Checkbox(
                      value: todo.completed,
                      onChanged: (bool? value) async {
                        if (value != null) {
                          try {
                            final updatedTodo = Todo(
                              id: todo.id,
                              accountId: todo.accountId,
                              chantierId: todo.chantierId,
                              personnelId: todo.personnelId,
                              description: todo.description,
                              estimatedAmount: todo.estimatedAmount,
                              dueDate: todo.dueDate,
                              paymentTypeId: todo.paymentTypeId,
                              completed: value,
                              createdAt: todo.createdAt,
                              updatedAt: DateTime.now(),
                            );

                            await ref
                                .read(todosStateProvider.notifier)
                                .updateTodo(updatedTodo);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value
                                      ? 'Tâche terminée'
                                      : 'Tâche réouverte'),
                                  backgroundColor:
                                      value ? Colors.green : Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Erreur lors de la mise à jour de la tâche'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final chantiersAsync =
                              ref.watch(chantiersStateProvider);
                          return chantiersAsync.when(
                            data: (chantiers) {
                              final chantier = chantiers.firstWhere(
                                (c) => c.id == todo.chantierId,
                                orElse: () =>
                                    throw Exception('Chantier non trouvé'),
                              );
                              return _buildInfoRow('Chantier', chantier.name);
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) =>
                                const Text('Chantier non disponible'),
                          );
                        },
                      ),
                      if (todo.personnelId != null)
                        Consumer(
                          builder: (context, ref, _) {
                            final personnelAsync =
                                ref.watch(personnelStateProvider);
                            return personnelAsync.when(
                              data: (personnel) {
                                final person = personnel.firstWhere(
                                  (p) => p.id == todo.personnelId,
                                  orElse: () =>
                                      throw Exception('Personnel non trouvé'),
                                );
                                return _buildInfoRow('Personnel', person.name);
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) =>
                                  const Text('Personnel non disponible'),
                            );
                          },
                        ),
                      if (todo.paymentTypeId != null)
                        Consumer(
                          builder: (context, ref, _) {
                            final typesAsync = ref.watch(paymentTypesProvider);
                            return typesAsync.when(
                              data: (types) {
                                final type = types.firstWhere(
                                  (t) => t.id == todo.paymentTypeId,
                                  orElse: () =>
                                      throw Exception('Type non trouvé'),
                                );
                                return _buildInfoRow(
                                    'Type de paiement', type.name);
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) =>
                                  const Text('Type non disponible'),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Créée le',
                        DateFormat('dd/MM/yyyy HH:mm').format(todo.createdAt),
                      ),
                      _buildInfoRow(
                        'Mise à jour le',
                        DateFormat('dd/MM/yyyy HH:mm').format(todo.updatedAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
