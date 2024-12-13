import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_caisse_flutter/providers/selected_chantier_personnel_provider.dart';
import '../services/database_helper.dart';

// Provider pour obtenir les totaux des transactions par chantier
final chantierTransactionsProvider = FutureProvider.family<Map<String, double>, String>((ref, chantierId) {
  final databaseHelper = ref.read(databaseHelperProvider);
  return databaseHelper.getChantierTransactionTotals(chantierId);
});

// Notifier pour gérer l'état des transactions de chantier
class ChantierTransactionsNotifier extends StateNotifier<AsyncValue<Map<String, double>>> {
  final Ref _ref;
  final DatabaseHelper _db;
  final String _chantierId;

  ChantierTransactionsNotifier(this._ref, this._db, this._chantierId)
      : super(const AsyncValue.loading()) {
    loadTransactionTotals();
  }

  Future<void> loadTransactionTotals() async {
    state = const AsyncValue.loading();
    try {
      final totals = await _db.getChantierTransactionTotals(_chantierId);
      state = AsyncValue.data(totals);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Provider de state pour les transactions de chantier
  final chantiersTransactionsStateProvider = StateNotifierProvider.family<ChantierTransactionsNotifier, AsyncValue<Map<String, double>>, String>((ref, chantierId) {
    return ChantierTransactionsNotifier(ref, ref.read(databaseHelperProvider), chantierId);
  });

  // Méthode pour rafraîchir les totaux des transactions
  Future<void> refreshTransactionTotals() async {
    try {
      final totals = await _db.getChantierTransactionTotals(_chantierId);
      state = AsyncValue.data(totals);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}