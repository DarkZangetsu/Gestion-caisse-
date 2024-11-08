import 'package:flutter/material.dart';
import 'package:caisse/models/chantier.dart';

class ChantierCard extends StatelessWidget {
  final Chantier chantier;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChantierCard({
    super.key,
    required this.chantier,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chantier.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Budget : ${chantier.budgetMax ?? 'N/A'}'),
              const SizedBox(height: 8),
              if (chantier.startDate != null && chantier.endDate != null)
                Text('Dates : ${chantier.startDate!.toString()} - ${chantier.endDate!.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}
