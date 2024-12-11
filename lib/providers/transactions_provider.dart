import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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

  Future<void> loadTransactions() async {
    print('Starting to load all transactions');

    try {
      state = const AsyncValue.loading();
      final transactions = await _db.getAllTransactions();
      print('Successfully loaded ${transactions.length} transactions');

      // Utilisez une méthode plus sûre pour mettre à jour l'état
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
      //await loadTransactions(transaction.accountId);
      await loadTransactions();
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

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      print('Updating transaction: ${transaction.toJson()}');

      final updatedTransaction = await _db.updateTransaction(transaction);
      print('Transaction successfully updated with ID: ${updatedTransaction.id}');

      // Utilisez une approche de mise à jour plus robuste
      state = await AsyncValue.guard(() async {
        final currentTransactions = state.value ?? [];
        final index = currentTransactions.indexWhere((t) => t.id == transaction.id);

        if (index != -1) {
          final updatedTransactions = List<Transaction>.from(currentTransactions);
          updatedTransactions[index] = updatedTransaction;
          return updatedTransactions;
        }

        return currentTransactions;
      });

      await loadTransactions();
    } catch (e, stackTrace) {
      print('Error in updateTransaction: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      print('Deleting transaction with ID: $transactionId');

      // Delete the transaction from the database
      await _db.deleteTransaction(transactionId);
      print('Transaction successfully deleted');

      // Update the state by removing the deleted transaction
      state.whenData((currentTransactions) {
        final updatedTransactions =
        currentTransactions.where((t) => t.id != transactionId).toList();
        state = AsyncValue.data(updatedTransactions);
      });

      // Reload all transactions to ensure synchronization
      await loadTransactions();
    } catch (e, stackTrace) {
      print('Error in deleteTransaction: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> createTransferTransaction({
    required String sourceAccountId,
    required String destinationAccountId,
    required double amount,
    required String sourceAccountName,
    required String destinationAccountName,
  }) async {
    try {
      // Création de la transaction de dépense (compte source)
      final sourceTransaction = Transaction(
        id: const Uuid().v4(), // Assurez-vous d'importer package:uuid/uuid.dart
        accountId: sourceAccountId,
        amount: amount,
        type: 'payé',
        description: 'Transfert à ${destinationAccountName}',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Création de la transaction de recette (compte destination)
      final destinationTransaction = Transaction(
        id: const Uuid().v4(),
        accountId: destinationAccountId,
        amount: amount,
        type: 'reçu',
        description: 'Transfert de ${sourceAccountName}',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Enregistrement des deux transactions
      await _db.createTransaction(sourceTransaction);
      await _db.createTransaction(destinationTransaction);

      // Mise à jour de l'état avec les nouvelles transactions
      state.whenData((currentTransactions) {
        state = AsyncValue.data([
          ...currentTransactions,
          sourceTransaction,
          destinationTransaction,
        ]);
      });
    } catch (e, stackTrace) {
      print('Error in createTransferTransaction: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
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
