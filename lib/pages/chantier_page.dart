import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chantier.dart';
import '../providers/chantiers_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/chantier/chantier_card.dart';
import '../widgets/chantier/chantier_form_dialog.dart';

class ChantierPage extends ConsumerWidget {
  const ChantierPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use .when() to handle the provider
    final userId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const MyText(
          texte: 'Gestion des Chantiers',
          color: Colors.white,
          fontSize: 20.0,
        ),
        backgroundColor: const Color(0xffea6b24),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: userId != null
                ? () => _showChantierFormDialog(context, ref, null, userId)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: userId != null
                ? () => ref.refresh(chantiersProvider(userId))
                : null,
          ),
        ],
      ),
      body: userId != null
          ? ref.watch(chantiersProvider(userId)).when(
                data: (chantiers) {
                  if (chantiers.isEmpty) {
                    return const Center(child: Text('Aucun chantier trouvé'));
                  }
                  return ChantierList(
                    chantiers: chantiers,
                    userId: userId,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Erreur : $error')),
              )
          : const Center(child: Text('Aucun utilisateur connecté')),
    );
  }

  void _showChantierFormDialog(
      BuildContext context, WidgetRef ref, Chantier? chantier, String userId) {
    showDialog(
      context: context,
      builder: (context) => ChantierFormDialog(
        chantier: chantier,
        onSave: (newChantier) async {
          if (chantier == null) {
            await ref
                .read(chantiersStateProvider.notifier)
                .createChantier(newChantier);
          } else {
            await ref
                .read(chantiersStateProvider.notifier)
                .updateChantier(newChantier);
          }
          if (context.mounted) {
            Navigator.of(context).pop();
            // Rafraîchir la liste après la sauvegarde
            ref.refresh(chantiersProvider(userId));
          }
        },
      ),
    );
  }
}

class ChantierList extends ConsumerWidget {
  final List<Chantier> chantiers;
  final String userId;

  const ChantierList(
      {super.key, required this.chantiers, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chantiers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final chantier = chantiers[index];
        return ChantierCard(
          chantier: chantier,
          onTap: () => _showChantierFormDialog(context, ref, chantier, userId),
          onDelete: () async {
            try {
              await ref
                  .read(chantiersStateProvider.notifier)
                  .deleteChantier(chantier.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chantier supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Rafraîchir la liste après la suppression
                ref.refresh(chantiersProvider(userId));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  void _showChantierFormDialog(
      BuildContext context, WidgetRef ref, Chantier? chantier, String userId) {
    showDialog(
      context: context,
      builder: (context) => ChantierFormDialog(
        chantier: chantier,
        onSave: (newChantier) async {
          try {
            if (chantier == null) {
              await ref
                  .read(chantiersStateProvider.notifier)
                  .createChantier(newChantier);
            } else {
              await ref
                  .read(chantiersStateProvider.notifier)
                  .updateChantier(newChantier);
            }
            if (context.mounted) {
              Navigator.of(context).pop();
              // Afficher un message de succès
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(chantier == null
                      ? 'Chantier créé avec succès'
                      : 'Chantier modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
              // Rafraîchir la liste
              ref.refresh(chantiersProvider(userId));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
