import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../services/database_helper.dart';

final transactionsStateProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>((ref) {
  return TransactionsNotifier(ref.read(databaseHelperProvider));
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final DatabaseHelper _db;

  TransactionsNotifier(this._db) : super(const AsyncValue.data([]));

  Future<void> getTransactions(String accountId) async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _db.getTransactions(accountId);
      state = AsyncValue.data(transactions);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createTransaction(Transaction transaction) async {
    try {
      final newTransaction = await _db.createTransaction(transaction);
      state = AsyncValue.data([...state.value ?? [], newTransaction]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final updatedTransaction = await _db.updateTransaction(transaction);
      state = AsyncValue.data(
        (state.value ?? []).map((t) => t.id == transaction.id ? updatedTransaction : t).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _db.deleteTransaction(transactionId);
      state = AsyncValue.data(
        (state.value ?? []).where((t) => t.id != transactionId).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> getTransactionsByChantier(String chantierId) async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _db.getTransactionsByChantier(chantierId);
      state = AsyncValue.data(transactions);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> getTransactionsByPersonnel(String personnelId) async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _db.getTransactionsByPersonnel(personnelId);
      state = AsyncValue.data(transactions);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}