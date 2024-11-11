import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import 'accounts_provider.dart';

final transactionsStateProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>((ref) {
  return TransactionsNotifier(ref.read(databaseHelperProvider));
});

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsStateProvider);
  final selectedAccount = ref.watch(selectedAccountProvider);

  return transactions.when(
    data: (data) => data.where((t) => t.accountId == selectedAccount?.id).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final DatabaseHelper _db;

  TransactionsNotifier(this._db) : super(const AsyncValue.data([]));

  Future<void> loadTransactions(String accountId) async {
    print('Loading transactions for account: $accountId');
    state = const AsyncValue.loading();
    try {
      final transactions = await _db.getTransactions(accountId);
      print('Loaded ${transactions.length} transactions');
      state = AsyncValue.data(transactions);
    } catch (e, stackTrace) {
      print('Error loading transactions: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      print('Adding transaction: ${transaction.toJson()}');
      final newTransaction = await _db.createTransaction(transaction);
      print('Transaction added successfully: ${newTransaction.toJson()}');

      // Mettre à jour l'état avec la nouvelle transaction
      final currentTransactions = state.value ?? [];
      state = AsyncValue.data([...currentTransactions, newTransaction]);
    } catch (e, stackTrace) {
      print('Error in addTransaction: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      throw e; // Relancer l'erreur pour la gestion dans _saveTransaction
    }
  }
}