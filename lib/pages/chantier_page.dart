import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chantier.dart';
import '../providers/chantierTransactionsTotalProvider.dart';
import '../providers/chantiers_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/chantier/chantier_card.dart';
import '../widgets/chantier/chantier_form_dialog.dart';

class ChantierPage extends ConsumerStatefulWidget {
  const ChantierPage({super.key});

  @override
  ConsumerState<ChantierPage> createState() => _ChantierPageState();
}

class _ChantierPageState extends ConsumerState<ChantierPage> {
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _refreshData(String userId) async {
    try {
      setState(() {
        _isRefreshing = true;
      });

      await ref.read(chantiersProvider(userId).future);

      ref.invalidate(chantierTransactionsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données rafraîchies'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de rafraîchissement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: _isRefreshing
                ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
            )
                : const Icon(Icons.refresh),
            onPressed: userId != null && !_isRefreshing
                ? () => _refreshData(userId)
                : null,
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
                hintText: 'Rechercher un chantier...',
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(chantiersProvider(userId));
                await ref.read(chantiersProvider(userId).future);
              },
              child: ref.watch(chantiersProvider(userId)).when(
                data: (chantiers) {
                  // Filtrer les chantiers en fonction de la recherche
                  final filteredChantiers = chantiers.where((chantier) {
                    return chantier.name.toLowerCase().contains(_searchQuery) ;//||
                        //chantier.adresse.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredChantiers.isEmpty) {
                    return const Center(child: Text('Aucun chantier trouvé'));
                  }
                  return ChantierList(
                    chantiers: filteredChantiers,
                    userId: userId,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur : $error'),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(chantiersProvider(userId));
                          ref.refresh(chantiersProvider(userId));
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

              // Invalider et rafraîchir le provider
              ref.invalidate(chantiersProvider(userId));
              ref.refresh(chantiersProvider(userId));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(chantier == null
                      ? 'Chantier créé avec succès'
                      : 'Chantier modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
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

                // Invalider et rafraîchir le provider
                ref.invalidate(chantiersProvider(userId));
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

              // Invalider et rafraîchir le provider
              ref.invalidate(chantiersProvider(userId));
              ref.refresh(chantiersProvider(userId));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(chantier == null
                      ? 'Chantier créé avec succès'
                      : 'Chantier modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
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