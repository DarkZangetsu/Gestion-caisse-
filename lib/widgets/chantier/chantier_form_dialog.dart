import 'package:flutter/material.dart';
import 'package:caisse/models/chantier.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Importer la bibliothèque uuid
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caisse/providers/users_provider.dart'; // Importer le provider de l'utilisateur

class ChantierFormDialog extends StatefulWidget {
  final Chantier? chantier;
  final void Function(Chantier) onSave;

  const ChantierFormDialog({
    super.key,
    this.chantier,
    required this.onSave,
  });

  @override
  _ChantierFormDialogState createState() => _ChantierFormDialogState();
}

class _ChantierFormDialogState extends State<ChantierFormDialog> {
  late final TextEditingController _nomController;
  late final TextEditingController _budgetController;
  late DateTime? _dateDebut;
  late DateTime? _dateFin;

  final uuid = Uuid();  // Instance de UUID pour générer un UUID v4

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.chantier?.name);
    _budgetController = TextEditingController(text: widget.chantier?.budgetMax?.toString());
    _dateDebut = widget.chantier?.startDate;
    _dateFin = widget.chantier?.endDate;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final userId = ref.watch(currentUserProvider)?.id ?? ''; // Récupérer l'ID de l'utilisateur connecté via le provider

        return AlertDialog(
          title: Text(widget.chantier == null ? 'Ajouter un Chantier' : 'Modifier le Chantier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'Budget Maximum'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateDebut ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateDebut = picked;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: TextEditingController(
                            text: _dateDebut != null ? DateFormat('yyyy-MM-dd').format(_dateDebut!) : '',
                          ),
                          decoration: const InputDecoration(labelText: 'Date de début'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateFin ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateFin = picked;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: TextEditingController(
                            text: _dateFin != null ? DateFormat('yyyy-MM-dd').format(_dateFin!) : '',
                          ),
                          decoration: const InputDecoration(labelText: 'Date de fin'),
                        ),
                      ),
                    ),
                  ),
                ],
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
                final nouveauChantier = Chantier(
                  id: widget.chantier?.id ?? uuid.v4(),  // Génère un UUID v4 si l'ID est vide
                  userId: widget.chantier?.userId ?? userId,
                  name: _nomController.text,
                  budgetMax: double.tryParse(_budgetController.text),
                  startDate: _dateDebut,
                  endDate: _dateFin,
                  createdAt: widget.chantier?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                widget.onSave(nouveauChantier);
              },
              child: Text(widget.chantier == null ? 'Ajouter' : 'Mettre à jour'),
            ),
          ],
        );
      },
    );
  }
}
