import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_method.dart';
import '../models/personnel.dart';
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
        await ref.read(chantiersStateProvider.notifier).getChantiers(selectedAccount.id);

        // Ensuite, charger les autres données
        await Future.wait([
          ref.read(personnelStateProvider.notifier).getPersonnel(selectedAccount.id),
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
                      data: (chantiers) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Chantier'),
                        value: selectedChantierId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sélectionner un chantier'),
                          ),
                          ...chantiers.map((chantier) {
                            return DropdownMenuItem(
                              value: chantier.id,
                              child: Text(chantier.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => selectedChantierId = value);
                        },
                      ),
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
                      data: (personnel) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Personnel'),
                        value: selectedPersonnelId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sélectionner un personnel'),
                          ),
                          ...personnel.map((person) {
                            return DropdownMenuItem(
                              value: person.id,
                              child: Text(person.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => selectedPersonnelId = value);
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Erreur: $error'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Description requise' : null,
                  onChanged: (value) => setState(() => description = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Montant estimé',
                    prefixText: 'Ar ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    final methodsAsync = ref.watch(paymentMethodsProvider);
                    return methodsAsync.when(
                      data: (methods) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Méthode de paiement',
                        ),
                        value: selectedPaymentMethodId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sélectionner une méthode'),
                          ),
                          ...methods.map((method) {
                            return DropdownMenuItem(
                              value: method.id,
                              child: Text(method.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => selectedPaymentMethodId = value);
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Erreur: $error'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final typesAsync = ref.watch(paymentTypesProvider);
                    return typesAsync.when(
                      data: (types) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Type de paiement',
                        ),
                        value: selectedPaymentTypeId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sélectionner un type'),
                          ),
                          ...types.map((type) {
                            return DropdownMenuItem(
                              value: type.id,
                              child: Text(type.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => selectedPaymentTypeId = value);
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Erreur: $error'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    dueDate == null
                        ? 'Sélectionner une échéance'
                        : 'Échéance: ${DateFormat('dd/MM/yyyy').format(dueDate!)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _saveTodo,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
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
            id: uniqueId,  // Maintenant c'est un UUID v4 valide
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
        title: const Text('Liste des tâches'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À faire'),
            Tab(text: 'Terminées'),
          ],
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final todosAsync = ref.watch(todosStateProvider);
          return todosAsync.when(
            data: (todos) {
              final pendingTodos = todos.where((todo) => !todo.completed).toList();
              final completedTodos = todos.where((todo) => todo.completed).toList();

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
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
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
              isCompleted ? Icons.check_circle_outline : Icons.assignment_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'Aucune tâche terminée'
                  : 'Aucune tâche en cours',
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
                title: const Text('Confirmation'),
                content: const Text('Voulez-vous vraiment supprimer cette tâche ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Non'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Oui'),
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
                  const SnackBar(
                    content: Text('Tâche supprimée avec succès'),
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
                    Text(
                      DateFormat('dd/MM/yyyy').format(todo.dueDate!),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (todo.estimatedAmount != null) ...[
                    const Icon(Icons.attach_money, size: 14),
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
                      // Créer la version mise à jour de la tâche
                      final updatedTodo = Todo(
                        id: todo.id,
                        accountId: todo.accountId,
                        chantierId: todo.chantierId,
                        personnelId: todo.personnelId,
                        description: todo.description,
                        estimatedAmount: todo.estimatedAmount,
                        dueDate: todo.dueDate,
                        paymentMethodId: todo.paymentMethodId,
                        paymentTypeId: todo.paymentTypeId,
                        completed: value,
                        createdAt: todo.createdAt,
                        updatedAt: DateTime.now(),
                      );

                      // Mettre à jour la tâche dans l'état
                      await ref.read(todosStateProvider.notifier).updateTodo(updatedTodo);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(value ? 'Tâche terminée' : 'Tâche réouverte'),
                            backgroundColor: value ? Colors.green : Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Erreur lors de la mise à jour de la tâche'),
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
                          final chantiersAsync = ref.watch(chantiersStateProvider);
                          return chantiersAsync.when(
                            data: (chantiers) {
                              final chantier = chantiers.firstWhere(
                                    (c) => c.id == todo.chantierId,
                                orElse: () => throw Exception('Chantier non trouvé'),
                              );
                              return _buildInfoRow('Chantier', chantier.name);
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('Chantier non disponible'),
                          );
                        },
                      ),
                      if (todo.personnelId != null)
                        Consumer(
                          builder: (context, ref, _) {
                            final personnelAsync = ref.watch(personnelStateProvider);
                            return personnelAsync.when(
                              data: (personnel) {
                                final person = personnel.firstWhere(
                                      (p) => p.id == todo.personnelId,
                                  orElse: () => throw Exception('Personnel non trouvé'),
                                );
                                return _buildInfoRow('Personnel', person.name);
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('Personnel non disponible'),
                            );
                          },
                        ),
                      if (todo.paymentMethodId != null)
                        Consumer(
                          builder: (context, ref, _) {
                            final methodsAsync = ref.watch(paymentMethodsProvider);
                            return methodsAsync.when(
                              data: (methods) {
                                final method = methods.firstWhere(
                                      (m) => m.id == todo.paymentMethodId,
                                  orElse: () => throw Exception('Méthode non trouvée'),
                                );
                                return _buildInfoRow('Méthode de paiement', method.name);
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('Méthode non disponible'),
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
                                  orElse: () => throw Exception('Type non trouvé'),
                                );
                                return _buildInfoRow('Type de paiement', type.name);
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('Type non disponible'),
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