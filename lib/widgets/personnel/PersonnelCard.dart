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
                personnel.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Rôle : ${personnel.role ?? 'Non défini'}'),
              const SizedBox(height: 8),
              Text('Salaire Max : ${personnel.salaireMax?.toStringAsFixed(2) ?? 'N/A'}'),
            ],
          ),
        ),
      ),
    );
  }
}
