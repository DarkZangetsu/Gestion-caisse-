import 'package:gestion_caisse_flutter/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_type.dart';
import '../services/database_helper.dart';

final paymentTypesProvider = StateNotifierProvider<PaymentTypesNotifier, AsyncValue<List<PaymentType>>>((ref) {
  return PaymentTypesNotifier(ref.read(databaseHelperProvider));
});

class PaymentTypesNotifier extends StateNotifier<AsyncValue<List<PaymentType>>> {
  final DatabaseHelper _db;

  PaymentTypesNotifier(this._db) : super(const AsyncValue.data([]));

  Future<void> getPaymentTypes() async {
    state = const AsyncValue.loading();
    try {
      final types = await _db.getPaymentTypes();
      state = AsyncValue.data(types);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createPaymentType(PaymentType paymentType) async {
    try {
      final newType = await _db.createPaymentType(paymentType);
      final currentTypes = state.value ?? [];
      state = AsyncValue.data([...currentTypes, newType]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updatePaymentType(PaymentType paymentType) async {
    try {
      final updatedType = await _db.updatePaymentType(paymentType);
      final currentTypes = state.value ?? [];
      final updatedTypes = currentTypes.map((type) {
        return type.id == updatedType.id ? updatedType : type;
      }).toList();
      state = AsyncValue.data(updatedTypes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deletePaymentType(String paymentTypeId) async {
    try {
      await _db.deletePaymentType(paymentTypeId);
      final currentTypes = state.value ?? [];
      final updatedTypes = currentTypes.where((type) => type.id != paymentTypeId).toList();
      state = AsyncValue.data(updatedTypes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Méthode utilitaire pour rafraîchir la liste
  Future<void> refreshPaymentTypes() async {
    await getPaymentTypes();
  }
}