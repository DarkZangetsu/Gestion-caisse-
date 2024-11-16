import 'package:caisse/composants/texts.dart';
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
    final userId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: const MyText(texte: 'Gestion des Chantiers', color: Colors.white,),
        backgroundColor: const Color(0xffea6b24),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showChantierFormDialog(context, ref, null),
          ),
        ],
      ),
      body: userId != null
          ? ref.watch(chantiersProvider(userId)).when(
        data: (chantiers) {
          if (chantiers.isEmpty) {
            return const Center(child: Text('Aucun chantier trouvé'));
          }
          return ChantierList(chantiers: chantiers);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Erreur : $error')),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  void _showChantierFormDialog(BuildContext context, WidgetRef ref, Chantier? chantier) {
    showDialog(
      context: context,
      builder: (context) => ChantierFormDialog(
        chantier: chantier,
        onSave: (newChantier) {
          Future.delayed(Duration.zero, () {
            if (chantier == null) {
              ref.read(chantiersStateProvider.notifier).createChantier(newChantier);
            } else {
              ref.read(chantiersStateProvider.notifier).updateChantier(newChantier);
            }
          });

          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class ChantierList extends ConsumerWidget {
  final List<Chantier> chantiers;

  const ChantierList({super.key, required this.chantiers});

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
          onTap: () => _showChantierFormDialog(context, ref, chantier),
          onDelete: () => ref.read(chantiersStateProvider.notifier).deleteChantier(chantier.id),
        );
      },
    );
  }

  void _showChantierFormDialog(BuildContext context, WidgetRef ref, Chantier? chantier) {
    showDialog(
      context: context,
      builder: (context) => ChantierFormDialog(
        chantier: chantier,
        onSave: (newChantier) {
          Future.delayed(Duration.zero, () {
            if (chantier == null) {
              ref.read(chantiersStateProvider.notifier).createChantier(newChantier);
            } else {
              ref.read(chantiersStateProvider.notifier).updateChantier(newChantier);
            }
          });

          Navigator.of(context).pop();
        },
      ),
    );
  }
}