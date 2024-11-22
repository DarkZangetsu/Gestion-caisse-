import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_type.dart';
import '../providers/payment_types_provider.dart';
import '../widgets/paymenttype/payment_type_form.dart';
import '../widgets/paymenttype/payment_type_list.dart';

class PaymentTypesPage extends ConsumerStatefulWidget {
  const PaymentTypesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentTypesPage> createState() => _PaymentTypesPageState();
}

class _PaymentTypesPageState extends ConsumerState<PaymentTypesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(paymentTypesProvider.notifier).getPaymentTypes());
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) => PaymentTypeForm(
        onSubmit: (name, category) async {
          try {
            final newPaymentType = PaymentType(
              id: const Uuid().v4(),
              name: name,
              category: category,
              createdAt: DateTime.now(),
            );
            await ref.read(paymentTypesProvider.notifier).createPaymentType(newPaymentType);
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

  Future<void> _handleRefresh() async {
    try {
      await ref.read(paymentTypesProvider.notifier).refreshPaymentTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liste des types de paiement mise à jour'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour : ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(texte: 'Types de paiement', color: Colors.white,),
        backgroundColor: const Color(0xffea6b24),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: const PaymentTypeList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffea6b24),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
}