import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_caisse_flutter/composants/text_transaction.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/models/payment_type.dart';
import 'package:gestion_caisse_flutter/models/personnel.dart';
import 'package:gestion_caisse_flutter/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:gestion_caisse_flutter/pages/home_page.dart';
import 'package:gestion_caisse_flutter/providers/accounts_provider.dart';
import 'package:gestion_caisse_flutter/providers/payment_types_provider.dart';
import 'package:gestion_caisse_flutter/providers/personnel_provider.dart';
import 'package:gestion_caisse_flutter/providers/users_provider.dart';
import 'package:intl/intl.dart';

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
                              return MyText(
                                texte: "Nom: ${person.name}",
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              );
                            },
                            loading: () => const DetailRow(
                              label: '',
                              value: '...',
                            ),
                            error: (error, stack) {
                              debugPrint('$stack');
                              return const DetailRow(
                                label: 'Personnel:',
                                value: 'Erreur de chargement',
                              );
                            },
                          );
                        },
                      ),
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
                              return MyText(
                                texte: "${type.name} (${type.category})",
                                fontSize: 12.0,
                              );
                            },
                            loading: () => const DetailRow(
                              label: '',
                              value: '...',
                            ),
                            error: (error, stack) {
                              debugPrint(
                                  'Erreur lors du chargement des types de paiement: $error');
                              debugPrint('$stack');
                              return const DetailRow(
                                label: 'Type de paiement:',
                                value: 'Erreur de chargement',
                              );
                            },
                          );
                        },
                      ),
                      if (widget.transaction.description != null &&
                          widget.transaction.description!.isNotEmpty)
                        Text(
                          widget.transaction.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      Consumer(
                        builder: (context, ref, child) {
                          final selectedAccount =
                              ref.watch(selectedAccountProvider);
                          return MyText(
                              texte: "Compte: ${selectedAccount?.name}");
                        },
                      ),
                    ]),
              ),
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
