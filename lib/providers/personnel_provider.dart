import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/personnel.dart';
import '../services/database_helper.dart';

final personnelStateProvider = StateNotifierProvider<PersonnelNotifier, AsyncValue<List<Personnel>>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;  // Récupérer l'ID de l'utilisateur connecté
  return PersonnelNotifier(ref.read(databaseHelperProvider), userId ?? '');
});

final personnelProvider = FutureProvider.family<List<Personnel>, String>((ref, userId) {
  return ref.read(personnelStateProvider.notifier).getPersonnel(userId);
});

class PersonnelNotifier extends StateNotifier<AsyncValue<List<Personnel>>> {
  final DatabaseHelper _db;

  PersonnelNotifier(this._db, String userId) : super(const AsyncValue.data([])) {
    // Initialiser avec les données de personnel dès la création
    getPersonnel(userId);
  }

  // Le retour doit être Future<List<Personnel>> et non void
  Future<List<Personnel>> getPersonnel(String userId) async {
    state = const AsyncValue.loading();
    try {
      final personnel = await _db.getPersonnel(userId);
      state = AsyncValue.data(personnel);
      return personnel;  // Retourner la liste du personnel
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> createPersonnel(Personnel personnel) async {
    try {
      final newPersonnel = await _db.createPersonnel(personnel);
      state = AsyncValue.data([...state.value ?? [], newPersonnel]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updatePersonnel(Personnel personnel) async {
    try {
      final updatedPersonnel = await _db.updatePersonnel(personnel);
      state = AsyncValue.data(
        (state.value ?? []).map((p) => p.id == personnel.id ? updatedPersonnel : p).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deletePersonnel(String personnelId) async {
    try {
      await _db.deletePersonnel(personnelId);
      state = AsyncValue.data(
        (state.value ?? []).where((p) => p.id != personnelId).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
