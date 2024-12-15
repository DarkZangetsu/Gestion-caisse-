import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/mode/dark_mode.dart';
import 'package:gestion_caisse_flutter/mode/light_mode.dart';
import 'package:gestion_caisse_flutter/models/chantier.dart';
import 'package:gestion_caisse_flutter/models/payment_type.dart';
import 'package:gestion_caisse_flutter/models/personnel.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_caisse_flutter/services/notification_manager.dart';
import 'package:gestion_caisse_flutter/services/work_manager_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../providers/accounts_provider.dart';
import '../providers/chantiers_provider.dart';
import '../providers/personnel_provider.dart';
import '../providers/payment_types_provider.dart';
import '../providers/todos_provider.dart';
import '../providers/users_provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late NotificationManager notificationManager;

  String? selectedChantierId;
  String? selectedPersonnelId;
  String? description;
  String? selectedPaymentMethodId;
  String? selectedPaymentTypeId;
  double? estimatedAmount;
  DateTime? dueDate;
  TimeOfDay? notificationTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_loadInitialData();
  }

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    notificationManager = NotificationManager(
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
    );
    _tabController = TabController(length: 2, vsync: this);

    // Initialiser le fuseau horaire de Madagascar
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Indian/Antananarivo'));

    _initializeServices();

    // Vérifier et reprogrammer les notifications au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //notificationManager.checkAndRescheduleNotifications();
      _loadInitialData();
    });
  }

  Future<void> _initializeServices() async {
    // Initialiser le fuseau horaire
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Indian/Antananarivo'));

    // Initialiser les notifications
    //await initializeNotifications(flutterLocalNotificationsPlugin);

    // Initialiser WorkManager
    await WorkManagerService.initialize();
  }

  // Helper function to generate unique notification IDs
  int uniqueNotificationId(String todoId, int index) {
    return int.parse(
        todoId.hashCode.toString().substring(0, 5) + index.toString());
  }

  Future<void> _selectNotificationTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (pickedTime != null) {
      setState(() {
        notificationTime = pickedTime;
      });
    }
  }

  // Ajouter cette nouvelle méthode pour obtenir le statut de la date d'échéance
  (String, Color) getDueDateStatus(DateTime dueDate) {
    final now = tz.TZDateTime.now(tz.getLocation('Indian/Antananarivo'));
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return ('En retard', Colors.red);
    } else if (difference == 0) {
      return ('Échéance aujourd\'hui', Colors.orange);
    } else if (difference == 1) {
      return ('Échéance demain', Colors.orange);
    } else if (difference <= 3) {
      return ('Échéance dans $difference jours', Colors.amber);
    } else {
      return ('', Colors.grey);
    }
  }

  Future<void> _loadInitialData() async {
    final selectedAccount = ref.read(selectedAccountProvider);
    if (selectedAccount != null) {
      try {
        // Charger les todos pour le compte sélectionné
        await ref
            .read(todosStateProvider.notifier)
            .getTodos(selectedAccount.id);

        // Charger les autres données nécessaires
        final userId = ref.read(currentUserProvider)?.id;
        if (userId != null) {
          await ref.read(chantiersStateProvider.notifier).loadChantiers(userId);
          await ref.read(paymentTypesProvider.notifier).getPaymentTypes();
          await ref.read(personnelStateProvider.notifier).getPersonnel(userId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des données: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddTodoDialog() {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
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
                        context: context,
                        items: chantiers,
                        labelText: 'Chantier (optionnel)',
                        placeholderText: "Sélectionner un chantier",
                        selectedValue: selectedChantierId,
                        onChanged: (value) {
                          setState(() => selectedChantierId = value);
                        },
                        getItemId: (chantier) => chantier.id,
                        getItemName: (chantier) => chantier.name,
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
                      data: (personnel) => myDropdownButtonFormField<Personnel>(
                        context: context,
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le montant est requis';
                    }
                    final number = double.tryParse(value);
                    if (number == null) {
                      return 'Montant invalide';
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
                          context: context,
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
                      cancelText: 'Annuler',
                      confirmText: 'Confirmer',
                      builder: (context, Widget? child) {
                        return Theme(
                          data: isDarkMode
                              ? darkTheme.copyWith(
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                )
                              : lightTheme.copyWith(
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                          child: child ?? const SizedBox(),
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => dueDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    notificationTime == null
                        ? 'Sélectionner une heure de notification'
                        : 'Notification: ${notificationTime!.format(context)}',
                    style: TextStyle(
                      color: notificationTime == null
                          ? Colors.grey[600]
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.access_time, color: Colors.grey),
                  onTap: () => _selectNotificationTime(),
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
              color: Colors.grey,
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
    required BuildContext context,
    required List<T> items,
    required String labelText,
    required String placeholderText,
    String? selectedValue,
    required void Function(String?) onChanged,
    required String Function(T) getItemId,
    required String Function(T) getItemName,
    String? Function(String?)? validator,
    bool isRequired = false,
    IconData? prefixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DropdownButtonFormField<String>(
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$labelText is required';
        }
        return validator?.call(value);
      },
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: colorScheme.primary)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: colorScheme.onSurface.withOpacity(0.7),
      ),
      value: selectedValue,
      hint: Text(
        placeholderText,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            placeholderText,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        ...items.map((item) {
          return DropdownMenuItem(
            value: getItemId(item),
            child: Text(
              getItemName(item),
              style: textTheme.bodyMedium,
            ),
          );
        }).toList(),
      ],
      onChanged: onChanged,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      dropdownColor: colorScheme.surface,
      isExpanded: true,
    );
  }

  void _printDebugInfo(String message) {
    if (mounted) {
      print('DEBUG: $message');
    }
  }

  Future<void> _saveDueDate(Todo todo) async {
    try {
      if (todo.dueDate != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dueDate', todo.dueDate!.toIso8601String());
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de la date d\'échéance: $e');
    }
  }

  Future<void> _saveTodo() async {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedAccount = ref.read(selectedAccountProvider);

      if (selectedAccount == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erreur: Aucun compte sélectionné'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      if (description == null || description!.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erreur: La description est requise'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      try {
        final uuid = Uuid();
        final uniqueId = uuid.v4();

        // Remove notificationTime from Todo object since it's not in the database schema
        final todo = Todo(
          id: uniqueId,
          accountId: selectedAccount.id,
          chantierId: selectedChantierId?.isNotEmpty == true
              ? selectedChantierId
              : null,
          personnelId: selectedPersonnelId?.isNotEmpty == true
              ? selectedPersonnelId
              : null,
          description: description!.trim(),
          estimatedAmount: estimatedAmount!,
          dueDate: dueDate,
          // Remove notificationTime field
          paymentMethodId: selectedPaymentMethodId?.isNotEmpty == true
              ? selectedPaymentMethodId
              : null,
          paymentTypeId: selectedPaymentTypeId?.isNotEmpty == true
              ? selectedPaymentTypeId
              : null,
          completed: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save the todo first
        await ref.read(todosStateProvider.notifier).createTodo(todo);

        if (todo.dueDate != null) {
          try {
            await WorkManagerService.scheduleNotification(
              todoId: todo.id,
              todoDescription: todo.description,
              dueDate: todo.dueDate!,
              notificationTime: notificationTime,
            );
          } catch (notifError) {
            print(
                'Erreur lors de la programmation des notifications: $notifError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'La tâche a été créée mais les notifications n\'ont pas pu être programmées'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Tâche créée avec succès'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print('Erreur détaillée lors de la création de la tâche: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erreur lors de la création de la tâche: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
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
        backgroundColor: const Color(0xff000000),
        bottom: TabBar(
          labelColor: Colors.white,
          controller: _tabController,
          tabs: const [
            Tab(text: 'À faire'),
            Tab(text: 'Terminées'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          // Écouter les changements dans le provider de todos
          final todosAsync = ref.watch(todosStateProvider);

          // Afficher les données en fonction de l'état
          return todosAsync.when(
            data: (todos) {
              if (todos.isEmpty) {
                return const Center(
                  child: Text('Aucune tâche disponible'),
                );
              }

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
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: $error',
                    textAlign: TextAlign.center,
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
        child: const Icon(Icons.add, color: Colors.white),
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
        final (dueDateStatus, statusColor) = todo.dueDate != null
            ? getDueDateStatus(todo.dueDate!)
            : ('', Colors.grey);
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
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: dueDateStatus.isNotEmpty
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
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
                              debugPrint("Erreur tâche: $e");
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
                              // Chercher le chantier de façon sécurisée
                              final chantier = chantiers
                                  .where((c) => c.id == todo.chantierId)
                                  .toList();

                              // Si aucun chantier n'est trouvé, afficher un message d'erreur
                              if (chantier.isEmpty) {
                                return _buildInfoRow(
                                  'Chantier',
                                  'Chantier non disponible (ID: ${todo.chantierId})',
                                );
                              }

                              // Si le chantier est trouvé, afficher ses informations
                              return _buildInfoRow(
                                  'Chantier', chantier.first.name);
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, stack) => _buildInfoRow(
                              'Chantier',
                              'Erreur de chargement du chantier',
                            ),
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
                                final person = personnel
                                    .where((p) => p.id == todo.personnelId)
                                    .toList();
                                if (person.isEmpty) {
                                  return _buildInfoRow(
                                    'Personnel',
                                    'Personnel non disponible (ID: ${todo.personnelId})',
                                  );
                                }
                                return _buildInfoRow(
                                    'Personnel', person.first.name);
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => _buildInfoRow(
                                'Personnel',
                                'Erreur de chargement du personnel',
                              ),
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
