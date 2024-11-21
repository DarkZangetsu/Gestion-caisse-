import 'package:flutter/material.dart';
import 'package:caisse/models/personnel.dart';

class PersonnelCard extends StatelessWidget {
  final Personnel personnel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PersonnelCard({
    super.key,
    required this.personnel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: screenSize.width < 600 ? 16 : 18,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                          personnel.salaireMax?.toStringAsFixed(2) ?? 'N/A',
                          Icons.wallet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBox(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
}
