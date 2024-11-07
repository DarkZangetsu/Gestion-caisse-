import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chantier.dart';
import '../services/database_helper.dart';

final chantiersStateProvider = StateNotifierProvider<ChantiersNotifier, AsyncValue<List<Chantier>>>((ref) {
  return ChantiersNotifier(ref.read(databaseHelperProvider));
});

class ChantiersNotifier extends StateNotifier<AsyncValue<List<Chantier>>> {
  final DatabaseHelper _db;

  ChantiersNotifier(this._db) : super(const AsyncValue.data([]));

  Future<void> getChantiers(String userId) async {
    state = const AsyncValue.loading();
    try {
      final chantiers = await _db.getChantiers(userId);
      state = AsyncValue.data(chantiers);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createChantier(Chantier chantier) async {
    try {
      final newChantier = await _db.createChantier(chantier);
      state = AsyncValue.data([...state.value ?? [], newChantier]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateChantier(Chantier chantier) async {
    try {
      final updatedChantier = await _db.updateChantier(chantier);
      state = AsyncValue.data(
        (state.value ?? []).map((c) => c.id == chantier.id ? updatedChantier : c).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteChantier(String chantierId) async {
    try {
      await _db.deleteChantier(chantierId);
      state = AsyncValue.data(
        (state.value ?? []).where((c) => c.id != chantierId).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
