import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_type_card.dart';
import '../../providers/payment_types_provider.dart';

class PaymentTypeList extends ConsumerWidget {
  const PaymentTypeList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentTypesAsync = ref.watch(paymentTypesProvider);

    return paymentTypesAsync.when(
      data: (paymentTypes) {
        if (paymentTypes.isEmpty) {
          return const Center(child: Text('Aucun type de paiement trouvé'));
        }
        return ListView.builder(
          itemCount: paymentTypes.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final paymentType = paymentTypes[index];
            return PaymentTypeCard(paymentType: paymentType);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: ${error.toString()}'),
      ),
    );
  }
}