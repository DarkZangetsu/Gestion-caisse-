import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/personnel.dart';
import '../providers/personnel_provider.dart';
import '../providers/remainingPaymentProvider.dart';
import '../providers/users_provider.dart';
import '../widgets/personnel/PersonnelCard.dart';
import '../widgets/personnel/PersonnelFormDialog.dart';

class PersonnelPage extends ConsumerStatefulWidget {
  const PersonnelPage({super.key});

  @override
  ConsumerState<PersonnelPage> createState() => _PersonnelPageState();
}

class _PersonnelPageState extends ConsumerState<PersonnelPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void refreshAllData() {
    ref.refresh(personnelStateProvider);
    ref.invalidate(remainingPaymentProvider);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;
    final personnelAsyncValue = ref.watch(personnelStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MyText(texte: 'Gestion des Personnels', color: Colors.white),
        backgroundColor: const Color(0xffea6b24),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshAllData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPersonnelFormDialog(context, ref, null),
          ),
        ],
      ),
      body: userId != null
          ? Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un personnel...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: personnelAsyncValue.when(
              data: (personnelList) {
                // Filtrer les personnels en fonction de la recherche
                final filteredPersonnelList = personnelList.where((personnel) {
                  return personnel.name.toLowerCase().contains(_searchQuery) ||
                      personnel.role != null && personnel.role!.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredPersonnelList.isEmpty) {
                  return const Center(child: Text('Aucun personnel trouvé'));
                }
                return PersonnelList(personnelList: filteredPersonnelList);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Erreur : $error')),
            ),
          ),
        ],
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
        onSave: (newPersonnel) async {
          try {
            final userId = ref.read(currentUserProvider)?.id;
            if (userId == null) {
              throw Exception('Utilisateur non connecté');
            }

            if (personnel == null) {
              await ref
                  .read(personnelStateProvider.notifier)
                  .createPersonnel(newPersonnel);
            } else {
              await ref
                  .read(personnelStateProvider.notifier)
                  .updatePersonnel(newPersonnel);
            }

            if (context.mounted) {
              Navigator.of(context).pop();
              // Afficher un message de succès
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(personnel == null
                      ? 'Personnel créé avec succès'
                      : 'Personnel modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
              // Rafraîchir la liste et le provider de paiement restant
              ref.refresh(personnelStateProvider);
              ref.invalidate(remainingPaymentProvider);
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
          onDelete: () => _showDeleteConfirmation(context, ref, personnel),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Personnel personnel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation de suppression'),
        content: Text('Voulez-vous vraiment supprimer ${personnel.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(personnelStateProvider.notifier).deletePersonnel(personnel.id);

              // Refresh remaining payment provider after deletion
              ref.invalidate(remainingPaymentProvider);

              Navigator.of(context).pop();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPersonnelFormDialog(
      BuildContext context, WidgetRef ref, Personnel? personnel) {
    showDialog(
      context: context,
      builder: (context) => PersonnelFormDialog(
        personnel: personnel,
        onSave: (newPersonnel) async {
          try {
            final userId = ref.read(currentUserProvider)?.id;
            if (userId == null) {
              throw Exception('Utilisateur non connecté');
            }

            if (personnel == null) {
              await ref
                  .read(personnelStateProvider.notifier)
                  .createPersonnel(newPersonnel);
            } else {
              await ref
                  .read(personnelStateProvider.notifier)
                  .updatePersonnel(newPersonnel);
            }

            if (context.mounted) {
              Navigator.of(context).pop();
              // Afficher un message de succès
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(personnel == null
                      ? 'Personnel créé avec succès'
                      : 'Personnel modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
              // Rafraîchir la liste et le provider de paiement restant
              ref.refresh(personnelStateProvider);
              ref.invalidate(remainingPaymentProvider);
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