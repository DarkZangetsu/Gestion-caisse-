import 'package:caisse/providers/users_provider.dart';
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
}