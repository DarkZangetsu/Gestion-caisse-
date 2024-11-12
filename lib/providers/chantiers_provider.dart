import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chantier.dart';
import '../services/database_helper.dart';

final chantiersStateProvider = StateNotifierProvider<ChantiersNotifier, AsyncValue<List<Chantier>>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return ChantiersNotifier(ref.read(databaseHelperProvider), userId ?? '');
});


final chantiersProvider = FutureProvider.family<List<Chantier>, String>((ref, userId) {
  return ref.read(chantiersStateProvider.notifier).getChantiers(userId);
});


class ChantiersNotifier extends StateNotifier<AsyncValue<List<Chantier>>> {
  final DatabaseHelper _db;

  ChantiersNotifier(this._db, String userId) : super(const AsyncValue.data([]));

  Future<List<Chantier>> getChantiers(String userId) async {
    try {
      return await _db.getChantiers(userId);
    } catch (e) {
      throw Exception("Erreur lors du chargement du chantier: $e");
    }
  }


  Future<void> loadChantiers(String userId) async {
    state = const AsyncValue.loading();
    try {
      final chantiers = await _db.getChantiers(userId);
      state = AsyncValue.data(chantiers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createChantier(Chantier chantier) async {
    try {
      // Crée le chantier
      final newChantier = await _db.createChantier(chantier);

      // Met à jour la liste des chantiers en ajoutant le nouveau chantier
      state = AsyncValue.data([...state.value ?? [], newChantier]);

      // Récupère les chantiers après la création
      final userId = chantier.userId;
      await getChantiers(userId);
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

