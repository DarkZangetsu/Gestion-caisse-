import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_caisse_flutter/composants/text_transaction.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/models/payment_type.dart';
import 'package:gestion_caisse_flutter/models/personnel.dart';
import 'package:gestion_caisse_flutter/models/transaction.dart';
import 'package:gestion_caisse_flutter/models/chantier.dart';
import 'package:flutter/material.dart';
import 'package:gestion_caisse_flutter/providers/accounts_provider.dart';

import 'package:gestion_caisse_flutter/providers/payment_types_provider.dart';
import 'package:gestion_caisse_flutter/providers/personnel_provider.dart';
import 'package:gestion_caisse_flutter/providers/chantiers_provider.dart';
import 'package:gestion_caisse_flutter/providers/users_provider.dart';
import 'package:intl/intl.dart';

import '../models/accounts.dart';

class TransactionRow extends ConsumerStatefulWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  ConsumerState<TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends ConsumerState<TransactionRow> {
  @override
  void initState() {
    super.initState();
    final userId = ref.read(currentUserProvider)?.id;
    _loadPersonnel(userId);
    _loadPaymentTypes();
    _loadChantiers(userId);
  }

  Future<void> _loadPersonnel(String? userId) async {
    await ref.read(personnelStateProvider.notifier).getPersonnel(userId!);
    final personnel = ref.read(personnelStateProvider).value ?? [];
    debugPrint('Personnel chargé: ${personnel.length}');
    debugPrint(
        'Personnel: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');
  }

  Future<void> _loadPaymentTypes() async {
    await ref.read(paymentTypesProvider.notifier).getPaymentTypes();
    final types = ref.read(paymentTypesProvider).value ?? [];
    debugPrint('Types de paiement chargés: ${types.length}');
    debugPrint('Types: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');
  }

  Future<void> _loadChantiers(String? userId) async {
    await ref.read(chantiersStateProvider.notifier).getChantiers(userId!);
    final chantiers = ref.read(chantiersStateProvider).value ?? [];
    debugPrint('Chantiers chargés: ${chantiers.length}');
    debugPrint('Chantiers: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(widget.transaction.transactionDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                      // Nom du personnel
                      Consumer(
                        builder: (context, ref, _) {
                          final personnelAsync =
                          ref.watch(personnelStateProvider);
                          return personnelAsync.when(
                            data: (personnel) {
                              final person = personnel.firstWhere(
                                    (p) => p.id == widget.transaction.personnelId,
                                orElse: () {
                                  debugPrint(
                                      'Personnel non trouvé pour l\'ID: ${widget.transaction.personnelId}');
                                  debugPrint(
                                      'Personnel disponible: ${personnel.map((p) => '${p.id}: ${p.name}').join(', ')}');
                                  return Personnel(
                                      id: '', name: 'Non trouvé', userId: '');
                                },
                              );

                              // N'afficher que si le nom n'est pas vide
                              return person.name.isNotEmpty
                                  ? MyText(
                                texte: "Nom: ${person.name}",
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              )
                                  : const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) => const SizedBox.shrink(),
                          );
                        },
                      ),
                      // Nom du chantier
                      Consumer(
                        builder: (context, ref, _) {
                          final chantiersAsync = ref.watch(chantiersStateProvider);
                          return chantiersAsync.when(
                            data: (chantiers) {
                              final chantier = chantiers.firstWhere(
                                    (c) => c.id == widget.transaction.chantierId,
                                orElse: () {
                                  debugPrint(
                                      'Chantier non trouvé pour l\'ID: ${widget.transaction.chantierId}');
                                  debugPrint(
                                      'Chantiers disponibles: ${chantiers.map((c) => '${c.id}: ${c.name}').join(', ')}');
                                  return Chantier(
                                      id: '', name: 'Non trouvé', userId: '');
                                },
                              );

                              // N'afficher que si le nom du chantier n'est pas vide
                              return chantier.name.isNotEmpty
                                  ? MyText(
                                texte: "Chantier: ${chantier.name}",
                                fontSize: 12.0,
                              )
                                  : const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) => const SizedBox.shrink(),
                          );
                        },
                      ),
                      // Type de paiement
                      Consumer(
                        builder: (context, ref, _) {
                          final typesAsync = ref.watch(paymentTypesProvider);
                          return typesAsync.when(
                            data: (types) {
                              final type = types.firstWhere(
                                    (t) => t.id == widget.transaction.paymentTypeId,
                                orElse: () {
                                  debugPrint(
                                      'Type de paiement non trouvé pour l\'ID: ${widget.transaction.paymentTypeId}');
                                  debugPrint(
                                      'Types disponibles: ${types.map((t) => '${t.id}: ${t.name}').join(', ')}');
                                  return PaymentType(
                                      id: '', name: 'Non trouvé', category: '');
                                },
                              );

                              // N'afficher que si le nom et la catégorie ne sont pas vides
                              return (type.name.isNotEmpty && type.category.isNotEmpty)
                                  ? MyText(
                                texte: "${type.name} (${type.category})",
                                fontSize: 12.0,
                              )
                                  : const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) => const SizedBox.shrink(),
                          );
                        },
                      ),
                      // Description (reste inchangé mais avec une vérification supplémentaire)
                      if (widget.transaction.description != null &&
                          widget.transaction.description!.trim().isNotEmpty)
                        Text(
                          widget.transaction.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      // Compte correspondant à la transaction
                      Consumer(
                        builder: (context, ref, child) {
                          final accountsAsync = ref.watch(accountsStateProvider);

                          return accountsAsync.when(
                            data: (accounts) {
                              final account = accounts.firstWhere(
                                    (a) => a.id == widget.transaction.accountId,
                                orElse: () {
                                  debugPrint('Compte non trouvé pour l\'ID: ${widget.transaction.accountId}');
                                  debugPrint('Comptes disponibles: ${accounts.map((a) => '${a.id}: ${a.name}').join(', ')}');
                                  return Account(id: '', name: 'Non trouvé', userId: '');
                                },
                              );

                              // N'afficher que si le nom du compte n'est pas vide
                              return account.name.isNotEmpty
                                  ? MyText(
                                texte: "Compte: ${account.name}",
                                fontSize: 12.0,
                              )
                                  : const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) => const SizedBox.shrink(),
                          );
                        },
                      )
                    ]),
              ),
              // Indicateurs de montant de transaction
              Text_transaction(
                text: 'reçu',
                transaction: widget.transaction,
                color: Colors.green,
              ),
              Text_transaction(
                text: 'payé',
                transaction: widget.transaction,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}