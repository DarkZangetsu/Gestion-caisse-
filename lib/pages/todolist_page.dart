import 'dart:convert';
import 'dart:io';
import 'package:caisse/composants/texts.dart';
import 'package:caisse/mode/dark_mode.dart';
import 'package:caisse/mode/light_mode.dart';
import 'package:caisse/models/chantier.dart';
import 'package:caisse/models/payment_type.dart';
import 'package:caisse/models/personnel.dart';
import 'package:caisse/pages/payment_page.dart';
import 'package:caisse/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  String? selectedChantierId;
  String? selectedPersonnelId;
  String? description;
  String? selectedPaymentMethodId;
  String? selectedPaymentTypeId;
  double? estimatedAmount;
  DateTime? dueDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialData();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    final userId = ref.read(currentUserProvider)?.id ?? '';
    ref.read(chantiersStateProvider.notifier).loadChantiers(userId);

    ref
        .read(chantiersStateProvider.notifier)
        .loadChantiers(ref.read(currentUserProvider)?.id ?? '');

    print(
        "user: ** ${ref.read(chantiersStateProvider.notifier).loadChantiers(ref.read(currentUserProvider)?.id ?? '')}");

    Future.microtask(() {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      ref.read(paymentTypesProvider.notifier).getPaymentTypes();
      ref.read(personnelStateProvider.notifier).getPersonnel(userId);
      ref.read(chantiersStateProvider.notifier).loadChantiers(userId);
    });
  }

  Future<void> _loadInitialData() async {
    final selectedAccount = ref.read(selectedAccountProvider);
    final userId = ref.read(currentUserProvider)?.id;

    if (selectedAccount != null && userId != null) {
      try {
        // Use the notifier to load chantiers
        await ref
            .read(chantiersStateProvider.notifier)
            .loadChantiers(selectedAccount.id);
      } catch (e) {
        print('Error loading chantiers: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des chantiers: $e'),
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

  Future<void> _saveTodo() async {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedAccount = ref.read(selectedAccountProvider);
      if (selectedAccount != null && description != null) {
        try {
          // Utilisez Uuid() pour générer un UUID v4 valide
          final uuid = Uuid();
          final uniqueId = uuid.v4();

          final todo = Todo(
            id: uniqueId,
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
          final notificationService = TodoNotificationService();
          await notificationService.scheduleTaskNotifications(todo);

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
                        style: TextStyle(
                          fontSize: 12,
                          color: todo.getDueDateColor(),
                          fontWeight: todo.isApproachingDueDate()
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

class TodoNotificationService {
  static final TodoNotificationService _instance =
      TodoNotificationService._internal();
  factory TodoNotificationService() => _instance;
  TodoNotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Constantes pour la configuration
  static const int _notificationHour = 8; // Notification à 8h du matin
  static const String _channelId = 'todo_alerts';
  static const String _channelName = 'Alertes des tâches';
  static const String _channelDescription =
      'Notifications pour les tâches à venir';
  static const Color _notificationColor = Color(0xffea6b24);

  Future<bool> initNotification() async {
    if (_isInitialized) return true;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      final success = await notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      _isInitialized = success ?? false;
      return _isInitialized;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des notifications: $e');
      return false;
    }
  }

  Future<void> _handleNotificationResponse(
      NotificationResponse response) async {
    if (response.payload == null) return;

    try {
      final payload = json.decode(response.payload!) as Map<String, dynamic>;
      debugPrint('Payload reçu: $payload');
    } catch (e) {
      debugPrint('Erreur lors du traitement de la notification: $e');
    }
  }

  Future<void> scheduleTaskNotifications(Todo todo) async {
    if (!_isInitialized || todo.dueDate == null) return;

    try {
      if (!await _checkNotificationPermissions()) {
        debugPrint('Permissions de notification non accordées');
        return;
      }

      await cancelTaskNotifications(todo.id);

      final alerts = [
        (days: 3, importance: Importance.defaultImportance),
        (days: 2, importance: Importance.high),
        (days: 1, importance: Importance.max),
      ];

      for (var alert in alerts) {
        final alertDate = _calculateAlertDateTime(todo.dueDate!, alert.days);

        if (alertDate.isAfter(tz.TZDateTime.now(tz.local))) {
          final payload = {
            'todoId': todo.id,
            'description': todo.description,
            'dueDate': todo.dueDate!.toIso8601String(),
            'alertDays': alert.days,
          };

          await notificationsPlugin.zonedSchedule(
            _generateNotificationId(todo.id, alert.days),
            'Rappel de tâche',
            _generateNotificationBody(todo, alert.days),
            alertDate,
            NotificationDetails(
              android: _createAndroidNotificationDetails(alert.importance),
              iOS: _createIOSNotificationDetails(),
            ),
            payload: json.encode(payload),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la programmation des notifications: $e');
    }
  }

  AndroidNotificationDetails _createAndroidNotificationDetails(
      Importance importance) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: importance,
      priority: Priority.high,
      color: _notificationColor,
      enableLights: true,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
    );
  }

  DarwinNotificationDetails _createIOSNotificationDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  tz.TZDateTime _calculateAlertDateTime(DateTime dueDate, int days) {
    final DateTime alertDate = dueDate.subtract(Duration(days: days));
    return tz.TZDateTime(
      tz.local,
      alertDate.year,
      alertDate.month,
      alertDate.day,
      _notificationHour, // Utilisation de la constante pour 8h
      0,
    );
  }

  String _generateNotificationBody(Todo todo, int days) {
    return 'La tâche "${todo.description}" arrive à échéance dans $days jour${days > 1 ? 's' : ''}';
  }

  int _generateNotificationId(String todoId, int days) {
    return (todoId + days.toString()).hashCode;
  }

  Future<bool> _checkNotificationPermissions() async {
    if (Platform.isAndroid) return true;

    if (Platform.isIOS) {
      final settings = await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return settings ?? false;
    }
    return false;
  }

  Future<void> cancelTaskNotifications(String todoId) async {
    try {
      for (var days in [3, 2, 1]) {
        await notificationsPlugin.cancel(_generateNotificationId(todoId, days));
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'annulation des notifications: $e');
    }
  }
}

class NotificationAlert {
  final int days;
  final Importance importance;

  NotificationAlert({
    required this.days,
    required this.importance,
  });
}

extension TodoNotifications on Todo {
  bool isApproachingDueDate() {
    if (dueDate == null) return false;
    final daysUntilDue = dueDate!.difference(DateTime.now()).inDays;
    return daysUntilDue <= 3 && daysUntilDue > 0;
  }

  Color getDueDateColor() {
    if (dueDate == null) return Colors.grey;
    if (completed) return Colors.green;

    final daysUntilDue = dueDate!.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) return Colors.red.shade700;
    if (daysUntilDue <= 1) return Colors.red;
    if (daysUntilDue <= 2) return Colors.orange;
    if (daysUntilDue <= 3) return Colors.yellow.shade700;
    return Colors.green;
  }
}
