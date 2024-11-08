import 'package:flutter/material.dart';
import 'package:caisse/models/personnel.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Importer la bibliothèque uuid
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caisse/providers/users_provider.dart';

class PersonnelFormDialog extends StatefulWidget {
  final Personnel? personnel;
  final void Function(Personnel) onSave;

  const PersonnelFormDialog({
    super.key,
    this.personnel,
    required this.onSave,
  });

  @override
  _PersonnelFormDialogState createState() => _PersonnelFormDialogState();
}

class _PersonnelFormDialogState extends State<PersonnelFormDialog> {
  late final TextEditingController _nomController;
  late final TextEditingController _roleController;
  late final TextEditingController _contactController;
  late final TextEditingController _salaireMaxController;

  final uuid = Uuid();  // Instance de UUID pour générer un UUID v4

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.personnel?.name);
    _roleController = TextEditingController(text: widget.personnel?.role);
    _contactController = TextEditingController(text: widget.personnel?.contact);
    _salaireMaxController = TextEditingController(text: widget.personnel?.salaireMax?.toString());
  }

  @override
  void dispose() {
    _nomController.dispose();
    _roleController.dispose();
    _contactController.dispose();
    _salaireMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final userId = ref.watch(currentUserProvider)?.id ?? '';

        return AlertDialog(
          title: Text(widget.personnel == null ? 'Ajouter un Personnel' : 'Modifier le Personnel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Rôle'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _salaireMaxController,
                decoration: const InputDecoration(labelText: 'Salaire Maximum'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final nouveauPersonnel = Personnel(
                  id: widget.personnel?.id ?? uuid.v4(),
                  userId: widget.personnel?.userId ?? userId,
                  name: _nomController.text,
                  role: _roleController.text,
                  contact: _contactController.text,
                  salaireMax: double.tryParse(_salaireMaxController.text),
                  createdAt: widget.personnel?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                widget.onSave(nouveauPersonnel);
              },
              child: Text(widget.personnel == null ? 'Ajouter' : 'Mettre à jour'),
            ),
          ],
        );
      },
    );
  }
}
