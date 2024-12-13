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

    // Use WidgetsBinding to ensure the widget is mounted before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        _loadData(userId);
      }
    });
  }

  Future<void> _loadData(String userId) async {
    try {
      await Future.wait([
        ref.read(personnelStateProvider.notifier).getPersonnel(userId),
        ref.read(paymentTypesProvider.notifier).getPaymentTypes(),
        ref.read(chantiersStateProvider.notifier).getChantiers(userId),
      ]);
    } catch (e) {
      debugPrint('Error loading transaction row data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Consumer(
      builder: (context, ref, _) {
        final chantiersAsync = ref.watch(chantiersStateProvider);

        return chantiersAsync.when(
          data: (chantiers) {
            final chantier = chantiers.firstWhere(
                  (c) => c.id == widget.transaction.chantierId,
              orElse: () => Chantier(id: '', name: '', userId: ''),
            );

            debugPrint('Chantier color: ${chantier.color}');
            debugPrint('Chantier colorValue: ${chantier.colorValue}');

            return InkWell(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: chantier.colorValue ?? Colors.grey[200]!,
                      width: 4,
                    ),
                  ),
                  color: chantier.colorValue != null
                      ? chantier.colorValue!.withOpacity(0.2)
                      : Theme.of(context).colorScheme.primary,
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
                                final personnelAsync = ref.watch(personnelStateProvider);
                                return personnelAsync.when(
                                  data: (personnel) {
                                    if (widget.transaction.personnelId == null) return const SizedBox.shrink();

                                    final person = personnel.firstWhere(
                                          (p) => p.id == widget.transaction.personnelId,
                                      orElse: () => Personnel(id: '', name: '', userId: ''),
                                    );

                                    // N'afficher que si le nom n'est pas vide
                                    return person.name.isNotEmpty
                                        ? MyText(
                                      texte: "${person.name}",
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
                            if (chantier.name.isNotEmpty)
                              MyText(
                                texte: "${chantier.name}",
                                fontSize: 12.0,
                              ),
                            // Type de paiement
                            Consumer(
                              builder: (context, ref, _) {
                                final typesAsync = ref.watch(paymentTypesProvider);
                                return typesAsync.when(
                                  data: (types) {
                                    if (widget.transaction.paymentTypeId == null) return const SizedBox.shrink();

                                    final type = types.firstWhere(
                                          (t) => t.id == widget.transaction.paymentTypeId,
                                      orElse: () => PaymentType(id: '', name: '', category: ''),
                                    );

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
                                overflow: TextOverflow.ellipsis,
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
                                    if (widget.transaction.accountId == null) return const SizedBox.shrink();

                                    final account = accounts.firstWhere(
                                          (a) => a.id == widget.transaction.accountId,
                                      orElse: () => Account(id: '', name: '', userId: '', solde: 0.0),
                                    );

                                    // N'afficher que si le nom du compte n'est pas vide
                                    return account.name.isNotEmpty
                                        ? MyText(
                                      texte: "${account.name}",
                                      fontSize: 12.0,
                                    )
                                        : const SizedBox.shrink();
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (error, stackTrace) => const SizedBox.shrink(),
                                );
                              },
                            )
                          ],
                        ),
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
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('Erreur de chargement: $error'),
        );
      },
    );
  }
}