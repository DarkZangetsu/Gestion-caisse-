import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gestion_caisse_flutter/models/personnel.dart';

import '../../providers/remainingPaymentProvider.dart';

class PersonnelCard extends ConsumerWidget {
  final Personnel personnel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRefresh;

  const PersonnelCard({
    super.key,
    required this.personnel,
    required this.onTap,
    required this.onDelete,
    this.onRefresh,
  });

  // French number formatter with two decimal places
  String _formatCurrency(double? value) {
    if (value == null) return 'N/A';
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return '${formatter.format(value)} Ar';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenir la taille de l'écran
    final screenSize = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapter le padding en fonction de la taille de l'écran
        final paddingValue = screenSize.width < 600 ? 12.0 : 16.0;

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          margin: EdgeInsets.all(paddingValue / 2),
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Padding(
                padding: EdgeInsets.all(paddingValue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            personnel.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: screenSize.width < 600 ? 16 : 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showOptionsMenu(
                                context, personnel, onDelete, onRefresh);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          onPressed: onDelete,
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBox(
                            context,
                            'Rôle',
                            personnel.role ?? 'Non défini',
                            Icons.work,
                          ),
                        ),
                        _buildInfoBox(
                          context,
                          'Salaire Max',
                          _formatCurrency(personnel.salaireMax),
                          Icons.wallet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Ajout du reste à payer
                    _buildRemainingPaymentSection(context, ref),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemainingPaymentSection(BuildContext context, WidgetRef ref) {
    final remainingPaymentAsync = ref.watch(remainingPaymentProvider(personnel.id));

    return remainingPaymentAsync.when(
      data: (remainingPayment) => _buildInfoBox(
        context,
        'Reste à Payer',
        _formatCurrency(remainingPayment),
        Icons.payment,
        backgroundColor: remainingPayment > 0
            ? Colors.orange.shade100
            : Colors.green.shade100,
      ),
      loading: () => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      error: (error, stack) => _buildInfoBox(
        context,
        'Reste à Payer',
        'Erreur',
        Icons.error_outline,
        backgroundColor: Colors.red.shade100,
      ),
    );
  }

  Widget _buildInfoBox(
      BuildContext context,
      String label,
      String value,
      IconData icon, {
        Color? backgroundColor,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xffea6b24)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context,
      Personnel personnel,
      VoidCallback onDelete,
      VoidCallback? onRefresh) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                  Icons.menu_book_sharp, color: Colors.blue),
              title: const Text(
                'Consulter transaction',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                Navigator.pushNamed(
                    context,
                    '/transaction-personnel',
                    arguments: {'personnelId': personnel.id}
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}