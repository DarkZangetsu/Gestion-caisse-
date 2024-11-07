import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/accounts.dart';
import '../services/database_helper.dart';

final accountsStateProvider = StateNotifierProvider<AccountsNotifier, AsyncValue<List<Account>>>((ref) {
  return AccountsNotifier(ref.read(databaseHelperProvider));
});

class AccountsNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final DatabaseHelper _db;

  AccountsNotifier(this._db) : super(const AsyncValue.data([]));

  Future<void> getAccounts(String userId) async {
    state = const AsyncValue.loading();
    try {
      final accounts = await _db.getAccounts(userId);
      state = AsyncValue.data(accounts);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createAccount(Account account) async {
    try {
      final newAccount = await _db.createAccount(account);
      state = AsyncValue.data([...state.value ?? [], newAccount]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      final updatedAccount = await _db.updateAccount(account);
      state = AsyncValue.data(
        (state.value ?? []).map((a) => a.id == account.id ? updatedAccount : a).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _db.deleteAccount(accountId);
      state = AsyncValue.data(
        (state.value ?? []).where((a) => a.id != accountId).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
