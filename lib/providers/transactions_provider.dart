import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import 'accounts_provider.dart';


// Provider pour le DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Provider pour les transactions
final transactionsStateProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>(
        (ref) {
  return TransactionsNotifier(ref.read(databaseHelperProvider));
});

// Provider pour les transactions filtrées
final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  final transactions = ref.watch(transactionsStateProvider);
  final selectedAccount = ref.watch(selectedAccountProvider);

  return transactions.when(
    data: (data) {
      if (selectedAccount == null) return const AsyncValue.data([]);

      final filteredTransactions =
          data.where((t) => t.accountId == selectedAccount.id).toList();

      print(
          'Filtered transactions for account ${selectedAccount.id}: ${filteredTransactions.length}');
      return AsyncValue.data(filteredTransactions);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class TransactionsNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  final DatabaseHelper _db;
  TransactionsNotifier(this._db) : super(const AsyncValue.loading());

  Future<void> loadTransactions(String accountId) async {
    print('Starting to load transactions for account: $accountId');

    try {
      state = const AsyncValue.loading();
      final transactions = await _db.getTransactions(accountId);
      print(
          'Successfully loaded ${transactions.length} transactions for account $accountId');

      state = AsyncValue.data(transactions);
    } catch (e, stackTrace) {
      print('Error loading transactions: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      print('Adding new transaction: ${transaction.toJson()}');

      // Sauvegarder la transaction dans la base de données
      final newTransaction = await _db.createTransaction(transaction);
      print('Transaction successfully added with ID: ${newTransaction.id}');

      // Mettre à jour l'état avec la nouvelle transaction
      state.whenData((currentTransactions) {
        state = AsyncValue.data([...currentTransactions, newTransaction]);
      });

      // Recharger toutes les transactions pour s'assurer de la synchronisation
      await loadTransactions(transaction.accountId);
    } catch (e, stackTrace) {
      print('Error in addTransaction: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow; // Relancer l'erreur pour la gestion externe
    }
  }

  Future<void> loadTransactionsByChantier(String chantierId) async {
    try {
      state = const AsyncValue.loading();
      final transactions = await _db.getTransactionsByChantier(chantierId);
      state = AsyncValue.data(transactions);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Ajoutez cette méthode pour déboguer l'état actuel
  void debugCurrentState() {
    state.whenData((transactions) {
      print('Current state contains ${transactions.length} transactions');
      for (var transaction in transactions) {
        print('Transaction: ${transaction.toJson()}');
      }
    });
  }
}
