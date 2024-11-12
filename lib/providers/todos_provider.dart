import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';
import '../services/database_helper.dart';

final todosStateProvider = StateNotifierProvider<TodosNotifier, AsyncValue<List<Todo>>>((ref) {
  return TodosNotifier(ref.read(databaseHelperProvider));
});

class TodosNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  final DatabaseHelper _db;

  TodosNotifier(this._db) : super(const AsyncValue.data([]));

  Future<void> getTodos(String accountId) async {
    state = const AsyncValue.loading();
    try {
      final todos = await _db.getTodos(accountId);
      state = AsyncValue.data(todos);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createTodo(Todo todo) async {
    try {
      final newTodo = await _db.createTodo(todo);
      state = AsyncValue.data([...state.value ?? [], newTodo]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      // Mettre à jour la tâche dans la base de données
      final updatedTodo = await _db.updateTodo(todo);

      // Mettre à jour l'état dans l'AsyncValue
      state = AsyncValue.data(
        (state.value ?? [])
            .map((t) => t.id == updatedTodo.id ? updatedTodo : t)
            .toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteTodo(String todoId) async {
    try {
      await _db.deleteTodo(todoId);
      state = AsyncValue.data(
        (state.value ?? []).where((t) => t.id != todoId).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> getTodosByChantier(String chantierId) async {
    state = const AsyncValue.loading();
    try {
      final todos = await _db.getTodosByChantier(chantierId);
      state = AsyncValue.data(todos);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> getPendingTodos(String accountId) async {
    state = const AsyncValue.loading();
    try {
      final todos = await _db.getPendingTodos(accountId);
      state = AsyncValue.data(todos);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}