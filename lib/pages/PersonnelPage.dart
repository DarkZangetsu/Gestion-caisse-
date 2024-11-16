import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/personnel.dart';
import '../providers/personnel_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/personnel/PersonnelCard.dart';
import '../widgets/personnel/PersonnelFormDialog.dart';

class PersonnelPage extends ConsumerWidget {
  const PersonnelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    final personnelAsyncValue = ref.watch(personnelStateProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            const MyText(texte: 'Gestion des Personnels', color: Colors.white),
        backgroundColor: const Color(0xffea6b24),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPersonnelFormDialog(context, ref, null),
          ),
        ],
      ),
      body: userId != null
          ? personnelAsyncValue.when(
              data: (personnelList) {
                if (personnelList.isEmpty) {
                  return const Center(child: Text('Aucun personnel trouvé'));
                }
                return PersonnelList(personnelList: personnelList);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Erreur : $error')),
            )
          : const Center(child: Text('Veuillez vous connecter')),
    );
  }

  void _showPersonnelFormDialog(
      BuildContext context, WidgetRef ref, Personnel? personnel) {
    showDialog(
      context: context,
      builder: (context) => PersonnelFormDialog(
        personnel: personnel,
        onSave: (newPersonnel) {
          Future.delayed(Duration.zero, () {
            if (personnel == null) {
              ref
                  .read(personnelStateProvider.notifier)
                  .createPersonnel(newPersonnel);
            } else {
              ref
                  .read(personnelStateProvider.notifier)
                  .updatePersonnel(newPersonnel);
            }
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class PersonnelList extends ConsumerWidget {
  final List<Personnel> personnelList;

  const PersonnelList({super.key, required this.personnelList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: personnelList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final personnel = personnelList[index];
        return PersonnelCard(
          personnel: personnel,
          onTap: () => _showPersonnelFormDialog(context, ref, personnel),
          onDelete: () => ref
              .read(personnelStateProvider.notifier)
              .deletePersonnel(personnel.id),
        );
      },
    );
  }

  void _showPersonnelFormDialog(
      BuildContext context, WidgetRef ref, Personnel? personnel) {
    showDialog(
      context: context,
      builder: (context) => PersonnelFormDialog(
        personnel: personnel,
        onSave: (newPersonnel) {
          Future.delayed(Duration.zero, () {
            if (personnel == null) {
              ref
                  .read(personnelStateProvider.notifier)
                  .createPersonnel(newPersonnel);
            } else {
              ref
                  .read(personnelStateProvider.notifier)
                  .updatePersonnel(newPersonnel);
            }
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
