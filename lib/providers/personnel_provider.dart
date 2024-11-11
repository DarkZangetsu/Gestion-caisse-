import 'package:caisse/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/personnel.dart';
import '../services/database_helper.dart';

// Provider pour la liste du personnel
final personnelStateProvider = StateNotifierProvider<PersonnelNotifier, AsyncValue<List<Personnel>>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return PersonnelNotifier(ref.read(databaseHelperProvider), userId ?? '');
});

class PersonnelNotifier extends StateNotifier<AsyncValue<List<Personnel>>> {
  final DatabaseHelper _db;
  final String? _currentUserId;

  PersonnelNotifier(this._db, this._currentUserId) : super(const AsyncValue.loading()) {
    _loadPersonnel();
  }

  Future<void> _loadPersonnel() async {
    if (_currentUserId != null) {
      try {
        final personnelList = await getPersonnel(_currentUserId!);
        if (mounted) {
          state = AsyncValue.data(personnelList);
        }
      } catch (e) {
        if (mounted) {
          state = AsyncValue.error(e, StackTrace.current);
        }
      }
    }
  }

  Future<List<Personnel>> getPersonnel(String userId) async {
    try {
      return await _db.getPersonnel(userId);
    } catch (e) {
      throw Exception("Erreur lors du chargement du personnel: $e");
    }
  }

  Future<void> createPersonnel(Personnel personnel) async {
    try {
      final currentList = state.value ?? [];
      final newPersonnel = await _db.createPersonnel(personnel);
      if (mounted) {
        state = AsyncValue.data([...currentList, newPersonnel]);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> updatePersonnel(Personnel personnel) async {
    try {
      final currentList = state.value ?? [];
      final updatedPersonnel = await _db.updatePersonnel(personnel);
      if (mounted) {
        state = AsyncValue.data(
          currentList.map((p) => p.id == personnel.id ? updatedPersonnel : p).toList(),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> deletePersonnel(String personnelId) async {
    try {
      final currentList = state.value ?? [];
      await _db.deletePersonnel(personnelId);
      if (mounted) {
        state = AsyncValue.data(
          currentList.where((p) => p.id != personnelId).toList(),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}
