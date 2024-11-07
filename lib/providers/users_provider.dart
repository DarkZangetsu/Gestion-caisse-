import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/database_helper.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());

final userStateProvider = StateNotifierProvider<UserNotifier, AsyncValue<AppUser?>>((ref) {
  return UserNotifier(ref.read(databaseHelperProvider));
});

class UserNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final DatabaseHelper _db;

  UserNotifier(this._db) : super(const AsyncValue.data(null));

  Future<void> createUser(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _db.createUser(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signInUser(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _db.signInUser(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOutUser() async {
    state = const AsyncValue.data(null);
    await _db.signOutUser();
  }
}