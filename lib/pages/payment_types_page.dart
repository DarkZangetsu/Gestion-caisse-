import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_type.dart';
import '../providers/payment_types_provider.dart';
import '../widgets/paymenttype/payment_type_form.dart';
import '../widgets/paymenttype/payment_type_card.dart';

class PaymentTypesPage extends ConsumerStatefulWidget {
  const PaymentTypesPage({super.key});

  @override
  ConsumerState<PaymentTypesPage> createState() => _PaymentTypesPageState();
}

class _PaymentTypesPageState extends ConsumerState<PaymentTypesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final paymentTypesAsyncValue = ref.watch(paymentTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MyText(
          texte: 'Types de paiement',
          color: Colors.white,
        ),
        backgroundColor: const Color(0xffea6b24),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un type de paiement...',
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
            child: paymentTypesAsyncValue.when(
              data: (paymentTypeList) {
                // Filtrer les types de paiement en fonction de la recherche
                final filteredPaymentTypes = paymentTypeList.where((paymentType) {
                  return paymentType.name.toLowerCase().contains(_searchQuery) ||
                      (paymentType.category.toLowerCase().contains(_searchQuery));
                }).toList();

                if (filteredPaymentTypes.isEmpty) {
                  return const Center(child: Text('Aucun type de paiement trouvé'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPaymentTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final paymentType = filteredPaymentTypes[index];
                    return PaymentTypeCard(paymentType: paymentType);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Erreur : $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffea6b24),
        onPressed: _showAddDialog,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
