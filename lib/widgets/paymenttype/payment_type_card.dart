import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/payment_type.dart';
import '../../providers/payment_types_provider.dart';
import '../../providers/selected_chantier_personnel_provider.dart';
import 'payment_type_form.dart';

class PaymentTypeCard extends ConsumerWidget {
  final PaymentType paymentType;

  const PaymentTypeCard({
    Key? key,
    required this.paymentType,
  }) : super(key: key);

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (context) => PaymentTypeForm(
        initialName: paymentType.name,
        initialCategory: paymentType.category,
        onSubmit: (name, category) async {
          try {
            final updatedPaymentType = PaymentType(
              id: paymentType.id,
              name: name,
              category: category,
              createdAt: paymentType.createdAt,
            );
            await ref.read(paymentTypesProvider.notifier).updatePaymentType(updatedPaymentType);
            if (context.mounted) {
              Navigator.pop(context);
            }
            return true;
          } catch (e) {
            return false;
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext parentContext, WidgetRef ref) {
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${paymentType.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Vérifier les transactions avant la suppression
                final transactions = await ref.read(databaseHelperProvider)
                    .getTransactionsByPaymentType(paymentType.id);

                // Si des transactions existent, afficher un dialogue d'interdiction
                if (transactions.isNotEmpty) {
                  if (parentContext.mounted) {
                    await showDialog(
                      context: parentContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Suppression impossible'),
                        content: Text('Ce type de paiement est utilisé dans ${transactions.length} transaction(s). '
                            'Vous ne pouvez pas le supprimer tant que ces transactions existent.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                // Supprimer le type de paiement
                await ref.read(paymentTypesProvider.notifier)
                    .deletePaymentType(paymentType.id);

                // Fermer les dialogues
                if (parentContext.mounted) {
                  Navigator.pop(context); // Ferme le dialogue de confirmation
                }
              } catch (e) {
                // Gérer les erreurs potentielles
                if (parentContext.mounted) {
                  await showDialog(
                    context: parentContext,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Erreur'),
                      content: Text('Une erreur est survenue : $e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(paymentType.name),
        subtitle: Text(paymentType.category),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}