import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chantier.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';

// Provider pour le DatabaseHelper
final databaseHelperProvider = Provider((ref) => DatabaseHelper());

// Provider pour le chantier sélectionné
final selectedChantierProvider = StateProvider<Chantier?>((ref) => null);

// Provider pour les transactions
final transactionStateProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return TransactionNotifier(databaseHelper);
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final DatabaseHelper _databaseHelper;

  TransactionNotifier(this._databaseHelper) : super(const AsyncValue.data([]));

  Future<void> loadTransactionsByChantier(String chantierId) async {
    try {
      state = const AsyncValue.loading();

      if (chantierId.isEmpty) {
        print('Error: Empty chantierId');
        throw Exception('ID du chantier invalide');
      }

      print('Attempting to load transactions for chantierId: $chantierId');

      final transactions = await _databaseHelper.getTransactionsByChantier(chantierId);

      print('Transactions loaded: ${transactions.length}');
      print('Transaction details: ${transactions.map((t) => t.toJson())}');

      state = AsyncValue.data(transactions);
    } catch (error, stackTrace) {
      print('Full error loading transactions: $error');
      print('Stacktrace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void resetTransactions() {
    state = const AsyncValue.data([]);
  }
}