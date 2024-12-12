import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_provider.dart';

// Provider pour calculer le reste à payer pour un personnel
final remainingPaymentProvider = FutureProvider.family<double, String>((ref, personnelId) async {
  final databaseHelper = ref.read(databaseHelperProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id;

  if (currentUserId == null) {
    throw Exception('Utilisateur non connecté');
  }

  try {
    return await databaseHelper.getRemainingPaymentForPersonnel(personnelId);
  } catch (e) {
    throw Exception('Erreur lors du calcul du reste à payer: $e');
  }
});