import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_method.dart';
import '../services/database_helper.dart';

final paymentMethodsProvider = StateNotifierProvider<PaymentMethodsNotifier, AsyncValue<List<PaymentMethod>>>((ref) {
  return PaymentMethodsNotifier(ref.read(databaseHelperProvider));
});

class PaymentMethodsNotifier extends StateNotifier<AsyncValue<List<PaymentMethod>>> {
  final DatabaseHelper _db;

  PaymentMethodsNotifier(this._db) : super(const AsyncValue.data([]));

  Future<void> getPaymentMethods() async {
    state = const AsyncValue.loading();
    try {
      final methods = await _db.getPaymentMethods();
      state = AsyncValue.data(methods);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}